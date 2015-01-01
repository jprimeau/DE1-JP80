boot_loader_start:  LXI     H,prompt
                    CALL    write_string
;
;Subroutine to get a decimal string, return a word value
;Calls int_str_to_word subroutine
;
read_integer:       LXI     H,buffer
                    CALL    get_line            ;returns with DE pointing to terminating zero
                    LXI     H,buffer
                    CALL    int_str_to_word
			        RET
;
;Subroutine to convert a decimal string to a word value
;Call with address of string in HL, pointer to end of string in DE
;Carry flag set if error (non-decimal char)
;Carry flag clear, word value in HL if no error.
;
int_str_to_word:    MOV     B,D
                    MOV     C,E                 ;use BC as string pointer
                    SHLD    current_location    ;store addr. of start of buffer in RAM word variable
                    LXI     H,000h              ;starting value zero
                    SHLD    current_value
                    LXI     H,int_place_value   ;pointer to values
                    SHLD    value_pointer
int_next_char:      DCX     B                   ;next char in string (moving right to left)
                    LXI     H,current_location  ;check if at end of decimal string
;			scf				;get ready to subtract de from buffer addr.
;			ccf				;set carry to zero (clear)
;			sbc	hl,bc			;keep going if bc > or = hl (buffer address)
;			jp	c,decimal_continue	;borrow means bc > hl
;			jp	z,decimal_continue	;z means bc = hl
;			ld	hl,(current_value)	;return if de < buffer address (no borrow)
;			scf				;get value back from RAM variable
;			ccf
;			ret				;return with carry clear, value in hl
;decimal_continue:	ld	a,(bc)			;next char in string (right to left)
;			sub	030h			;ASCII value of zero char
;			jp	m,decimal_error		;error if char value less than 030h
;			cp	00ah			;error if byte value > or = 10 decimal
;			jp	p,decimal_error		;a reg now has value of decimal numeral
;			ld	hl,(value_pointer)	;get value to add an put in de
;			ld	e,(hl)			;little-endian (low byte in low memory)
;			inc	hl
;			ld	d,(hl)
;			inc	hl			;hl now points to next value
;			ld	(value_pointer),hl
;			ld	hl,(current_value)	;get back current value
;decimal_add:		dec	a			;add loop to increase total value
;			jp	m,decimal_add_done	;end of multiplication
;			add	hl,de
;			jp	decimal_add
;decimal_add_done:	ld	(current_value),hl
;			jp	decimal_next_char
;decimal_error:		scf
;			ret
;			jp	decimal_add
int_place_value:    defw    1,10,100,1000,10000
;
;Subroutine to write a zero-terminated string to serial output
;Pass address of string in HL register
;No error checking
;
write_string:       IN      3                   ;read status
                    ANI     001h                ;check TxBUSY bit
                    JNZ     write_string        ;loop if not set
                    MOV     A,M                 ;get char from string
                    ANA     A                   ;check if 0
                    RZ                          ;yes, finished
                    OUT     2                   ;no, write char to output
                    INX     H                   ;next char in string
                    JMP     write_string        ;start over
;
;Subroutine to get a string from serial input, place in buffer.
;Buffer address passed in HL reg.
;Uses A,BC,DE,HL registers (including calls to other subroutines).
;Line entry ends by hitting return key. Return char not included in string (replaced by zero).
;No error checking.
;
get_line:           MVI     C,00H			    ;line position
                    MOV     A,H                 ;put original buffer address in DE
                    MOV     D,A                 ;after this don't need to preserve HL
                    MOV     A,L                 ;subroutines called don't use DE
                    MOV     E,A
get_line_next_char:	IN      3                   ;get status
                    ANI     002h                ;check RxBUSY bit
                    JNZ     get_line_next_char  ;not ready, loop
                    IN      2                   ;get char
                    CPI     0DH                 ;check if return
                    RZ                          ;yes, normal exit
                    CALL    write_char          ;put char on screen
                    STAX    D                   ;store char in buffer
                    INX     D                   ;point to next space in buffer
                    INR     C                   ;inc counter
                    MVI     A,000h
                    STAX    D                   ;leaves a zero-terminated string in buffer
                    JMP     get_line_next_char
;
;Puts a single char (byte value) on serial output
;Call with char to send in A register. Uses B register
;
write_char:         MOV     B,A                 ;store char
write_char_loop:    IN      3                   ;check if OK to send
                    ANI     001h                ;check TxBUSY bit
                    JNZ     write_char_loop     ;loop if not set
                    MOV     A,B                 ;get char back
                    OUT     2                   ;send to output
                    RET                         ;returns with char in a
prompt:             defm    "> ",0
current_location:   equ     0F80h               ;word variable in RAM
value_pointer:      equ     0F84h               ;word variable in RAM
current_value:      equ     0F86h               ;word variable in RAM
buffer:             equ     0F88h               ;buffer in RAM -- up to stack area
