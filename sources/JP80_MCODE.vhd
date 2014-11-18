library ieee;
    use ieee.std_logic_1164.all;
    
use work.jp80_pkg.all;
    
entity JP80_MCODE is
    port (
        clk         : in t_wire;
        reset       : in t_wire;
        opcode      : in t_opcode;
        
        use_alu_q   : out t_flag;
        
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
        elsif clk'event and clk='1' then
            ps <= ns;
        end if;
    end process;
    
    process (ps, opcode)
    begin
        con <= (others => '0');
        case ps is
        when reset_state =>
            ns <= address_state;
        
		when address_state =>
            con(Epc) <= '1';
            con(Laddr) <= '1';
            
--            con(RegB2 downto RegB0) <= "111";
--            con(EregB)  <= '1';
--            con(La)  <= '1';
    
--            ns <= memory_state;
			ns <= increment_state;
            
		when increment_state =>
            con(Ipc) <= '1';
			ns <= memory_state;
            
		when memory_state =>
--            con(Ipc) <= '1';
            con(EdataL) <= '1';
            con(Li) <= '1';
			ns <= decode_instruction;
        
        when decode_instruction =>
            case opcode(7 downto 6) is
                when "00" =>
                    case opcode(2 downto 0) is
                    when "010" =>
--                        <= opcode(5 downto 3);
                    when "110" => -- MVI r,<b>
                        con(Epc)    <= '1';
                        con(Laddr)  <= '1';
                        ns <= mbyte_to_reg_1;
                    when others =>
                        con <= (others => '0');
                        ns <= address_state;
                    end case;
                when "01" => -- MOV r,r or HLT
                    if opcode(5 downto 0) = "110110" then
                        con(HALT) <= '1'; -- HLT is the exception in the "01" range
                    else
                        con(RegB2 downto RegB0) <= opcode(5 downto 3);
                        con(RegI2 downto RegI0) <= opcode(2 downto 0);
                        con(EregB)  <= '1';
                        con(LregI)  <= '1';
                    end if;
                    ns <= address_state;
                when "10" => -- ALU stuff
                    con(ALU2 downto ALU0) <= opcode(5 downto 3);
                    con(RegA2 downto RegA0) <= "111";
                    con(RegB2 downto RegB0) <= opcode(2 downto 0);
                    con(Lu)     <= '1';
                    con(RegI2 downto RegI0) <= "111";
                    con(LregI)  <= '1';
                    ns <= address_state;
--                    ns <= alu_to_acc;
                when others =>
                    con <= (others => '0');
                    ns <= address_state;
            end case;
            
        when mbyte_to_reg_1 =>
            con(Ipc)    <= '1';
            ns <= mbyte_to_reg_2;
            
        when mbyte_to_reg_2 =>
            con(EdataL) <= '1';
            con(RegI2 downto RegI0) <= opcode(5 downto 3);
            con(LregI)  <= '1';
            ns <= address_state;
            
--        when alu_to_acc =>
--            con(RegI2 downto RegI0) <= "111";
--            con(Eu)     <= '1';
--            con(LregI)  <= '1';
--            ns <= address_state;
            
		when others =>
            con <= (others => '0');
			ns <= address_state;
		end case;
    end process;
    
end architecture;