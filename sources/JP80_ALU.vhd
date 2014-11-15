library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    
use work.jp80_pkg.all;
    
entity JP80_ALU is
    port (
        alucode     : in t_aluop;
        bus_a       : in t_data;
        bus_b       : in t_data;
        flag_in     : in t_data;
        q           : out t_data;
        flag_out    : out t_data
    );
end JP80_ALU;

architecture rtl of JP80_ALU is
    signal c_i      : t_wire;
    signal c7_i     : t_wire;
    signal h_i      : t_wire;
    signal p_i      : t_wire;
    signal sub_i    : t_wire;
    signal q_i      : t_data;
    signal carry_i  : t_wire;

	procedure AddSub(
            a               : std_logic_vector;
            b               : std_logic_vector;
            sub             : std_logic;
            c_in            : std_logic;
            signal result   : out std_logic_vector;
            signal c_out    : out std_logic
        ) is
		variable b_i	: unsigned(a'length - 1 downto 0);
		variable q_i	: unsigned(a'length + 1 downto 0);
	begin
		if sub = '1' then
			b_i := not unsigned(b);
		else
			b_i := unsigned(b);
		end if;
		q_i := unsigned("0" & a & c_in) + unsigned("0" & b_i & "1");
		c_out <= q_i(a'length + 1);
		result <= std_logic_vector(q_i(a'length downto 1));
	end;
begin
    sub_i <= alucode(1);
    -- Use carry in for ADC and SBB
    carry_i <= sub_i xor (not alucode(2) and alucode(0) and flag_in(FlagC));
    AddSub(bus_a(3 downto 0), bus_b(3 downto 0), sub_i, carry_i, q_i(3 downto 0), h_i);
	AddSub(bus_a(6 downto 4), bus_b(6 downto 4), sub_i, h_i, q_i(6 downto 4), c7_i);
	AddSub(bus_a(7 downto 7), bus_b(7 downto 7), sub_i, c7_i, q_i(7 downto 7), c_i);
	p_i <= c_i xor c7_i;
    
    process (alucode, bus_a, bus_b)
    begin
        case alucode is
        when "000" | "001" => -- ADD or ADC
            q <= q_i;
            flag_out(FlagC) <= c_i;
            flag_out(FlagH) <= h_i;
            flag_out(FlagP) <= p_i;
        when "010" | "011" | "111" => -- SUB or SBB or CMP
            q <= q_i;
            flag_out(FlagC) <= not c_i;
            flag_out(FlagH) <= not h_i;
            flag_out(FlagP) <= p_i;
        when "100" => -- ANA
            q <= bus_a and bus_b;
            flag_out(FlagH) <= '1';
        when "101" => -- XRA
            q <= bus_a xor bus_b;
            flag_out(FlagH) <= '0';
        when "110" => -- ORA
            q <= bus_a or bus_b;
            flag_out(FlagH) <= '0';
        when others =>
            null;
        end case;
    end process;
end architecture;