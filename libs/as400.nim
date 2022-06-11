import strutils
import utils
import net

proc parse_ebcdic_response*(response: string): string = 
    return ""

proc get_login_sequence*(username: string, password: string): string = 

    var logical_record_length: string = "" # \xAA\xBB -> defined at the end because need to setup all variables first to well calculate the length
    var record_type: string = "\x12\xA0"
    var reserved: string = "\x00\x00"
    var variable_header_length: string = "\x04"
    var flags: string = "\x00\x00"
    var opcode: string = "\x03"     # \x00: no operation
                                    # \x01: invite operation
                                    # \x02: output only 
                                    # \x03: put/get operation
                                    # \x04: save screen operation
                                    # \x05: restore screen operation                                        # \x06: read immediate operation
                                    # \x07: reserved
                                    # \x08: read screen operation
                                    # \x09: reserved
                                    # \x0A: cancel invite operation
                                    # \x0B: turn on message light
                                    # \x0C: turn off message light

    var record: string = record_type & 
                         reserved & 
                         variable_header_length & 
                         flags & 
                         opcode  

    var command: string = "\x07\x3B\xF1\x11\x06\x35" # login
    record = record & command
    record = record & ascii2ebcdic(username)
    record = record & "\x11\x07\x35"
    record = record & ascii2ebcdic(password)

    var end_of_record: string = "\xFF\xEF"
    record = record & end_of_record

    logical_record_length = toHex(len(record), 4)   # "AABB"
                                                    # parseHexStr("AABB") = "\xAA\xBB"

    var request: string = parseHexStr(logical_record_length) & 
                          record
            
    return request

proc get_signoff_sequence*(): string =
    var logical_record_length: string = "\x00\xA9" 
    var record_type: string = "\x12\xA0"
    var reserved: string = "\x00\x00"
    var variable_header_length: string = "\x04"
    var flags: string = "\x00\x00"
    var opcode: string = "\x03"     # \x00: no operation
                                    # \x01: invite operation
                                    # \x02: output only 
                                    # \x03: put/get operation
                                    # \x04: save screen operation
                                    # \x05: restore screen operation                                        # \x06: read immediate operation
                                    # \x07: reserved
                                    # \x08: read screen operation
                                    # \x09: reserved
                                    # \x0A: cancel invite operation
                                    # \x0B: turn on message light
                                    # \x0C: turn off message light

    var record: string = record_type & 
                         reserved & 
                         variable_header_length & 
                         flags & 
                         opcode  

    var command: string = "\x14\x0E\xF1\x11\x14\x07\xa2\x89\x87\x95\x96\x86\x86" # signoff
    command = command & repeat("\x40", 146)
    record = record & command

    var end_of_record: string = "\xFF\xEF"
    record = record & end_of_record

    var request: string = logical_record_length & record

    return request

proc telnet_negotiation*(socket: Socket): bool =
    var response: string = ""

    try:
        response = recv(socket, 6) 
        if "\xFF\xFD\x27\xFF\xFD\x18" in response:   
            #socket.send("\xFF\xFB\x27") 
            socket.send("\xFF\xFB\x18")    
    
        response = recv(socket, 6)  
        if "\xFF\xFA\x18\x01\xFF\xF0" in response:
            socket.send("\xff\xfa\x18\x00\x49\x42\x4d\x2d\x33\x31\x37\x39\x2d\x32\xff\xf0")

        response = recv(socket, 12)
        if "\xff\xfd\x19\xff\xfb\x19\xff\xfd\x00\xff\xfb\x00" in response:   
            #socket.send("\xff\xfb\x00\xff\xfd\x00")
            socket.send("\xff\xfb\x19")
            socket.send("\xff\xfd\x19\xff\xfb\x00")
            socket.send("\xff\xfd\x00")
    except:
        return false

    return true

