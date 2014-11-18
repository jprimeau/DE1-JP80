library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;
    
use work.jp80_pkg.all;
    
entity JP80_FILEREG is
    port (
        clk         : in t_wire;
        input       : in t_data;
        en_a        : in t_wire;
        en_b        : in t_wire;
        reg_a_sel   : in t_regaddr;
        reg_b_sel   : in t_regaddr;
        reg_wr_sel  : in t_regaddr;
        we          : in t_wire;
        out_a       : out t_data;
        out_b       : out t_data
    );
end JP80_FILEREG;

architecture rtl of JP80_FILEREG is
    type file_register is array(0 to 7) of t_data;
    signal registers : file_register;
begin
    process (clk)
    begin
        if clk'event and clk = '0' then
            if we = '1' then
                registers(conv_integer(reg_wr_sel)) <= input;
            end if;
        end if;
    end process;
    out_a <= registers(conv_integer(reg_a_sel)) when en_a = '1' else (others=>'Z');
    out_b <= registers(conv_integer(reg_b_sel)) when en_b = '1' else (others=>'Z');
end architecture;