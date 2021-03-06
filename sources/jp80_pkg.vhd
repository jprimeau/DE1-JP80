-- DESCRIPTION: JP-80 - PKG
-- AUTHOR: Jonathan Primeau

library ieee;
    use ieee.std_logic_1164.all;

package jp80_pkg is

    subtype t_wire is std_logic;
    subtype t_flag is std_logic;
    subtype t_bus is std_logic_vector(15 downto 0);
    subtype t_address is std_logic_vector(15 downto 0);
    subtype t_data is std_logic_vector(7 downto 0);
    subtype t_opcode is std_logic_vector(7 downto 0);
    subtype t_control is std_logic_vector(58 downto 0);
    subtype t_alucode is std_logic_vector(3 downto 0);
    subtype t_8bit is std_logic_vector(7 downto 0);
    subtype t_16bit is std_logic_vector(15 downto 0);
    subtype t_tstate is integer;

    constant Lpc    : integer := 00; -- Load Program Counter
    constant Ipc    : integer := 01; -- Increment Program Counter
    constant Epc    : integer := 02; -- Enable Program Counter
    constant Laddr  : integer := 03; -- Load Memory Address Register
    constant LaddrL : integer := 04;
    constant LaddrH : integer := 05;
    constant Eaddr  : integer := 06;
    constant Ldata  : integer := 07; -- Load Memory Data Register
    constant Edata  : integer := 08; -- Enable Memory Data Register
    constant Lir    : integer := 09; -- Load Instruction Register
    constant Lacc   : integer := 10; -- Load Accumulator
    constant Eacc   : integer := 11; -- Enable Accumulator
    constant Lb     : integer := 12; -- Load B register
    constant Eb     : integer := 13; -- Enable C register
    constant Lc     : integer := 14; -- Load C register
    constant Ec     : integer := 15; -- Enable C register
    constant Ld     : integer := 16; -- Load D register
    constant Ed     : integer := 17; -- Enable D register
    constant Le     : integer := 18; -- Load E register
    constant Ee     : integer := 19; -- Enable E register
    constant Lh     : integer := 20;
    constant Eh     : integer := 21;
    constant Ll     : integer := 22;
    constant El     : integer := 23;
    constant Ehl    : integer := 24;
    constant LaluA  : integer := 25;
    constant LaluB  : integer := 26;
    constant Eu     : integer := 27;
    constant Lu     : integer := 28;
    constant Wr     : integer := 29;
    constant IO     : integer := 30;
    constant HALT   : integer := 31;
    
    constant Lsp    : integer := 32;
    constant Esp    : integer := 33;
    constant Isp    : integer := 34;
    constant Dsp    : integer := 35;
    
    constant Ibc    : integer := 36;
    constant Dbc    : integer := 37;
    constant Ide    : integer := 38;
    constant Dde    : integer := 39;
    constant Ihl    : integer := 40;
    constant Dhl    : integer := 41;

    constant Ebc    : integer := 42;
    constant Lbc    : integer := 43;
    
    constant Ede    : integer := 44;
    constant Lde    : integer := 45;
    
    constant Lt     : integer := 46;
    constant LtL    : integer := 47;
    constant LtH    : integer := 48;
    constant Et     : integer := 49;
    
    constant Lhl    : integer := 50;
    
    constant I2pc   : integer := 51;
    constant Iaddr  : integer := 52;
    constant Lflg   : integer := 53;
    constant Eflg   : integer := 54;
    
    constant EpcL   : integer := 55;
    constant EpcH   : integer := 56;
    constant LpcL   : integer := 57;
    constant LpcH   : integer := 58;
    
    constant FlagC  : integer := 00;
    constant FlagP  : integer := 02;
    constant FlagH  : integer := 04;
    constant FlagI  : integer := 05;
    constant FlagZ  : integer := 06;
    constant FlagS  : integer := 07;
    
    type t_cpu_state is (
        reset_state,
        opcode_fetch_1, opcode_fetch_2, opcode_fetch_3,
        read_data8b_reg, read_data8b_pc, read_data8b,
        read_addr16b_1, read_addr16b_2, read_addr16b_3, read_addr16b_4, 
        read_addr16b_5, read_addr16b_6, read_addr16b_7,
        skip_addr16b_1,
        memio_to_acc_1, memio_to_acc_2,
        acc_to_memio_1, acc_to_memio_2,
        x1, x2, x3, y1, y2, y3, y4,
        push_1, push_2, push_3, push_4, push_5,
        pop_1, pop_2, pop_3, pop_4, pop_5,
        data_to_reg, mem_write,
        decode_instruction
    );
end package jp80_pkg;
