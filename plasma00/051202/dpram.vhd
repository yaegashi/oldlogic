-- $Id: dpram.vhd 25 2005-11-27 23:53:22Z yaegashi $
-- vim: set sw=2 sts=2:

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_unsigned.ALL;
use IEEE.std_logic_arith.ALL;

library UNISIM;
use UNISIM.vcomponents.ALL;


entity reg_file_dp_ram_xc4000xla is
  port (
    A      : in  std_logic_vector(4 downto 0);
    DI     : in  std_logic_vector(31 downto 0);
    WR_EN  : in  std_logic;
    WR_CLK : in  std_logic;
    DPRA   : in  std_logic_vector(4 downto 0);
    SPO    : out std_logic_vector(31 downto 0);
    DPO    : out std_logic_vector(31 downto 0));
end reg_file_dp_ram_xc4000xla;
   

architecture RTL of reg_file_dp_ram_xc4000xla is

  signal WE0, WE1: std_logic;
  signal SPO0, SPO1, DPO0, DPO1: std_logic_vector(31 downto 0); 

begin

  PORT_A:
  for i in 0 to 31 generate
  begin
    BANK0: RAM16X1D port map (WCLK => WR_CLK,
                              WE => WE0,
			      A0 => A(0),
			      A1 => A(1),
			      A2 => A(2),
			      A3 => A(3),
			      DPRA0 => DPRA(0),
			      DPRA1 => DPRA(1),
			      DPRA2 => DPRA(2),
			      DPRA3 => DPRA(3),
			      D => DI(i),
			      SPO => SPO0(i),
			      DPO => DPO0(i));
    BANK1: RAM16X1D port map (WCLK => WR_CLK,
                              WE => WE1,
			      A0 => A(0),
			      A1 => A(1),
			      A2 => A(2),
			      A3 => A(3),
			      DPRA0 => DPRA(0),
			      DPRA1 => DPRA(1),
			      DPRA2 => DPRA(2),
			      DPRA3 => DPRA(3),
			      D => DI(i),
			      SPO => SPO1(i),
			      DPO => DPO1(i));
  end generate;

  WE0 <= '1' when WR_EN = '1' and A(4) = '0' else '0';
  WE1 <= '1' when WR_EN = '1' and A(4) = '1' else '0';
  SPO <= SPO0 when A(4) = '0' else SPO1;
  DPO <= DPO0 when DPRA(4) = '0' else DPO1;

end RTL;
