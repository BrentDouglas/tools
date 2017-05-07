#!/usr/bin/env python3
# coding: utf-8
"""
Watch script
"""

import getopt
import re
import subprocess
import sys
import time
from watchdog.events import PatternMatchingEventHandler
from watchdog.observers import Observer
from watchdog.utils import echo

RED = "\033[31m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
CYAN = "\033[36m"
RESET = "\033[00m"


def start(command):
    return subprocess.Popen(command)


def stop(process, kill_after):
    if process is None:
        return
    try:
        process.terminate()
        process = None
    except OSError:
        process = None
    while process is not None:
        kill_time = time.time() + kill_after
        while time.time() < kill_time:
            if process.poll() is not None:
                break
            time.sleep(0.25)
        else:
            try:
                process.kill()
                process = None
            except OSError:
                process = None


class EventHandler(PatternMatchingEventHandler):
    def __init__(self, command, patterns=None, ignore_patterns=None,
                 ignore_directories=True, kill_after=10):
        super(EventHandler, self).__init__(
            patterns=patterns,
            ignore_patterns=ignore_patterns,
            ignore_directories=ignore_directories,
            case_sensitive=False
        )
        self.command = command
        self.kill_after = kill_after
        self.process = None

    def start(self):
        self.process = start(self.command)

    def stop(self):
        stop(self.process, self.kill_after)

    @echo.echo
    def on_any_event(self, event):
        self.stop()
        self.start()


def usage():
    print("""
Usage: watch.py [-d path]... -c command -w watch [-t timeout] [-h]

    [-d|--dir]      A directory to watch
    [-c|--cmd]      A command to run constantly
    [-w|--watch]    A command to run every time something changes
    [-t|--timeout]  The time to wait for a process to complete on shutdown
    [-h|--help]     Print this message and exit
""")


def main():
    try:
        opts, args = getopt.getopt(sys.argv[1:], "c:w:d:t:h", ["cmd=", "watch=", "dir=", "timeout=", "help"])
    except getopt.GetoptError as err:
        print(str(err))
        usage()
        sys.exit(2)
    command = []
    watch = []
    dirs = []
    timeout = 10
    for o, a in opts:
        if o in ("-c", "--cmd"):
            command += re.split('\s+', a)
        elif o in ("-w", "--watch"):
            watch += re.split('\s+', a)
        elif o in ("-d", "--dir"):
            dirs.append(a)
        elif o in ("-t", "--timeout"):
            timeout = int(a)
        elif o in ("-h", "--help"):
            usage()
            sys.exit()
        else:
            assert False, "unhandled option " + o

    observer = Observer()
    handler = EventHandler(command=watch, kill_after=timeout)
    for dir in dirs:
        observer.schedule(handler, dir, recursive=True)
    handler.start()
    observer.start()
    process = start(command)
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        handler.stop()
        observer.stop()
        stop(process, timeout)
    observer.join()


if __name__ == '__main__':
    main()
