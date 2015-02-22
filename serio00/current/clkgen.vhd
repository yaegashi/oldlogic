-- $Id: clkgen.vhd 16 2005-11-24 21:16:19Z yaegashi $

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_unsigned.ALL;

library UNISIM;
use UNISIM.vcomponents.ALL;

entity CLKGEN is
  port (CLK: in std_logic;
        RESET, MCLK, VCLK: out std_logic);
end CLKGEN;

architecture RTL of CLKGEN is

  signal IBUFG0_I, IBUFG0_O, BUFG0_I, BUFG0_O, BUFG1_I, BUFG1_O: std_logic;

begin

  -- Reset On Configuration
  ROC0: ROC port map (O => RESET);

  -- Global clock buffers
  IBUFG0: IBUFG port map (I => IBUFG0_I, O => IBUFG0_O);
  BUFG0: BUFG port map (I => BUFG0_I, O => BUFG0_O);
  BUFG1: BUFG port map (I => BUFG1_I, O => BUFG1_O);

  -- Digital Clock Manager
  DCM0: DCM generic map (CLKDV_DIVIDE => 2.0)
            port map (CLKIN => IBUFG0_O,
	              CLKFB => BUFG0_O,
		      CLK0 => BUFG0_I,
		      CLKDV => BUFG1_I);

  IBUFG0_I <= CLK;
  MCLK <= BUFG0_O;
  VCLK <= BUFG1_O;
  
end RTL;
