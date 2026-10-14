#!/usr/bin/env -S python3 -S
"""File cache for the tmux-pr-* screens. See docs/tmux-pr-menu.md#state-and-cache"""

from __future__ import annotations

import os
import sys
import time

DEFAULT_TTL_SECONDS = 300
PRUNE_AFTER_SECONDS = 86400
EXIT_USAGE = 2
EXIT_TERMINATED = 143
COPY_CHUNK_BYTES = 65536
USAGE = """usage:
  tmux-pr-cache.py get [--debounce SECONDS] FILE -- COMMAND...
  tmux-pr-cache.py age FILE
  tmux-pr-cache.py prune DIR..."""


def ttl_seconds() -> float:
    return float(os.environ.get("PR_CACHE_TTL") or DEFAULT_TTL_SECONDS)


def is_fresh(path: str) -> bool:
    try:
        stat = os.stat(path)
    except FileNotFoundError:
        return False
    return stat.st_size > 0 and time.time() - stat.st_mtime < ttl_seconds()


def remove_quietly(path: str) -> None:
    try:
        os.unlink(path)
    except FileNotFoundError:
        pass


def run_into(path: str, command: list[str]) -> int:
    import subprocess
    import tempfile

    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path), prefix=f"{os.path.basename(path)}.")
    try:
        with os.fdopen(fd, "wb") as out:
            status = subprocess.run(command, stdout=out, check=False).returncode
        if status == 0:
            os.replace(tmp, path)
        return status
    finally:
        remove_quietly(tmp)


def fetch_once(path: str, command: list[str]) -> int:
    import fcntl

    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(f"{path}.lock", "a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if is_fresh(path):
            return 0
        return run_into(path, command)


def copy_to_stdout(path: str) -> None:
    with open(path, "rb") as source:
        while chunk := source.read(COPY_CHUNK_BYTES):
            sys.stdout.buffer.write(chunk)


def cmd_get(args: list[str]) -> int:
    debounce = 0.0
    if args[:1] == ["--debounce"]:
        debounce, args = float(args[1]), args[2:]
    if len(args) < 3 or args[1] != "--":
        return usage()
    path, command = args[0], args[2:]
    if not is_fresh(path):
        time.sleep(debounce)
        status = fetch_once(path, command)
        if status != 0:
            return status
    try:
        copy_to_stdout(path)
    except FileNotFoundError:
        return 1
    return 0


def cmd_age(args: list[str]) -> int:
    if len(args) != 1:
        return usage()
    try:
        mtime = os.stat(args[0]).st_mtime
    except FileNotFoundError:
        return 1
    print(int(time.time() - mtime))
    return 0


def prune_dir(root: str, cutoff: float) -> None:
    for dirpath, _, filenames in os.walk(root, topdown=False):
        for name in filenames:
            path = os.path.join(dirpath, name)
            if os.stat(path).st_mtime < cutoff:
                remove_quietly(path)
        if dirpath != root and not os.listdir(dirpath):
            os.rmdir(dirpath)


def cmd_prune(args: list[str]) -> int:
    cutoff = time.time() - PRUNE_AFTER_SECONDS
    for root in args:
        try:
            prune_dir(root, cutoff)
        except OSError:
            pass
    return 0


def usage() -> int:
    print(USAGE, file=sys.stderr)
    return EXIT_USAGE


COMMANDS = {
    "get": cmd_get,
    "age": cmd_age,
    "prune": cmd_prune,
}


def main(argv: list[str]) -> int:
    import signal

    signal.signal(signal.SIGTERM, lambda *_: sys.exit(EXIT_TERMINATED))
    handler = COMMANDS.get(argv[0]) if argv else None
    return handler(argv[1:]) if handler else usage()


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
