-- DESCRIPTION: JP-80 - PKG
-- AUTHOR: Jonathan Primeau

library ieee;
use ieee.std_logic_1164.all;

package jp80_pkg is

    subtype t_wire is std_logic;
    subtype t_flag is std_logic;
    subtype t_bus is std_logic_vector(15 downto 0);
    subtype t_address is std_logic_vector(15 downto 0);
    subtype t_data is std_logic_vector(7 downto 0);
    subtype t_opcode is std_logic_vector(7 downto 0);
    subtype t_control is std_logic_vector(31 downto 0);
    subtype t_alucode is std_logic_vector(3 downto 0);
    
    subtype t_regaddr is std_logic_vector(15 downto 0);
    subtype t_aluop is std_logic_vector(2 downto 0);
    
    subtype t_8bit is std_logic_vector(7 downto 0);
    subtype t_16bit is std_logic_vector(15 downto 0);
    
    subtype t_tstate is integer;

    -- Op code
--    constant I_ACI      : t_opcode := x"CE";
--    
--    constant I_ADCA     : t_opcode := x"8F";
--    constant I_ADCB     : t_opcode := x"88";
--    constant I_ADCC     : t_opcode := x"89";
--    constant I_ADCD     : t_opcode := x"8A";
--    constant I_ADCE     : t_opcode := x"8B";
--    constant I_ADCH     : t_opcode := x"8C";
--    constant I_ADCL     : t_opcode := x"8D";
--    constant I_ADCM     : t_opcode := x"8E";
    
    constant I_ADDA     : t_opcode := x"87";
    constant I_ADDB     : t_opcode := x"80";
    constant I_ADDC     : t_opcode := x"81";
    constant I_ADDD     : t_opcode := x"82";
    constant I_ADDE     : t_opcode := x"83";
    constant I_ADDH     : t_opcode := x"84";
    constant I_ADDL     : t_opcode := x"85";
--    constant I_ADDM     : t_opcode := x"86";

    constant I_ANAA     : t_opcode := x"A7";
    constant I_ANAB     : t_opcode := x"A0";
    constant I_ANAC     : t_opcode := x"A1";
    constant I_ANAD     : t_opcode := x"A2";
    constant I_ANAE     : t_opcode := x"A3";
    constant I_ANAH     : t_opcode := x"A4";
    constant I_ANAL     : t_opcode := x"A5";
--    constant I_ANAM     : t_opcode := x"A6";

    constant I_ANI      : t_opcode := x"E6";
    constant I_CALL     : t_opcode := x"CD";
    constant I_CMA      : t_opcode := x"2F";
    constant I_DCRA     : t_opcode := x"3D";
    constant I_DCRB     : t_opcode := x"05";
    constant I_DCRC     : t_opcode := x"0D";
--    constant I_HLT      : t_opcode := x"76";
    constant I_IN       : t_opcode := x"DB";
    constant I_INRA     : t_opcode := x"3C";
    constant I_INRB     : t_opcode := x"04";
    constant I_INRC     : t_opcode := x"0C";
    constant I_JM       : t_opcode := x"FA";
    constant I_JMP      : t_opcode := x"C3";
    constant I_JNZ      : t_opcode := x"C2";
    constant I_JZ       : t_opcode := x"CA";
    constant I_LDA      : t_opcode := x"3A";
    
--    constant I_MOVAA    : t_opcode := x"7F";
--    constant I_MOVAB    : t_opcode := x"78";
--    constant I_MOVAC    : t_opcode := x"79";
--    constant I_MOVAD    : t_opcode := x"7A";
--    constant I_MOVAE    : t_opcode := x"7B";
--    constant I_MOVAH    : t_opcode := x"7C";
--    constant I_MOVAL    : t_opcode := x"7D";
--    constant I_MOVAM    : t_opcode := x"7E";
--    
--    constant I_MOVBA    : t_opcode := x"47";
--    constant I_MOVBB    : t_opcode := x"40";
--    constant I_MOVBC    : t_opcode := x"41";
--    constant I_MOVBD    : t_opcode := x"42";
--    constant I_MOVBE    : t_opcode := x"43";
--    constant I_MOVBH    : t_opcode := x"44";
--    constant I_MOVBL    : t_opcode := x"45";
--    constant I_MOVBM    : t_opcode := x"46";
--    
--    constant I_MOVCA    : t_opcode := x"4F";
--    constant I_MOVCB    : t_opcode := x"48";
--    constant I_MOVCC    : t_opcode := x"49";
--    constant I_MOVCD    : t_opcode := x"4A";
--    constant I_MOVCE    : t_opcode := x"4B";
--    constant I_MOVCH    : t_opcode := x"4C";
--    constant I_MOVCL    : t_opcode := x"4D";
--    constant I_MOVCM    : t_opcode := x"4E";
--
--    constant I_MOVDA    : t_opcode := x"57";
--    constant I_MOVDB    : t_opcode := x"50";
--    constant I_MOVDC    : t_opcode := x"51";
--    constant I_MOVDD    : t_opcode := x"52";
--    constant I_MOVDE    : t_opcode := x"53";
--    constant I_MOVDH    : t_opcode := x"54";
--    constant I_MOVDL    : t_opcode := x"55";
--    constant I_MOVDM    : t_opcode := x"56";
--
--    constant I_MOVEA    : t_opcode := x"5F";
--    constant I_MOVEB    : t_opcode := x"58";
--    constant I_MOVEC    : t_opcode := x"59";
--    constant I_MOVED    : t_opcode := x"5A";
--    constant I_MOVEE    : t_opcode := x"5B";
--    constant I_MOVEH    : t_opcode := x"5C";
--    constant I_MOVEL    : t_opcode := x"5D";
--    constant I_MOVEM    : t_opcode := x"5E";
--
--    constant I_MOVHA    : t_opcode := x"67";
--    constant I_MOVHB    : t_opcode := x"60";
--    constant I_MOVHC    : t_opcode := x"61";
--    constant I_MOVHD    : t_opcode := x"62";
--    constant I_MOVHE    : t_opcode := x"63";
--    constant I_MOVHH    : t_opcode := x"64";
--    constant I_MOVHL    : t_opcode := x"65";
--    constant I_MOVHM    : t_opcode := x"66";
--
--    constant I_MOVLA    : t_opcode := x"6F";
--    constant I_MOVLB    : t_opcode := x"68";
--    constant I_MOVLC    : t_opcode := x"69";
--    constant I_MOVLD    : t_opcode := x"6A";
--    constant I_MOVLE    : t_opcode := x"6B";
--    constant I_MOVLH    : t_opcode := x"6C";
--    constant I_MOVLL    : t_opcode := x"6D";
--    constant I_MOVLM    : t_opcode := x"6E";
--
--    constant I_MOVMA    : t_opcode := x"77";
--    constant I_MOVMB    : t_opcode := x"70";
--    constant I_MOVMC    : t_opcode := x"71";
--    constant I_MOVMD    : t_opcode := x"72";
--    constant I_MOVME    : t_opcode := x"73";
--    constant I_MOVMH    : t_opcode := x"74";
--    constant I_MOVML    : t_opcode := x"75";
--    
--    constant I_MVIA     : t_opcode := x"3E";
--    constant I_MVIB     : t_opcode := x"06";
--    constant I_MVIC     : t_opcode := x"0E";
--    constant I_MVID     : t_opcode := x"16";
--    constant I_MVIE     : t_opcode := x"1E";
--    constant I_MVIH     : t_opcode := x"26";
--    constant I_MVIL     : t_opcode := x"2E";
--    constant I_MVIM     : t_opcode := x"36";
    
    constant I_NOP      : t_opcode := x"00";
    constant I_ORAB     : t_opcode := x"B0";
    constant I_ORAC     : t_opcode := x"B1";
    constant I_ORI      : t_opcode := x"F6";
    constant I_OUT      : t_opcode := x"D3";
    
    constant I_PCHL     : t_opcode := x"E9";
    
    constant I_RAL      : t_opcode := x"17";
    constant I_RAR      : t_opcode := x"1F";
    constant I_RET      : t_opcode := x"C9";
    constant I_STA      : t_opcode := x"32";
    constant I_SUBB     : t_opcode := x"90";
    constant I_SUBC     : t_opcode := x"91";
    constant I_XRAB     : t_opcode := x"A8";
    constant I_XRAC     : t_opcode := x"A9";
    constant I_XRI      : t_opcode := x"EE";
    
    constant Lpc    : integer := 00;
    constant Ipc    : integer := 01;
    constant Epc    : integer := 02;
    constant Lmar   : integer := 03;
    constant Lmdr   : integer := 04;
    constant Emdr   : integer := 05;

    constant Lir    : integer := 07;
    constant Esrc   : integer := 08;
    constant Ldst   : integer := 09;
--    constant La     : integer := 23;
--    constant Ea     : integer := 09;
--    constant Lb     : integer := 10;
--    constant Eb     : integer := 11;
--    constant Lc     : integer := 12;
--    constant Ec     : integer := 13;
--    constant Ld     : integer := 14;
--    constant Ed     : integer := 15;
--    constant Le     : integer := 16;
--    constant Ee     : integer := 17;
--    constant Lh     : integer := 18;
--    constant Eh     : integer := 19;
--    constant Ll     : integer := 20;
--    constant El     : integer := 21;
--    constant Lm     : integer := 22;
--    constant Em     : integer := 23;
    constant Lt     : integer := 24;
    constant Et     : integer := 25;
    constant Eu     : integer := 26;
    constant Lu     : integer := 27;
    constant Lsz    : integer := 28;
    constant Wr     : integer := 29;
    constant IO     : integer := 30;
    constant HALT   : integer := 31;
    
    -- Sources and destinations
    constant sdB    : integer := 00;
    constant sdC    : integer := 01;
    constant sdD    : integer := 02;
    constant sdE    : integer := 03;
    constant sdH    : integer := 04;
    constant sdL    : integer := 05;
    constant sdACC  : integer := 07;
    constant sdPC	: integer := 11;
    
--    constant EregA  : integer := 08;
--    constant EregB  : integer := 09;
--    constant LregI  : integer := 10;
--    constant RegA0  : integer := 11;
--    constant RegA1  : integer := 12;
--    constant RegA2  : integer := 13;
--    constant RegB0  : integer := 14;
--    constant RegB1  : integer := 15;
--    constant RegB2  : integer := 16;
--    constant RegI0  : integer := 17;
--    constant RegI1  : integer := 18;
--    constant RegI2  : integer := 19;
    
    constant ALU0   : integer := 20;
    constant ALU1   : integer := 21;
    constant ALU2   : integer := 22;
    
    constant FlagC  : integer := 00;
    constant FlagP  : integer := 02;
    constant FlagH  : integer := 04;
    constant FlagI  : integer := 05;
    constant FlagZ  : integer := 06;
    constant FlagS  : integer := 07;
    

    type t_cpu_state is (
        reset_state,
        opcode_fetch_1, opcode_fetch_2, opcode_fetch_3,
        memory_read_1, memory_read_2, memory_read_3,
        decode_instruction
--        address_state, increment_state, memory_state, decode_instruction,
--        add_1, add_2, ana_1,ana_2, ani_1, ani_2, ani_3,
--        call_1, call_2, call_3, call_4, call_5, call_6,
--        dcra_1, dcrb_1, dcrc_1,
--        in_1, in_2, in_3, in_4,
--        inra_1, inrb_1, inrc_1, jm_1, jm_2, jm_3, jm_4, jm_5, 
--        jmp_1, jmp_2, jmp_3, jmp_4, jmp_5,
--        jnz_1, jnz_2, jnz_3, jnz_4, jnz_5,
--        jz_1, jz_2, jz_3, jz_4, jz_5,
--        lda_1, lda_2, lda_3, lda_4, lda_5, lda_6, lda_7,
--        mvia_1, mvia_2, mvib_1, mvib_2, mvic_1, mvic_2, mvid_1, mvid_2,
--        mvie_1, mvie_2, mvih_1, mvih_2, mvil_1, mvil_2,
--        ora_1, ori_1, ori_2, ori_3, 
--        out_1, out_2, out_3, out_4, ret_1, ret_2, 
--        sta_1, sta_2, sta_3, sta_4, sta_5, sta_6, sta_7, sub_1,
--        xra_1, xri_1, xri_2, xri_3,
        
--        mbyte_to_reg_1, mbyte_to_reg_2, alu_to_acc
    );
    
--    type t_aluio is (
--        ALU_A_REG,
--        ALU_B_REG,
--        ALU_C_REG,
--        ALU_D_REG,
--        ALU_E_REG,
--        ALU_H_REG,
--        ALU_L_REG
--    );
    
--    constant ALU_NOT        : t_alucode := x"0";
--    constant ALU_AND        : t_alucode := x"1";
--    constant ALU_OR         : t_alucode := x"2";
--    constant ALU_XOR        : t_alucode := x"3";
--    constant ALU_ROL        : t_alucode := x"4";
--    constant ALU_ROR        : t_alucode := x"5";
--    constant ALU_INC        : t_alucode := x"6";
--    constant ALU_DEC        : t_alucode := x"7";
--    constant ALU_ADD        : t_alucode := x"8";
--    constant ALU_SUB        : t_alucode := x"9";
--    constant ALU_ONES       : t_alucode := x"A";

end package jp80_pkg;
