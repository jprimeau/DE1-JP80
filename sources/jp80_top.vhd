-- DESCRIPTION: JP-80 - Top (SoC)
-- AUTHOR: Jonathan Primeau

-- TODO:
--  o Implement PS/2 interface
--  o Use external SRAM
--  o Implement serial interface

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.jp80_pkg.all;
use work.all;

entity jp80_top is
    port (
        clock       : in t_wire;
        reset       : in t_wire;
        addr_out    : out t_address;
        data_in     : in t_data;
        data_out    : out t_data;
        read_out    : out t_wire;
        write_out   : out t_wire;
        reqmem_out  : out t_wire;
        reqio_out   : out t_wire
        
        -- BEGIN: SIMULATION ONLY
--        Lpc_out     : out std_logic;
--        Ipc_out     : out std_logic;
--        Epc_out     : out std_logic;
--        Laddr_out   : out std_logic;
--        LaddrL_out  : out std_logic;
--        LaddrH_out  : out std_logic;
--        Eaddr_out   : out std_logic;
--        Ldata_out   : out std_logic;
--        Edata_out   : out std_logic;
--        Lir_out     : out std_logic;
--        Lacc_out    : out std_logic;
--        Eacc_out    : out std_logic;
--        Lb_out      : out std_logic;
--        Eb_out      : out std_logic;
--        Lc_out      : out std_logic;
--        Ec_out      : out std_logic;
--        Ld_out      : out std_logic;
--        Ed_out      : out std_logic;
--        Le_out      : out std_logic;
--        Ee_out      : out std_logic;
--        Lh_out      : out std_logic;
--        Eh_out      : out std_logic;
--        Ll_out      : out std_logic;
--        El_out      : out std_logic;
--        Ehl_out     : out std_logic;
--        Lt_out      : out std_logic;
--        LtL_out     : out std_logic;
--        LtH_out     : out std_logic;
--        Et_out      : out std_logic;
--        LaluA_out   : out std_logic;
--        LaluB_out   : out std_logic;
--        Eu_out      : out std_logic;
--        Lu_out      : out std_logic;
--        Wr_out      : out std_logic;
--        IO_out      : out std_logic;
--        HALT_out    : out std_logic;
--        
--        addr_bus_out    : out t_address;
--        data_bus_out    : out t_data;
--        pc_out          : out t_address;
--        acc_out         : out t_8bit;
--        de_out          : out t_16bit;
--        hl_out          : out t_16bit;
--        sp_out          : out t_16bit;
--        flag_out        : out t_8bit;
--        ir_out          : out t_8bit;
--        tmp_out         : out t_16bit;
--        alu_a_out       : out t_data;
--        alu_b_out       : out t_data;
--        alu_out         : out t_data;
--        bc_out          : out t_16bit
        -- END: SIMULATION ONLY
    );
end entity jp80_top;

architecture behv of jp80_top is

    signal clk      : t_wire;

    type t_ram is array (0 to 255) of t_data;
    signal ram : t_ram := (
        x"31",x"FF",x"00",x"21",x"34",x"00",x"CD",x"0D", -- 0000
        x"00",x"CD",x"1D",x"00",x"76",x"DB",x"03",x"E6", -- 0008
        x"01",x"C2",x"0D",x"00",x"7E",x"A7",x"C8",x"D3", -- 0010
        x"02",x"23",x"C3",x"0D",x"00",x"3E",x"0D",x"CD", -- 0018
        x"28",x"00",x"3E",x"0A",x"CD",x"28",x"00",x"C9", -- 0020
        x"47",x"DB",x"03",x"E6",x"01",x"C2",x"29",x"00", -- 0028
        x"78",x"D3",x"02",x"C9",x"48",x"65",x"6C",x"6C", -- 0030
        x"6F",x"2C",x"20",x"53",x"74",x"65",x"70",x"68", -- 0038
        x"61",x"6E",x"65",x"20",x"4C",x"61",x"6A",x"6F", -- 0040
        x"69",x"65",x"21",x"00",x"FF",x"FF",x"FF",x"FF", -- 0048
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 0050
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 0058
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 0060
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 0068
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 0070
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 0078
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 0080
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 0088
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 0090
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 0098
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 00A0
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 00A8
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 00B0
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 00B8
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 00C0
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 00C8
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 00D0
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 00D8
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 00E0
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 00E8
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 00F0
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF"  -- 00F8
    );
    
    signal cpu_data_in      : t_data;
    signal cpu_addr         : t_address;
    signal cpu_data_out     : t_data;
    signal cpu_read         : t_wire;
    signal cpu_write        : t_wire;
    signal cpu_reqmem       : t_wire;
    signal cpu_reqio        : t_wire;
    
    -- BEGIN: SIMULATION ONLY
--    signal cpu_con          : t_control := (others => '0');
--    signal cpu_addr_bus     : t_address;
--    signal cpu_data_bus     : t_data;
--    signal cpu_pc           : t_address;
--    signal cpu_acc          : t_data;
--    signal cpu_bc           : t_16bit;
--    signal cpu_de           : t_16bit;
--    signal cpu_hl           : t_16bit;
--    signal cpu_sp           : t_16bit;
--    signal cpu_flag         : t_8bit;
--    signal cpu_ir           : t_8bit;
--    signal cpu_tmp          : t_16bit;
--    signal cpu_alu_a        : t_data;
--    signal cpu_alu_b        : t_data;
--    signal cpu_alu          : t_data;
    -- END: SIMULATION ONLY
    
begin
    addr_out        <= cpu_addr;
    data_out        <= cpu_data_out;
    read_out        <= cpu_read;
    write_out       <= cpu_write;
    reqmem_out      <= cpu_reqmem;
    reqio_out       <= cpu_reqio;
    
    -- BEGIN: SIMULATION ONLY
--    Lpc_out     <= cpu_con(Lpc);
--    Ipc_out     <= cpu_con(Ipc);
--    Epc_out     <= cpu_con(Epc);
--    Laddr_out   <= cpu_con(Laddr);
--    LaddrL_out  <= cpu_con(LaddrL);
--    LaddrH_out  <= cpu_con(LaddrH);
--    Eaddr_out   <= cpu_con(Eaddr);
--    Ldata_out   <= cpu_con(Ldata);
--    Edata_out   <= cpu_con(Edata);
--    Lir_out     <= cpu_con(Lir);
--    Lacc_out    <= cpu_con(Lacc);
--    Eacc_out    <= cpu_con(Eacc);
--    Lb_out      <= cpu_con(Lb);
--    Eb_out      <= cpu_con(Eb);
--    Lc_out      <= cpu_con(Lc);
--    Ec_out      <= cpu_con(Ec);
--    Ld_out      <= cpu_con(Ld);
--    Ed_out      <= cpu_con(Ed);
--    Le_out      <= cpu_con(Le);
--    Ee_out      <= cpu_con(Ee);
--    Lh_out      <= cpu_con(Lh);
--    Eh_out      <= cpu_con(Eh);
--    Ll_out      <= cpu_con(Ll);
--    El_out      <= cpu_con(El);
--    Ehl_out     <= cpu_con(Ehl);
--    Lt_out      <= cpu_con(Lt);
--    LtL_out     <= cpu_con(LtL);
--    LtH_out     <= cpu_con(LtH);
--    Et_out      <= cpu_con(Et);
--    LaluA_out   <= cpu_con(LaluA);
--    LaluB_out   <= cpu_con(LaluB);
--    Eu_out      <= cpu_con(Eu);
--    Lu_out      <= cpu_con(Lu);
--    Wr_out      <= cpu_con(Wr);
--    IO_out      <= cpu_con(IO);
--    HALT_out    <= cpu_con(HALT);
--    
--    addr_bus_out    <= cpu_addr_bus;
--    data_bus_out    <= cpu_data_bus;
--    pc_out          <= cpu_pc;
--    acc_out         <= cpu_acc;
--    bc_out          <= cpu_bc;
--    de_out          <= cpu_de;
--    hl_out          <= cpu_hl;
--    sp_out          <= cpu_sp;
--    flag_out        <= cpu_flag;
--    ir_out          <= cpu_ir;
--    tmp_out         <= cpu_tmp;
--    alu_a_out       <= cpu_alu_a;
--    alu_b_out       <= cpu_alu_b;
--    alu_out         <= cpu_alu;
    -- END: SIMULATION ONLY

    memory:
    process (clock)
    begin
        if clock'event and clock = '0' then
            if cpu_reqmem = '1' and cpu_write = '1' then
                ram(conv_integer(cpu_addr)) <= cpu_data_out;
            end if;
        end if;
    end process memory;
    
    cpu_data_in <= ram(conv_integer(cpu_addr)) when cpu_reqmem = '1' and cpu_read = '1' else (others=>'Z');
    cpu_data_in <= data_in when cpu_reqio = '1' and cpu_read = '1' else (others=>'Z');
    
    cpu : entity work.jp80_cpu
    port map (
        clock       => clock,
        reset       => reset,
        data_in     => cpu_data_in,
        addr_out    => cpu_addr,
        data_out    => cpu_data_out,
        read_out    => cpu_read,
        write_out   => cpu_write,
        reqmem_out  => cpu_reqmem,
        reqio_out   => cpu_reqio
        
        -- BEGIN: SIMULATION ONLY
--        con_out         => cpu_con,
--        addr_bus_out    => cpu_addr_bus,
--        data_bus_out    => cpu_data_bus,
--        pc_out          => cpu_pc,
--        acc_out         => cpu_acc,
--        bc_out          => cpu_bc,
--        de_out          => cpu_de,
--        hl_out          => cpu_hl,
--        sp_out          => cpu_sp,
--        flag_out        => cpu_flag,
--        ir_out          => cpu_ir,
--        tmp_out         => cpu_tmp,
--        alu_a_out       => cpu_alu_a,
--        alu_b_out       => cpu_alu_b,
--        alu_out         => cpu_alu
        -- END: SIMULATION ONLY
    );

end architecture behv;