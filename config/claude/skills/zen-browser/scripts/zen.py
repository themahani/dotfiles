#!/usr/bin/env python3
"""Drive the Zen browser (Firefox-based) over Marionette. Stdlib only.

Each invocation opens a fresh Marionette session against the running browser,
does one thing, and disconnects. Marionette window handles are random per session, so tabs are addressed by
their number in `tabs` or by a substring of their URL/title; without --tab,
commands act on the browser's currently selected tab.
"""
import argparse
import base64
import json
import os
import shutil
import socket
import subprocess
import sys
import time

HOST = os.environ.get("ZEN_MARIONETTE_HOST", "127.0.0.1")
PORT = int(os.environ.get("ZEN_MARIONETTE_PORT", "2828"))
ZEN_BIN = os.environ.get("ZEN_BIN") or shutil.which("zen-browser") or "/opt/zen-browser-bin/zen-bin"
ELEMENT_KEY = "element-6066-11e4-a52e-4f735466cecf"


class MarionetteError(Exception):
    pass


class Marionette:
    def __init__(self, host=HOST, port=PORT, timeout=60):
        self.sock = socket.create_connection((host, port), timeout=timeout)
        self.buf = b""
        self.msg_id = 0
        self._read()  # server hello: {"applicationType": "gecko", "marionetteProtocol": 3}

    def _read(self):
        while b":" not in self.buf:
            self._recv()
        length, _, rest = self.buf.partition(b":")
        length = int(length)
        self.buf = rest
        while len(self.buf) < length:
            self._recv()
        data, self.buf = self.buf[:length], self.buf[length:]
        return json.loads(data)

    def _recv(self):
        chunk = self.sock.recv(65536)
        if not chunk:
            raise MarionetteError("connection closed by browser")
        self.buf += chunk

    def call(self, command, params=None):
        self.msg_id += 1
        payload = json.dumps([0, self.msg_id, command, params or {}]).encode()
        self.sock.sendall(str(len(payload)).encode() + b":" + payload)
        while True:
            msg = self._read()
            if msg[0] == 1 and msg[1] == self.msg_id:
                break
        _, _, error, result = msg
        if error:
            raise MarionetteError(f"{error.get('error')}: {error.get('message')}")
        return result

    def value(self, command, params=None):
        result = self.call(command, params)
        if isinstance(result, dict) and "value" in result:
            return result["value"]
        return result

    def close(self):
        try:
            self.call("WebDriver:DeleteSession")
        except Exception:
            pass
        self.sock.close()


def port_open(host=HOST, port=PORT):
    try:
        socket.create_connection((host, port), timeout=1).close()
        return True
    except OSError:
        return False


def connect(return_caps=False):
    if not port_open():
        sys.exit(f"zen: nothing listening on {HOST}:{PORT}. Run `zen.py start` "
                 "(Zen must be launched with --marionette; an already-running Zen "
                 "without it has to be quit first).")
    m = Marionette()
    r = m.call("WebDriver:NewSession", {"capabilities": {"alwaysMatch": {"pageLoadStrategy": "normal"}}})
    return (m, r.get("capabilities", {})) if return_caps else m


def tab_list(m):
    """[(handle, title, url)] in tab order; leaves the session on the original tab."""
    current = m.value("WebDriver:GetWindowHandle")
    out = []
    for h in m.value("WebDriver:GetWindowHandles"):
        m.call("WebDriver:SwitchToWindow", {"handle": h, "focus": False})
        out.append((h, m.value("WebDriver:GetTitle"), m.value("WebDriver:GetCurrentURL")))
    m.call("WebDriver:SwitchToWindow", {"handle": current, "focus": False})
    return out


def resolve_tab(m, spec):
    """Tab number from `tabs`, or a case-insensitive substring of its URL or title."""
    tabs = tab_list(m)
    if spec.isdigit():
        i = int(spec)
        if not 0 <= i < len(tabs):
            sys.exit(f"zen: no tab #{i} (there are {len(tabs)})")
        return tabs[i][0]
    hits = [t for t in tabs if spec.lower() in (t[1] + " " + t[2]).lower()]
    if len(hits) != 1:
        found = "\n".join(f"  {t[1]}\t{t[2]}" for t in hits)
        sys.exit(f"zen: --tab {spec!r} matched {len(hits)} tabs" + (f":\n{found}" if hits else ""))
    return hits[0][0]


def use_tab(m, tab, focus=False):
    if tab:
        m.call("WebDriver:SwitchToWindow", {"handle": resolve_tab(m, tab), "focus": focus})


def selector(ref):
    """`@12` -> the element tagged by `elements`; anything else is a CSS selector."""
    return f'[data-zenref="{ref[1:]}"]' if ref.startswith("@") else ref


def find(m, ref):
    el = m.value("WebDriver:FindElement", {"using": "css selector", "value": selector(ref)})
    return el[ELEMENT_KEY]


def script(m, body, args=()):
    return m.value("WebDriver:ExecuteScript", {"script": body, "args": list(args)})


ELEMENTS_JS = r"""
const sel = 'a[href], button, input:not([type=hidden]), textarea, select, summary, ' +
  '[role=button], [role=link], [role=tab], [role=menuitem], [role=checkbox], ' +
  '[contenteditable=""], [contenteditable=true], [onclick]';
document.querySelectorAll('[data-zenref]').forEach(e => e.removeAttribute('data-zenref'));
const out = [];
let n = 0;
for (const e of document.querySelectorAll(sel)) {
  const r = e.getBoundingClientRect();
  const st = getComputedStyle(e);
  if (r.width === 0 || r.height === 0 || st.visibility === 'hidden' || st.display === 'none') continue;
  n += 1;
  e.setAttribute('data-zenref', n);
  const label = (e.getAttribute('aria-label') || e.innerText || e.value || e.placeholder ||
                 e.title || e.name || '').trim().replace(/\s+/g, ' ').slice(0, 80);
  const kind = e.tagName.toLowerCase() + (e.type && e.tagName !== 'BUTTON' ? '[' + e.type + ']' : '');
  const href = e.tagName === 'A' ? e.getAttribute('href') : '';
  out.push(`@${n} ${kind} "${label}"` + (href ? ` -> ${href}` : ''));
}
return out.join('\n');
"""


def cmd_start(a):
    if port_open():
        print(f"already listening on {HOST}:{PORT}")
        return
    args = [ZEN_BIN, "--marionette"]
    if a.headless:
        args.append("--headless")
    if a.profile:
        args += ["--profile", a.profile]
    subprocess.Popen(args, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                     stderr=subprocess.DEVNULL, start_new_session=True)
    for _ in range(60):
        if port_open():
            print(f"Zen started; Marionette on {HOST}:{PORT}")
            return
        time.sleep(0.5)
    sys.exit("zen: started Zen but Marionette never came up. If Zen was already "
             "running without --marionette, the launch was handed to that instance; "
             "quit Zen and retry.")


def cmd_status(a):
    if not port_open():
        print("down")
        sys.exit(1)
    m, c = connect(return_caps=True)
    print(f"up: {c.get('browserName')} {c.get('browserVersion')} on {HOST}:{PORT}")
    m.close()


def cmd_tabs(a):
    m = connect()
    current = m.value("WebDriver:GetWindowHandle")
    for i, (h, title, url) in enumerate(tab_list(m)):
        print(f"{'*' if h == current else ' '} {i}\t{title}\t{url}")
    m.close()


def cmd_open(a):
    m = connect()
    h = m.value("WebDriver:NewWindow", {"type": "tab", "focus": True})["handle"]
    m.call("WebDriver:SwitchToWindow", {"handle": h, "focus": True})
    if a.url:
        m.call("WebDriver:Navigate", {"url": a.url})
    n = m.value("WebDriver:GetWindowHandles").index(h)
    print(f"{n}\t{m.value('WebDriver:GetTitle')}\t{m.value('WebDriver:GetCurrentURL')}")
    m.close()


def cmd_nav(a):
    m = connect()
    use_tab(m, a.tab)
    if a.url == "back":
        m.call("WebDriver:Back")
    elif a.url == "forward":
        m.call("WebDriver:Forward")
    elif a.url == "reload":
        m.call("WebDriver:Refresh")
    else:
        m.call("WebDriver:Navigate", {"url": a.url})
    print(f"{m.value('WebDriver:GetTitle')}\t{m.value('WebDriver:GetCurrentURL')}")
    m.close()


def cmd_focus(a):
    m = connect()
    use_tab(m, a.tab, focus=True)
    m.close()


def cmd_close(a):
    m = connect()
    use_tab(m, a.tab)
    m.call("WebDriver:CloseWindow")
    m.close()


def cmd_text(a):
    m = connect()
    use_tab(m, a.tab)
    body = "const e = document.querySelector(arguments[0]); return e ? e.innerText : null;"
    text = script(m, body, [selector(a.selector)])
    if text is None:
        sys.exit(f"zen: no element matches {a.selector}")
    print(text[: a.max] if a.max else text)
    m.close()


def cmd_html(a):
    m = connect()
    use_tab(m, a.tab)
    if a.selector:
        html = script(m, "const e = document.querySelector(arguments[0]); return e ? e.outerHTML : null;",
                      [selector(a.selector)])
    else:
        html = m.value("WebDriver:GetPageSource")
    print(html[: a.max] if a.max else html)
    m.close()


def cmd_elements(a):
    m = connect()
    use_tab(m, a.tab)
    print(script(m, ELEMENTS_JS) or "(no visible interactive elements)")
    m.close()


def cmd_click(a):
    m = connect()
    use_tab(m, a.tab)
    m.call("WebDriver:ElementClick", {"id": find(m, a.target)})
    print(f"{m.value('WebDriver:GetTitle')}\t{m.value('WebDriver:GetCurrentURL')}")
    m.close()


def cmd_type(a):
    m = connect()
    use_tab(m, a.tab)
    el = find(m, a.target)
    if a.clear:
        m.call("WebDriver:ElementClear", {"id": el})
    text = a.text + ("" if a.enter else "")  #  = WebDriver Enter key
    m.call("WebDriver:ElementSendKeys", {"id": el, "text": text})
    m.close()


def cmd_eval(a):
    m = connect()
    use_tab(m, a.tab)
    src = sys.stdin.read() if a.js == "-" else a.js
    if "return" not in src:
        src = f"return ({src});"
    result = script(m, src)
    print(result if isinstance(result, str) else json.dumps(result, indent=2))
    m.close()


def cmd_screenshot(a):
    m = connect()
    use_tab(m, a.tab)
    params = {"full": a.full}
    if a.selector:
        params["id"] = find(m, a.selector)
    png = base64.b64decode(m.value("WebDriver:TakeScreenshot", params))
    with open(a.out, "wb") as f:
        f.write(png)
    print(a.out)
    m.close()


def cmd_wait(a):
    m = connect()
    use_tab(m, a.tab)
    deadline = time.time() + a.timeout
    while time.time() < deadline:
        if script(m, "return !!document.querySelector(arguments[0]);", [selector(a.selector)]):
            print("found")
            m.close()
            return
        time.sleep(0.25)
    m.close()
    sys.exit(f"zen: timed out waiting for {a.selector}")


def main():
    p = argparse.ArgumentParser(prog="zen.py", description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)

    def add(name, fn, help, tab=True):
        sp = sub.add_parser(name, help=help)
        if tab:
            sp.add_argument("--tab", help="tab number from `tabs` or URL/title substring (default: selected tab)")
        sp.set_defaults(fn=fn)
        return sp

    sp = add("start", cmd_start, "launch Zen with Marionette enabled", tab=False)
    sp.add_argument("--headless", action="store_true")
    sp.add_argument("--profile", help="profile directory (default: Zen's default profile)")
    add("status", cmd_status, "check whether Zen is reachable", tab=False)
    add("tabs", cmd_tabs, "list tabs: index, title, url (* = selected)", tab=False)
    sp = add("open", cmd_open, "open a new tab, optionally at URL", tab=False)
    sp.add_argument("url", nargs="?")
    sp = add("nav", cmd_nav, "navigate a tab to URL, or back/forward/reload")
    sp.add_argument("url")
    sp = add("focus", cmd_focus, "bring a tab to the front", tab=False)
    sp.add_argument("tab", help="tab number or URL/title substring")
    add("close", cmd_close, "close a tab")
    sp = add("text", cmd_text, "print visible text of the page or an element")
    sp.add_argument("selector", nargs="?", default="body")
    sp.add_argument("--max", type=int, default=0, help="truncate to N chars")
    sp = add("html", cmd_html, "print page source or an element's outerHTML")
    sp.add_argument("selector", nargs="?")
    sp.add_argument("--max", type=int, default=0)
    add("elements", cmd_elements, "list visible interactive elements as @N refs")
    sp = add("click", cmd_click, "click an element (@N or CSS selector)")
    sp.add_argument("target")
    sp = add("type", cmd_type, "type into an element (@N or CSS selector)")
    sp.add_argument("target")
    sp.add_argument("text")
    sp.add_argument("--clear", action="store_true", help="clear the field first")
    sp.add_argument("--enter", action="store_true", help="press Enter afterwards")
    sp = add("eval", cmd_eval, "run JS in the page ('-' reads stdin); prints the return value")
    sp.add_argument("js")
    sp = add("screenshot", cmd_screenshot, "save a PNG of the viewport, full page, or an element")
    sp.add_argument("out")
    sp.add_argument("--full", action="store_true", help="whole page, not just the viewport")
    sp.add_argument("--selector", help="screenshot just this element")
    sp = add("wait", cmd_wait, "wait until a selector exists")
    sp.add_argument("selector")
    sp.add_argument("--timeout", type=float, default=15)

    a = p.parse_args()
    try:
        a.fn(a)
    except MarionetteError as e:
        sys.exit(f"zen: {e}")


if __name__ == "__main__":
    main()
