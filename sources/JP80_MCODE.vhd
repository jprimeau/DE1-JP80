-- DESCRIPTION: JP-80 - MICRO CODE
-- AUTHOR: Jonathan Primeau

-- TODO:
--  o Support op with M
--  o Load and store (8 and 16-bit)
--  o Pop and push
--  o CALL and RET

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;
    
use work.jp80_pkg.all;
    
entity JP80_MCODE is
    port (
        clk         : in t_wire;
        reset       : in t_wire;
        opcode      : in t_opcode;
        aluflag     : in t_data;
        alu_to_reg  : in std_logic_vector(3 downto 0);
        alucode     : out t_alucode;
        con         : out t_control
    );
end JP80_MCODE;

architecture rtl of JP80_MCODE is
    signal ns, ps, cb   : t_cpu_state;
    
    function SSS(src : std_logic_vector(2 downto 0))
        return integer is
    begin
        if src = "000" then
            return Eb;
        elsif src = "001" then
            return Ec;
        elsif src = "010" then
            return Ed;
        elsif src = "011" then
            return Ee;
        elsif src = "100" then
            return Eh;
        elsif src = "101" then
            return El;
        else
            return Eacc;
        end if;
    end SSS;
    
    function DDD(dst : std_logic_vector(2 downto 0))
        return integer is
    begin
        if dst = "000" then
            return Lb;
        elsif dst = "001" then
            return Lc;
        elsif dst = "010" then
            return Ld;
        elsif dst = "011" then
            return Le;
        elsif dst = "100" then
            return Lh;
        elsif dst = "101" then
            return Ll;
        else
            return Lacc;
        end if;
    end DDD;
    
    function SS(src : std_logic_vector(1 downto 0))
        return integer is
    begin
        if src = "00" then
            return Ebc;
        elsif src = "01" then
            return Ede;
        elsif src = "10" then
            return Ehl;
        else
            return Esp;
        end if;
    end SS;
    
    function DD(dst : std_logic_vector(1 downto 0))
        return integer is
    begin
        if dst = "00" then
            return Ebc;
        elsif dst = "01" then
            return Ede;
        elsif dst = "10" then
            return Ehl;
        else
            return Esp;
        end if;
    end DD;
    
    function INCDEC(code : std_logic_vector(2 downto 0))
        return integer is
        variable dst : std_logic_vector(1 downto 0);
    begin
        dst := code(2 downto 1);
        if code(0) = '0' then
            if dst = "00" then
                return Ibc;
            elsif dst = "01" then
                return Ide;
            elsif dst = "10" then
                return Ihl;
            else
                return Isp;
            end if;
        else
            if dst = "00" then
                return Dbc;
            elsif dst = "01" then
                return Dde;
            elsif dst = "10" then
                return Dhl;
            else
                return Dsp;
            end if;
        end if;
    end INCDEC;
begin
    process (clk, reset)
    begin
        if reset = '1' then
            ps <= reset_state;
        elsif clk'event and clk='0' then
            ps <= ns;
        end if;
    end process;
    
    process (ps, opcode)
        variable op76   : std_logic_vector(1 downto 0) := "00";
        variable op53   : std_logic_vector(2 downto 0) := "000";
        variable op20   : std_logic_vector(2 downto 0) := "000";
    begin
        con <= (others=>'0');
        alucode <= (others=>'0');
        op76 := opcode(7 downto 6);
        op53 := opcode(5 downto 3);
        op20 := opcode(2 downto 0);

        case ps is
        when reset_state =>
            ns <= opcode_fetch_1;
            
        when opcode_fetch_1 =>
            con(Epc) <= '1';
            con(Laddr) <= '1';
            if alu_to_reg(3) = '1' then
                con(Eu) <= '1';
                con(DDD(alu_to_reg(2 downto 0))) <= '1';
            end if;
            ns <= opcode_fetch_2;
            
        when opcode_fetch_2 =>
            con(Ipc) <= '1';
            ns <= opcode_fetch_3;
            
        when opcode_fetch_3 =>
            con(Edata) <= '1';
            con(Lir) <= '1';
            ns <= decode_instruction;
            
        when data_read_1 =>
            con(Epc) <= '1';
            con(Laddr) <= '1';
            ns <= data_read_2;
            
        when data_read_2 =>
            con(Ipc) <= '1';
            ns <= data_read_3;
            
        when data_read_3 =>
            ns <= cb;
            con(Edata) <= '1';

            if opcode = "11011011" then -- IN <b>
                ns <= memio_to_acc_1;
                con(LaddrL) <= '1';
            elsif opcode = "11010011" then -- OUT <b>
                ns <= acc_to_memio_1;
                con(LaddrL) <= '1';
            elsif op76 = "11" and op20 = "110" then
                alucode <= "0" & op53;
                con(LaluA) <= '1';
                con(LaluB) <= '1';
                con(Lu) <= '1';
            else
                con(DDD(op53)) <= '1';
            end if;
            
        when memio_to_acc_1 =>
            con(IO) <= '1';
            ns <= memio_to_acc_2;
            
        when memio_to_acc_2 =>
            con(Edata) <= '1';
            con(Lacc) <= '1';
            ns <= cb;
            
        when acc_to_memio_1 =>
            con(Eacc) <= '1';
            con(Ldata) <= '1';
            ns <= acc_to_memio_2;
            
        when acc_to_memio_2 =>
            con(IO) <= '1';
            con(Wr) <= '1';
            ns <= cb;
            
        when addr_read_1 =>
            con(Epc) <= '1';
            con(Laddr) <= '1';
            ns <= addr_read_2;
            
        when addr_read_2 =>
            con(Ipc) <= '1';
            ns <= addr_read_3;
            
        when addr_read_3 =>
            con(Edata) <= '1';
            con(LtL) <= '1';
            ns <= addr_read_4;
            
        when addr_read_4 =>
            con(Epc) <= '1';
            con(Laddr) <= '1';
            ns <= addr_read_5;
            
        when addr_read_5 =>
            con(Ipc) <= '1';
            ns <= addr_read_6;
            
        when addr_read_6 =>
            con(Edata) <= '1';
            con(LtH) <= '1';
            
            if op76 = "11" and op20 = "011" then
                con(Et) <= '1';
                con(Lpc) <= '1';
            end if;
            
            ns <= cb;
            
        when skip_addr_1 =>
            con(Ipc) <= '1';
            ns <= skip_addr_2;
            
        when skip_addr_2 =>
            con(Ipc) <= '1';
            ns <= opcode_fetch_1;
            
        when decode_instruction =>
            case op76 is
            when "00" =>
                case op20 is
                
                when "000" =>
                    -- TODO
                    --00 XXX 000
                    --00    00000000    NOP
                    --08    00001000    XXX
                    --10    00010000    XXX
                    --18    00011000    XXX
                    --20    00100000    RIM
                    --28    00101000    XXX
                    --30    00110000    SIM
                    --38    00111000    XXX
                    ns <= opcode_fetch_1;
                    
                when "001" =>
                    -- TODO
                    --00 XXX 001
                    --01    00000001    LXI B,<b>
                    --09    00001001    DAD B
                    --11    00010001    LXI D,<b>
                    --19    00011001    DAD D
                    --21    00100001    LXI H,<b>
                    --29    00101001    DAD H
                    --31    00110001    LXI SP,<b>
                    --39    00111001    DAD SP
                    ns <= opcode_fetch_1;
                    
                when "010" =>
                    -- TODO
                    --00 PP X 010
                    --02	00000010	STAX B
                    --0A	00001010	LDAX B
                    --12	00010010	STAX D
                    --1A	00011010	LDAX D
                    --22	00100010	SHLD <a>
                    --2A	00101010	LHLD <a>
                    --32	00110010	STA <a>
                    --3A	00111010	LDA <a>
                    ns <= opcode_fetch_1;
                    
                when "011" =>
                    --00 PP X 011
                    --03	00000011	INX B
                    --0B	00001011	DCX B
                    --13	00010011	INX D
                    --1B	00011011	DCX D
                    --23	00100011	INX H
                    --2B	00101011	DCX H
                    --33	00110011	INX SP
                    --3B	00111011	DCX SP
                    con(INCDEC(op53)) <= '1';
                    ns <= opcode_fetch_1;
                    
                when "100" => -- INR
                    -- TODO
                    --00 XXX 100
                    --04	00000100	INR B
                    --0C	00001100	INR C
                    --14	00010100	INR D
                    --1C	00011100	INR E
                    --24	00100100	INR H
                    --2C	00101100	INR L
                    --34	00110100	INR M
                    --3C	00111100	INR A
                    alucode <= "0000"; -- ADD
                    con(SSS(op53)) <= '1';
                    con(LaluA) <= '0'; -- A = source
                    con(LaluB) <= '0'; -- B = 00000001
                    con(Lu) <= '1';
                    ns <= opcode_fetch_1;

                when "101" => -- DCR
                    -- TODO
                    --00 XXX 101
                    --05	00000101	DCR B
                    --0D	00001101	DCR C
                    --15	00010101	DCR D
                    --1D	00011101	DCR E
                    --25	00100101	DCR H
                    --2D	00101101	DCR L
                    --35	00110101	DCR M
                    --3D	00111101	DCR A
                    alucode <= "0010"; -- SUB
                    con(SSS(op53)) <= '1';
                    con(LaluA) <= '0'; -- A = source
                    con(LaluB) <= '0'; -- B = 00000001
                    con(Lu) <= '1';
                    ns <= opcode_fetch_1;
                    
                when "110" =>
                    --00 XXX 110
                    --06	00000110	MVI B
                    --0E	00001110	MVI C
                    --16	00010110	MVI D
                    --1E	00011110	MVI E
                    --26	00100110	MVI H
                    --2E	00101110	MVI L
                    --36	00110110	MVI M
                    --3E	00111110	MVI A
                    ns <= data_read_1;
                    cb <= opcode_fetch_1;
                    
                when "111" =>
                    --00 XXX 111
                    --07	00000111	RLC
                    --0F	00001111	RRC
                    --17	00010111	RAL
                    --1F	00011111	RAR
                    --27	00100111	DAA
                    --2F	00101111	CMA
                    --37	00110111	STC
                    --3F	00111111	CMC
                    alucode <= "1" & op53;
                    con(LaluA) <= '1';
                    con(Lu) <= '1';
                    ns <= opcode_fetch_1;
                    
                end case;
                
            when "01" =>
                --01 DDD SSS
                --40	01000000	MOV B,B
                --41	01000001	MOV B,C
                --42	01000010	MOV B,D
                --43	01000011	MOV B,E
                --44	01000100	MOV B,H
                --45	01000101	MOV B,L
                --46	01000110	MOV B,M
                --47	01000111	MOV B,A
                --
                --48	01001000	MOV C,B
                --49	01001001	MOV C,C
                --4A	01001010	MOV C,D
                --4B	01001011	MOV C,E
                --4C	01001100	MOV C,H
                --4D	01001101	MOV C,L
                --4E	01001110	MOV C,M
                --4F	01001111	MOV C,A
                --
                --50	01010000	MOV D,B
                --51	01010001	MOV D,C
                --52	01010010	MOV D,D
                --53	01010011	MOV D,E
                --54	01010100	MOV D,H
                --55	01010101	MOV D,L
                --56	01010110	MOV D,M
                --57	01010111	MOV D,A
                --
                --58	01011000	MOV E,B
                --59	01011001	MOV E,C
                --5A	01011010	MOV E,D
                --5B	01011011	MOV E,E
                --5C	01011100	MOV E,H
                --5D	01011101	MOV E,L
                --5E	01011110	MOV E,M
                --5F	01011111	MOV E,A
                --
                --60	01100000	MOV H,B
                --61	01100001	MOV H,C
                --62	01100010	MOV H,D
                --63	01100011	MOV H,E
                --64	01100100	MOV H,H
                --65	01100101	MOV H,L
                --66	01100110	MOV H,M
                --67	01100111	MOV H,A
                --
                --68	01100000	MOV L,B
                --69	01100001	MOV L,C
                --6A	01100010	MOV L,D
                --6B	01100011	MOV L,E
                --6C	01100100	MOV L,H
                --6D	01100101	MOV L,L
                --6E	01100110	MOV L,M
                --6F	01100111	MOV L,A
                --
                --70	01110000	MOV M,B
                --71	01110001	MOV M,C
                --72	01110010	MOV M,D
                --73	01110011	MOV M,E
                --74	01110100	MOV M,H
                --75	01110101	MOV M,L
                --76	01110110	HALT
                --77	01110111	MOV M,A
                --
                --78	01111000	MOV A,B
                --79	01111001	MOV A,C
                --7A	01111010	MOV A,D
                --7B	01111011	MOV A,E
                --7C	01111100	MOV A,H
                --7D	01111101	MOV A,L
                --7E	01111110	MOV A,M
                --7F	01111111	MOV A,A
                if opcode(5 downto 0) = "110110" then
                    con(HALT) <= '1'; -- HLT is the exception in the "01" range
                else
                    con(SSS(op20)) <= '1';
                    con(DDD(op53)) <= '1';
                end if;
                ns <= opcode_fetch_1;
                
            when "10" =>
                --10 000 SSS
                --80	10000000	ADD B
                --81	10000001	ADD C
                --82	10000010	ADD D
                --83	10000011	ADD E
                --84	10000100	ADD H
                --85	10000101	ADD L
                --86	10000110	ADD M
                --87	10000111	ADD A
                --
                --10 001 SSS
                --88	10001000	ADC B
                --89	10001001	ADC C
                --8A	10001010	ADC D
                --8B	10001011	ADC E
                --8C	10001100	ADC H
                --8D	10001101	ADC L
                --8E	10001110	ADC M
                --8F	10001111	ADC A
                --
                --10 010 SSS
                --90	10010000	SUB B
                --91	10010001	SUB C
                --92	10010010	SUB D
                --93	10010011	SUB E
                --94	10010100	SUB H
                --95	10010101	SUB L
                --96	10010110	SUB M
                --97	10010111	SUB A
                --
                --10 011 SSS
                --98	10011000	SBB B
                --89	10011001	SBB C
                --8A	10011010	SBB D
                --8B	10011011	SBB E
                --8C	10011100	SBB H
                --8D	10011101	SBB L
                --8E	10011110	SBB M
                --9F	10011111	SBB A
                --
                --10 100 SSS
                --A0	10100000	ANA B
                --A1	10100001	ANA C
                --A2	10100010	ANA D
                --A3	10100011	ANA E
                --A4	10100100	ANA H
                --A5	10100101	ANA L
                --A6	10100110	ANA M
                --A7	10100111	ANA A
                --
                --10 101 SSS
                --A8	10101000	XRA B
                --A9	10101001	XRA C
                --AA	10101010	XRA D
                --AB	10101011	XRA E
                --AC	10101100	XRA H
                --AD	10101101	XRA L
                --AE	10101110	XRA M
                --AF	10101111	XRA A
                --
                --10 110 SSS
                --B0	10110000	ORA B
                --B1	10110001	ORA C
                --B2	10110010	ORA D
                --B3	10110011	ORA E
                --B4	10110100	ORA H
                --B5	10110101	ORA L
                --B6	10110110	ORA M
                --B7	10110111	ORA A
                --
                --10 111 SSS
                --B8	10111000	CMP B
                --B9	10111001	CMP C
                --BA	10111010	CMP D
                --BB	10111011	CMP E
                --BC	10111100	CMP H
                --BD	10110101	CMP L
                --BE	10111110	CMP M
                --BF	10111111	CMP A
                alucode <= "0"&op53;
                con(SSS(op20)) <= '1';
                con(LaluA) <= '1';
                con(LaluB) <= '1';
                con(Lu) <= '1';
                ns <= opcode_fetch_1;
                
            when "11" =>
                case op20 is
                
                when "000" =>
                    -- TODO
                    --11 XXX 000
                    --C8	11001000	RZ
                    --D8	11011000	RC
                    --E8	11101000	RPE
                    --F8	11111000	RM
                    --C0	11000000	RNZ
                    --D0	11010000	RNC
                    --E0	11100000	RPO
                    --F0	11110000	RP
                    ns <= opcode_fetch_1;
                    
                when "001" =>
                    -- TODO
                    --11 XXX 001
                    --C1	11000001	POP B
                    --C9	11001001	RET
                    --D1	11010001	POP D
                    --D9	11011001	XXX
                    --E1	11100001	POP H
                    --E9	11101001	PCHL
                    --F1	11110001	POP PSW
                    --F9	11111001	SPHL
                    case op53 is
                    when "000" => -- POP B
                        null;
                    when "001" => -- RET
                        null;
                    when "010" => -- POP D
                        null;
                    when "011" => -- XXX
                        null;
                    when "100" => -- POP H
                        null;
                    when "101" => -- PCHL
                        con(Ehl) <= '1';
                        con(Lpc) <= '1';
                    when "110" => -- POP PSW
                        null;
                    when "111" => -- SPHL
                        con(Ehl) <= '1';
                        con(Lsp) <= '1';
                    end case;
                    ns <= opcode_fetch_1;
                    
                when "010" =>
                    --11 XXX 010
                    --C2	11000010	JNZ
                    --CA	11001010	JZ
                    --D2	11010010	JNC
                    --DA	11011010	JC
                    --EA	11101010	JPE
                    --E2	11100010	JPO
                    --F2	11110010	JP
                    --FA	11111010	JM
                    ns <= skip_addr_1;
                    cb <= opcode_fetch_1;
                    case op53 is
                    when "000" => -- JNZ
                        if aluflag(FlagZ) = '0' then
                            ns <= addr_read_1;
                        end if;
                    when "001" => -- JZ
                        if aluflag(FlagZ) = '1' then
                            ns <= addr_read_1;
                        end if;
                    when "010" => -- JNC
                        if aluflag(FlagC) = '0' then
                            ns <= addr_read_1;
                        end if;
                    when "011" => -- JC
                        if aluflag(FlagC) = '1' then
                            ns <= addr_read_1;
                        end if;
                    when "100" => -- JPO
                        if aluflag(FlagP) = '0' then
                            ns <= addr_read_1;
                        end if;
                    when "101" => -- JPE
                        if aluflag(FlagP) = '1' then
                            ns <= addr_read_1;
                        end if;
                    when "110" => -- JP
                        if aluflag(FlagS) = '0' then
                            ns <= addr_read_1;
                        end if;
                    when "111" => -- JM
                        if aluflag(FlagS) = '1' then
                            ns <= addr_read_1;
                        end if;
                    end case;

                when "011" =>
                    ns <= opcode_fetch_1;
                    cb <= opcode_fetch_1;
                    --11 XXX 011
                    --C3	11000011	JMP <a>
                    --CB	11001011	XXX
                    --D3	11010011	OUT <b>
                    --DB	11011011	IN <b>
                    --E3	11100011	XTHL
                    --EB	11101011	XCHG
                    --F3	11110011	DI
                    --FB	11111011	EI
                    case op53 is
                    when "000" => -- JMP
                        ns <= addr_read_1;
                        cb <= opcode_fetch_1;
                    when "001" => -- No instruction
                        ns <= opcode_fetch_1;
                    when "010" => -- OUT <b>
                        ns <= data_read_1;
                        cb <= opcode_fetch_1;
                    when "011" => -- IN <b>
                        ns <= data_read_1;
                        cb <= opcode_fetch_1;
                    when "100" => -- XTHL
                        -- TODO
                        ns <= opcode_fetch_1;
                    when "101" => -- XCHG
                        -- TODO
                        ns <= opcode_fetch_1;
                    when "110" => -- DI
                        -- TODO
                        ns <= opcode_fetch_1;
                    when "111" => -- EI
                        -- TODO
                        ns <= opcode_fetch_1;
                    end case;

                when "100" =>
                    -- TODO
                    --11 XXX 100
                    --C4	11000100	CNZ
                    --CC	11001100	CZ
                    --D4	11010100	CNC
                    --DC	11011100	CC
                    --E4	11100100	CPO
                    --EC	11101100	CPE
                    --F4	11110100	CP
                    --FC	11111100	CM
                    ns <= opcode_fetch_1;
                    
                when "101" =>
                    -- TODO
                    --11 XXX 101
                    --C5	11000101	PUSH B
                    --CD	11001101	CALL
                    --D5	11010101	PUSH D
                    --DD	11011101	XXX
                    --E5	11100101	PUSH H
                    --ED	11011101	XXX
                    --F5	11110101	PUSH PSW
                    --FD	11011101	XXX
                    ns <= opcode_fetch_1;
                    
                when "110" =>
                    --11 XXX 110
                    --C6	11000110	ADI <b>
                    --CE	11001110	ACI <b>
                    --D6	11010110	SUI <b>
                    --DE	11011110	SBI <b>
                    --E6	11100110	ANI <b>
                    --EE	11101110	XRI <b>
                    --F6	11110110	ORI <b>
                    --FE	11111110	CPI <b>
                    ns <= data_read_1;
                    cb <= opcode_fetch_1;
                    
                when "111" =>
                    -- TODO
                    --11 XXX 111
                    --C7	11000111	RST 0
                    --CF	11001111	RST 1
                    --D7	11010111	RST 2
                    --DF	11011111	RST 3
                    --E7	11100111	RST 4
                    --EF	11101111	RST 5
                    --F7	11110111	RST 6
                    --FF	11111111	RST 7
                    ns <= opcode_fetch_1;
                    
                end case;
            when others =>
                ns <= reset_state;
            end case;
        when others =>
            ns <= reset_state;
        end case;
    end process;
    
end architecture;