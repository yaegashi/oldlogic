-- $Id: top.vhd 16 2005-11-24 21:16:19Z yaegashi $
-- vim: set sw=2 sts=2:

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_unsigned.ALL;
use IEEE.std_logic_arith.ALL;


entity TOP is
  port (CLK: in std_logic;
	RXD: in std_logic;
        TXD: out std_logic;
	LED: out std_logic_vector(7 downto 0));
end TOP;


architecture RTL of TOP is

  component CLKGEN
    port (CLK: in std_logic;
	  RESET, MCLK, VCLK: out std_logic);
  end component;

  component SERIO
    generic (W: integer := 5);
    port (CLK, RESET: in std_logic;
	  DIVIDER: in std_logic_vector(W-1 downto 0);
	  RXD: in std_logic;
	  TXD: out std_logic;
	  DI: in std_logic_vector(7 downto 0);
	  DO: out std_logic_vector(7 downto 0);
	  STROBE: in std_logic;
	  EMPTY, READY, FERROR: out std_logic);
  end component;

  signal RESET, MCLK, VCLK: std_logic;

  -- 115200*16 Hz = 50MHz / 27
  constant DIVIDER: std_logic_vector(4 downto 0) := "11011";
  signal DI, DO: std_logic_vector(7 downto 0);
  signal STROBE, EMPTY, READY, FERROR: std_logic;

begin

  -- Clock generator
  CLKGEN0: CLKGEN port map (CLK => CLK,
			    RESET => RESET,
			    MCLK => MCLK,
                            VCLK => VCLK);

  -- Serial I/O
  SERIO0: SERIO generic map (W => 5)
                port map (CLK => MCLK,
		          RESET => RESET,
			  DIVIDER => DIVIDER,
			  RXD => RXD,
			  TXD => TXD,
			  DI => DI,
			  DO => DO,
			  STROBE => STROBE,
			  EMPTY => EMPTY,
			  READY => READY,
			  FERROR => FERROR);

  -- Loopback connection (RxD -> TxD)
  STROBE <= READY;
  DI <= DO;

  -- LED diagnostics
  process (MCLK, RESET)
  begin
    if RESET = '1' then
      LED <= (others=>'0');
    elsif MCLK'event and MCLK = '1' then
      if READY = '1' then
        LED <= DO;
      end if;
    end if;
  end process;


end RTL;
