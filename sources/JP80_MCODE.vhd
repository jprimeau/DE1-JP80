library ieee;
    use ieee.std_logic_1164.all;
    
use work.jp80_pkg.all;
    
entity JP80_MCODE is
    port (
        clk         : in t_wire;
        reset       : in t_wire;
        op_code     : in t_opcode;
        dst_reg     : out t_regaddr;
        src_reg     : out t_regaddr;
        en_a_reg    : out t_wire;
        wr_reg      : out t_wire;
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
        
        when reset_state =>
            ns <= address_state;
        
		when address_state =>
            con(Ep) <= '1';
            con(Laddr) <= '1';
			ns <= increment_state;
            
		when increment_state =>
            con(Cp) <= '1';
			ns <= memory_state;
            
		when memory_state =>
            con(EdataL) <= '1';
            con(Li) <= '1';
			ns <= decode_instruction;
        
        when decode_instruction =>
            case op_code(7 downto 6) is
                when "10" => -- ALU stuff
                    alu_op <= op_code(5 downto 3);
                    src_reg <= op_code(2 downto 0);
                when "01" => -- MOV r,r or HLT
                    if op_code = "01110110" then
                        con(HALT) <= '1'; -- HLT is the exception in the "01" range
                    else
                        dst_reg <= op_code(5 downto 3);
                        src_reg <= op_code(2 downto 0);
                        en_a_reg <= '1';
                        wr_reg <= '1';
                    end if;
                when others =>
                    null;
            end case;
            
		when others =>
			ns <= address_state;
		end case;
    end process;
    
end architecture;