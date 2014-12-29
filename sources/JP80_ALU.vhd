library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.std_logic_unsigned.all;
    
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
begin
    process (alucode, a, b, f_in)
        variable check_z    : std_logic;
        variable check_s    : std_logic;
        variable tmp_a      : std_logic_vector(8 downto 0);
        variable tmp_b      : std_logic_vector(8 downto 0);
        variable tmp_c      : std_logic;
        variable tmp_z      : std_logic;
        variable tmp_s      : std_logic;
        variable tmp_q      : std_logic_vector(8 downto 0);
    begin
        tmp_a := "0"&a;
        tmp_b := "0"&b;
        tmp_c := f_in(FlagC);
        tmp_s := f_in(FlagS);
        tmp_z := f_in(FlagZ);
        check_z := '1';
        check_s := '1';
        case alucode is
        when "0000" | "0001" => -- ADD or ADC
            if alucode = "0001" then
                tmp_q := tmp_a + tmp_b + f_in(FlagC);
            else
                tmp_q := tmp_a + tmp_b;
            end if;
            tmp_c := tmp_q(8);
        when "0010" | "0011" | "0111" => -- SUB or SBB or CMP
            if alucode = "0011" then
                tmp_q := tmp_a - tmp_b - f_in(FlagC);
            else
                tmp_q := tmp_a - tmp_b;
            end if;
            tmp_c := tmp_q(8);
        when "0100" => -- ANA
            tmp_q := tmp_a and tmp_b;
            tmp_c := '0';
        when "0101" => -- XRA
            tmp_q := tmp_a xor tmp_b;
            tmp_c := '0';
        when "0110" => -- ORA
            tmp_q := tmp_a or tmp_b;
            tmp_c := '0';
            
--        when "1000" => -- RLC
--            tmp_q := to_stdlogicvector(to_bitvector(a) rol 1);
--            tmp_c := tmp_q(0);
--            check_z := '0';
--            check_s := '0';
--        when "1001" => -- RRC
--            tmp_q := to_stdlogicvector(to_bitvector(a) ror 1);
--            tmp_c := tmp_q(7);
--            check_z := '0';
--            check_s := '0';
--        when "1010" => -- RAL
--            -- TODO
--            tmp_q := (others=>'0');
--            check_z := '0';
--            check_s := '0';
--        when "1011" => -- RAR
--            -- TODO
--            tmp_q := (others=>'0');
--            check_z := '0';
--            check_s := '0';
--        when "1100" => -- DAA
--            -- TODO
--            tmp_q := (others=>'0');
--            check_z := '0';
--            check_s := '0';
        when "1101" => -- CMA
            tmp_q := not "0"&a;
            check_z := '0';
            check_s := '0';
        when "1110" => -- STC
            tmp_c := '1';
            check_z := '0';
            check_s := '0';
        when "1111" => -- CMC
            tmp_c := not f_in(FlagC);
            check_z := '0';
            check_s := '0';
        when others =>
            tmp_q := (others=>'0');
            tmp_c := '0';
        end case;
        
        if check_z = '1' then
            if tmp_q = "000000000" then
                tmp_z := '1';
            else
                tmp_z := '0';
            end if;
        end if;
        if check_s = '1' then
            tmp_s := tmp_q(7);
        end if;
        
        f_out(FlagC) <= tmp_c;
        f_out(FlagZ) <= tmp_z;
        f_out(FlagS) <= tmp_s;
        if alucode = "0111" or alucode = "1110" or alucode = "1111"then
            q <= a;
        else
            q <= tmp_q(7 downto 0);
        end if;
    end process;
end architecture;