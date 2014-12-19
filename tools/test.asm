;			.org	00000h
;Start_of_RAM:		.eq	0x0800
			JMP 	Get_address		;Skip over message
;			defm	"JP-80 ROM v.1",0
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
Simple_Counter:		LDA 	000h			;One-byte counter for slow clock
Loop_1:			OUT 	0
			INR 	A
			JMP 	Loop_1
Count_to_a_million:	MVI 	L,000h			;Two-byte (16-bit) counter
			MVI 	H,000h			;Clear registers
Loop_2:			MVI 	A,010h			;Count 16 times, then
Loop_3:			DCR 	A
			JNZ 	Loop_3
			INR 	H			;increment the 16-bit number
			MOV 	A,L
			OUT 	0			;Output the 16-bit number
			MOV 	A,H
			OUT 	1
			JMP 	Loop_2			;Do it again
