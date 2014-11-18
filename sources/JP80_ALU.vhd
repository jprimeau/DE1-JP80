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
--        en          : in t_wire;
        q           : out t_data;
        flag_out    : out t_data
    );
end JP80_ALU;

architecture rtl of JP80_ALU is
    signal cout_i   : t_data;
    signal c_i      : t_wire;
    signal c7_i     : t_wire;
    signal h_i      : t_wire;
    signal p_i      : t_wire;
    signal sub_i    : t_wire;
    signal q_i      : t_data;
	signal q_t      : t_data;
    signal cin_i    : t_wire;
    
    procedure AddSub(
        a_i         : in t_data;
        b_i         : in t_data;
        s_i         : in t_wire;
        c_i         : in t_wire;
        signal q_o  : out t_data; 
        signal c_o  : out t_data
    ) is
        variable b_t, c_t : t_data;
    begin
        if s_i = '1' then
            b_t := not b_i;
        else
            b_t := b_i;
        end if;
        c_t(0) := (a_i(0) and b_t(0)) or (a_i(0) and c_i) or (b_t(0) and c_i);
        c_t(1) := (a_i(1) and b_t(1)) or (a_i(1) and c_t(0)) or (b_t(1) and c_t(0));
        c_t(2) := (a_i(2) and b_t(2)) or (a_i(2) and c_t(1)) or (b_t(2) and c_t(1));
        c_t(3) := (a_i(3) and b_t(3)) or (a_i(3) and c_t(2)) or (b_t(3) and c_t(2));
        c_t(4) := (a_i(4) and b_t(4)) or (a_i(4) and c_t(3)) or (b_t(4) and c_t(3));
        c_t(5) := (a_i(5) and b_t(5)) or (a_i(5) and c_t(4)) or (b_t(5) and c_t(4));
        c_t(6) := (a_i(6) and b_t(6)) or (a_i(6) and c_t(5)) or (b_t(6) and c_t(5));
        c_t(7) := (a_i(7) and b_t(7)) or (a_i(7) and c_t(6)) or (b_t(7) and c_t(6));
        q_o(0) <= a_i(0) xor b_t(0) xor c_i;
        q_o(1) <= a_i(1) xor b_t(1) xor c_t(0);
        q_o(2) <= a_i(2) xor b_t(2) xor c_t(1);
        q_o(3) <= a_i(3) xor b_t(3) xor c_t(2);
        q_o(4) <= a_i(4) xor b_t(4) xor c_t(3);
        q_o(5) <= a_i(5) xor b_t(5) xor c_t(5);
        q_o(6) <= a_i(6) xor b_t(6) xor c_t(6);
        q_o(7) <= a_i(7) xor b_t(7) xor c_t(7);
        c_o <= c_t;
    end;
begin
    sub_i <= alucode(1);
    -- Use carry in for ADC and SBB
    cin_i <= sub_i xor (not alucode(2) and alucode(0) and flag_in(FlagC));
    AddSub(bus_a, bus_b, sub_i, cin_i, q_t, cout_i);
    c_i  <= cout_i(7);
    c7_i <= cout_i(6);
    h_i  <= cout_i(3);
	p_i  <= c_i xor c7_i;
    
    process (alucode, bus_a, bus_b)
    begin
        case alucode is
        when "000" | "001" => -- ADD or ADC
            q_i <= q_t;
            flag_out(FlagC) <= c_i;
            flag_out(FlagH) <= h_i;
            flag_out(FlagP) <= p_i;
        when "010" | "011" | "111" => -- SUB or SBB or CMP
            q_i <= q_t;
            flag_out(FlagC) <= not c_i;
            flag_out(FlagH) <= not h_i;
            flag_out(FlagP) <= p_i;
        when "100" => -- ANA
            q_i <= bus_a and bus_b;
            flag_out(FlagH) <= '1';
        when "101" => -- XRA
            q_i <= bus_a xor bus_b;
            flag_out(FlagH) <= '0';
        when "110" => -- ORA
            q_i <= bus_a or bus_b;
            flag_out(FlagH) <= '0';
        when others =>
            null;
        end case;
        if q_i = "00000000" then
            flag_out(FlagZ) <= '1';
        else
            flag_out(FlagZ) <= '0';
        end if;
        case alucode is
        when "100" | "101" | "110" => -- ANA or XRA or ORA
            flag_out(FlagP) <= not (q_i(0) xor q_i(1) xor q_i(2) xor 
                q_i(3) xor q_i(4) xor q_i(5) xor q_i(6) xor q_i(7));
        when others =>
            null;
        end case;
    end process;
    q <= q_i;
--    q <= q_i when en = '1' else (others=>'Z');
end architecture;