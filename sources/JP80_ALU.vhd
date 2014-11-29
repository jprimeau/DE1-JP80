library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    
use work.jp80_pkg.all;
    
entity JP80_ALU is
    port (
        alucode     : in t_alucode;
        a           : in t_data;
        b           : in t_data;
        f_in        : in t_data;
        q           : out t_data;
        f_out       : out t_data
    );
end JP80_ALU;

architecture rtl of JP80_ALU is
    signal tmp_a        : t_data;
    signal tmp_b        : t_data;
    signal tmp_c        : std_logic;
    signal tmp_z        : std_logic;
    signal tmp_s        : std_logic;
    signal tmp_q        : t_data;
    
    signal check_z      : std_logic;
    signal check_s      : std_logic;
    
    procedure FullAdder(
        signal a    : in t_data;
        signal b    : in t_data;
        signal cin  : in std_logic;
        signal q    : out t_data;
        signal cout : out std_logic
    ) is
        variable c1, c2, c3, c4, c5, c6, c7 : std_logic;
    begin
        c1 := (a(0) and b(0)) or (a(0) and cin) or (b(0) and cin);
        c2 := (a(1) and b(1)) or (a(1) and c1) or (b(1) and c1);
        c3 := (a(2) and b(2)) or (a(2) and c2) or (b(2) and c2);
        c4 := (a(3) and b(3)) or (a(3) and c3) or (b(3) and c3);
        c5 := (a(4) and b(4)) or (a(4) and c4) or (b(4) and c4);
        c6 := (a(5) and b(5)) or (a(5) and c5) or (b(5) and c5);
        c7 := (a(6) and b(6)) or (a(6) and c6) or (b(6) and c6);
        cout <= (a(7) and b(7)) or (a(7) and c7) or (b(7) and c7);
        q(0) <= a(0) xor b(0) xor cin;
        q(1) <= a(1) xor b(1) xor c1;
        q(2) <= a(2) xor b(2) xor c2;
        q(3) <= a(3) xor b(3) xor c3;
        q(4) <= a(4) xor b(4) xor c4;
        q(5) <= a(5) xor b(5) xor c5;
        q(6) <= a(6) xor b(6) xor c6;
        q(7) <= a(7) xor b(7) xor c7;
    end FullAdder;
begin
    process (alucode, a, b)
    begin
        tmp_c <= f_in(FlagC);
        tmp_s <= f_in(FlagS);
        tmp_z <= f_in(FlagZ);
        check_z <= '1';
        check_s <= '1';
        case alucode is
        when "0000" | "0001" => -- ADD or ADC
            tmp_a <= a;
            tmp_b <= b;
            tmp_c <= '0';
            if alucode = "001" then
                tmp_c <= f_in(FlagC);
            end if;
            FullAdder(tmp_a, tmp_b, tmp_c, tmp_q, tmp_c);
        when "0010" | "0011" | "0111" => -- SUB or SBB or CMP
            tmp_a <= a;
            tmp_b <= not b;
            tmp_c <= '0';
            if alucode = "011" then
                tmp_c <= f_in(FlagC);
            end if;
            FullAdder(tmp_a, tmp_b, tmp_c, tmp_q, tmp_c);
        when "0100" => -- ANA
            tmp_q <= a and b;
            tmp_c <= '0';
        when "0101" => -- XRA
            tmp_q <= a xor b;
            tmp_c <= '0';
        when "0110" => -- ORA
            tmp_q <= a or b;
            tmp_c <= '0';
            
        when "1000" => -- RLC
            tmp_q <= to_stdlogicvector(to_bitvector(a) rol 1);
            tmp_c <= tmp_q(0);
            check_z <= '0';
            check_s <= '0';
        when "1001" => -- RRC
            tmp_q <= to_stdlogicvector(to_bitvector(a) ror 1);
            tmp_c <= tmp_q(7);
            check_z <= '0';
            check_s <= '0';
        when "1010" => -- RAL
            -- TODO
            check_z <= '0';
            check_s <= '0';
        when "1011" => -- RAR
            -- TODO
            check_z <= '0';
            check_s <= '0';
        when "1100" => -- DAA
            -- TODO
            check_z <= '0';
            check_s <= '0';
        when "1101" => -- CMA
            tmp_q <= not a;
            check_z <= '0';
            check_s <= '0';
        when "1110" => -- STC
            tmp_c <= '1';
            check_z <= '0';
            check_s <= '0';
        when "1111" => -- CMC
            tmp_c <= not f_in(FlagC);
            check_z <= '0';
            check_s <= '0';
        end case;
        
        if check_z = '1' then
            if tmp_q = "00000000" then
                tmp_z <= '1';
            else
                tmp_z <= '0';
            end if;
        end if;
        if check_s = '1' then
            tmp_s <= tmp_q(7);
        end if;
        
    end process;
    f_out(FlagC) <= tmp_c;
    f_out(FlagZ) <= tmp_z;
    f_out(FlagS) <= tmp_s;
    q <= tmp_q;
end architecture;