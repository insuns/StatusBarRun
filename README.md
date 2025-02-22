# StatusBarRun

![supported os: osx](https://img.shields.io/badge/supported%20os-osx-brightgreen.svg)

This program allows you to run **any program** (terminal command / applescript / open file / start application) via your **status bar** or a **global shortcut**.

This is a mac only application developed natively in swift. Thus its very CPU efficient and does not consume any battery when in idle (**zero energy impact** in activity monitor).

## Installation

This app has been tested on macOS Sierra and macOS High Sierra, but should also work in prior versions of macOS.

1. Download the app from [here](https://github.com/insuns/StatusBarRun/releases)
2. Execute the app once
3. Click on the R on the top left of your screen and select the menu item `Edit items` to edit your [config](https://github.com/insuns/StatusBarRun#configuration)
4. To add this app to the **startup** simply drag it into your login items (System Preferences -> Users & Groups -> Current User -> **Login Items**) and tick the checkbox

## Configuration

This program will create a config file located at `~/.status-bar-run.json`.
You can edit this file with your default editor (StatusBarRun -> Edit Config).

You can register different command there.
The key in the json object is the name which appears in the status bar item.
The value must be a json object too.
It must have the attributes `launchPath` (string) and `arguments` (array of strings).
The `launchPath` is the path to the program to start with the given `arguments`.

Moreover you can use a `label` option (which also contains `launchPath` and `arguments`).
The output of this process will override the label, as seen in the second example (`week`).

Additionally it's possible to nest your commands as seen in the second example.

Example:

![Greet](http://i.imgur.com/5dylGW2.png)

This Example registers a item named `Greet` which runs the command `say hi` in `/bin/sh`. It can also be triggered by pressing `command + option + g`

```json
[
    {
        "title": "Greet",
        "launchPath": "/bin/sh",
        "arguments": ["-c", "say hi"],
        "hotkey": {
            "key": "g",
            "modifiers": ["command", "option"]
        }
    }
]
```

Second example:

```json
[
    {
        "title": "Week",
        "label": {
            "launchPath": "/bin/sh",
            "arguments": ["-c", "date '+%V'"],
            "suffix": ". week of year",
            "trimOutput": true
        },
        "launchPath": "/bin/sh",
        "arguments": ["-c", "open /Applications/Calendar.app"]
    },
    {
        "title": "Fortune",
        "launchPath": "/bin/sh",
        "arguments": [
            "-c",
            "say -v Samantha $('/usr/local/Cellar/fortune/9708/bin/fortune' -s)"
        ]
    },
    {
        "title": "Remove formatting of clipboard",
        "hotkey": {
            "key": "g",
            "modifiers": ["command", "option"]
        },
        "launchPath": "/bin/sh",
        "arguments": ["-c", "pbpaste | pbcopy"]
    },
    {
        "title": "Web proxy",
        "children" : [
            {
                "title": "On",
                "launchPath": "/bin/sh",
                "arguments": [
                    "-c",
                    "networksetup -setwebproxy 'Wi-Fi' 127.0.0.1 8080 && networksetup -setsecurewebproxy 'Wi-Fi' 127.0.0.1 8080"
                ]
            },
            {
                "title": "Off",
                "launchPath": "/bin/sh",
                "arguments": ["-c", "networksetup -setwebproxystate 'Wi-Fi' off && networksetup -setsecurewebproxystate 'Wi-Fi' off"]
            }
        ]
    }
]
```

After modifying the config you have to either restart the program or reload the config (StatusBarRun -> Reload Config).

## Global shortcuts

For possible `key` codes, see [soffes/HotKey](https://github.com/soffes/HotKey/blob/5970874b44ee03e381f46c61b4b6a75c9b49243e/HotKey/Sources/Key.swift).

Possible modifiers are:

```
capsLock
shift
control
option // Alt
command
numericPad // Any key on the number pad
help // Help key
function // Any function key
```

## Uninstallation

To uninstall StatusBarRun simply delete the StatusBarRun.app and the config file (`rm ~/.status-bar-run.json`), THATS IT!


## Development
1. install carthage, run `brew update && brew install carthage`

2. update dependency, run `carthage update --platform macosx`
