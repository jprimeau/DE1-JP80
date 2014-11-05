-- DESCRIPTION: JP-80 - CPU
-- AUTHOR: Jonathan Primeau

-- TODO:
-- o Fix CALL and RET (16 bit)

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.jp80_pkg.all;

entity jp80_cpu is
    port (
        clock       : in t_wire;
        reset       : in t_wire;
        data_inout  : inout t_data;
        addr_out    : out t_address;
        read_out    : out t_wire;
        write_out   : out t_wire;
        reqmem_out  : out t_wire;
        reqio_out   : out t_wire
        
        -- BEGIN: SIMULATION ONLY
--        con_out     : out t_control;
--        bus_out     : out t_bus;
--        pc_out      : out t_address;
--        a_out       : out t_data;
--        b_out       : out t_data;
--        c_out       : out t_data;
--        tmp_out     : out t_data;
--        alu_out     : out t_data
        -- END: SIMULATION ONLY
    );
end entity jp80_cpu;

architecture behv of jp80_cpu is

    signal clk      : t_wire;

    signal ns, ps   : t_cpu_state;

    signal AF_reg   : t_address;
    alias  A_reg    is AF_reg(15 downto 8);
    alias  F_reg    is AF_reg(7 downto 0);
    signal BC_reg   : t_address;
    alias  B_reg    is BC_reg(15 downto 8);
    alias  C_reg    is BC_reg(7 downto 0);
    signal DE_reg   : t_address;
    alias  D_reg    is DE_reg(15 downto 8);
    alias  E_reg    is DE_reg(7 downto 0);
    signal HL_reg   : t_address;
    alias  H_reg    is HL_reg(15 downto 8);
    alias  L_reg    is HL_reg(7 downto 0);
--    signal A_reg    : t_data;
--    signal B_reg    : t_data;
--    signal C_reg    : t_data;
--    signal D_reg    : t_data;
--    signal E_reg    : t_data;
--    signal F_reg    : t_data; -- FLAG
--    signal H_reg    : t_data;
--    signal L_reg    : t_data;
    signal TMP_reg  : t_data;
    signal ALU_reg  : t_data;
    signal PC_reg   : t_address;
    signal SP_reg   : t_address;
    signal ADDR_reg : t_address;
    signal DATA_reg : t_data;
    signal I_reg    : t_data;

    signal w_bus    : t_bus;
    alias  w_bus_h  is w_bus(15 downto 8);
    alias  w_bus_l  is w_bus(7 downto 0);
    
    signal op_code  : t_opcode;
    
    signal alu_code : t_alucode;
    signal alu_a    : t_aluio;
    signal alu_b    : t_aluio;
    signal alu_q    : t_aluio;

    signal con      : t_control := (others => '0');
    
    signal flag_z   : t_wire;
    signal flag_s   : t_wire;
    
begin
    addr_out    <= ADDR_reg;
    data_inout  <= DATA_reg when con(Wr) = '1' else (others=>'Z');
    read_out    <= not con(Wr);
    write_out   <= con(Wr);
    reqmem_out  <= not con(IO);
    reqio_out   <= con(IO);
    
    -- BEGIN: SIMULATION ONLY
--    con_out     <= con;
--    bus_out     <= w_bus;
--    pc_out      <= PC_reg;
--    a_out       <= A_reg;
--    b_out       <= B_reg;
--    c_out       <= C_reg;
--    tmp_out     <= TMP_reg;
--    alu_out     <= ALU_reg;
    -- END: SIMULATION ONLY

    run:
    process (clock, reset, con)
    begin
        if reset = '1' then
            clk <= '0';
        else
            if con(HALT) = '1' then
                clk <= '0';
            else
                clk <= clock;
            end if;
        end if;
    end process run;

    program_counter:
    process (clk, reset)
    begin
        if reset = '1' then
            PC_reg <= (others => '0');
        elsif clk'event and clk = '0' then
            if con(Cp) = '1' then
                PC_reg <= PC_reg + 1;
            elsif con(Lp) = '1' then
                PC_reg <= w_bus;
            end if;
        end if;
    end process program_counter;
    w_bus <= PC_reg when con(Ep) = '1' else (others => 'Z');

    ADDR_register:
    process (clk, reset)
    begin
        if reset = '1' then
            ADDR_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Laddr) = '1' then
                ADDR_reg <= w_bus;
            end if;
        end if;
    end process ADDR_register;
    
    DATA_register:
    process (clk, reset)
    begin
        if reset = '1' then
            DATA_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Ldata) = '1' then
                DATA_reg <= w_bus_l;
            else
                DATA_reg <= data_inout;
            end if;
        end if;
    end process DATA_register;
    w_bus_l <= DATA_reg when con(EdataL) = '1' else (others => 'Z');
    w_bus_h <= DATA_reg when con(EdataH) = '1' else (others => 'Z');
    
    A_register:
    process (clk, reset)
    begin
        if reset = '1' then
            A_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(La) = '1' then
                A_reg <= w_bus_l;
            end if;
        end if;
    end process A_register;
    w_bus_l <= A_reg when con(Ea) = '1' else (others => 'Z');
    
    TMP_register:
    process (clk, reset)
    begin
        if reset = '1' then
            TMP_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Lt) = '1' then
                TMP_reg <= w_bus_l;
            end if;
        end if;
    end process TMP_register;
    w_bus_l <= TMP_reg when con(Et) = '1' else (others => 'Z');
    
    B_register:
    process (clk, reset)
    begin
        if reset = '1' then
            B_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Lb) = '1' then
                B_reg <= w_bus_l;
            end if;
        end if;
    end process B_register;
    w_bus_l <= B_reg when con(Eb) = '1' else (others => 'Z');
    
    C_register:
    process (clk, reset)
    begin
        if reset = '1' then
            C_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Lc) = '1' then
                C_reg <= w_bus_l;
            end if;
        end if;
    end process C_register;
    w_bus_l <= C_reg when con(Ec) = '1' else (others => 'Z');
    
    D_register:
    process (clk, reset)
    begin
        if reset = '1' then
            D_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Ld) = '1' then
                D_reg <= w_bus_l;
            end if;
        end if;
    end process D_register;
    w_bus_l <= D_reg when con(Ed) = '1' else (others => 'Z');
    
    E_register:
    process (clk, reset)
    begin
        if reset = '1' then
            E_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Le) = '1' then
                E_reg <= w_bus_l;
            end if;
        end if;
    end process E_register;
    w_bus_l <= E_reg when con(Ee) = '1' else (others => 'Z');
    
    H_register:
    process (clk, reset)
    begin
        if reset = '1' then
            H_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Lh) = '1' then
                H_reg <= w_bus_l;
            end if;
        end if;
    end process H_register;
    w_bus_h <= H_reg when con(Eh) = '1' else (others => 'Z');
    
    L_register:
    process (clk, reset)
    begin
        if reset = '1' then
            L_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Ll) = '1' then
                L_reg <= w_bus_l;
            end if;
        end if;
    end process L_register;
    w_bus_l <= L_reg when con(El) = '1' else (others => 'Z');
    
    I_register:
    process (clk, reset)
    begin
        if reset = '1' then
            I_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Li) = '1' then
                I_reg <= w_bus_l;
            end if;
        end if;
    end process I_register;
    op_code <= I_reg;
    
    arithmetic_logic_unit:
    process (clk, reset)
        variable a  : t_data;
        variable b  : t_data;
    begin
        if reset = '1' then
            ALU_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Lu) = '1' then
--                case alu_a is
--                    when ALU_A_REG => a := A_reg;
--                    when ALU_B_REG => a := B_reg;
--                    when ALU_C_REG => a := C_reg;
--                    when ALU_D_REG => a := D_reg;
--                    when ALU_E_REG => a := E_reg;
--                    when ALU_H_REG => a := H_reg;
--                    when ALU_L_REG => a := L_reg;
--                end case;
--                case alu_b is
--                    when ALU_A_REG => b := A_reg;
--                    when ALU_B_REG => b := B_reg;
--                    when ALU_C_REG => b := C_reg;
--                    when ALU_D_REG => b := D_reg;
--                    when ALU_E_REG => b := E_reg;
--                    when ALU_H_REG => b := H_reg;
--                    when ALU_L_REG => b := L_reg;
--                end case;
                a := w_bus_l;
                b := TMP_reg;
                case alu_code is
                when ALU_NOT =>
                    ALU_reg <= not a;
                when ALU_AND =>
                    ALU_reg <= a and b;
                when ALU_OR =>
                    ALU_reg <= a or b;
                when ALU_XOR =>
                    ALU_reg <= a xor b;
                when ALU_ROL =>
                    ALU_reg <= to_stdlogicvector(to_bitvector(a) rol 1);
                when ALU_ROR =>
                    ALU_reg <= to_stdlogicvector(to_bitvector(a) ror 1);
                when ALU_ONES =>
                    ALU_reg <= (others => '1');
                when ALU_INC =>
                    ALU_reg <= a + 1;
                when ALU_DEC =>
                    ALU_reg <= a - 1;
                when ALU_ADD =>
                    ALU_reg <= a + b;
                when ALU_SUB =>
                    ALU_reg <= a - b;
                when others =>
                    null;
                end case;
--                case alu_q is
--                    when ALU_A_REG => A_reg <= ALU_reg;
--                    when ALU_B_REG => B_reg <= ALU_reg;
--                    when ALU_C_REG => C_reg <= ALU_reg;
--                    when ALU_D_REG => D_reg <= ALU_reg;
--                    when ALU_E_REG => E_reg <= ALU_reg;
--                    when ALU_H_REG => H_reg <= ALU_reg;
--                    when ALU_L_REG => L_reg <= ALU_reg;
--                end case;
            end if;
        end if;
    end process arithmetic_logic_unit;
    w_bus_l <= ALU_reg when con(Eu) = '1' else (others => 'Z');
    
    flags:
    process (clk, con)
    begin
        if clk'event and clk = '1' then
            if con(Lsz) = '1' then
                if ALU_reg(7) = '1' then
                    flag_s <= '1';
                else
                    flag_s <= '0';
                end if;
                if ALU_reg = "0" then
                    flag_z <= '1';
                else
                    flag_z <= '0';
                end if;
            end if;
        end if;
    end process flags;
    
    cpu_state_machine_reg:
    process (clk, reset)
    begin
        if reset = '1' then
            ps <= reset_state;
        elsif clk'event and clk='0' then
            ps <= ns;
        end if;
    end process cpu_state_machine_reg;
    
    cpu_state_machine_transitions:
    process (ps, op_code)
    begin
        con <= (others => '0');
        case ps is
        
        when reset_state =>
            ns <= address_state;
        
		when address_state =>
            con(Ep) <= '1';
            con(Laddr) <= '1';
			ns <= increment_state;
            
		when increment_state =>
            con(Cp) <= '1';
			ns <= memory_state;
            
		when memory_state =>
            con(EdataL) <= '1';
            con(Li) <= '1';
			ns <= decode_instruction;
            
		when decode_instruction =>
            case op_code is
            
--            when I_ACI =>
--                ns <= address_state;

--            when I_ADCA =>
--                ns <= address_state;
--            when I_ADCB =>
--                ns <= address_state;
--            when I_ADCC =>
--                ns <= address_state;
--            when I_ADCD =>
--                ns <= address_state;
--            when I_ADCE =>
--                ns <= address_state;
--            when I_ADCH =>
--                ns <= address_state;
--            when I_ADCL =>
--                ns <= address_state;
--            when I_ADCM =>
--                ns <= address_state;

            when I_ADDA =>
                con(Ea) <= '1';
                con(Lt) <= '1';
                ns <= add_1;
            when I_ADDB =>
                con(Eb) <= '1';
                con(Lt) <= '1';
                ns <= add_1;
            when I_ADDC =>
                con(Ec) <= '1';
                con(Lt) <= '1';
                ns <= add_1;
            when I_ADDD =>
                con(Ed) <= '1';
                con(Lt) <= '1';
                ns <= add_1;
            when I_ADDE =>
                con(Ee) <= '1';
                con(Lt) <= '1';
                ns <= add_1;
            when I_ADDH =>
                con(Eh) <= '1';
                con(Lt) <= '1';
                ns <= add_1;
            when I_ADDL =>
                con(El) <= '1';
                con(Lt) <= '1';
                ns <= add_1;
--            when I_ADDM =>
--                ns <= address_state;

            when I_ANAA =>
                ns <= address_state;
            when I_ANAB =>
                con(Eb) <= '1';
                con(Lt) <= '1';
                ns <= ana_1;
            when I_ANAC =>
                con(Ec) <= '1';
                con(Lt) <= '1';
                ns <= ana_1;
            when I_ANAD =>
                con(Ed) <= '1';
                con(Lt) <= '1';
                ns <= ana_1;
            when I_ANAE =>
                con(Ee) <= '1';
                con(Lt) <= '1';
                ns <= ana_1;
            when I_ANAH =>
                con(Eh) <= '1';
                con(Lt) <= '1';
                ns <= ana_1;
            when I_ANAL =>
                con(El) <= '1';
                con(Lt) <= '1';
                ns <= ana_1;
--            when I_ANAM =>
--                ns <= address_state;

            when I_ANI =>
                con(Ep) <= '1';
                con(Laddr) <= '1';
                ns <= ani_1;
            when I_CALL =>
                con(Ep) <= '1';
                con(Laddr) <= '1';
                ns <= call_1;
            when I_CMA =>
                alu_code <= ALU_NOT;
                con(Eu) <= '1';
                con(La) <= '1';
                ns <= address_state;
            when I_DCRA =>
                alu_code <= ALU_DEC;
                con(Ea) <= '1';
                con(Lu) <= '1';
                ns <= dcra_1;
            when I_DCRB =>
                alu_code <= ALU_DEC;
                con(Eb) <= '1';
                con(Lu) <= '1';
                ns <= dcrb_1;
            when I_DCRC =>
                alu_code <= ALU_DEC;
                con(Ec) <= '1';
                con(Lu) <= '1';
                ns <= dcrc_1;
            when I_HLT =>
                con(HALT) <= '1';
                ns <= address_state;
            when I_IN =>
                con(Ep) <= '1';
                con(Laddr) <= '1';
                ns <= in_1;
            when I_INRA =>
                alu_code <= ALU_INC;
                con(Ea) <= '1';
                con(Lu) <= '1';
                ns <= inra_1;
            when I_INRB =>
                con(Eb) <= '1';
                con(La) <= '1';
                ns <= inrb_1;
            when I_INRC =>
                con(Ec) <= '1';
                con(La) <= '1';
                ns <= inrc_1;
            when I_JM =>
                con(Ep) <= '1';
                con(Laddr) <= '1';
                ns <= jm_1;
            when I_JMP =>
                con(Ep) <= '1';
                con(Laddr) <= '1';
                ns <= jmp_1;
            when I_JNZ =>
                con(Ep) <= '1';
                con(Laddr) <= '1';
                ns <= jnz_1;
            when I_JZ =>
                con(Ep) <= '1';
                con(Laddr) <= '1';
                ns <= jz_1;
            when I_LDA =>
                con(Ep) <= '1';
                con(Laddr) <= '1';
                ns <= lda_1;

            when I_MOVAA =>
                ns <= address_state;
            when I_MOVAB =>
                con(Eb) <= '1';
                con(La) <= '1';
                ns <= address_state;
            when I_MOVAC =>
                con(Ec) <= '1';
                con(La) <= '1';
                ns <= address_state;
            when I_MOVAD =>
                con(Ed) <= '1';
                con(La) <= '1';
                ns <= address_state;
            when I_MOVAE =>
                con(Ee) <= '1';
                con(La) <= '1';
                ns <= address_state;
            when I_MOVAH =>
                con(Eh) <= '1';
                con(La) <= '1';
                ns <= address_state;
            when I_MOVAL =>
                con(El) <= '1';
                con(La) <= '1';
                ns <= address_state;
--            when I_MOVAM =>
--                ns <= address_state;

            when I_MOVBA =>
                con(Ea) <= '1';
                con(Lb) <= '1';
                ns <= address_state;
            when I_MOVBB =>
                ns <= address_state;
            when I_MOVBC =>
                con(Ec) <= '1';
                con(Lb) <= '1';
                ns <= address_state;
            when I_MOVBD =>
                con(Ed) <= '1';
                con(Lb) <= '1';
                ns <= address_state;
            when I_MOVBE =>
                con(Ee) <= '1';
                con(Lb) <= '1';
                ns <= address_state;
            when I_MOVBH =>
                con(Eh) <= '1';
                con(Lb) <= '1';
                ns <= address_state;
            when I_MOVBL =>
                con(El) <= '1';
                con(Lb) <= '1';
                ns <= address_state;
--            when I_MOVBM =>
--                ns <= address_state;

            when I_MOVCA =>
                con(Ea) <= '1';
                con(Lc) <= '1';
                ns <= address_state;
            when I_MOVCB =>
                con(Eb) <= '1';
                con(Lc) <= '1';
                ns <= address_state;
            when I_MOVCC =>
                ns <= address_state;
            when I_MOVCD =>
                con(Ed) <= '1';
                con(Lc) <= '1';
                ns <= address_state;
            when I_MOVCE =>
                con(Ee) <= '1';
                con(Lc) <= '1';
                ns <= address_state;
            when I_MOVCH =>
                con(Eh) <= '1';
                con(Lc) <= '1';
                ns <= address_state;
            when I_MOVCL =>
                con(El) <= '1';
                con(Lc) <= '1';
                ns <= address_state;
--            when I_MOVCM =>
--                ns <= address_state;

            when I_MOVDA =>
                con(Ea) <= '1';
                con(Ld) <= '1';
                ns <= address_state;
            when I_MOVDB =>
                con(Eb) <= '1';
                con(Ld) <= '1';
                ns <= address_state;
            when I_MOVDC =>
                con(Ec) <= '1';
                con(Ld) <= '1';
                ns <= address_state;
            when I_MOVDD =>
                ns <= address_state;
            when I_MOVDE =>
                con(Ee) <= '1';
                con(Ld) <= '1';
                ns <= address_state;
            when I_MOVDH =>
                con(Eh) <= '1';
                con(Ld) <= '1';
                ns <= address_state;
            when I_MOVDL =>
                con(El) <= '1';
                con(Ld) <= '1';
                ns <= address_state;
--            when I_MOVDM =>
--                ns <= address_state;

            when I_MOVEA =>
                con(Ea) <= '1';
                con(Le) <= '1';
                ns <= address_state;
            when I_MOVEB =>
                con(Eb) <= '1';
                con(Le) <= '1';
                ns <= address_state;
            when I_MOVEC =>
                con(Ec) <= '1';
                con(Le) <= '1';
                ns <= address_state;
            when I_MOVED =>
                con(Ed) <= '1';
                con(Le) <= '1';
                ns <= address_state;
            when I_MOVEE =>
                ns <= address_state;
            when I_MOVEH =>
                con(Eh) <= '1';
                con(Le) <= '1';
                ns <= address_state;
            when I_MOVEL =>
                con(El) <= '1';
                con(Le) <= '1';
                ns <= address_state;
--            when I_MOVEM =>
--                ns <= address_state;

            when I_MOVHA =>
                con(Ea) <= '1';
                con(Lh) <= '1';
                ns <= address_state;
            when I_MOVHB =>
                con(Eb) <= '1';
                con(Lh) <= '1';
                ns <= address_state;
            when I_MOVHC =>
                con(Ec) <= '1';
                con(Lh) <= '1';
                ns <= address_state;
            when I_MOVHD =>
                con(Ed) <= '1';
                con(Lh) <= '1';
                ns <= address_state;
            when I_MOVHE =>
                con(Ee) <= '1';
                con(Lh) <= '1';
                ns <= address_state;
            when I_MOVHH =>
                ns <= address_state;
            when I_MOVHL =>
                con(El) <= '1';
                con(Lh) <= '1';
                ns <= address_state;
--            when I_MOVHM =>
--                ns <= address_state;

            when I_MOVLA =>
                con(Ea) <= '1';
                con(Ll) <= '1';
                ns <= address_state;
            when I_MOVLB =>
                con(Eb) <= '1';
                con(Ll) <= '1';
                ns <= address_state;
            when I_MOVLC =>
                con(Ec) <= '1';
                con(Ll) <= '1';
                ns <= address_state;
            when I_MOVLD =>
                con(Ed) <= '1';
                con(Ll) <= '1';
                ns <= address_state;
            when I_MOVLE =>
                con(Ee) <= '1';
                con(Ll) <= '1';
                ns <= address_state;
            when I_MOVLH =>
                con(Eh) <= '1';
                con(Ll) <= '1';
                ns <= address_state;
            when I_MOVLL =>
                ns <= address_state;
--            when I_MOVLM =>
--                ns <= address_state;

--            when I_MOVMA =>
--                ns <= address_state;
--            when I_MOVMB =>
--                ns <= address_state;
--            when I_MOVMC =>
--                ns <= address_state;
--            when I_MOVMD =>
--                ns <= address_state;
--            when I_MOVME =>
--                ns <= address_state;
--            when I_MOVMH =>
--                ns <= address_state;
--            when I_MOVML =>
--                ns <= address_state;

            when I_MVIA =>
                con(Ep) <= '1';
                con(Laddr) <= '1';
                ns <= mvia_1;
            when I_MVIB =>
                con(Ep) <= '1';
                con(Laddr) <= '1';
                ns <= mvib_1;
            when I_MVIC =>
                con(Ep) <= '1';
                con(Laddr) <= '1';
                ns <= mvic_1;
            when I_MVID =>
                con(Ep) <= '1';
                con(Laddr) <= '1';
                ns <= mvid_1;
            when I_MVIE =>
                con(Ep) <= '1';
                con(Laddr) <= '1';
                ns <= mvie_1;
            when I_MVIH =>
                con(Ep) <= '1';
                con(Laddr) <= '1';
                ns <= mvih_1;
            when I_MVIL =>
                con(Ep) <= '1';
                con(Laddr) <= '1';
                ns <= mvil_1;
            when I_MVIM =>
                ns <= address_state;

            when I_NOP =>
                ns <= address_state;
            when I_ORAB =>
                con(Eb) <= '1';
                con(Lt) <= '1';
                ns <= ora_1;
            when I_ORAC =>
                con(Ec) <= '1';
                con(Lt) <= '1';
                ns <= ora_1;
            when I_ORI =>
                con(Ep) <= '1';
                con(Laddr) <= '1';
                ns <= ori_1;
            when I_OUT =>
                con(Ep) <= '1';
                con(Laddr) <= '1';
                ns <= out_1;

            when I_PCHL =>
                con(Lp) <= '1';
                con(Eh) <= '1';
                con(El) <= '1';
                ns <= address_state;
                
                
            when I_RAL =>
                alu_code <= ALU_ROL;
                con(Eu) <= '1';
                con(La) <= '1';
                ns <= address_state;
            when I_RAR =>
                alu_code <= ALU_ROR;
                con(Eu) <= '1';
                con(La) <= '1';
                ns <= address_state;
            when I_RET =>
                alu_code <= ALU_ONES;
                con(Eu) <= '1';
                con(Laddr) <= '1';
                ns <= ret_1;
            when I_STA =>
                con(Ep) <= '1';
                con(Laddr) <= '1';
                ns <= sta_1;
            when I_SUBB =>
                con(Eb) <= '1';
                con(Lt) <= '1';
                ns <= sub_1;
            when I_SUBC =>
                con(Ec) <= '1';
                con(Lt) <= '1';
                ns <= sub_1;
            when I_XRAB =>
                con(Eb) <= '1';
                con(Lt) <= '1';
                ns <= xra_1;
            when I_XRAC =>
                con(Ec) <= '1';
                con(Lt) <= '1';
                ns <= xra_1;
            when I_XRI =>
                con(Ep) <= '1';
                con(Laddr) <= '1';
                ns <= xri_1;
            when others =>
                ns <= address_state;
            end case;

        when add_1 =>
            alu_code <= ALU_ADD;
            con(Ea) <= '1';
            con(Lu) <= '1';
            ns <= add_2;
        when add_2 =>
            con(Eu) <= '1';
            con(La) <= '1';
            con(Lsz) <= '1';
            ns <= address_state;
       
        when ana_1 =>
            alu_code <= ALU_AND;
            con(Ea) <= '1';
            con(Lu) <= '1';
            ns <= ana_2;
        when ana_2 =>
            con(Eu) <= '1';
            con(La) <= '1';
            con(Lsz) <= '1';
            ns <= address_state;

        when ani_1 =>
            con(Cp) <= '1';
            ns <= ani_2;
        when ani_2 =>
            con(EdataL) <= '1';
            con(Lt) <= '1';
            ns <= ani_3;
        when ani_3 =>
            alu_code <= ALU_AND;
            con(Eu) <= '1';
            con(La) <= '1';
            con(Lsz) <= '1';
            ns <= address_state;

        when call_1 =>
            con(Cp) <= '1';
            ns <= call_2;
        when call_2 =>
            con(Ep) <= '1';
            con(Lt) <= '1';
            ns <= call_3;
        when call_3 =>
            con(EdataL) <= '1';
            con(Lp) <= '1';
            ns <= call_4;
        when call_4 =>
            alu_code <= ALU_ONES;
            con(Eu) <= '1';
            con(Laddr) <= '1';
            ns <= call_5;
        when call_5 =>
            ns <= call_6; -- Sleep 1 cycle
        when call_6 =>
            con(Et) <= '1';
            con(Wr) <= '1';
            ns <= address_state;

        when dcra_1 =>
            con(Eu) <= '1';
            con(La) <= '1';
            con(Lsz) <= '1';
            ns <= address_state;

        when dcrb_1 =>
            con(Eu) <= '1';
            con(Lb) <= '1';
            con(Lsz) <= '1';
            ns <= address_state;

        when dcrc_1 =>
            con(Eu) <= '1';
            con(Lc) <= '1';
            con(Lsz) <= '1';
            ns <= address_state;
            
        when in_1 =>
            con(Cp) <= '1';
            ns <= in_2;
        when in_2 =>
            con(EdataL) <= '1';
            con(Laddr) <= '1';
            ns <= in_3;
        when in_3 =>
            con(IO) <= '1';
            ns <= in_4;
        when in_4 =>
            con(EdataL) <= '1';
            con(La) <= '1';
            ns <= address_state;
            
        when inra_1 =>
            con(Eu) <= '1';
            con(La) <= '1';
            con(Lsz) <= '1';
            ns <= address_state;

        when inrb_1 =>
            con(Eu) <= '1';
            con(Lb) <= '1';
            con(Lsz) <= '1';
            ns <= address_state;

        when inrc_1 =>
            con(Eu) <= '1';
            con(Lc) <= '1';
            con(Lsz) <= '1';
            ns <= address_state;
          
        when jm_1 =>
            con(Cp) <= '1';
            ns <= jm_2;
        when jm_2 =>
            con(EdataL) <= '1';
            con(Lt) <= '1';
            ns <= jm_3;
        when jm_3 =>
            con(Ep) <= '1';
            con(Laddr) <= '1';
            ns <= jm_4;
        when jm_4 =>
            con(Cp) <= '1';
            ns <= jm_5;
        when jm_5 =>
            if flag_s = '1' then
                con(EdataH) <= '1';
                con(Et) <= '1';
                con(Lp) <= '1';
            end if;
            ns <= address_state;

        when jmp_1 =>
            con(Cp) <= '1';
            ns <= jmp_2;
        when jmp_2 =>
            con(EdataL) <= '1';
            con(Lt) <= '1';
            ns <= jmp_3;
        when jmp_3 =>
            con(Ep) <= '1';
            con(Laddr) <= '1';
            ns <= jmp_4;
        when jmp_4 =>
            con(Cp) <= '1';
            ns <= jmp_5;
        when jmp_5 =>
            con(EdataH) <= '1';
            con(Et) <= '1';
            con(Lp) <= '1';
            ns <= address_state;
            
        when jnz_1 =>
            con(Cp) <= '1';
            ns <= jnz_2;
        when jnz_2 =>
            con(EdataL) <= '1';
            con(Lt) <= '1';
            ns <= jnz_3;
        when jnz_3 =>
            con(Ep) <= '1';
            con(Laddr) <= '1';
            ns <= jnz_4;
        when jnz_4 =>
            con(Cp) <= '1';
            ns <= jnz_5;
        when jnz_5 =>
            if flag_z = '0' then
                con(EdataH) <= '1';
                con(Et) <= '1';
                con(Lp) <= '1';
            end if;
            ns <= address_state;

        when jz_1 =>
            con(Cp) <= '1';
            ns <= jz_2;
        when jz_2 =>
            con(EdataL) <= '1';
            con(Lt) <= '1';
            ns <= jz_3;
        when jz_3 =>
            con(Ep) <= '1';
            con(Laddr) <= '1';
            ns <= jz_4;
        when jz_4 =>
            con(Cp) <= '1';
            ns <= jz_5;
        when jz_5 =>
            if flag_z = '1' then
                con(EdataH) <= '1';
                con(Et) <= '1';
                con(Lp) <= '1';
            end if;
            ns <= address_state;

        when lda_1 =>
            con(Cp) <= '1';
            ns <= lda_2;
        when lda_2 =>
            con(EdataL) <= '1';
            con(Lt) <= '1';
            ns <= lda_3;
        when lda_3 =>
            con(Ep) <= '1';
            con(Laddr) <= '1';
            ns <= lda_4;
        when lda_4 =>
            con(Cp) <= '1';
            ns <= lda_5;
        when lda_5 =>
            con(EdataH) <= '1';
            con(Et) <= '1';
            con(Laddr) <= '1';
            ns <= lda_6;
        when lda_6 =>
            con(EdataL) <= '1';
            con(La) <= '1';
            ns <= address_state;

        when mvia_1 =>
            con(Cp) <= '1';
            ns <= mvia_2;
        when mvia_2 =>
            con(EdataL) <= '1';
            con(La) <= '1';
            ns <= address_state;

        when mvib_1 =>
            con(Cp) <= '1';
            ns <= mvib_2;
        when mvib_2 =>
            con(EdataL) <= '1';
            con(Lb) <= '1';
            ns <= address_state;

        when mvic_1 =>
            con(Cp) <= '1';
            ns <= mvic_2;
        when mvic_2 =>
            con(EdataL) <= '1';
            con(Lc) <= '1';
            ns <= address_state;
            
        when mvih_1 =>
            con(Cp) <= '1';
            ns <= mvih_2;
        when mvih_2 =>
            con(EdataL) <= '1';
            con(Lh) <= '1';
            ns <= address_state;
            
        when mvil_1 =>
            con(Cp) <= '1';
            ns <= mvil_2;
        when mvil_2 =>
            con(EdataL) <= '1';
            con(Ll) <= '1';
            ns <= address_state;

        when ora_1 =>
            alu_code <= ALU_OR;
            con(Eu) <= '1';
            con(La) <= '1';
            con(Lsz) <= '1';
            ns <= address_state;

        when ori_1 =>
            con(Cp) <= '1';
            ns <= ori_2;
        when ori_2 =>
            con(EdataL) <= '1';
            con(Lt) <= '1';
            ns <= ori_3;
        when ori_3 =>
            alu_code <= ALU_OR;
            con(Eu) <= '1';
            con(La) <= '1';
            con(Lsz) <= '1';
            ns <= address_state;
            
        when out_1 =>
            con(Cp) <= '1';
            ns <= out_2;
        when out_2 =>
            con(EdataL) <= '1';
            con(Laddr) <= '1';
            ns <= out_3;
        when out_3 =>
            con(Ea) <= '1';
            con(Ldata) <= '1';
            ns <= out_4;
        when out_4 =>
            con(IO) <= '1';
            con(Wr) <= '1';
            ns <= address_state;

        when ret_1 =>
            ns <= ret_2; -- Sleep 1 cycle
        when ret_2 =>
            con(EdataL) <= '1';
            con(Lp) <= '1';
            ns <= address_state;

        when sta_1 =>
            con(Cp) <= '1';
            ns <= sta_2;
        when sta_2 =>
            con(EdataL) <= '1';
            con(Lt) <= '1';
            ns <= sta_3;
        when sta_3 =>
            con(Ep) <= '1';
            con(Laddr) <= '1';
            ns <= sta_4;
        when sta_4 =>
            con(Cp) <= '1';
            ns <= sta_5;
        when sta_5 =>
            con(EdataH) <= '1';
            con(Et) <= '1';
            con(Laddr) <= '1';
            ns <= sta_6;
        when sta_6 =>
            con(Ea) <= '1';
            con(Ldata) <= '1';
            ns <= sta_7;
        when sta_7 =>
            con(Wr) <= '1';
            ns <= address_state;

        when sub_1 =>
            alu_code <= ALU_SUB;
            con(Eu) <= '1';
            con(La) <= '1';
            con(Lsz) <= '1';
            ns <= address_state;
  
        when xra_1 =>
            alu_code <= ALU_XOR;
            con(Eu) <= '1';
            con(La) <= '1';
            con(Lsz) <= '1';
            ns <= address_state;

        when xri_1 =>
            con(Cp) <= '1';
            ns <= ori_2;
        when xri_2 =>
            con(EdataL) <= '1';
            con(Lt) <= '1';
            ns <= xri_3;
        when xri_3 =>
            alu_code <= ALU_XOR;
            con(Eu) <= '1';
            con(La) <= '1';
            con(Lsz) <= '1';
            ns <= address_state;

		when others =>
			con <= (others=>'0');
			ns <= address_state;
		end case;
    end process cpu_state_machine_transitions;

end architecture behv;