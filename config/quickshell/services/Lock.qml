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

    function lock() {
        if (locked) return;
        Panels.close();
        password = "";
        failed = false;
        message = "";
        locked = true;
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
                root.locked = false;
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

    IpcHandler {
        target: "lock"
        function lock(): void { root.lock(); }
        function status(): string {
            return JSON.stringify({locked: root.locked, checking: root.checking, failures: root.failures});
        }
    }
}
