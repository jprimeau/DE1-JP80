library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;
    
use work.jp80_pkg.all;
    
entity JP80_FILEREG is
    port (
        clk             : in t_wire;
        data_in_h       : in t_data;
        data_in_l       : in t_data;
        we_h            : in t_wire;
        we_l            : in t_wire;
        reg_addr_in     : in t_regaddr;
        reg_addr_out_a  : in t_regaddr;
        reg_addr_out_b  : in t_regaddr;
        data_out_a_h    : out t_data;
        data_out_a_l    : out t_data;
        en_a_h          : in t_wire;
        en_a_l          : in t_wire;
        data_out_b_h    : out t_data;
        data_out_b_l    : out t_data;
        en_b_h          : in t_wire;
        en_b_l          : in t_wire;
        
        -- BEGIN: SIMULATION ONLY
        reg_bc          : out t_16bit;
        reg_de          : out t_16bit;
        reg_hl          : out t_16bit;
        reg_sp          : out t_16bit
        -- END: SIMULATION ONLY
    );
end JP80_FILEREG;

architecture rtl of JP80_FILEREG is
    type file_register is array(0 to 3) of t_data;
    signal regs_h : file_register;
    signal regs_l : file_register;
begin
    process (clk)
    begin
        if clk'event and clk = '0' then
            if we_h = '1' then
                regs_h(conv_integer(reg_addr_in)) <= data_in_h;
            end if;
            if we_l = '1' then
                regs_l(conv_integer(reg_addr_in)) <= data_in_l;
            end if;
        end if;
    end process;
    data_out_a_h <= regs_h(conv_integer(reg_addr_out_a)) when en_a_h = '1' else (others=>'Z');
    data_out_a_l <= regs_l(conv_integer(reg_addr_out_a)) when en_a_l = '1' else (others=>'Z');
    data_out_b_h <= regs_h(conv_integer(reg_addr_out_b)) when en_b_h = '1' else (others=>'Z');
    data_out_b_l <= regs_l(conv_integer(reg_addr_out_b)) when en_b_l = '1' else (others=>'Z');
    
    -- BEGIN: SIMULATION ONLY
--    reg_bc <= regs_h(conv_integer("00")) & regs_l(conv_integer("000"))
--    reg_de <= regs_h(conv_integer("00")) & regs_l(conv_integer("000"))
--    reg_hl <= regs_h(conv_integer("00")) & regs_l(conv_integer("000"))
--    reg_sp <= regs_h(conv_integer("00")) & regs_l(conv_integer("000"))
    -- END: SIMULATION ONLY
end architecture;