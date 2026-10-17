pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth as Blue
import Quickshell.Io

// bluez's own pairing agent (bluetoothctl), registered as the default agent
// so pairing asks to confirm a passkey or enter a PIN instead of pairing
// blind. The Bluetooth page answers its prompts; requests that arrive while
// no panel is open open that page, and while locked every request is refused.
Singleton {
    id: root
    property bool ready: false          // registered as the default agent
    // The pending request: "confirm", "pin", "passkey", "pairing" or "service"
    // wait for an answer; "displayPin" and "displayPasskey" show a code to
    // type on the device. Empty when nothing is pending.
    property string type: ""
    property string code: ""            // the passkey or PIN to confirm or show
    property string service: ""         // the service UUID, for "service"
    readonly property bool answerable: ["confirm", "pin", "passkey", "pairing", "service"].includes(type)
    property string pending: ""         // output after the last line break
    property string answered: ""        // the prompt just answered, see ask()

    function respond(value) {
        if (answerable) {
            agent.write(value + "\n");
            answered = type + ":" + code + service;
            forgetAnswer.restart();
        }
        clear();
    }
    // Refuses the request, or stops the pairing whose code is on screen.
    function cancel() {
        if (answerable) respond("no");
        else if (type !== "") {
            Blue.Bluetooth.devices.values.filter(device => device.pairing).forEach(device => device.cancelPair());
            clear();
        }
    }
    function clear() { type = ""; code = ""; service = ""; }

    function ask(kind, value) {
        // bluetoothctl redraws a waiting prompt around other output, and a
        // redraw can still arrive just after the answer.
        if (kind === type && value === code + service) return;
        if (kind + ":" + value === answered) return;
        code = kind === "service" ? "" : value;
        service = kind === "service" ? value : "";
        type = kind;
        if (Lock.locked) cancel();
        else Panels.openPage("system", "bluetooth");
    }
    // One line of output with its color codes removed; returns whether it
    // was a prompt.
    function parse(line) {
        let match;
        if ((match = line.match(/Confirm passkey (\d+) \(yes\/no\)/))) ask("confirm", match[1]);
        else if (line.includes("Enter PIN code:")) ask("pin", "");
        else if (line.includes("Enter passkey (number")) ask("passkey", "");
        else if (/Accept pairing.*\(yes\/no\)/.test(line)) ask("pairing", "");
        else if ((match = line.match(/Authorize service (\S+) \(yes\/no\)/))) ask("service", match[1]);
        else if ((match = line.match(/\[agent\] PIN code: (\S+)/))) ask("displayPin", match[1]);
        else if ((match = line.match(/\[agent\] Passkey: (\d+)/))) ask("displayPasskey", match[1]);
        else {
            if (line.includes("Default agent request successful")) ready = true;
            else if (/Agent released|No agent is registered|Failed to (register|request default) agent/.test(line)) ready = false;
            else if (line.includes("Request canceled")) clear();
            else if (/(Paired|Bonded): yes/.test(line) && type.startsWith("display")) clear();
            return false;
        }
        return true;
    }

    Process {
        id: agent
        running: true
        command: ["bluetoothctl", "--agent", "KeyboardDisplay"]
        stdinEnabled: true
        onStarted: write("default-agent\n")
        onExited: {
            root.ready = false;
            root.clear();
            root.pending = "";
            restart.start();
        }
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                const lines = (root.pending + data).split(/[\r\n]/);
                root.pending = lines.pop();
                const strip = line => line.replace(/\x1b\[[0-9;?]*[A-Za-z]/g, "");
                lines.forEach(line => root.parse(strip(line)));
                // Prompts wait for input without a line break. Drop one once
                // handled, so the answer echoed after it doesn't repeat it.
                if (root.parse(strip(root.pending))) root.pending = "";
            }
        }
    }
    Timer { id: restart; interval: 5000; onTriggered: agent.running = true }
    Timer { id: forgetAnswer; interval: 1000; onTriggered: root.answered = "" }

    // Closing the panel answers the prompt it was showing.
    Connections {
        target: Panels
        function onOpenChanged() { if (Panels.open !== "system") root.cancel(); }
    }
}
