library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;
    
use work.jp80_pkg.all;
    
entity JP80_MCODE is
    port (
        clk         : in t_wire;
        reset       : in t_wire;
        opcode      : in t_opcode;
        aluop       : out t_aluop;
        alu_to_acc  : out t_flag;
        con         : out t_control;
        src         : out t_regaddr;
        dst         : out t_regaddr;
        tstate      : out t_tstate
    );
end JP80_MCODE;

architecture rtl of JP80_MCODE is
    signal ns, ps   : t_cpu_state;
    signal save_alu : t_flag;
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
		variable DDD : std_logic_vector(2 downto 0);
		variable SSS : std_logic_vector(2 downto 0);
    begin
		DDD := opcode(5 downto 3);
		SSS := opcode(2 downto 0);
        
        src <= (others=>'0');
        dst <= (others=>'0');
    
        con <= (others => '0');
        alu_to_acc <= '0';
        
        case ps is
        when reset_state =>
            ns <= opcode_fetch_1;
        
		when opcode_fetch_1 =>
            tstate <= 1;
            con(Epc) <= '1';
            con(Lmar) <= '1';
            alu_to_acc <= save_alu and '1';
            save_alu <= '0';
			ns <= opcode_fetch_2;
            
		when opcode_fetch_2 =>
            tstate <= 2;
            con(Ipc) <= '1';
			ns <= opcode_fetch_3;
            
		when opcode_fetch_3 =>
            tstate <= 3;
            con(Emdr) <= '1';
            con(Lir) <= '1';
			ns <= decode_instruction;
            
        when memory_read_1 =>
            tstate <= 1;
            con(Esrc) <= '1';
            con(Lmar) <= '1';
            ns <= memory_read_2;
        
        when memory_read_2 =>
            tstate <= 2;
            con(Ipc) <= '1';
            ns <= memory_read_3;
        
        when memory_read_3 =>
            tstate <= 3;
            con(Emdr) <= '1';
            con(Ldst) <= '1';
--            ns <= exec_cb;
            ns <= opcode_fetch_1;
        
        when decode_instruction =>
            tstate <= 4;
            case opcode(7 downto 6) is
                when "00" =>
                    case opcode(2 downto 0) is
                    when "010" =>
                    when "110" => -- MVI r,<b>
                        src(sdPC) <= '1';
                        con(Ssrc) <= '1';
                        dst(conv_integer(DDD)) <= '1';
                        con(Sdst) <= '1';
                        ns <= memory_read_1;
                    when others =>
                        con <= (others => '0');
                        ns <= opcode_fetch_1;
                    end case;
                when "01" => -- MOV r,r or HLT
                    if opcode(5 downto 0) = "110110" then
                        con(HALT) <= '1'; -- HLT is the exception in the "01" range
                    else
                        src(conv_integer(SSS)) <= '1';
                        con(Ssrc) <= '1';
                        dst(conv_integer(DDD)) <= '1';
                        con(Sdst) <= '1';
                        con(Esrc) <= '1';
                        con(Ldst) <= '1';
                    end if;
                    ns <= opcode_fetch_1;
                when "10" => -- ALU stuff
                    aluop <= opcode(5 downto 3);
                    src(conv_integer(SSS)) <= '1';
                    con(Ssrc) <= '1';
                    con(LaluA) <= '1';
                    con(LaluB) <= '1';
                    con(Esrc) <= '1';
                    save_alu <= '1';
                    con(Lu) <= '1';
                    ns <= opcode_fetch_1;
                when others =>
                    con <= (others => '0');
                    ns <= opcode_fetch_1;
            end case;
      
		when others =>
            con <= (others => '0');
			ns <= opcode_fetch_1;
		end case;
    end process;
    
end architecture;