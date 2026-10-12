#!/usr/bin/env python3
"""Opt-in profiles, transactional config linking, and Arch provisioning.

Uses only Python's standard library until invoking the pinned Dotbot submodule.
Planning never initializes submodules, installs packages, or writes state.
"""

import argparse
import contextlib
import datetime
import fcntl
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import uuid


ROOT = Path(__file__).resolve().parent
COLOR_MODE = "auto"
COLORS = {"info": "36", "success": "32", "warning": "33", "error": "31"}


def log(message, level="info", *, file=None, flush=False):
    stream = file or sys.stdout
    enabled = COLOR_MODE == "always" or (
        COLOR_MODE == "auto" and stream.isatty() and "NO_COLOR" not in os.environ
        and os.environ.get("TERM") != "dumb"
    )
    if enabled:
        message = f"\033[{COLORS[level]}m{message}\033[0m"
    print(message, file=stream, flush=flush)


def read_json(path):
    with path.open() as stream:
        return json.load(stream)


def write_json(path, value):
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps(value, indent=2) + "\n")
    temporary.chmod(0o600)
    temporary.replace(path)


def load_profile(name, root=ROOT, seen=()):
    if not re.fullmatch(r"[a-zA-Z0-9_-]+", name):
        raise ValueError("Profile names may contain only letters, digits, '-' and '_'.")
    if name in seen:
        raise ValueError(f"Profile inheritance cycle: {' -> '.join((*seen, name))}")
    data = read_json(root / "profiles" / f"{name}.json")
    parent = load_profile(data["extends"], root, (*seen, name)) if "extends" in data else {}
    result = {**parent, **data}
    for key in ("modules", "packages", "aur"):
        result[key] = list(dict.fromkeys(parent.get(key, []) + data.get(key, [])))
    result["links"] = {**parent.get("links", {}), **data.get("links", {})}
    return result


def select_modules(profile, extra, catalog):
    selected = []
    visiting = set()

    def add(name):
        if name not in catalog:
            raise ValueError(f"Unknown module: {name}")
        if name in visiting:
            raise ValueError(f"Module dependency cycle at {name}")
        if name in selected:
            return
        visiting.add(name)
        for dependency in catalog[name].get("requires", []):
            add(dependency)
        visiting.remove(name)
        selected.append(name)

    for name in profile["modules"] + extra:
        add(name)
    return selected


def expand_target(value, home, config):
    if value == "~" or value.startswith("~/"):
        path = home / value[2:] if value != "~" else home
    elif value == "$CONFIG" or value.startswith("$CONFIG/"):
        path = config / value[len("$CONFIG/"):] if value != "$CONFIG" else config
    else:
        raise ValueError(f"Destination must start with ~/ or $CONFIG/: {value}")
    path = Path(os.path.abspath(path))
    if path not in (home, config) and not (path.is_relative_to(home) or path.is_relative_to(config)):
        raise ValueError(f"Destination escapes the target home/config directory: {value}")
    if path in (home, config):
        raise ValueError(f"Refusing to manage an entire home/config directory: {value}")
    return path


def same_link(destination, source):
    return destination.is_symlink() and destination.resolve() == source.resolve()


def unsafe_parent(path):
    for parent in path.parents:
        if parent.is_symlink():
            return f"symlinked parent {parent}; migrate that directory separately"
        if parent.exists() and not parent.is_dir():
            return f"non-directory parent {parent}"
    return None


def build_spec(profile_name, extra, home, config, root=ROOT):
    profile = load_profile(profile_name, root)
    catalog = read_json(root / "manifests" / "modules.json")
    modules = select_modules(profile, extra, catalog)
    links = {"~/.dotfiles": "."}
    directories = []
    packages = set(profile["packages"]) | {"git", "python"}
    aur, commands = set(profile["aur"]), {"git", "python3"}
    for name in modules:
        module = catalog[name]
        for target, source in module.get("links", {}).items():
            if target in links and links[target] != source:
                raise ValueError(f"Modules disagree about destination {target}")
            links[target] = source
        directories.extend(module.get("directories", []))
        packages.update(module.get("packages", []))
        aur.update(module.get("aur", []))
        commands.update(module.get("commands", []))
    # Overrides may only affect destinations belonging to selected modules.
    links.update({key: value for key, value in profile["links"].items() if key in links})
    entries = []
    for target, relative in links.items():
        source = Path(os.path.abspath(root / relative))
        if not source.is_relative_to(root):
            raise ValueError(f"Source outside repository: {relative}")
        destination = expand_target(target, home, config)
        if destination.is_relative_to(root) and destination != source:
            raise ValueError(f"Refusing to install a link inside the source checkout: {destination}")
        if root.is_relative_to(destination) and destination != root:
            raise ValueError(f"Refusing to replace a directory containing the checkout: {destination}")
        entries.append({"destination": str(destination), "source": str(source)})
    destinations = [Path(entry["destination"]) for entry in entries]
    if len(set(destinations)) != len(destinations):
        raise ValueError("Duplicate destination after expanding paths")
    for target in destinations:
        if any(other != target and target.is_relative_to(other) for other in destinations):
            raise ValueError(f"Overlapping link destinations: {target}")
    return {
        "profile": profile_name, "modules": modules, "links": entries,
        "directories": [str(expand_target(value, home, config)) for value in dict.fromkeys(directories)],
        "packages": sorted(packages), "aur": sorted(aur), "commands": sorted(commands),
    }


def inspect_spec(spec, relink=False):
    entries = []
    for link in spec["links"]:
        target, source = Path(link["destination"]), Path(link["source"])
        entry = dict(link)
        entry["missing"] = not source.exists()
        if same_link(target, source) or (target == source and target.is_dir()):
            entry["action"] = "keep"
        elif reason := unsafe_parent(target):
            entry.update(action="blocked", reason=reason)
        elif relink and target.is_symlink() and not target.exists() and source.exists():
            entry["action"] = "relink"
        elif os.path.lexists(target):
            entry["action"] = "conflict"
        else:
            entry["action"] = "link"
        entries.append(entry)
    return entries


def display_plan(spec, entries):
    log(f"Profile: {spec['profile']}\nModules: {', '.join(spec['modules'])}")
    for entry in entries:
        suffix = " [missing source; initialize selected submodules]" if entry["missing"] else ""
        reason = f" ({entry['reason']})" if "reason" in entry else ""
        level = "error" if entry["action"] in ("conflict", "blocked") else (
            "warning" if entry["missing"] or entry["action"] == "relink" else "success" if entry["action"] == "keep" else "info")
        log(f"{entry['action'].upper():8} {entry['destination']} -> {entry['source']}{suffix}{reason}", level)
    for directory in spec["directories"]:
        log(f"DIRECTORY {directory}")
    log(f"\nArch packages ({len(spec['packages'])}, never installed by config apply):")
    log("  " + " ".join(spec["packages"]))
    if spec["aur"]:
        log("Manual AUR/foreign prerequisites (not automatically installed): " + ", ".join(spec["aur"]), "warning")


def check_conflicts(spec, entries, backup):
    problems = [entry for entry in entries if entry["action"] == "blocked" or
                (entry["action"] == "conflict" and not backup)]
    if problems:
        raise ValueError("Conflicts found; no links changed. Review the plan, or explicitly use "
                         "--backup-conflicts for direct destinations. Symlinked parents are never replaced.")
    for value in spec["directories"]:
        path = Path(value)
        if path.is_symlink() or (path.exists() and not path.is_dir()) or unsafe_parent(path):
            raise ValueError(f"Unsafe writable directory: {path}")


def ensure_submodules(spec):
    required = {"dotbot"}
    output = subprocess.check_output(
        ["git", "config", "--file", str(ROOT / ".gitmodules"), "--get-regexp", r"submodule\..*\.path"],
        cwd=ROOT, text=True,
    )
    paths = [line.split(None, 1)[1] for line in output.splitlines()]
    for entry in spec["links"]:
        source = Path(entry["source"])
        for path in paths:
            if source.is_relative_to(ROOT / path):
                required.add(path)
            elif (ROOT / path).is_relative_to(source) and source != ROOT:
                required.add(path)
    subprocess.run(["git", "submodule", "update", "--init", "--recursive", "--", *sorted(required)],
                   cwd=ROOT, check=True)


@contextlib.contextmanager
def state_lock(state):
    if state.is_symlink() or unsafe_parent(state):
        raise ValueError(f"Refusing symlinked/non-directory state path: {state}")
    state.mkdir(parents=True, exist_ok=True, mode=0o700)
    with (state / "lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        yield


def make_directories(path, journal, journal_path):
    missing = []
    current = path
    while not current.exists():
        missing.append(current)
        current = current.parent
    for directory in reversed(missing):
        journal["created_directories"].append(str(directory))
        write_json(journal_path, journal)
        directory.mkdir()


def restore_journal(journal_path):
    journal = read_json(journal_path)
    issues = []
    for entry in reversed(journal["changes"]):
        target, source = Path(entry["destination"]), Path(entry["source"])
        backup = Path(entry["backup"]) if entry.get("backup") else None
        if reason := unsafe_parent(target):
            issues.append(f"{target}: {reason}")
            continue
        if same_link(target, source):
            target.unlink()
        elif os.path.lexists(target):
            # A failed move may have left the original destination untouched.
            if backup is not None and not os.path.lexists(backup) and entry.get("restored"):
                continue
            issues.append(f"{target}: changed since installation; left untouched")
            continue
        if backup is not None and os.path.lexists(backup):
            backup.rename(target)
        entry["restored"] = True
        write_json(journal_path, journal)
    for value in reversed(journal["created_directories"]):
        path = Path(value)
        if not path.is_symlink():
            try:
                path.rmdir()  # Only remove empty directories; never recursive deletion.
            except OSError:
                pass
    journal["status"] = "restore-incomplete" if issues else "restored"
    write_json(journal_path, journal)
    for issue in issues:
        log("WARNING: " + issue, "warning", file=sys.stderr)
    return not issues


def apply(spec, state, backup, relink=False):
    entries = inspect_spec(spec, relink)
    check_conflicts(spec, entries, backup)
    ensure_submodules(spec)
    entries = inspect_spec(spec, relink)
    check_conflicts(spec, entries, backup)
    if any(entry["missing"] for entry in entries):
        raise ValueError("Required source files are missing even after submodule initialization.")
    with state_lock(state):
        # Recheck after taking the lock: another bootstrap may have completed.
        entries = inspect_spec(spec, relink)
        check_conflicts(spec, entries, backup)
        changes = [entry for entry in entries if entry["action"] != "keep"]
        missing_directories = any(not Path(value).exists() for value in spec["directories"])
        if not changes and not missing_directories:
            log("Already applied; no changes.", "success")
            return
        transaction = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%SZ-") + uuid.uuid4().hex[:8]
        directory = state / "transactions" / transaction
        directory.mkdir(parents=True, mode=0o700)
        journal_path = directory / "journal.json"
        journal = {"version": 1, "profile": spec["profile"], "status": "applying",
                   "changes": [], "created_directories": []}
        write_json(journal_path, journal)
        try:
            for index, entry in enumerate(changes):
                target = Path(entry["destination"])
                record = {"destination": str(target), "source": entry["source"]}
                if entry["action"] in ("conflict", "relink"):
                    record["backup"] = str(directory / f"backup-{index}")
                journal["changes"].append(record)
                write_json(journal_path, journal)
                if "backup" in record:
                    # Rename preserves the original, including symlinks. Cross-filesystem
                    # backups intentionally fail rather than copy/delete user directories.
                    target.rename(record["backup"])
                make_directories(target.parent, journal, journal_path)
            for value in spec["directories"]:
                make_directories(Path(value), journal, journal_path)
            config = directory / "dotbot.json"
            write_json(config, [
                {"defaults": {"link": {"create": False, "relink": False, "force": False}}},
                {"link": {entry["destination"]: {"path": entry["source"]} for entry in changes}},
            ])
            if changes:
                color_arg = "--force-color" if COLOR_MODE == "always" else "--no-color" if (
                    COLOR_MODE == "never" or "NO_COLOR" in os.environ) else None
                command = [sys.executable, str(ROOT / "dotbot" / "bin" / "dotbot"),
                           "-d", str(ROOT), "-c", str(config), "--exit-on-failure"]
                if color_arg:
                    command.append(color_arg)
                subprocess.run(command, check=True)
            journal["status"] = "applied"
            write_json(journal_path, journal)
        except BaseException:
            restore_journal(journal_path)
            log(f"Apply failed. Recovery journal: {journal_path}", "error", file=sys.stderr)
            raise
        log(f"Applied. Transaction: {transaction}", "success")
        log(f"Restore with: ./install restore --transaction {transaction}")
        log("Packages, services, login shell, and existing local overrides were not changed.")


def arch_packages(spec, install):
    release = Path("/etc/os-release").read_text()
    if not re.search(r'^ID=["\']?arch["\']?$', release, re.MULTILINE):
        raise ValueError("Package provisioning currently supports Arch Linux only.")
    ansible = shutil.which("ansible-playbook")
    if not ansible:
        raise ValueError("Ansible is not installed. Install ansible-core, then run "
                         "ansible-galaxy collection install -r ansible/requirements.yml.")
    if spec["aur"]:
        log("Not installing AUR/foreign prerequisites: " + ", ".join(spec["aur"]), "warning", flush=True)
    command = [ansible, "-i", "localhost,", "-c", "local", str(ROOT / "ansible" / "playbook.yml"),
               "--extra-vars", json.dumps({"dotfiles_packages": spec["packages"]})]
    command += ["--ask-become-pass"] if install else ["--check", "--diff"]
    subprocess.run(command, cwd=ROOT, check=True)


def doctor(spec, entries):
    display_plan(spec, entries)
    missing = [name for name in spec["commands"] if not shutil.which(name)]
    log("\nMissing commands: " + (", ".join(missing) if missing else "none"), "warning" if missing else "success")
    compatible = True
    if shutil.which("nvim") and "neovim" in spec["modules"]:
        output = subprocess.check_output(["nvim", "--version"], text=True)
        log(output.splitlines()[0] + " (config targets Neovim >= 0.12)")
        version = re.search(r"NVIM v(\d+)\.(\d+)", output)
        compatible = bool(version and tuple(map(int, version.groups())) >= (0, 12))
        if not compatible:
            log("WARNING: This Neovim version is below the supported minimum.", "warning")
    if shutil.which("pacman"):
        installed = set(subprocess.check_output(["pacman", "-Qq"], text=True).splitlines())
        log("Missing official packages: " + (", ".join(sorted(set(spec["packages"]) - installed)) or "none"))
        log("Missing manual prerequisites: " + (", ".join(sorted(set(spec["aur"]) - installed)) or "none"))
    if "hyprland-desktop" in spec["modules"]:
        log("Desktop config uses Hyprland's Lua API (tested on 0.56.2).")
    return compatible and not missing and not any(entry["missing"] or entry["action"] in ("conflict", "blocked") for entry in entries)


def main(argv=None):
    global COLOR_MODE
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", nargs="?", default="plan",
                        choices=["plan", "apply", "doctor", "packages", "restore", "profiles"])
    parser.add_argument("--profile", default="developer")
    parser.add_argument("--modules", nargs="+", action="extend", default=[], metavar="MODULE",
                        help="Add one or more modules; repeatable")
    parser.add_argument("--backup-conflicts", action="store_true")
    parser.add_argument("--relink", action="store_true", help="Back up and replace broken destination symlinks only")
    parser.add_argument("--color", choices=["auto", "always", "never"], default="auto",
                        help="ANSI log colors (default: auto; respects NO_COLOR)")
    parser.add_argument("--apply", action="store_true", help="Actually install packages (packages command only)")
    parser.add_argument("--check", action="store_true", help="Package preview; already the default")
    parser.add_argument("--transaction", help="Exact transaction ID to restore")
    parser.add_argument("--home", type=Path, help="Isolated target home for config tests; not for packages")
    args = parser.parse_args(argv)
    COLOR_MODE = args.color
    if args.relink and args.command not in ("plan", "apply", "doctor"):
        parser.error("--relink is only valid with plan/apply/doctor")
    if args.command not in ("plan", "apply") and args.backup_conflicts:
        parser.error("--backup-conflicts is only valid with plan/apply")
    if args.command != "packages" and (args.apply or args.check):
        parser.error("--apply/--check are only valid with packages")
    if args.apply and args.check:
        parser.error("Choose either --apply or --check")
    if args.command != "restore" and args.transaction:
        parser.error("--transaction is only valid with restore")
    if args.command == "packages" and args.home:
        parser.error("--home does not isolate system packages; use a disposable VM")
    if args.command in ("apply", "restore", "packages") and os.geteuid() == 0:
        parser.error("Run as the target user, not root; only Ansible package tasks use become")
    home = (args.home or Path.home()).expanduser().resolve()
    config = home / ".config" if args.home else Path(os.environ.get("XDG_CONFIG_HOME") or home / ".config")
    state_base = home / ".local/state" if args.home else Path(os.environ.get("XDG_STATE_HOME") or home / ".local/state")
    if not config.is_absolute() or not state_base.is_absolute():
        parser.error("XDG_CONFIG_HOME and XDG_STATE_HOME must be absolute paths")
    state = state_base / "dotfiles"
    try:
        if args.command == "profiles":
            for path in sorted((ROOT / "profiles").glob("*.json")):
                log(f"{path.stem:12} {read_json(path).get('description', '')}")
            return 0
        if args.command == "restore":
            if not args.transaction or not re.fullmatch(r"[0-9]{8}T[0-9]{6}Z-[a-f0-9]{8}", args.transaction):
                raise ValueError("Provide an exact transaction ID from an apply operation.")
            with state_lock(state):
                success = restore_journal(state / "transactions" / args.transaction / "journal.json")
            log("Config restoration complete." if success else "Some changed destinations were left untouched.",
                "success" if success else "warning")
            return 0 if success else 1
        spec = build_spec(args.profile, args.modules, home, config)
        entries = inspect_spec(spec, args.relink)
        if args.command == "plan":
            display_plan(spec, entries)
            check_conflicts(spec, entries, args.backup_conflicts)
        elif args.command == "doctor":
            return 0 if doctor(spec, entries) else 1
        elif args.command == "apply":
            display_plan(spec, entries)
            apply(spec, state, args.backup_conflicts, args.relink)
        elif args.command == "packages":
            arch_packages(spec, args.apply)
        return 0
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        log(f"ERROR: {error}", "error", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
