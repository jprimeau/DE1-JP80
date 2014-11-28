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
        reqio_out   : out t_wire;
        
        -- BEGIN: SIMULATION ONLY
        Lpc_out     : out t_wire;
        Ipc_out     : out t_wire;
        Epc_out     : out t_wire;
        Lmar_out    : out t_wire;
        Lmdr_out    : out t_wire;
        Emdr_out    : out t_wire;
        Lir_out     : out t_wire;
--        Esrc_out    : out t_wire;
--        Ldst_out    : out t_wire;
        LaluA_out   : out t_wire;
        LaluB_out   : out t_wire;
        
--        src_out     : out t_regaddr;
--        dst_out     : out t_regaddr;
--        srcACC_out  : out t_wire;
--        srcB_out    : out t_wire;
--        srcPC_out   : out t_wire;
--        dstACC_out  : out t_wire;
--        dstB_out    : out t_wire;

--        EregA_out   : out t_wire;
--        EregB_out   : out t_wire;
--        LregI_out   : out t_wire;
--        RegA_out    : out t_regaddr;
--        RegB_out    : out t_regaddr;
--        RegI_out    : out t_regaddr;
        
--        Lt_out      : out t_wire;
--        Et_out      : out t_wire;
--        Lu_out      : out t_wire;
--        Eu_out      : out t_wire;
--        Lsz_out     : out t_wire;
--        Wr_out      : out t_wire;
--        IO_out      : out t_wire;
        halt_out    : out t_wire;
        
        addr_bus_out    : out t_address;
        data_bus_out    : out t_data;
        pc_out          : out t_address;
        acc_out         : out t_8bit;
        alu_a_out       : out t_data;
        alu_b_out       : out t_data;
        alu_out         : out t_data;
        bc_out          : out t_16bit
        -- END: SIMULATION ONLY
    );
end entity jp80_top;

architecture behv of jp80_top is

    signal clk      : t_wire;

    type t_ram is array (0 to 255) of t_data;
    signal ram : t_ram := (
        x"3E",x"10",x"D6",x"02",x"76",x"FF",x"FF",x"FF", -- 00H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 08H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 10H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 18H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 20H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 28H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 30H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 38H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 40H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 48H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 50H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 58H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 60H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 68H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 70H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 78H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 80H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 88H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 90H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 98H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- A0H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- A8H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- B0H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- B8H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- C0H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- C8H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- D0H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- D8H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- E0H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- E8H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- F0H
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF"  -- F8H
        
--        x"C3",x"18",x"00",x"FF",x"FF",x"FF",x"FF",x"FF", -- 00H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 08H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00", -- 10H
--        x"DB",x"00",x"6F",x"DB",x"01",x"67",x"E9",x"DB", -- 18H
--        x"00",x"D3",x"00",x"DB",x"01",x"D3",x"01",x"C3", -- 20H
--        x"1F",x"00",x"3E",x"00",x"D3",x"00",x"3C",x"C3", -- 28H
--        x"2C",x"00",x"2E",x"00",x"26",x"00",x"3E",x"10", -- 30H
--        x"3D",x"C2",x"38",x"00",x"23",x"7D",x"D3",x"00", -- 38H
--        x"7C",x"D3",x"01",x"C3",x"36",x"00",x"FF",x"FF", -- 40H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 48H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 50H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 58H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 60H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 68H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 70H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 78H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 80H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 88H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 90H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 98H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- A0H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- A8H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- B0H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- B8H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- C0H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- C8H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- D0H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- D8H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- E0H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- E8H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- F0H
--        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF"  -- F8H
    );
    
    signal cpu_data_inout   : t_data;
    signal cpu_addr         : t_address;
    signal cpu_read         : t_wire;
    signal cpu_write        : t_wire;
    signal cpu_reqmem       : t_wire;
    signal cpu_reqio        : t_wire;
    
    signal cpu_con          : t_control := (others => '0');
    signal cpu_addr_bus     : t_address;
    signal cpu_data_bus     : t_data;
    signal cpu_pc           : t_address;
    signal cpu_acc          : t_data;
    signal cpu_bc           : t_16bit;
    signal cpu_alu_a        : t_data;
    signal cpu_alu_b        : t_data;
    signal cpu_alu          : t_data;
    
begin
    addr_out        <= cpu_addr;
    data_out        <= cpu_data_inout when cpu_write = '1' else (others=>'Z');
    read_out        <= cpu_read;
    write_out       <= cpu_write;
    reqmem_out      <= cpu_reqmem;
    reqio_out       <= cpu_reqio;
    
    -- BEGIN: SIMULATION ONLY
    Lpc_out     <= cpu_con(Lpc);
    Ipc_out     <= cpu_con(Ipc);
    Epc_out     <= cpu_con(Epc);
    Lmar_out    <= cpu_con(Lmar);
    Lmdr_out    <= cpu_con(Lmdr);
    Emdr_out    <= cpu_con(Emdr);
    Lir_out     <= cpu_con(Lir);
--    Esrc_out    <= cpu_con(Esrc);
--    Ldst_out    <= cpu_con(Ldst);
    LaluA_out   <= cpu_con(LaluA);
    LaluB_out   <= cpu_con(LaluB);
    
--    src_out     <= cpu_src;
--    dst_out     <= cpu_dst;
--    srcACC_out  <= cpu_src(sdACC);
--    srcB_out    <= cpu_src(sdB);
--    srcPC_out   <= cpu_src(sdPC);
--    dstACC_out  <= cpu_dst(sdACC);
--    dstB_out    <= cpu_dst(sdB);
    
    halt_out    <= cpu_con(HALT);

--    EregA_out   <= cpu_con(EregA);
--    EregB_out   <= cpu_con(EregB);
--    LregI_out   <= cpu_con(LregI);
--    RegA_out    <= cpu_con(RegA2 downto RegA0);
--    RegB_out    <= cpu_con(RegB2 downto RegB0);
--    RegI_out    <= cpu_con(RegI2 downto RegI0);
    
--    Lt_out      <= cpu_con(Lt);
--    Et_out      <= cpu_con(Et);
--    Lu_out      <= cpu_con(Lu);
--    Eu_out      <= cpu_con(Eu);
--    Lsz_out     <= cpu_con(Lsz);
--    Wr_out      <= cpu_con(Wr);
--    IO_out      <= cpu_con(IO);
    
    
    addr_bus_out    <= cpu_addr_bus;
    data_bus_out    <= cpu_data_bus;
    pc_out          <= cpu_pc;
    acc_out         <= cpu_acc;
    bc_out          <= cpu_bc;
    alu_a_out       <= cpu_alu_a;
    alu_b_out       <= cpu_alu_b;
    alu_out         <= cpu_alu;
    -- END: SIMULATION ONLY

    memory:
    process (cpu_reqmem, cpu_write)
    begin
        if cpu_reqmem = '1' then
            if cpu_write'event and cpu_write = '1' then
                ram(conv_integer(cpu_addr)) <= cpu_data_inout;
            end if;
        end if;
    end process memory;
    cpu_data_inout <= ram(conv_integer(cpu_addr)) when cpu_read = '1' and cpu_reqmem = '1' else (others=>'Z');
    
    input_output:
    process (cpu_reqio, cpu_write)
    begin
        if cpu_reqio = '1' then
            if cpu_write'event and cpu_write = '1' then
--                ram(conv_integer(cpu_addr)) <= cpu_data_inout;
            end if;
        end if;
    end process input_output;
    cpu_data_inout <= data_in when cpu_reqio = '1' and cpu_read = '1' else (others=>'Z');

    cpu : entity work.jp80_cpu
    port map (
        clock       => clock,
        reset       => reset,
        data_inout  => cpu_data_inout,
        addr_out    => cpu_addr,
        read_out    => cpu_read,
        write_out   => cpu_write,
        reqmem_out  => cpu_reqmem,
        reqio_out   => cpu_reqio,
        
        -- BEGIN: SIMULATION ONLY
        con_out     => cpu_con,
        addr_bus_out    => cpu_addr_bus,
        data_bus_out    => cpu_data_bus,
        pc_out          => cpu_pc,
        acc_out         => cpu_acc,
        bc_out          => cpu_bc,
        alu_a_out       => cpu_alu_a,
        alu_b_out       => cpu_alu_b,
        alu_out     => cpu_alu
        -- END: SIMULATION ONLY
    );

end architecture behv;