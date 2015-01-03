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
        
        -- ***** UART / RS-232
        UART_RXD    : in std_logic;
        UART_TXD    : out std_logic;
        
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
    
--    signal clk_1hz          : std_logic;
--    signal counter_1hz      : std_logic_vector(25 downto 0);
    signal clk_10hz         : std_logic;
    signal counter_10hz     : std_logic_vector(25 downto 0);
--    signal clk_100hz        : std_logic;
--    signal counter_100hz    : std_logic_vector(25 downto 0);
--    signal clk_1khz         : std_logic;
--    signal counter_1khz     : std_logic_vector(25 downto 0);
    signal clk_1MHz         : std_logic;
    signal counter_1MHz     : std_logic_vector(25 downto 0);

    signal reset            : std_logic;
    signal cpu_clk          : std_logic;
    signal halt             : std_logic;
    
    signal addr_out         : std_logic_vector(15 downto 0);
    signal data_in          : std_logic_vector(7 downto 0);
    signal data_out         : std_logic_vector(7 downto 0);
    
    signal sw_port          : std_logic := '1';
    signal port_store       : std_logic := '0';
    
    signal in_port_0_en     : std_logic := '1';
    signal in_port_1_en     : std_logic := '0';
    signal in_port_2_en     : std_logic := '0';
    signal in_port_3_en     : std_logic := '0';
    
    signal in_port_0        : std_logic_vector(7 downto 0) := x"00";
    signal in_port_1        : std_logic_vector(7 downto 0) := x"00";
    signal in_port_2        : std_logic_vector(7 downto 0) := x"00";
    signal in_port_3        : std_logic_vector(7 downto 0) := x"00";
    
    signal out_port_2_en    : std_logic := '0';
    signal out_port_3_en    : std_logic := '0';
    
    signal out_port_0       : std_logic_vector(7 downto 0) := x"00";
    signal out_port_1       : std_logic_vector(7 downto 0) := x"00";
    signal out_port_2       : std_logic_vector(7 downto 0) := x"00";
    signal out_port_3       : std_logic_vector(7 downto 0) := x"00";

    signal rd_request       : std_logic := '0';
    signal wr_request       : std_logic := '0';
    signal mem_request      : std_logic := '0';
    signal io_request       : std_logic := '0';
    
    signal tx_start         : std_logic := '0';
    signal tx_busy          : std_logic;
    --signal rx_data          : std_logic_vector(7 downto 0);
    --signal rx_busy          : std_logic;

begin

    reset <= not SW(9);
    
    LEDR(9) <= SW(9);
    LEDR(8) <=  cpu_clk;
    --LEDR(7 downto 0) <= SW(7 downto 0);
    
    LEDG(7) <= not sw_port;
    LEDG(6) <= sw_port;
    
    port_store <= not KEY(2);
    LEDG(5) <= port_store and not sw_port;
    LEDG(4) <= port_store and sw_port;
    
    cpu_clk <= clk_10hz when SW(8) = '0' else clk_1MHz;
    
    process (KEY(3))
    begin
        if KEY(3)'event and KEY(3) = '0' then
            sw_port <= not sw_port;
        end if;
    end process;
    
    process (port_store)
    begin
        if port_store'event and port_store = '1' then
            if sw_port = '1' then
                in_port_0 <= SW(7 downto 0);
            else
                in_port_1 <= SW(7 downto 0);
            end if;
        end if;
    end process;
    
    data_in <=  in_port_0 when in_port_0_en = '1' else 
                in_port_1 when in_port_1_en = '1' else
                in_port_2 when in_port_2_en = '1' else
                in_port_3 when in_port_3_en = '1';
                
--    UARTO: entity work.UART
--    generic map
--    (
--        CLK_FREQ    => 1,
--        BAUD_RATE   => 9600
--    )
--    port map
--    (
--        clk         => cpu_clk,
--        rst         => reset,
--        rx          => UART_RXD,
--        tx          => UART_TXD,
--        tx_req      => out_port_2_en,
--        tx_ready    => in_port_3(0),
--        tx_data     => out_port_2,
--        rx_ready    => in_port_3(1),
--        rx_data     => in_port_2
--    );
    
    TX: entity work.UART_TX
    port map
    (
        clk => cpu_clk,
        start => out_port_2_en,
        data => out_port_2,
        ready => in_port_3(0),
        tx_line => UART_TXD
    );
    RX: entity work.UART_RX
    port map
    (
        clk => cpu_clk,
        rx_line => UART_RXD,
        data => in_port_2,
        ready => in_port_3(1),
        done => out_port_3(1) and out_port_3_en
    );

    -- Generate a 1Hz clock.
--    process(CLOCK_50)
--    begin
--        if CLOCK_50'event and CLOCK_50 = '1' then
--            if reset = '1' then
--                clk_1hz <= '0';
--                counter_1hz <= (others => '0');
--            else
--                if conv_integer(counter_1hz) = 25000000 then
--                    counter_1hz <= (others => '0');
--                    clk_1hz <= not clk_1hz;
--                else
--                    counter_1hz <= counter_1hz + 1;
--                end if;
--            end if;
--        end if;
--    end process;
    
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
--    process(CLOCK_50)
--    begin
--        if CLOCK_50'event and CLOCK_50 = '1' then
--            if reset = '1' then
--                clk_100hz <= '0';
--                counter_100hz <= (others => '0');
--            else
--                if conv_integer(counter_100hz) = 250000 then
--                    counter_100hz <= (others => '0');
--                    clk_100hz <= not clk_100hz;
--                else
--                    counter_100hz <= counter_100hz + 1;
--                end if;
--            end if;
--        end if;
--    end process;
    
    -- Generate a 1KHz clock.
--    process(CLOCK_50)
--    begin
--        if CLOCK_50'event and CLOCK_50 = '1' then
--            if reset = '1' then
--                clk_1khz <= '0';
--                counter_1khz <= (others => '0');
--            else
--                if conv_integer(counter_1khz) = 25000 then
--                    counter_1khz <= (others => '0');
--                    clk_1khz <= not clk_1khz;
--                else
--                    counter_1khz <= counter_1khz + 1;
--                end if;
--            end if;
--        end if;
--    end process;
    
    -- Generate a 1MHz clock.
    process(CLOCK_50)
    begin
        if CLOCK_50'event and CLOCK_50 = '1' then
            if reset = '1' then
                clk_1MHz <= '0';
                counter_1MHz <= (others => '0');
            else
                if conv_integer(counter_1MHz) = 25 then
                    counter_1MHz <= (others => '0');
                    clk_1MHz <= not clk_1MHz;
                else
                    counter_1MHz <= counter_1MHz + 1;
                end if;
            end if;
        end if;
    end process;
    
    process (cpu_clk)
    begin
        if cpu_clk'event and cpu_clk = '1' then
            if io_request = '1' and wr_request = '1' then
                if addr_out(7 downto 0) = x"00" then
                    out_port_0 <= data_out;
                elsif addr_out(7 downto 0) = x"01" then
                    out_port_1 <= data_out;
                elsif addr_out(7 downto 0) = x"02" then
                    out_port_2 <= data_out;
                    out_port_2_en <= '1';
                elsif addr_out(7 downto 0) = x"03" then
                    out_port_3 <= data_out;
                    out_port_3_en <= '1';
                end if;
            elsif io_request = '1' and rd_request = '1' then
                if addr_out(7 downto 0) = x"00" then
                    in_port_0_en <= '1';
                elsif addr_out(7 downto 0) = x"01" then
                    in_port_1_en <= '1';
                elsif addr_out(7 downto 0) = x"02" then
                    in_port_2_en <= '1';
                elsif addr_out(7 downto 0) = x"03" then
                    in_port_3_en <= '1';
                end if;
            else
                out_port_2_en <= '0';
                out_port_3_en <= '0';
                in_port_0_en <= '0';
                in_port_1_en <= '0';
                in_port_2_en <= '0';
                in_port_3_en <= '0';
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
        read_out    => rd_request,
        write_out   => wr_request,
        reqmem_out  => mem_request,
        reqio_out   => io_request
    );

end architecture rtl;