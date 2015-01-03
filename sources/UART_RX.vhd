library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity UART_RX is
    port
    (
        clk     : in std_logic;
        rx_line : in std_logic;
        data    : out std_logic_vector(7 downto 0);
        ready   : out std_logic;
        done    : in std_logic
    );
end UART_RX;

architecture rtl of UART_RX is
    signal full_data    : std_logic_vector(9 downto 0);
    signal rx_flg       : std_logic := '0';
    signal prscl        : integer range 0 to 104 := 0;
    signal index        : integer range 0 to 9 := 0;
    signal ready_tmp    : std_logic := '0';
begin
    process(clk)
    begin
        if clk'event and clk = '1' then
            if done = '1' then
                ready_tmp <= '0';
            end if;
            
            if rx_flg = '0' and rx_line = '0' then
                index <= 0;
                prscl <= 0;
                ready_tmp <= '0';
                rx_flg <= '1';
            end if;
         
            if rx_flg = '1' then
                full_data(index) <= rx_line;
                if prscl < 103 then
                    prscl <= prscl + 1;
                else
                    prscl <= 0;
                end if;
                if prscl = 50 then
                    if index < 9 then
                        index<=index+1;
                    else
                        if full_data(0) = '0' and full_data(9) = '1' then
                            data <= full_data(8 downto 1);
                        else
                            data <= (others=>'0');
                        end if;
                        rx_flg <= '0';
                        ready_tmp <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;
    ready <= ready_tmp;
end architecture rtl;

