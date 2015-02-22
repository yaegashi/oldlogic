-- $Id: serio.vhd 16 2005-11-24 21:16:19Z yaegashi $
-- vim: set sw=2 sts=2:

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_unsigned.ALL;


entity SERIO is
  generic (W: integer := 5);
  port (CLK, RESET: in std_logic;
        DIVIDER: in std_logic_vector(W-1 downto 0);
	RXD: in std_logic;
	TXD: out std_logic;
	DI: in std_logic_vector(7 downto 0);
	DO: out std_logic_vector(7 downto 0);
	STROBE: in std_logic;
	EMPTY, READY, FERROR: out std_logic);
end SERIO;


architecture RTL of SERIO is

  constant DIVZERO: std_logic_vector(W-1 downto 0) := (others=>'0');
  signal DIVCNT: std_logic_vector(W-1 downto 0);
  signal DIVEN: std_logic;

  constant CNTZERO: std_logic_vector(7 downto 0) := (others=>'0');
  constant CNTFULL: std_logic_vector(7 downto 0) := (others=>'1');
  signal IN_RXD, IN_TXD: std_logic;
  signal RXCNT, TXCNT: std_logic_vector(7 downto 0);
  signal RXSR: std_logic_vector(7 downto 0);
  signal TXSR: std_logic_vector(8 downto 0);

begin

  -- Clock divider
  process (CLK, RESET)
  begin
    if RESET = '1' then
      DIVCNT <= (others=>'0');
      DIVEN <= '0';
    elsif CLK'event and CLK = '1' then
      if DIVCNT = DIVZERO then
        DIVCNT <= DIVIDER;
	DIVEN <= '1';
      else
        DIVCNT <= DIVCNT - '1';
	DIVEN <= '0';
      end if;
    end if;
  end process;

  -- Receiver
  process (CLK, RESET)
  begin
    if RESET = '1' then
      IN_RXD <= '1';
      RXCNT <= (others=>'1');
      RXSR <= (others=>'1');
    elsif CLK'event and CLK = '1' then
      IN_RXD <= RXD;
      if DIVEN = '1' then
        if RXCNT = CNTFULL then
	  if IN_RXD = '0' then
	    RXCNT <= "10011000";
	  end if;
	else
	  RXCNT <= RXCNT - 1;
	end if;
	if RXCNT(3 downto 0) = "0000" then
	  RXSR(7) <= IN_RXD;
	  RXSR(6 downto 0) <= RXSR(7 downto 1);
	end if;
      end if;
    end if;
  end process;

  DO <= RXSR;
  READY <= '1' when DIVEN = '1' and RXCNT = CNTZERO and IN_RXD = '1' else '0';
  FERROR <= '1' when DIVEN = '1' and RXCNT = CNTZERO and IN_RXD = '0' else '0';

  -- Transmitter
  process (CLK, RESET)
  begin
    if RESET = '1' then
      IN_TXD <= '1';
      TXCNT <= (others=>'0');
      TXSR <= (others=>'1');
    elsif CLK'event and CLK = '1' then
      if TXCNT = CNTZERO then
        if STROBE = '1' then
	  TXCNT <= "10100000";
	  TXSR(8 downto 1) <= DI;
	  TXSR(0) <= '0';
	end if;
      elsif DIVEN = '1' then
	TXCNT <= TXCNT - 1;
	if TXCNT(3 downto 0) = "0000" then
	  IN_TXD <= TXSR(0);
	  TXSR(8) <= '1';
	  TXSR(7 downto 0) <= TXSR(8 downto 1);
	end if;
      end if;
    end if;
  end process;

  TXD <= IN_TXD;
  EMPTY <= '1' when TXCNT = CNTZERO else '0';

end RTL;
