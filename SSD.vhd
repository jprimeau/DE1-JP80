-- DESCRIPTION: Seven Segment Display Decoder
-- AUTHOR: Jonathan Primeau

library ieee;
    use ieee.std_logic_1164.all;
    
entity SSD is
    port
    (
        input   : in std_logic_vector(3 downto 0);
        output  : out std_logic_vector(6 downto 0)
    );
end SSD;
 
architecture behv of SSD is
begin
    process(input)
    begin
        case input is
        when X"0" => output <= "0000001";
        when X"1" => output <= "1001111";
        when X"2" => output <= "0010010";
        when X"3" => output <= "0000110";
        when X"4" => output <= "1001100";
        when X"5" => output <= "0100100";
        when X"6" => output <= "0100000";
        when X"7" => output <= "0001111";
        when X"8" => output <= "0000000";
        when X"9" => output <= "0000100";
        when X"A" => output <= "0001000";
        when X"B" => output <= "1100000";
        when X"C" => output <= "0110001";
        when X"D" => output <= "1000010";
        when X"E" => output <= "0110000";
        when X"F" => output <= "0111000";
        when others => output <= "0111111"; -- can't happen
        end case;
    end process;
end behv;