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
        reqio_out   : out t_wire;
        
        -- BEGIN: SIMULATION ONLY
        con_out         : out t_control;
        addr_bus_out    : out t_address;
        data_bus_out    : out t_data;
        pc_out          : out t_address;
        acc_out         : out t_8bit;
        bc_out          : out t_16bit;
        alu_a_out       : out t_data;
        alu_b_out       : out t_data;
        alu_out         : out t_data
        -- END: SIMULATION ONLY
    );
end entity jp80_cpu;

architecture behv of jp80_cpu is

    signal clk      : t_wire;

    signal BC_reg   : t_16bit;
    alias  B_reg    is BC_reg(15 downto 8);
    alias  C_reg    is BC_reg(7 downto 0);
    signal DE_reg   : t_16bit;
    alias  D_reg    is DE_reg(15 downto 8);
    alias  E_reg    is DE_reg(7 downto 0);
    signal HL_reg   : t_16bit;
    alias  H_reg    is HL_reg(15 downto 8);
    alias  L_reg    is HL_reg(7 downto 0);

    signal ACC_reg  : t_8bit;
    signal FLAG_Reg : t_data;
    signal ALU_reg  : t_data;
    signal ALU_q    : t_data;
    signal PC_reg   : t_address;
    signal ADDR_reg : t_address;
    signal DATA_reg : t_data;
    signal SP_reg   : t_address;
    signal IR_reg   : t_data;
    
    -- Buses
    signal addr_bus     : t_address;
    alias  addr_bus_h   is addr_bus(15 downto 8);
    alias  addr_bus_l   is addr_bus(7 downto 0);
    signal data_bus     : t_data;
    
    signal opcode       : t_opcode;
    
    signal alucode      : t_alucode := "0000";
    signal alu_a        : t_data;
    signal alu_b        : t_data;

    -- Microcode signals
    signal con      : t_control := (others => '0');
    
    signal ns, ps, cb   : t_cpu_state;
    signal save_alu     : std_logic := '0';
    
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
    
begin
    addr_out    <= ADDR_reg;
    data_inout  <= DATA_reg when con(Wr) = '1' else (others=>'Z');
    read_out    <= not con(Wr);
    write_out   <= con(Wr);
    reqmem_out  <= not con(IO);
    reqio_out   <= con(IO);
    
    -- BEGIN: SIMULATION ONLY
    con_out         <= con;
    addr_bus_out    <= addr_bus;
    data_bus_out    <= data_bus;
    pc_out          <= PC_reg;
    acc_out         <= ACC_reg;
    bc_out          <= BC_reg;
    alu_a_out       <= alu_a;
    alu_b_out       <= alu_b;
    alu_out         <= ALU_reg;
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

    PC_register:
    process (clk, reset)
    begin
        if reset = '1' then
            PC_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Ipc) = '1' then
                PC_reg <= PC_reg + 1;
            elsif con(Lpc) = '1' then
                PC_reg <= addr_bus;
            end if;
        end if;
    end process PC_register;
    addr_bus <= PC_reg when con(Epc) = '1' else (others => 'Z');
    
    ADDR_register:
    process (clk, reset)
    begin
        if reset = '1' then
            ADDR_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Laddr) = '1' then
                ADDR_reg <= addr_bus;
            elsif con(LaddrL) = '1' then
                ADDR_reg(7 downto 0) <= data_bus;
            elsif con(LaddrH) = '1' then
                ADDR_reg(15 downto 8) <= data_bus;
            end if;
        end if;
    end process ADDR_register;
    addr_bus <= ADDR_reg when con(Eaddr) = '1' else (others => 'Z');
    
    DATA_register:
    process (clk, reset)
    begin
        if reset = '1' then
            DATA_reg <= (others => '0');
        elsif clk'event and clk = '0' then
            if con(Ldata) = '1' then
                DATA_reg <= data_bus;
            else
                DATA_reg <= data_inout;
            end if;
        end if;
    end process DATA_register;
    data_bus <= DATA_reg when con(Edata) = '1' else (others => 'Z');

    ACC_register:
    process (clk, reset)
    begin
        if reset = '1' then
            ACC_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Lacc) = '1' then
                ACC_reg <= data_bus;
            end if;
        end if;
    end process ACC_register;
    data_bus <= ACC_reg when con(Eacc) = '1' else (others => 'Z');

    BC_register:
    process (clk, reset)
    begin
        if reset = '1' then
            BC_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Lb) = '1' then
                B_reg <= data_bus;
            end if;
            if con(Lc) = '1' then
                C_reg <= data_bus;
            end if;
        end if;
    end process BC_register;
    data_bus <= B_reg when con(Eb) = '1' else (others => 'Z');
    data_bus <= C_reg when con(Ec) = '1' else (others => 'Z');
    addr_bus <= BC_reg when con(Eb) = '1' and con(Ec) = '1' else (others => 'Z');
    
    DE_register:
    process (clk, reset)
    begin
        if reset = '1' then
            DE_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Ld) = '1' then
                D_reg <= data_bus;
            end if;
            if con(Le) = '1' then
                E_reg <= data_bus;
            end if;
        end if;
    end process DE_register;
    data_bus <= D_reg when con(Ed) = '1' else (others => 'Z');
    data_bus <= E_reg when con(Ee) = '1' else (others => 'Z');
    addr_bus <= DE_reg when con(Ed) = '1' and con(Ee) = '1' else (others => 'Z');
    
    HL_register:
    process (clk, reset)
    begin
        if reset = '1' then
            HL_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Lh) = '1' and con(Ll) = '1'  then
                HL_reg <= addr_bus;
            else
                if con(Lh) = '1' then
                    H_reg <= data_bus;
                end if;
                if con(Ll) = '1' then
                    L_reg <= data_bus;
                end if;
            end if;
        end if;
    end process HL_register;
    data_bus <= H_reg when con(Eh) = '1' else (others => 'Z');
    data_bus <= L_reg when con(El) = '1' else (others => 'Z');
    addr_bus <= HL_reg when con(Ehl) = '1' else (others => 'Z');

    ALU_register:
    process (clk, reset)
    begin
        if reset = '1' then
            ALU_reg <= (others => '1');
        elsif clk'event and clk = '1' then
            if con(Lu) = '1' then
                ALU_reg <= ALU_q;
            end if;
        end if;
    end process ALU_register;
    data_bus <= ALU_reg when con(Eu) = '1' else (others => 'Z');

    alu_a <= ACC_reg when con(LaluA) = '1' else (others=>'Z');
    alu_b <= data_bus when con(LaluB) = '1' else (others=>'Z');
    
    ALU : work.JP80_ALU
    port map (
        alucode     => alucode,
        a           => alu_a,
        b           => alu_b,
        f_in        => FLAG_Reg,
        q           => ALU_q,
        f_out       => FLAG_Reg
    );
    
    IR_register:
    process (clk, reset)
    begin
        if reset = '1' then
            IR_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Lir) = '1' then
                IR_reg <= data_bus;
            end if;
        end if;
    end process IR_register;
    opcode <= IR_reg;
    
    process (clk, reset)
    begin
        if reset = '1' then
            ps <= reset_state;
        elsif clk'event and clk='0' then
            ps <= ns;
        end if;
    end process;
    
    process (ps, opcode, save_alu)
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
            if save_alu = '1' then
                con(Eu) <= '1';
                con(Lacc) <= '1';
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
            con(LaddrL) <= '1';
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
            con(LaddrH) <= '1';
            
            if op76 = "11" and op20 = "011" then
                con(Eaddr) <= '1';
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
                when "000" => -- NOP, RIM & SIM
                    -- TODO
                    ns <= opcode_fetch_1;
                when "001" => -- LXI & DAD
                    -- TODO
                    ns <= opcode_fetch_1;
                when "010" => -- STXX & LDXX
                    -- TODO
                    ns <= opcode_fetch_1;
                when "011" => -- INX & DCX
                    -- TODO
                    ns <= opcode_fetch_1;
                when "100" => -- INR
                    -- TODO
                    ns <= opcode_fetch_1;
                when "101" => -- DCR
                    -- TODO
                    ns <= opcode_fetch_1;
                when "110" => -- MVI r,<b>
                    ns <= data_read_1;
                    cb <= opcode_fetch_1;
                when "111" => -- MISC ALU
                    alucode <= "1" & op53;
                    con(LaluA) <= '1';
                    con(Lu) <= '1';
                    ns <= opcode_fetch_1;
                end case;
            when "01" => -- MOV r,r or HLT
                if opcode(5 downto 0) = "110110" then
                    con(HALT) <= '1'; -- HLT is the exception in the "01" range
                else
                    con(SSS(op20)) <= '1';
                    con(DDD(op53)) <= '1';
                end if;
                ns <= opcode_fetch_1;
            when "10" => -- ALU with register
                alucode <= "0"&op53;
                con(SSS(op20)) <= '1';
                con(LaluA) <= '1';
                con(LaluB) <= '1';
                con(Lu) <= '1';
                ns <= opcode_fetch_1;
            when "11" =>
                case op20 is
                when "000" => -- RXX (conditional return)
                    -- TODO
                    null;
                when "001" => -- POP, RET & misc
                    -- TODO
                    null;
                when "010" => -- JXX (conditional jump)
                    ns <= skip_addr_1;
                    cb <= opcode_fetch_1;
                    case op53 is
                    when "000" => -- JNZ
                        if FLAG_reg(FlagZ) = '0' then
                            ns <= addr_read_1;
                        end if;
                    when "001" => -- JZ
                        if FLAG_reg(FlagZ) = '1' then
                            ns <= addr_read_1;
                        end if;
                    when "010" => -- JNC
                        if FLAG_reg(FlagC) = '0' then
                            ns <= addr_read_1;
                        end if;
                    when "011" => -- JC
                        if FLAG_reg(FlagC) = '1' then
                            ns <= addr_read_1;
                        end if;
                    when "100" => -- JPO
                        if FLAG_reg(FlagP) = '0' then
                            ns <= addr_read_1;
                        end if;
                    when "101" => -- JPE
                        if FLAG_reg(FlagP) = '1' then
                            ns <= addr_read_1;
                        end if;
                    when "110" => -- JP
                        if FLAG_reg(FlagS) = '0' then
                            ns <= addr_read_1;
                        end if;
                    when "111" => -- JM
                        if FLAG_reg(FlagS) = '1' then
                            ns <= addr_read_1;
                        end if;
                    end case;

                when "011" => -- JMP and misc
                
                    case op53 is
                    when "000" => -- JMP
                        ns <= addr_read_1;
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
                        null;
                    when "101" => -- XCHG
                        -- TODO
                        null;
                    when "110" => -- DI
                        -- TODO
                        null;
                    when "111" => -- EI
                        -- TODO
                        null;
                    end case;

                when "100" => -- CXX (conditional call)
                    -- TODO
                    null;
                when "101" => -- PUSH & CALL
                    -- TODO
                    null;
                when "110" => -- ALU with immediate
                    ns <= data_read_1;
                    cb <= opcode_fetch_1;
                when "111" => -- RST X
                    -- TODO
                    ns <= opcode_fetch_1;
                    null;
                end case;
            when others =>
                ns <= reset_state;
            end case;
        when others =>
            ns <= reset_state;
        end case;
    end process;
    save_alu <= '1' when opcode(7 downto 6) = "10" or (opcode(7 downto 6) = "11" and opcode(2 downto 0) = "110") else '0';

end architecture behv;