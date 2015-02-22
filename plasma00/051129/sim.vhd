-- $Id: sim.vhd 49 2005-11-29 13:29:05Z yaegashi $
-- vim: set sw=2 sts=2:

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_unsigned.ALL;
use IEEE.std_logic_arith.ALL;

entity tbench is end;

architecture behavior of tbench is

  component TOP
    generic (
      SKIP_CONFINIT: boolean := false;
      RAM_DEPTH: integer := 18;
      RAM_WIDTH: integer := 32;
      RAM_ENABLES: integer := 4;
      CONFINIT_K: integer := 5;
      CONFINIT_L: integer := 14;
      CONFINIT_M: integer := 50560/4);
    port (
      CLK: in std_logic;
      VR, VG, VB, HSYNC, VSYNC: out std_logic;
      RAM_A: out std_logic_vector(RAM_DEPTH-1 downto 0);
      RAM_D: inout std_logic_vector(RAM_WIDTH-1 downto 0);
      RAM_EN: out std_logic_vector(RAM_ENABLES-1 downto 0);
      RAM_WE, RAM_OE, RAM_CE1, RAM_CE2: out std_logic;
      CDIN: in std_logic;
      CINIT, CCLK: out std_logic;
      LED: out std_logic_vector(7 downto 0));
  end component;

  component SRAM
    generic (W: integer := 18);
    port (
      D: inout std_logic_vector(31 downto 0);
      A: in std_logic_vector(W-1 downto 0);
      CE1, UB1, LB1, CE2, UB2, LB2, WE, OE: in std_logic);
  end component;
  
  signal CLK, VR, VG, VB, HSYNC, VSYNC: std_logic;
  signal RAM_A: std_logic_vector(17 downto 0);
  signal RAM_D: std_logic_vector(31 downto 0);
  signal RAM_EN: std_logic_vector(3 downto 0);
  signal RAM_WE, RAM_OE, RAM_CE1, RAM_CE2: std_logic;
  signal CDIN, CINIT, CCLK: std_logic;
  signal LED: std_logic_vector(7 downto 0);

  signal PROM: std_logic_vector(31 downto 0) := "11101111101111101010110111011110";
  
  constant CYCLE: Time := 40 ns;
  
begin

  U0: TOP
    generic map (
      SKIP_CONFINIT => true)
    port map (
      CLK => CLK,
      VR => VR,
      VG => VG,
      VB => VB,
      HSYNC => HSYNC,
      VSYNC => VSYNC,
      RAM_A => RAM_A,
      RAM_D => RAM_D,
      RAM_EN => RAM_EN,
      RAM_WE => RAM_WE,
      RAM_OE => RAM_OE,
      RAM_CE1 => RAM_CE1,
      RAM_CE2 => RAM_CE2,
      CDIN => CDIN,
      CINIT => CINIT,
      CCLK => CCLK,
      LED => LED);

  U1: SRAM
    generic map (
      W => 8)
    port map (
      A => RAM_A(7 downto 0),
      D => RAM_D,
      CE1 => RAM_CE1,
      CE2 => RAM_CE2,
      OE => RAM_OE,
      WE => RAM_WE,
      LB1 => RAM_EN(0),
      UB1 => RAM_EN(1),
      LB2 => RAM_EN(2),
      UB2 => RAM_EN(3));

  process
  begin
    CLK <= '1';
    wait for CYCLE/2;
    CLK <= '0';
    wait for CYCLE/2;
  end process;

  process (CCLK)
  begin
    if CCLK'event and CCLK = '1' then
      PROM(PROM'left) <= '1';
      PROM(PROM'left-1 downto 0) <= PROM(PROM'left downto 1);
    end if;
  end process;

  CDIN <= PROM(0);
  
end behavior;
