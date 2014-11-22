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
        con_out     : out t_control;
        addr_bus_out    : out t_address;
        data_bus_out    : out t_data;
        pc_out      : out t_address;
        acc_out     : out t_8bit;
        bc_out      : out t_16bit;
--        c_out       : out t_data;
--        tmp_out     : out t_data;
        alu_out     : out t_data;
        src_out     : out t_regaddr;
        dst_out     : out t_regaddr;
        tstate_out  : out t_tstate
        -- END: SIMULATION ONLY
    );
end entity jp80_cpu;

architecture behv of jp80_cpu is

    signal clk      : t_wire;

--    signal ns, ps   : t_cpu_state;

--    signal AF_reg   : t_address;
--    alias  A_reg    is AF_reg(15 downto 8);
--    alias  F_reg    is AF_reg(7 downto 0);
    signal BC_reg   : t_16bit;
    alias  B_reg    is BC_reg(15 downto 8);
    alias  C_reg    is BC_reg(7 downto 0);
    signal DE_reg   : t_16bit;
    alias  D_reg    is DE_reg(15 downto 8);
    alias  E_reg    is DE_reg(7 downto 0);
    signal HL_reg   : t_16bit;
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

    signal ACC_reg  : t_8bit;
    signal FLAG_Reg : t_data;
--    signal TMP_reg  : t_data;
    signal ALU_reg  : t_data;
    signal ALU_q    : t_data;
    signal PC_reg   : t_address;
    signal SP_reg   : t_address;
    signal MAR_reg  : t_address;
    signal MDR_reg  : t_data;
    signal IR_reg   : t_data;
    
    -- Buses
    signal addr_bus     : t_address;
    alias  addr_bus_h   is addr_bus(15 downto 8);
    alias  addr_bus_l   is addr_bus(7 downto 0);
    signal data_bus     : t_data;

--    signal w_bus    : t_bus;
--    alias  w_bus_h  is w_bus(15 downto 8);
--    alias  w_bus_l  is w_bus(7 downto 0);
    
    signal opcode   : t_opcode;
    
    signal aluop        : t_aluop;
    signal alu_a        : t_data;
    signal alu_b        : t_data;
    signal alu_to_acc   : t_flag;
    
    signal bus_a    : t_data;
    signal bus_b    : t_data;
    signal reg_a    : t_data;
    signal reg_b    : t_data;
    
    -- Microcode signals
    signal use_alu_q    : t_flag;

    signal con      : t_control := (others => '0');
    signal src      : t_regaddr := (others => '0');
    signal dst      : t_regaddr := (others => '0');
    signal tstate   : integer := 0;
--    alias reg_a_addr is con(RegA2 downto RegA0);
--    alias reg_b_addr is con(RegB2 downto RegB0);
--    alias reg_i_addr is con(RegI2 downto RegI0);
--    alias alu_op     is con(ALU2 downto ALU0);
    
begin
    addr_out    <= MAR_reg;
    data_inout  <= MDR_reg when con(Wr) = '1' else (others=>'Z');
    read_out    <= not con(Wr);
    write_out   <= con(Wr);
    reqmem_out  <= not con(IO);
    reqio_out   <= con(IO);
    
    -- BEGIN: SIMULATION ONLY
    con_out     <= con;
    addr_bus_out    <= addr_bus;
    data_bus_out    <= data_bus;
    pc_out      <= PC_reg;
    acc_out     <= ACC_reg;
    bc_out       <= BC_reg;
--    c_out       <= C_reg;
--    tmp_out     <= TMP_reg;
    alu_out     <= ALU_reg;
    src_out     <= src;
    dst_out     <= dst;
    tstate_out  <= tstate;
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
    addr_bus <= PC_reg when con(Epc) = '1' or (src(sdPC) = '1' and con(Esrc) = '1') else (others => 'Z');

    MAR_register:
    process (clk, reset)
    begin
        if reset = '1' then
            MAR_reg <= (others => '0');
        elsif clk'event and clk = '0' then
            if con(Lmar) = '1' then
                MAR_reg <= addr_bus;
            end if;
        end if;
    end process MAR_register;
    
    MDR_register:
    process (clk, reset)
    begin
        if reset = '1' then
            MDR_reg <= (others => '0');
        elsif clk'event and clk = '0' then
            if con(Lmdr) = '1' then
                MDR_reg <= data_bus;
            else
                MDR_reg <= data_inout;
            end if;
        end if;
    end process MDR_register;
    data_bus <= MDR_reg when con(Emdr) = '1' else (others => 'Z');

    ACC_register:
    process (clk, reset)
    begin
        if reset = '1' then
            ACC_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if dst(sdACC) = '1' and con(Ldst) = '1' then
                ACC_reg <= data_bus;
            elsif alu_to_acc = '1' then
                ACC_reg <= ALU_reg;
            end if;
        end if;
    end process ACC_register;
    data_bus <= ACC_reg when src(sdACC) = '1' and con(Esrc) = '1' else (others => 'Z');

    BC_register:
    process (clk, reset)
    begin
        if reset = '1' then
            BC_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Ldst) = '1' then
                if dst(sdB) = '1' then
                    B_reg <= data_bus;
                end if;
                if dst(sdC) = '1' then
                    C_reg <= data_bus;
                end if;
            end if;
        end if;
    end process BC_register;
    data_bus <= B_reg when src(sdB) = '1' and con(Esrc) = '1' else (others => 'Z');
--    data_bus <= C_reg when src(sdC) = '1' and con(Esrc) = '1' else (others => 'Z');
--    addr_bus <= BC_reg when con(Eb) = '1' and con(Ec) = '1' else (others => 'Z');
    
--    DE_register:
--    process (clk, reset)
--    begin
--        if reset = '1' then
--            DE_reg <= (others => '0');
--        elsif clk'event and clk = '1' then
--            if con(Ld) = '1' then
--                D_reg <= data_bus;
--            end if;
--            if con(Le) = '1' then
--                E_reg <= data_bus;
--            end if;
--        end if;
--    end process DE_register;
--    data_bus <= D_reg when con(Ed) = '1' else (others => 'Z');
--    data_bus <= E_reg when con(Ee) = '1' else (others => 'Z');
--    addr_bus <= DE_reg when con(Ed) = '1' and con(Ee) = '1' else (others => 'Z');
--    
--    HL_register:
--    process (clk, reset)
--    begin
--        if reset = '1' then
--            HL_reg <= (others => '0');
--        elsif clk'event and clk = '1' then
--            if con(Lh) = '1' and con(Ll) = '1'  then
--                HL_reg <= addr_bus;
--            else
--                if con(Lh) = '1' then
--                    H_reg <= data_bus;
--                end if;
--                if con(Ll) = '1' then
--                    L_reg <= data_bus;
--                end if;
--            end if;
--        end if;
--    end process HL_register;
--    data_bus <= H_reg when con(Eh) = '1' else (others => 'Z');
--    data_bus <= L_reg when con(El) = '1' else (others => 'Z');
--    addr_bus <= HL_reg when con(Ehl) = '1' else (others => 'Z');
    

    
--    REGISTERS : work.JP80_FILEREG
--    port map (
--        clk             => clk,
--        data_in_h       => data_bus,
--        data_in_l       => data_bus,
--        we_h            => '0',
--        we_l            => con(LregI),
--        reg_addr_in     => con(RegI2 downto RegI0),
--        reg_addr_out_a  => con(RegA2 downto RegA0),
--        reg_addr_out_b  => con(RegB2 downto RegB0),
--        data_out_a_h    => open,
--        data_out_a_l    => open,
--        en_a_h          => '0',
--        en_a_l          => con(EregA),
--        data_out_b_h    => open,
--        data_out_b_l    => data_bus,
--        en_b_h          => '0',
--        en_b_l          => con(EregB)
--        
--        -- BEGIN: SIMULATION ONLY
--       ,reg_bc          => out_reg_bc,
--        reg_de          => out_reg_de,
--        reg_hl          => out_reg_hl,
--        reg_sp          => out_reg_sp
--        -- END: SIMULATION ONLY
--    );
    
    MICROCODE : work.JP80_MCODE
    port map (
        clk         => clk,
        reset       => reset,
        opcode      => opcode,
        aluop       => aluop,
        alu_to_acc  => alu_to_acc,
        con         => con,
        src         => src,
        dst         => dst,
        tstate      => tstate
    );
    
    ALU_register:
    process (clk, reset)
    begin
        if reset = '1' then
            ALU_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Lu) = '1' then
                ALU_reg <= ALU_q;
            end if;
        end if;
    end process ALU_register;

    alu_a <= ACC_reg when con(LaluA) = '1' else (others=>'Z');
    alu_b <= data_bus when con(LaluB) = '1' else (others=>'Z');
    
    ALU : work.JP80_ALU
    port map (
        alucode     => aluop,
        bus_a       => bus_a,
        bus_b       => bus_b,
        flag_in     => FLAG_Reg,
        q           => ALU_Q,
        flag_out    => FLAG_Reg
    );
    
    IR_register:
    process (clk, reset)
    begin
        if reset = '1' then
            IR_reg <= (others => '0');
        elsif clk'event and clk = '0' then
            if con(Lir) = '1' then
                IR_reg <= data_bus;
            end if;
        end if;
    end process IR_register;
    opcode <= IR_reg;

end architecture behv;