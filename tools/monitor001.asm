                    LXI     SP,00FFh
monitor_warm_start: LXI     H,monitor_message
                    CALL    write_string
                    CALL    write_newline
                    LXI     H,00A0h
                    CALL    read_prompt
                    HLT
;
read_prompt:        MVI     C,000h              ;line position
                    MOV     A,H                 ;put original buffer address in DE
                    MOV     D,A                 ;after this don't need to preserve HL
                    MOV     A,L                 ;subroutines called don't use DE
                    MOV     E,A
                    MVI     B,000h 
echo_char:          IN      3                   ;get status
                    ANI     002h                ;check RxRDY bit
                    JZ      echo_char           ;not ready, loop
                    IN      2                   ;get char
                    CALL    write_char          ;put char on screen
                    ;INR     B
                    ;MOV     A,B
                    ;OUT     0
                    MVI     A,002h
                    OUT     3
                    INX     D                   ;point to next space in buffer
                    INR     C                   ;inc counter
                    MVI     A,000h
                    STAX    D                   ;leaves a zero-terminated string in buffer
                    JMP     echo_char
;
;Subroutine to write a zero-terminated string to serial output
;Pass address of string in HL register
;No error checking
;
write_string:       IN      3                   ;read status
                    ANI     001h                ;check TxRDY bit
                    JZ      write_string        ;loop if not set
                    MOV     A,M                 ;get char from string
                    ANA     A                   ;check if 0
                    RZ                          ;yes, finished
                    OUT     2                   ;no, write char to output
                    INX     H                   ;next char in string
                    JMP     write_string        ;start over
;
;Subroutine to start a new line
;
write_newline:      MVI     A,00DH              ;ASCII carriage return character
                    CALL    write_char
                    MVI     A,00AH              ;new line (line feed) character
                    CALL    write_char
                    RET
;
;Puts a single char (byte value) on serial output
;Call with char to send in A register. Uses B register
;
write_char:         MOV     B,A                 ;store char
write_char_loop:    IN      3                   ;check if OK to send
                    ANI     001h                ;check TxRDY bit
                    JZ      write_char_loop     ;loop if not set
                    MOV     A,B                 ;get char back
                    OUT     2                   ;send to output
                    RET                         ;returns with char in a
monitor_message:    defm    "Hello, world!",0
