pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

// Session lock state and the password check. Only a successful PAM
// authentication unlocks; there is deliberately no IPC call to unlock.
Singleton {
    id: root
    property bool locked: false
    property string password: ""
    property bool checking: false
    property bool failed: false
    property int failures: 0            // bumps on each failure, for the shake
    property string message: ""         // PAM's own explanation, e.g. a faillock notice

    // Fingerprint runs as its own PAM session next to the password one.
    property bool fingerprintEnrolled: false
    property string fingerprint: "off"  // "off", "listening", "mismatch" or "exhausted"
    property string fingerprintPrompt: ""   // fprintd's own wording, naming the enrolled finger
    // Misses over the whole lock. pam_fprintd's max-tries counts per PAM
    // session, and a new session starts after every wake-up or error.
    property int fingerprintMisses: 0
    readonly property int fingerprintTries: 5
    property bool sleeping: false       // from logind's PrepareForSleep until the wake-up

    // A reload starts the config over with locked false, and the new
    // WlSessionLock then releases the session. Don't reload on file changes
    // while locked.
    Binding { target: Quickshell; property: "watchFiles"; value: !root.locked }

    function lock() {
        if (locked) return;
        Panels.close();
        password = "";
        failed = false;
        message = "";
        fingerprintMisses = 0;
        locked = true;
        enrolled.running = true;        // fingers may have been enrolled since the last lock
    }
    function unlock() {
        locked = false;
        password = "";
        if (pam.active) pam.abort();
        if (finger.active) finger.abort();
        fingerprint = "off";
    }
    function listenForFingerprint() {
        if (!locked || sleeping || !fingerprintEnrolled || finger.active) return;
        if (fingerprintMisses >= fingerprintTries) { fingerprint = "exhausted"; return; }
        fingerprint = "listening";
        finger.start();
        if (!finger.active) fingerprint = "off";     // fprintd or the PAM file is missing
    }
    function submit() {
        if (!locked || checking || password === "") return;
        checking = true;
        failed = false;
        message = "";
        pam.start();
    }

    // lock/pam/password: the system-auth stack without fingerprint login.
    PamContext {
        id: pam
        configDirectory: Quickshell.shellPath("lock/pam")
        config: "password"
        onPamMessage: {
            if (responseRequired) respond(root.password);
            else if (messageIsError) root.message = message;
        }
        onCompleted: result => {
            root.checking = false;
            root.password = "";
            if (result === PamResult.Success) {
                root.failures = 0;
                root.unlock();
                return;
            }
            root.failed = true;
            root.failures++;
            if (result === PamResult.MaxTries) root.message = "Too many attempts. Try again later.";
        }
        onError: error => {
            root.checking = false;
            root.password = "";
            root.failed = true;
            root.failures++;
            root.message = "Authentication error: " + PamError.toString(error);
        }
    }

    PamContext {
        id: finger
        configDirectory: Quickshell.shellPath("lock/pam")
        config: "fingerprint"
        onPamMessage: {
            if (responseRequired) respond("");
            else if (!messageIsError) root.fingerprintPrompt = message;
            else if (root.locked) {
                // Counts retry hints ("too fast") too, which errs toward the password.
                root.fingerprintMisses++;
                if (root.fingerprintMisses >= root.fingerprintTries) {
                    Qt.callLater(() => { if (finger.active) finger.abort(); });
                    root.fingerprint = "exhausted";
                    return;
                }
                root.fingerprint = "mismatch";
                backToListening.restart();
            }
        }
        onCompleted: result => {
            if (result === PamResult.Success && root.locked) { root.unlock(); return; }
            if (!root.locked) return;
            // Five mismatches end the session; anything else (the reader busy
            // elsewhere, fprintd restarting) is retried shortly.
            if (result === PamResult.Failed || result === PamResult.MaxTries) root.fingerprint = "exhausted";
            else retry.restart();
        }
        onError: { if (root.locked) retry.restart(); }
    }
    Timer { id: backToListening; interval: 2000; onTriggered: if (root.fingerprint === "mismatch") root.fingerprint = "listening" }
    Timer { id: retry; interval: 5000; onTriggered: root.listenForFingerprint() }

    // fprintd suspends the reader with the system and can't while a scan is
    // open, and a scan left open across a suspend never reports again. The
    // lock usually starts right before sleep (hypridle's before_sleep_cmd), so
    // stop the scan for the suspend and start a new one after the wake-up,
    // once the reader is back.
    Process {
        running: true
        command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1", "--object-path", "/org/freedesktop/login1"]
        stdout: SplitParser {
            onRead: line => {
                const match = line.match(/\.PrepareForSleep \((true|false),\)/);
                if (!match) return;
                root.sleeping = match[1] === "true";
                if (root.sleeping) {
                    if (finger.active) finger.abort();
                    retry.stop();
                    afterWake.stop();
                } else {
                    afterWake.restart();
                }
            }
        }
    }
    Timer { id: afterWake; interval: 2000; onTriggered: root.listenForFingerprint() }

    // Whether this account has fingerprints enrolled on any reader.
    Process {
        id: enrolled
        running: true
        command: ["fprintd-list", Quickshell.env("USER") || ""]
        property bool found: false
        onStarted: found = false
        stdout: SplitParser { onRead: line => { if (/^\s*-\s*#\d+:/.test(line)) enrolled.found = true; } }
        onExited: {
            root.fingerprintEnrolled = found;
            root.listenForFingerprint();
        }
    }

    IpcHandler {
        target: "lock"
        function lock(): void { root.lock(); }
        function status(): string {
            return JSON.stringify({locked: root.locked, checking: root.checking, failures: root.failures,
                fingerprint: root.fingerprint, fingerprintEnrolled: root.fingerprintEnrolled});
        }
    }
}
