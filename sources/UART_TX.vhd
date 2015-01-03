library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity UART_TX is
    port
    (
        clk     : in std_logic;
        start   : in std_logic;
        data    : in std_logic_vector(7 downto 0);
        ready   : out std_logic;
        tx_line : out std_logic
    );
end UART_TX;

architecture rtl of UART_TX is
    signal prscl        : integer range 0 to 104 := 0;
    signal index        : integer range 0 to 9 := 0;
    signal full_data    : std_logic_vector(9 downto 0);
    signal tx_flg       : std_logic := '0';
    signal ready_tmp    : std_logic := '1';
begin
    process(clk)
    begin
        if clk'event and clk = '1' then
            if tx_flg = '0' and start = '1' then
                tx_flg <= '1';
                ready_tmp <= '0';
                full_data(0) <= '0';
                full_data(9) <= '1';
                full_data(8 downto 1) <= data;
            end if;
         
            if tx_flg = '1' then
                if prscl < 103 then
                    prscl <= prscl + 1;
                else
                    prscl <= 0;
                end if;

                if prscl = 52 then
                    tx_line <= full_data(index);
                    if index < 9 then
                        index <= index + 1;
                    else
                        tx_flg <= '0';
                        ready_tmp <= '1';
                        index <= 0;
                    end if;
                end if;
            end if;
        end if;
    end process;
    ready <= ready_tmp;
end architecture rtl;

