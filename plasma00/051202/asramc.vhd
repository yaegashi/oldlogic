-- $Id: asramc.vhd 37 2005-11-28 22:26:27Z yaegashi $
-- vim: set sw=2 sts=2:

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_unsigned.ALL;

entity ASRAMC is
  generic (
    DEPTH: integer := 18;
    WIDTH: integer := 32;
    ENABLES: integer := 4);
  port (
    CLK, RESET: in std_logic;
    A: in std_logic_vector(DEPTH-1 downto 0);
    DI: in std_logic_vector(WIDTH-1 downto 0);
    DO: out std_logic_vector(WIDTH-1 downto 0);
    EN: in std_logic_vector(ENABLES-1 downto 0);
    WR: in std_logic;
    BUSY: out std_logic;
    RAM_A: out std_logic_vector(DEPTH-1 downto 0);
    RAM_D: inout std_logic_vector(WIDTH-1 downto 0);
    RAM_EN: out std_logic_vector(ENABLES-1 downto 0);
    RAM_RW, RAM_OE: out std_logic);
end ASRAMC;


architecture RTL of ASRAMC is

  type MEMORY_STATE is (MS0, MS1, MS2, MS3);
  signal MSTATE: MEMORY_STATE;
  signal IN_EN: std_logic_vector(ENABLES-1 downto 0);

begin

  process (RESET, CLK)
  begin
    if RESET = '1' then
      MSTATE <= MS0;
      IN_EN <= (others=>'1');
    elsif CLK'event and CLK = '1' then
      case MSTATE is
        when MS0 =>
          if WR = '1' then
            MSTATE <= MS1;
            IN_EN <= not EN;
          end if;
        when MS1 =>
          MSTATE <= MS2;
        when MS2 =>
          MSTATE <= MS3;
        when others =>
          MSTATE <= MS0;
      end case;
    end if;
  end process;

  process (MSTATE, IN_EN, DI)
  begin
    case MSTATE is
      when MS0 =>
        BUSY <= '0';
        RAM_RW <= '1';
        RAM_OE <= '0';
        RAM_EN <= (others=>'0');
        RAM_D <= (others=>'Z');
      when MS1 =>
        BUSY <= '1';
        RAM_RW <= '1';
        RAM_OE <= '1';
        RAM_EN <= IN_EN;
        RAM_D <= DI;
      when MS2 =>
        BUSY <= '1';
        RAM_RW <= '0';
        RAM_OE <= '1';
        RAM_EN <= IN_EN;
        RAM_D <= DI;
      when MS3 =>
        BUSY <= '0';
        RAM_RW <= '1';
        RAM_OE <= '1';
        RAM_EN <= IN_EN;
        RAM_D <= DI;
      when others =>
        BUSY <= 'X';
        RAM_RW <= 'X';
        RAM_OE <= 'X';
        RAM_EN <= (others=>'X');
        RAM_D <= (others=>'Z');
    end case;
  end process;
  
  DO <= RAM_D;
  RAM_A <= A;

end RTL;
