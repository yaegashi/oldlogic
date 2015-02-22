-- $Id: confinit.vhd 10 2005-11-21 12:31:56Z yaegashi $
-- vim: set sw=2 sts=2:

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_unsigned.ALL;
use IEEE.std_logic_arith.ALL;

entity CONFINIT is
  generic (K: integer := 5;
	   L: integer := 14;
	   M: integer := 16383);
  port (CLK, RESET: in std_logic;
        A: out std_logic_vector(L-1 downto 0);
	D: out std_logic_vector(2**K-1 downto 0);
	STB, FIN: out std_logic;
	CDIN: in std_logic;
	CINIT, CCLK: out std_logic);
end CONFINIT;


architecture RTL of CONFINIT is

  type GLOBAL_STATE is (GS0, GS1, GS2);
  signal GSTATE: GLOBAL_STATE;
  constant SIGN: std_logic_vector(2**K-1 downto 0) := "11101111101111101010110111011110"; -- XXX

  constant FULL: std_logic_vector(K downto 0) := (others=>'1');
  constant FINA: std_logic_vector(L-1 downto 0) := CONV_STD_LOGIC_VECTOR(M, L);
  signal COUNTER: std_logic_vector(K+L downto 0);
  signal SR: std_logic_vector(2**K-1 downto 0);
  signal FOUND: std_logic;

begin

  process (RESET, CLK)
  begin
    if RESET = '1' then
      GSTATE <= GS0;
    elsif CLK'event and CLK = '1' then
      if GSTATE = GS0 then
	if FOUND = '1' then
	  GSTATE <= GS1;
	end if;
      elsif GSTATE = GS1 then
	if COUNTER = FINA & FULL then
	  GSTATE <= GS2;
	end if;
      end if;
    end if;
  end process;

  process (RESET, CLK)
  begin
    if RESET = '1' then
      COUNTER <= (others=>'0');
      SR <= (others=>'0');
    elsif CLK'event and CLK = '1' then
      if GSTATE = GS0 and FOUND = '1' then
        COUNTER <= (others=>'0');
      else
	COUNTER <= COUNTER +'1';
      end if;
      if COUNTER(0) = '0' then
        SR(SR'left-1 downto 0) <= SR(SR'left downto 1);
	SR(SR'left) <= CDIN;
      end if;
    end if;
  end process;

  FOUND <= '1' when COUNTER(0) = '1' and SR = SIGN else '0';

  A <= COUNTER(K+L downto K+1);
  D <= SR;
  STB <= '1' when COUNTER(K downto 0) = FULL else '0';
  FIN <= '1' when GSTATE = GS2 else '0';
  CCLK <= not COUNTER(0);
  CINIT <= '1';
  
end RTL;
