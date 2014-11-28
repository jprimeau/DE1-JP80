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
    subtype t_control is std_logic_vector(31 downto 0);
    subtype t_alucode is std_logic_vector(3 downto 0);
    subtype t_8bit is std_logic_vector(7 downto 0);
    subtype t_16bit is std_logic_vector(15 downto 0);
    subtype t_tstate is integer;

    constant Lpc    : integer := 00; -- Load Program Counter
    constant Ipc    : integer := 01; -- Increment Program Counter
    constant Epc    : integer := 02; -- Enable Program Counter
    constant Lmar   : integer := 03; -- Load Memory Address Register
    constant Lmdr   : integer := 04; -- Load Memory Data Register
    constant Emdr   : integer := 05; -- Enable Memory Data Register
    constant Lir    : integer := 06; -- Load Instruction Register
    constant Lacc   : integer := 07; -- Load Accumulator
    constant Eacc   : integer := 08; -- Enable Accumulator
    constant Lb     : integer := 09; -- Load B register
    constant Eb     : integer := 10; -- Enable C register
    constant Lc     : integer := 11; -- Load C register
    constant Ec     : integer := 12; -- Enable C register
    constant Ld     : integer := 13;
    constant Ed     : integer := 14;
    constant Le     : integer := 15;
    constant Ee     : integer := 16;
    constant LaluA  : integer := 17;
    constant LaluB  : integer := 18;
    constant LaddrL : integer := 18;
    constant LaddrH : integer := 19;
    constant Eaddr  : integer := 20;

--    constant Lh     : integer := 18;
--    constant Eh     : integer := 19;
--    constant Ll     : integer := 20;
--    constant El     : integer := 21;
--    constant Lm     : integer := 22;
--    constant Em     : integer := 23;
--    constant Lt     : integer := 24;
--    constant Et     : integer := 25;
    constant Eu     : integer := 26;
    constant Lu     : integer := 27;
--    constant Lsz    : integer := 28;
    constant Wr     : integer := 29;
    constant IO     : integer := 30;
    constant HALT   : integer := 31;
    
    -- Sources and destinations
    constant sdB    : integer := 00;
    constant sdC    : integer := 01;
    constant sdD    : integer := 02;
    constant sdE    : integer := 03;
    constant sdH    : integer := 04;
    constant sdL    : integer := 05;
    constant sdACC  : integer := 07;
    constant sdPC	: integer := 11;
    
--    constant ALU0   : integer := 20;
--    constant ALU1   : integer := 21;
--    constant ALU2   : integer := 22;
    
    constant FlagC  : integer := 00;
    constant FlagP  : integer := 02;
    constant FlagH  : integer := 04;
    constant FlagI  : integer := 05;
    constant FlagZ  : integer := 06;
    constant FlagS  : integer := 07;
    
    type t_cpu_state is (
        reset_state,
        opcode_fetch_1, opcode_fetch_2, opcode_fetch_3,
        data_read_1, data_read_2, data_read_3,
        addr_read_1, addr_read_2, addr_read_3,
        addr_read_4, addr_read_5, addr_read_6,
        decode_instruction
    );
end package jp80_pkg;
