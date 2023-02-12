# Package

version       = "0.0.1"
author        = "the-argus"
description   = "Server that analyzes obsidian vaults for TODOs and sends notifications."
license       = "GPL v3"
srcDir        = "src"
bin           = @["notify_tasks"]

# Dependencies

requires "nim >= 1.0.0"
requires "markdown >= 0.8.5"
requires "regex >= 0.20.0"
