-- $Id: asramc.vhd 6 2005-11-20 11:32:43Z yaegashi $
-- vim: set sw=2 sts=2:

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_unsigned.ALL;

entity ASRAMC is
  generic (DEPTH: integer := 18;
           WIDTH: integer := 32;
	   ENABLES: integer := 4);
  port (CLK, RESET: in std_logic;
        A: in std_logic_vector(DEPTH-1 downto 0);
	DI: in std_logic_vector(WIDTH-1 downto 0);
	DO: out std_logic_vector(WIDTH-1 downto 0);
	EN: in std_logic_vector(ENABLES-1 downto 0);
	RW: in std_logic;
	RAM_A: out std_logic_vector(DEPTH-1 downto 0);
	RAM_D: inout std_logic_vector(WIDTH-1 downto 0);
	RAM_EN: out std_logic_vector(ENABLES-1 downto 0);
	RAM_RW: out std_logic);
end ASRAMC;


architecture RTL of ASRAMC is

  signal IN_A: std_logic_vector(DEPTH-1 downto 0);
  signal IN_D: std_logic_vector(WIDTH-1 downto 0);
  signal IN_EN: std_logic_vector(ENABLES-1 downto 0);
  signal IN_RW, IN_DZ: std_logic;

begin

  process (RESET, CLK)
  begin
    if RESET = '1' then
      IN_A <= (others=>'1');
      IN_D <= (others=>'1');
      IN_EN <= (others=>'1');
    elsif CLK'event and CLK = '1' then
      if IN_RW = '1' then
        IN_A <= A;
        IN_D <= DI;
        IN_EN <= EN;
      end if;
    end if;
  end process;

  process (RESET, CLK)
  begin
    if RESET = '1' then
      IN_RW <= '1';
      IN_DZ <= '1';
    elsif CLK'event and CLK = '1' then
      if IN_RW = '0' then
        IN_RW <= '1';
      elsif RW = '0' then
        IN_RW <= '0';
      end if;
      if RW = '0' or IN_RW = '0' then
        IN_DZ <= '0';
      else
        IN_DZ <= '1';
      end if;
    end if;
  end process;

  DO <= RAM_D;
  RAM_A <= IN_A;
  RAM_D <= IN_D when IN_DZ = '0' else (others=>'Z');
  RAM_EN <= IN_EN;
  RAM_RW <= IN_RW;
  
end RTL;
