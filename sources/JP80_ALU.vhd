library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;
    
use work.jp80_pkg.all;
    
entity JP80_ALU is
    port (
        alu_op      : in t_aluop;
        bus_a       : in t_data;
        bus_b       : in t_data;
        flags_in    : in t_data;
        q           : out t_data;
        flags_out   : out t_data
    );
end JP80_ALU;

architecture rtl of JP80_ALU is
	procedure AddSub(
            a               : std_logic_vector;
            b               : std_logic_vector;
            c_in            : std_logic;
            sub             : std_logic;
            signal as_q     : out std_logic_vector;
            signal c_out    : out std_logic
        ) is
		variable b_i	: conv_integer(a'length - 1 downto 0);
		variable q_i	: conv_integer(a'length + 1 downto 0);
	begin
		if sub = '1' then
			b_i := not conv_integer(b);
		else
			b_i := conv_integer(b);
		end if;
		q_i := conv_integer("0" & a & c_in) + conv_integer("0" & b_i & "1");
		c_out <= q_i(a'length + 1);
		as_q <= std_logic_vector(q_i(a'length downto 1));
	end;
begin
    process (alu_op, bus_a, bus_b)
    begin
        case alu_op is
        when "000" => -- ADD
        end case;
    end process;
end architecture;