library ieee;
    use ieee.std_logic_1164.all;
    
use work.jp80_pkg.all;
    
entity JP80_MCODE is
    port (
        clk         : in t_wire;
        reset       : in t_wire;
        op_code     : in t_opcode;
        con         : out t_control
    );
end JP80_MCODE;

architecture rtl of JP80_MCODE is
    signal ns, ps   : t_cpu_state;
begin
    process (clk, reset)
    begin
        if reset = '1' then
            ps <= reset_state;
        elsif clk'event and clk='0' then
            ps <= ns;
        end if;
    end process;
    
    process (ps, op_code)
    begin
        case ps is
        
        when decode_instruction =>
            case op_code(7 downto 6) is
                when "01" => -- MOV r,r
                    ld_reg <= op_code(5 downto 3);
                    en_reg <= op_code(2 downto 0);
                when others =>
                    null;
            end case;
            
		when others =>
			ns <= address_state;
		end case;
    end process;
    
end architecture;