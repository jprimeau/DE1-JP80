			.org	00000h
Start_of_RAM:		.eq	0x0800
			JMP 	Get_address		;Skip over message
			defm	"JP-80 ROM v1.0",0
Get_address:		IN	0			;Get address from input ports
			MOV	L,A
			IN 	1
			MOV 	H,A
			PCHL				;Jump to the address
Port_Reflector:		IN 	0			;Simple program to test ports
			OUT 	0
			IN 	1
			OUT 	1
			JMP	Port_Reflector
Simple_Counter:		MVI 	A,000h			;One-byte counter for slow clock
Loop_1:			OUT 	0
			INR 	A
			JMP 	Loop_1
Count_to_a_million:	MVI 	L,000h			;Two-byte (16-bit) counter
			MVI 	H,000h			;Clear registers
Loop_2:			MVI 	A,010h			;Count 16 times, then
Loop_3:			DCR 	A
			JNZ 	Loop_3
			INX 	H			;increment the 16-bit number
			MOV 	A,L
			OUT 	0			;Output the 16-bit number
			MOV 	A,H
			OUT 	1
			JMP 	Loop_2			;Do it again
Program_loader:		LXI 	H,Start_of_RAM		;Load a program in RAM
Loop_4:			IN 	1
			ANI 	081h			;Check input port 1
			JZ 	Loop_4			;If switches 0 and 7 open, loop
			CALL 	debounce
			IN 	1			;Get input port byte again
			ANI 	080h			;Is the left switch (bit 7) closed?
			JNZ 	Start_of_RAM		;Yes, run loaded program
			IN 	0			;No, then right switch (bit 0) closed.
			OUT 	0			;Get byte from port 0, display on output
			MOV 	M,A			;Store it in RAM
			MVI 	A,0ffh			;Turn port 1 lights on (signal that
			OUT 	1			;a byte was stored)
Loop_6:			IN 	1			;Wait for switch to open
			ANI 	001h
			JNZ 	Loop_6
			CALL 	debounce
			MOV 	A,L			;Put low byte of address on port 1
			OUT 	1
			INX 	H			;Point to next location in RAM
			JMP 	Loop_4			;Do it again
Memory_test:		LXI 	H,Start_of_RAM		;check RAM by writing and reading each location
Loop_8:			IN 	1			;read port 1 to get a bit pattern
			MOV 	B,A			;copy it to register b
			MOV 	M,A			;store it in memory
			MOV 	A,M			;read back the same location
			CMP 	B			;same as reg b?
			JNZ 	Exit_1			;no, test failed, exit
			INX 	H			;yes, RAM location OK
			JMP 	Loop_8			;keep going
Exit_1:			MOV 	A,H			;display the address
			OUT 	1			;where the test failed
			MOV 	A,L			;should be 4K (cycled around to ROM)
			OUT 	0			;any other value means bad RAM
			JMP 	Memory_test		;do it again (use a different bit pattern)
Peek:			IN 	0			;Get low byte
			MOV 	L,A			;Put in reg L
			IN 	1			;Get hi byte
			MOV 	H,A			;Put in reg H
			MOV 	A,M			;Get byte from memory
			OUT 	0			;Display on port 0 LEDs
			JMP 	Peek			;Do it again
Poke:			MVI 	A,000h			;Clear output port LEDs
			OUT 	0
			OUT 	1
Loop_9:			IN 	1			;Look for switch closure
			ANI 	001h
			JZ 	Loop_9
			CALL 	debounce
			MVI 	A,0ffh			;Light port 1 LEDs
			OUT 	1
			IN 	0			;Get hi byte
			MOV 	H,A			;Put in reg H
Loop_11:		IN 	1			;Look for switch open
			ANI 	001h
			JNZ 	Loop_11
			CALL 	debounce
			MOV 	A,H			;Show hi byte on port 1
			OUT 	1
Loop_13:		IN 	1			;Look for switch closure
			ANI 	001h
			JZ 	Loop_13
			CALL 	debounce
			MVI 	A,0ffh			;Light port 0 LEDs
			OUT 	0
			IN 	0			;Get lo byte
			MOV 	L,A			;Put in reg L
Loop_15:		IN 	1			;Look for switch open
			ANI 	001h
			JNZ 	Loop_15
			CALL 	debounce
			MOV 	A,L			;Show lo byte on port 0
			OUT 	0
Loop_17:		IN 	1			;Look for switch closure
			ANI 	001h
			JZ 	Loop_17
			CALL 	debounce
			IN 	0			;Get byte to load
			MOV 	M,A			;Store in memory
Loop_19:		IN 	1			;Look for switch open
			ANI 	001h
			JNZ 	Loop_19
			CALL 	debounce
			JMP 	Poke			;Start over
;
;Subroutine for a switch debounce delay
debounce:		MVI 	A,010h			;Outer loop
debounce_loop:		MVI	B,0ffh			;Inner loop
			NOP;djnz 	$+0			;Loop here until B reg is zero
			DCR 	A
			JNZ 	debounce_loop
			RET
