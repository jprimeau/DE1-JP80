                    LXI     H,monitor_message
                    CALL    write_string
                    CALL    write_newline
                    HLT
;
;Subroutine to get a string from serial input, place in buffer.
;Buffer address passed in HL reg.
;Uses A,BC,DE,HL registers (including calls to other subroutines).
;Line entry ends by hitting return key. Return char not included in string (replaced by zero).
;Backspace editing OK. No error checking.
;
get_line:           MVI     C,00H			    ;line position
                    MOV     A,H                 ;put original buffer address in DE
                    MOV     D,A                 ;after this don't need to preserve HL
                    MOV     A,L                 ;subroutines called don't use DE
                    MOV     E,A
get_line_next_char:	IN      3                   ;get status
                    ANI     02h                 ;check RxRDY bit
                    JZ      get_line_next_char  ;not ready, loop
                    IN      2                   ;get char
                    CPI     0DH                 ;check if return
                    RZ                          ;yes, normal exit
                    CPI     7FH                 ;check if backspace (VT102 keys)
                    JZ      get_line_backspace  ;yes, jump to backspace routine
                    CPI     08H                 ;check if backspace (ANSI keys)
                    JZ      get_line_backspace  ;yes, jump to backspace
                    CALL    write_char          ;put char on screen
                    STAX    D                   ;store char in buffer
                    INX     D                   ;point to next space in buffer
                    INR     C                   ;inc counter
                    MVI     A,00h
                    STAX    D                   ;leaves a zero-terminated string in buffer
                    JMP     get_line_next_char
get_line_backspace: MOV     A,C                 ;check current position in line
                    CPI     00H                 ;at beginning of line?
                    JZ      get_line_next_char  ;yes, ignore backspace, get next char
                    DCX     D                   ;no, erase char from buffer
                    DCR     C                   ;back up one
                    MVI     A,00H               ;put a zero in buffer where the last char was
                    STAX    D
                    ;LXI     H,erase_char_string ;ANSI sequence to delete one char from line
                    CALL    write_string        ;transmits sequence to backspace and erase char
                    JMP     get_line_next_char
write_string:       MOV     A,M
                    ANA     A
                    RZ
                    OUT     0
                    INX     H
                    JMP     write_string
write_newline:      MVI     A,0DH
                    CALL    write_char
                    MVI     A,0AH
                    CALL    write_char
                    RET
write_char:         OUT     0
                    RET
monitor_message:    defm	"Hello"
