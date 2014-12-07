-- DESCRIPTION: JP-80 - CPU
-- AUTHOR: Jonathan Primeau

-- TODO:

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
        de_out          : out t_16bit;
        hl_out          : out t_16bit;
        sp_out          : out t_16bit;
        flag_out        : out t_8bit;
        ir_out          : out t_8bit;
        tmp_out         : out t_16bit;
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
    signal TMP_reg  : t_address;
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
    signal alu_to_reg   : std_logic_vector(3 downto 0) := (others => '0');

    -- Microcode signals
    signal con      : t_control := (others => '0');
    
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
    de_out          <= DE_reg;
    hl_out          <= HL_reg;
    sp_out          <= SP_reg;
    flag_out        <= FLAG_reg;
    ir_out          <= IR_reg;
    tmp_out         <= TMP_reg;
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
            elsif con(I2pc) = '1' then
                PC_reg <= PC_reg + 2;
            elsif con(Lpc) = '1' then
                PC_reg <= addr_bus;
            elsif con(LpcL) = '1' then
                PC_reg(7 downto 0) <= data_bus;
            elsif con(LpcH) = '1' then
                PC_reg(15 downto 8) <= data_bus;
            end if;
        end if;
    end process PC_register;
    addr_bus <= PC_reg when con(Epc) = '1' else (others => 'Z');
    data_bus <= PC_reg(15 downto 8) when con(EpcH) = '1' else (others => 'Z');
    data_bus <= PC_reg(7 downto 0) when con(EpcL) = '1' else (others => 'Z');
    
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
            elsif con(Iaddr) = '1' then
                ADDR_reg <= ADDR_reg + 1;
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
    
    TMP_register:
    process (clk, reset)
    begin
        if reset = '1' then
            TMP_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Lt) = '1' then
                TMP_reg <= addr_bus;
            elsif con(LtL) = '1' then
                TMP_reg(7 downto 0) <= data_bus;
            elsif con(LtH) = '1' then
                TMP_reg(15 downto 8) <= data_bus;
            end if;
        end if;
    end process TMP_register;
    addr_bus <= TMP_reg when con(Et) = '1' else (others => 'Z');

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
    
--    FLAG_register:
--    process (clk, reset)
--    begin
--        if reset = '1' then
--            FLAG_reg <= (others => '0');
--        elsif clk'event and clk = '1' then
--            if con(Lflg) = '1' then
--                FLAG_reg <= data_bus;
--            end if;
--        end if;
--    end process FLAG_register;
--    data_bus <= FLAG_reg when con(Eflg) = '1' else (others => 'Z');

    BC_register:
    process (clk, reset)
    begin
        if reset = '1' then
            BC_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Lb) = '1' then
                B_reg <= data_bus;
            elsif con(Lc) = '1' then
                C_reg <= data_bus;
            elsif con(Lbc) = '1' then
                BC_reg <= addr_bus;
            elsif con(Ibc) = '1' then
                BC_reg <= BC_reg + 1;
            elsif con(Dbc) = '1' then
                BC_reg <= BC_reg - 1;
            end if;
        end if;
    end process BC_register;
    data_bus <= B_reg when con(Eb) = '1' else (others => 'Z');
    data_bus <= C_reg when con(Ec) = '1' else (others => 'Z');
    addr_bus <= BC_reg when con(Ebc) = '1' else (others => 'Z');
    
    DE_register:
    process (clk, reset)
    begin
        if reset = '1' then
            DE_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Ld) = '1' then
                D_reg <= data_bus;
            elsif con(Le) = '1' then
                E_reg <= data_bus;
            elsif con(Lde) = '1' then
                DE_reg <= addr_bus;
            elsif con(Ide) = '1' then
                DE_reg <= DE_reg + 1;
            elsif con(Dde) = '1' then
                DE_reg <= DE_reg - 1;
            end if;
        end if;
    end process DE_register;
    data_bus <= D_reg when con(Ed) = '1' else (others => 'Z');
    data_bus <= E_reg when con(Ee) = '1' else (others => 'Z');
    addr_bus <= DE_reg when con(Ede) = '1' else (others => 'Z');
    
    HL_register:
    process (clk, reset)
    begin
        if reset = '1' then
            HL_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Lh) = '1' then
                H_reg <= data_bus;
            elsif con(Ll) = '1' then
                L_reg <= data_bus;
            elsif con(Lhl) = '1' then
                HL_reg <= addr_bus;
            elsif con(Ihl) = '1' then
                HL_reg <= DE_reg + 1;
            elsif con(Dhl) = '1' then
                HL_reg <= DE_reg - 1;
            end if;
        end if;
    end process HL_register;
    data_bus <= H_reg when con(Eh) = '1' else (others => 'Z');
    data_bus <= L_reg when con(El) = '1' else (others => 'Z');
    addr_bus <= HL_reg when con(Ehl) = '1' else (others => 'Z');
    
    SP_register:
    process (clk, reset)
    begin
        if reset = '1' then
            SP_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Lsp) = '1' then
                SP_reg <= addr_bus;
            elsif con(Isp) = '1' then
                SP_reg <= SP_reg + 1;
            elsif con(Dsp) = '1' then
                SP_reg <= SP_reg - 1;
            end if;
        end if;
    end process SP_register;
    addr_bus <= SP_reg when con(Esp) = '1' else (others => 'Z');

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

    alu_a <= ACC_reg when con(LaluA) = '1' else data_bus;
    alu_b <= data_bus when con(LaluB) = '1' else "00000001";
    
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
    
    MCODE : work.JP80_MCODE
    port map (
        clk         => clk,
        reset       => reset,
        opcode      => opcode,
        aluflag     => FLAG_reg,
        alu_to_reg  => alu_to_reg,
        alucode     => alucode,
        con         => con
    );
    
    process (clk)
    begin
        if clk'event and clk = '0' then
            if con(Lu) = '1' then
                alu_to_reg <= "1" & opcode(5 downto 3);
            else
                alu_to_reg <= (others=>'0');
            end if;
        end if;
    end process;

end architecture behv;