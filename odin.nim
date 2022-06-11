# linux:
# nim c --cpu:amd64 --os:linux --app:gui -d:danger -d:strip --opt:size --verbosity:0 --out:odin odin.nim
#
# windows:
# nim c --cpu:amd64 --os:windows --app:console --gcc.exe:x86_64-w64-mingw32-gcc --gcc.linkerexe:x86_64-w64-mingw32-gcc --verbosity:0 --out:odin.exe odin.nim

# RFC
# https://datatracker.ietf.org/doc/html/rfc1205
# https://www.rfc-editor.org/rfc/rfc2877.html
# https://www.rfc-editor.org/rfc/rfc4777.html


import os
import net
#import libs/illwill
import libs/as400_api
import libs/zos_api


proc help() =
    stdout.write("[*] " & paramStr(0) & " <ip> <port> <OS> <CMD> [ARG]\n\n")

    stdout.write("# OS400\n")
    stdout.write(paramStr(0) & " 127.0.0.1 23 as400 brute\n")
    stdout.write("\t\t\t\tusernames.txt \t List of username:password\n")

    stdout.write(paramStr(0) & " 127.0.0.1 23 as400 test\n")
    stdout.write("\t\t\t\tusername \t Username to test\n")
    stdout.write("\t\t\t\tpassword \t Password to test\n")

    stdout.write("\n# ZOS\n")

proc main() =

    if paramCount() < 4:
        help()
        quit(0)

    let SERVER_ADDR: string = paramStr(1)
    let SERVER_PORT: string = paramStr(2)
    let OS: string = paramStr(3) # zos, as400
    let CMD: string = paramStr(4)

    if OS == "zos":
        discard

    elif OS == "as400":

        if CMD == "brute":
            if paramCount() < 5:
                help()
                quit(0)

            let USERFILE = paramStr(5)
            let _ = as400_api.brute_usernames(SERVER_ADDR, SERVER_PORT, USERFILE)

        elif CMD == "test":
            if paramCount() < 6:
                help()
                quit(0)

            let credential: seq[string] = @[paramStr(5), paramStr(6)]
            let _ = as400_api.test_username(SERVER_ADDR, SERVER_PORT, credential)

        elif CMD == "emulator":
            echo "emulator"
            #[
            # 1. Initialise terminal in fullscreen mode and make sure we restore the state
            # of the terminal state when exiting.
            proc exitProc() {.noconv.} =
                illwillDeinit()
                showCursor()
                quit(0)

            illwillInit(fullscreen=true)
            setControlCHook(exitProc)
            hideCursor()           

            # 2. We will construct the next frame to be displayed in this buffer and then
            # just instruct the library to display its contents to the actual terminal
            # (double buffering is enabled by default; only the differences from the
            # previous frame will be actually printed to the terminal).
            var tb = newTerminalBuffer(terminalWidth(), terminalHeight())

            # 3. Display some simple static UI that doesn't change from frame to frame.
            tb.setForegroundColor(fgBlack, true)
            #tb.drawRect(0, 0, 40, 5)
            tb.drawRect(0, 0, terminalWidth()-1, terminalHeight()-1)
            tb.drawHorizLine(2, 38, 3, doubleStyle=true)

            tb.write(2, 1, fgWhite, "Press any key to display its name")
            tb.write(2, 2, "Press ", fgYellow, "ESC", fgWhite,
               " or ", fgYellow, "Q", fgWhite, " to quit")
            tb.write(2, terminalHeight()-2, fgWhite, "cmd> ")

            # 4. This is how the main event loop typically looks like: we keep polling for
            # user input (keypress events), do something based on the input, modify the
            # contents of the terminal buffer (if necessary), and then display the new
            # frame.
            let position_init: int = 7
            var position: int = position_init
            var command: string = ""
            while true:
                var key = getKey()
                case key
                of Key.None:
                    tb.write(position, terminalHeight()-2, resetStyle, "_")
                of Key.CtrlH: # delete backward why CtrlH ? dont know
                    position -= 1
                    command = command[.. ^2] # remove the last char
                    tb.write(position, terminalHeight()-2, resetStyle, " ")
                of Key.Enter:
                    tb.write(position_init, terminalHeight()-2, resetStyle, ' '.repeat(terminalWidth()-2))
                    # do something with command then reset it
                    case command
                    of "QUIT": exitProc()
                    else: discard

                    command = ""
                    position = position_init
                else:
                    tb.write(position, terminalHeight()-2, resetStyle, $key)
                    command = command & $key
                    position += 1

                tb.display()
                sleep(20)
            ]#
        else:
            help()
            quit("[-] That command does not exist: " & CMD)
    else:
        help()
        quit("[-] This OS is not handled: " & OS)

main()
quit(0)
