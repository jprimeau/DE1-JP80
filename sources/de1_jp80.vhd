-- DESCRIPTION: JP-80 - DE1
-- AUTHOR: Jonathan Primeau

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.all;

entity de1_jp80 is
    port (
        -- ***** Clocks
        CLOCK_50    : in std_logic;
        
        -- ***** SRAM 256K x 16
--        SRAM_ADDR   : out std_logic_vector(17 downto 0);
--        SRAM_DQ     : inout std_logic_vector(15 downto 0);
--        SRAM_OE_N   : out std_logic;
--        SRAM_UB_N   : out std_logic;
--        SRAM_LB_N   : out std_logic;        
--        SRAM_CE_N   : out std_logic;
--        SRAM_WE_N   : out std_logic; 
        
        -- ***** RS-232
--        UART_RXD    : in std_logic;
--        UART_TXD    : out std_logic;
        
        -- ***** Switches and buttons
        SW          : in std_logic_vector(9 downto 0);
        KEY         : in std_logic_vector(3 downto 0);
        
        -- ***** Leds
        LEDR        : out std_logic_vector(9 downto 0);
        LEDG        : out std_logic_vector(7 downto 0);
        
        -- ***** Quad 7-seg displays
        HEX0        : out std_logic_vector(0 to 6);
        HEX1        : out std_logic_vector(0 to 6);
        HEX2        : out std_logic_vector(0 to 6);
        HEX3        : out std_logic_vector(0 to 6)
    );
    
end de1_jp80;

architecture rtl of de1_jp80 is
    
    signal clk_1hz          : std_logic;
    signal counter_1hz      : std_logic_vector(25 downto 0);
    signal clk_10hz         : std_logic;
    signal counter_10hz     : std_logic_vector(25 downto 0);
    signal clk_100hz        : std_logic;
    signal counter_100hz    : std_logic_vector(25 downto 0);
    signal clk_1khz         : std_logic;
    signal counter_1khz     : std_logic_vector(25 downto 0);

    signal reset            : std_logic;
    signal cpu_clk          : std_logic;
    signal halt             : std_logic;
    
    signal addr_out         : std_logic_vector(15 downto 0);
    signal data_in          : std_logic_vector(7 downto 0);
    signal data_out         : std_logic_vector(7 downto 0);
    
    signal in_port_0_en     : std_logic := '1';
    
    signal in_port_0        : std_logic_vector(7 downto 0) := x"00";
    signal in_port_1        : std_logic_vector(7 downto 0) := x"00";
    signal out_port_0       : std_logic_vector(7 downto 0) := x"00";
    signal out_port_1       : std_logic_vector(7 downto 0) := x"00";
    
    signal in_port_store    : std_logic := '0';
    signal out_port_wr      : std_logic := '0';

begin

    reset <= not SW(9);
    
    LEDR(9) <= SW(9);
    LEDR(8) <=  cpu_clk;
    LEDR(7 downto 0) <= SW(7 downto 0);
    
    LEDG(7) <= not in_port_0_en;
    LEDG(6) <= in_port_0_en;
    
    in_port_store <= not KEY(2);
    LEDG(5) <= in_port_store and not in_port_0_en;
    LEDG(4) <= in_port_store and in_port_0_en;
    
    cpu_clk <= clk_10hz when SW(8) = '0' else clk_1khz;
    
    process (KEY(3))
    begin
        if KEY(3)'event and KEY(3) = '0' then
            in_port_0_en <= not in_port_0_en;
        end if;
    end process;
    
    process (in_port_store)
    begin
        if in_port_store'event and in_port_store = '1' then
            if in_port_0_en = '1' then
                in_port_0 <= SW(7 downto 0);
            else
                in_port_1 <= SW(7 downto 0);
            end if;
        end if;
    end process;
    
    data_in <= in_port_0 when in_port_0_en = '1' else in_port_1;

    -- Generate a 1Hz clock.
    process(CLOCK_50)
    begin
        if CLOCK_50'event and CLOCK_50 = '1' then
            if reset = '1' then
                clk_1hz <= '0';
                counter_1hz <= (others => '0');
            else
                if conv_integer(counter_1hz) = 25000000 then
                    counter_1hz <= (others => '0');
                    clk_1hz <= not clk_1hz;
                else
                    counter_1hz <= counter_1hz + 1;
                end if;
            end if;
        end if;
    end process;
    
    -- Generate a 10Hz clock.
    process(CLOCK_50)
    begin
        if CLOCK_50'event and CLOCK_50 = '1' then
            if reset = '1' then
                clk_10hz <= '0';
                counter_10hz <= (others => '0');
            else
                if conv_integer(counter_10hz) = 2500000 then
                    counter_10hz <= (others => '0');
                    clk_10hz <= not clk_10hz;
                else
                    counter_10hz <= counter_10hz + 1;
                end if;
            end if;
        end if;
    end process;
    
    -- Generate a 100Hz clock.
    process(CLOCK_50)
    begin
        if CLOCK_50'event and CLOCK_50 = '1' then
            if reset = '1' then
                clk_100hz <= '0';
                counter_100hz <= (others => '0');
            else
                if conv_integer(counter_100hz) = 250000 then
                    counter_100hz <= (others => '0');
                    clk_100hz <= not clk_100hz;
                else
                    counter_100hz <= counter_100hz + 1;
                end if;
            end if;
        end if;
    end process;
    
    -- Generate a 1KHz clock.
    process(CLOCK_50)
    begin
        if CLOCK_50'event and CLOCK_50 = '1' then
            if reset = '1' then
                clk_1khz <= '0';
                counter_1khz <= (others => '0');
            else
                if conv_integer(counter_1khz) = 25000 then
                    counter_1khz <= (others => '0');
                    clk_1khz <= not clk_1khz;
                else
                    counter_1khz <= counter_1khz + 1;
                end if;
            end if;
        end if;
    end process;
    
    process (out_port_wr, addr_out)
    begin
        if out_port_wr'event and out_port_wr = '1' then
--            if addr_out(0) = '0' and in_port_0_en = '1' then
            if addr_out(0) = '0' then
                out_port_0 <= data_out;
--            elsif addr_out(0) = '1' and in_port_0_en = '0' then
            elsif addr_out(0) = '1' then
                out_port_1 <= data_out;
            end if;
        end if;
    end process;
    
    HEX3_DISPLAY : SSD
    port map
    (
        input   => out_port_1(7 downto 4),
        output  => HEX3
    );
    
    HEX2_DISPLAY : SSD
    port map
    (
        input   => out_port_1(3 downto 0),
        output  => HEX2
    );
    
    HEX1_DISPLAY : SSD
    port map
    (
        input   => out_port_0(7 downto 4),
        output  => HEX1
    );
    
    HEX0_DISPLAY : SSD
    port map
    (
        input   => out_port_0(3 downto 0),
        output  => HEX0
    );

    top : entity work.jp80_top
    port map (
        clock       => cpu_clk,
        reset       => reset,
        addr_out    => addr_out,
        data_in     => data_in,
        data_out    => data_out,
        read_out    => open,
        write_out   => out_port_wr,
        reqmem_out  => open,
        reqio_out   => open
    );

end architecture rtl;