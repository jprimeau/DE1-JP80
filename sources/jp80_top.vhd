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
        Lp_out      : out t_wire;
        Cp_out      : out t_wire;
        Ep_out      : out t_wire;
        Laddr_out   : out t_wire;
        Ldata_out   : out t_wire;
        EdataL_out  : out t_wire;
        EdataH_out  : out t_wire;
        Li_out      : out t_wire;
        La_out      : out t_wire;
        Ea_out      : out t_wire;
        Lb_out      : out t_wire;
        Eb_out      : out t_wire;
        Lc_out      : out t_wire;
        Ec_out      : out t_wire;
        Ld_out      : out t_wire;
        Ed_out      : out t_wire;
        Le_out      : out t_wire;
        Ee_out      : out t_wire;
        Lh_out      : out t_wire;
        Eh_out      : out t_wire;
        Ll_out      : out t_wire;
        El_out      : out t_wire;
        Lt_out      : out t_wire;
        Et_out      : out t_wire;
        Lu_out      : out t_wire;
        Eu_out      : out t_wire;
        Lsz_out     : out t_wire;
        Wr_out      : out t_wire;
        IO_out      : out t_wire;
        halt_out    : out t_wire;
        
        bus_out     : out t_bus;
        pc_out      : out t_address;
        a_out       : out t_data;
        tmp_out     : out t_data;
        alu_out     : out t_data;
        b_out       : out t_data;
        c_out       : out t_data
        -- END: SIMULATION ONLY
    );
end entity jp80_top;

architecture behv of jp80_top is

    signal clk      : t_wire;

    type t_ram is array (0 to 255) of t_data;
    signal ram : t_ram := (
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 00H
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
    signal cpu_bus          : t_address;
    signal cpu_pc           : t_address;
    signal cpu_a            : t_data;
    signal cpu_b            : t_data;
    signal cpu_c            : t_data;
    signal cpu_tmp          : t_data;
    signal cpu_alu          : t_data;
    
begin
    addr_out        <= cpu_addr;
    data_out        <= cpu_data_inout when cpu_write = '1' else (others=>'Z');
    read_out        <= cpu_read;
    write_out       <= cpu_write;
    reqmem_out      <= cpu_reqmem;
    reqio_out       <= cpu_reqio;
    
    -- BEGIN: SIMULATION ONLY
--    Lp_out      <= cpu_con(Lp);
--    Cp_out      <= cpu_con(Cp);
--    Ep_out      <= cpu_con(Ep);
--    Laddr_out   <= cpu_con(Laddr);
--    Ldata_out   <= cpu_con(Ldata);
--    EdataL_out  <= cpu_con(EdataL);
--    EdataH_out  <= cpu_con(EdataH);
--    Li_out      <= cpu_con(Li);
--    La_out      <= cpu_con(La);
--    Ea_out      <= cpu_con(Ea);
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
--    Lt_out      <= cpu_con(Lt);
--    Et_out      <= cpu_con(Et);
--    Lu_out      <= cpu_con(Lu);
--    Eu_out      <= cpu_con(Eu);
--    Lsz_out     <= cpu_con(Lsz);
--    Wr_out      <= cpu_con(Wr);
--    IO_out      <= cpu_con(IO);
--    halt_out    <= cpu_con(HALT);
--    
--    bus_out     <= cpu_bus;
--    pc_out      <= cpu_pc;
--    a_out       <= cpu_a;
--    b_out       <= cpu_b;
--    c_out       <= cpu_c;
--    tmp_out     <= cpu_tmp;
--    alu_out     <= cpu_alu;
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
        reqio_out   => cpu_reqio
        
        -- BEGIN: SIMULATION ONLY
--        con_out     => cpu_con,
--        bus_out     => cpu_bus,
--        pc_out      => cpu_pc,
--        a_out       => cpu_a,
--        b_out       => cpu_b,
--        c_out       => cpu_c,
--        tmp_out     => cpu_tmp,
--        alu_out     => cpu_alu
        -- END: SIMULATION ONLY
    );

end architecture behv;