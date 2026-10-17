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

    function lock() {
        if (locked) return;
        Panels.close();
        password = "";
        failed = false;
        message = "";
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
        if (!locked || !fingerprintEnrolled || finger.active) return;
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
