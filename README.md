![banner](https://raw.githubusercontent.com/ayumi-aiko/banners/refs/heads/main/bash-installer.png)

# Bash-Installer
Bash-Installer, a simple installer with multi-language support.

> Chinese (Simplified + Traditional), Portuguese, Ukranian, Turkish, Russian, Japanese, *Itallian*, Indoneasian, Español (Spanish) and English are available to switch but it's not translated yet, translate it if you want.

## Salient Features:
- Switches back to English if there's no language asset found
- Everything is in bash, no other languages are used
- Option navigation support using Volume Keys
- No need to hard-code partition paths
- Easy debugging with shell functions and with recovery logs
- Latest stable busybox

## Functions usage:
```bash
installImages "<image file name in the zip, ex: system.img>" "<block name, ex: system>"
```
```bash
findActualBlock "<block name, ex: system>"
```
```bash
logInterpreter --ignore-failure "Trying to run a command.." "ls /sequoia"
logInterpreter --handle-failure "Trying to run a command.." "ls /sequoia" "Fallback was triggered!" "ls /montana"
```
```bash
consolePrint "hello world"
consolePrint --language welcome.hello # reads the variable value from the language file
```
```bash
debugPrint "Error-Info|Error|Warning|Abort|Failure | <service>: <message>"
```
```bash
amiMountedOrNot "<partition name, ex: system>"
```