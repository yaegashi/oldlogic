-- $Id: fb.vhd 10 2005-11-21 12:31:56Z yaegashi $
-- vim: set sw=2 sts=2:

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_unsigned.ALL;
use IEEE.std_logic_arith.ALL;

library UNISIM;
use UNISIM.vcomponents.ALL;


entity FB is
  port (CLK: in std_logic;
        VR, VG, VB, HSYNC, VSYNC: out std_logic;
	RAM_A: out std_logic_vector(17 downto 0);
	RAM_D: inout std_logic_vector(31 downto 0);
	RAM_WE, RAM_OE: out std_logic;
	RAM_CE1, RAM_LB1, RAM_UB1, RAM_CE2, RAM_LB2, RAM_UB2: out std_logic;
	CDIN: in std_logic;
	CINIT, CCLK: out std_logic);
end FB;


architecture RTL of FB is

  constant RAM_DEPTH: integer := RAM_A'length;
  constant RAM_WIDTH: integer := RAM_D'length;
  constant RAM_ENABLES: integer := 4;
  constant CONFINIT_K: integer := 5;
  constant CONFINIT_L: integer := 15;
  constant CONFINIT_M: integer := 25281;

  component CRTC
    generic (H0: integer := 640;
             H1: integer := 656;
	     H2: integer := 752;
	     H3: integer := 800;
	     V0: integer := 480;
	     V1: integer := 490;
	     V2: integer := 492;
	     V3: integer := 521);
    port (CLK, RESET: in std_logic;
          HSYNC, VSYNC, BLANK: out std_logic;
  	  HADDR, VADDR, MADDR: out integer);
  end component;

  component ASRAMC
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
  end component;

  component CONFINIT
    generic (K: integer := 5;
	     L: integer := 14;
	     M: integer := 16383);
    port (CLK, RESET: in std_logic;
	  A: out std_logic_vector(L-1 downto 0);
	  D: out std_logic_vector(2**K-1 downto 0);
	  STB, FIN: out std_logic;
	  CDIN: in std_logic;
	  CINIT, CCLK: out std_logic);
  end component;

  signal VCLK, RESET: std_logic;
  signal IBUFG0_I, IBUFG0_O, BUFG0_I, BUFG0_O, BUFG1_I, BUFG1_O: std_logic;
  signal IN_HSYNC, IN_VSYNC, IN_BLANK: std_logic;
  signal IN_HADDR, IN_VADDR, IN_MADDR: integer;

  signal IN_A: std_logic_vector(RAM_DEPTH-1 downto 0);
  signal IN_DI, IN_DO: std_logic_vector(RAM_WIDTH-1 downto 0);
  signal IN_EN: std_logic_vector(RAM_ENABLES-1 downto 0);
  signal IN_RW: std_logic;
  signal RAM_EN: std_logic_vector(RAM_ENABLES-1 downto 0);
  signal RAM_RW: std_logic;
  signal D_D: std_logic_vector(RAM_WIDTH-1 downto 0);
  signal D_A: std_logic_vector(1 downto 0);
  signal D_HSYNC, D_VSYNC, D_BLANK: std_logic;

  signal VIDEO_A: std_logic_vector(RAM_DEPTH+1 downto 0);
  signal CI0_A: std_logic_vector(CONFINIT_L-1 downto 0);
  signal CI0_D: std_logic_vector(2**CONFINIT_K-1 downto 0);
  signal CI0_STB, CI0_FIN: std_logic;
  constant CI0_UA: std_logic_vector(RAM_DEPTH-CONFINIT_L-1 downto 0)
	           := (others=>'0');

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
  VCLK <= BUFG1_O;

  -- CRT controller
  CRTC0: CRTC port map (CLK => VCLK,
                        RESET => RESET,
			HSYNC => IN_HSYNC,
			VSYNC => IN_VSYNC,
			BLANK => IN_BLANK,
			HADDR => IN_HADDR,
			VADDR => IN_VADDR,
			MADDR => IN_MADDR);

  -- Asynchronous SRAM controller
  ASRAMC0: ASRAMC generic map (DEPTH => RAM_DEPTH,
			       WIDTH => RAM_WIDTH,
			       ENABLES => RAM_ENABLES)
                  port map (CLK => VCLK,
			    RESET => RESET,
			    A => IN_A,
			    DI => IN_DI,
			    DO => IN_DO,
			    EN => IN_EN,
			    RW => IN_RW,
			    RAM_A => RAM_A,
			    RAM_D => RAM_D,
			    RAM_EN => RAM_EN,
			    RAM_RW => RAM_RW);

  RAM_WE <= RAM_RW;
  RAM_OE <= '0';
  RAM_CE1 <= '0';
  RAM_LB1 <= RAM_EN(0);
  RAM_UB1 <= RAM_EN(1);
  RAM_CE2 <= '0';
  RAM_LB2 <= RAM_EN(2);
  RAM_UB2 <= RAM_EN(3);

  -- Configuration RAM initializer
  CI0: CONFINIT generic map (K => CONFINIT_K,
			     L => CONFINIT_L,
			     M => CONFINIT_M)
                port map (CLK => VCLK,
			  RESET => RESET,
			  A => CI0_A,
			  D => CI0_D,
			  STB => CI0_STB,
			  FIN => CI0_FIN,
			  CDIN => CDIN,
			  CINIT => CINIT,
			  CCLK => CCLK);

  VIDEO_A <= CONV_STD_LOGIC_VECTOR(IN_MADDR, VIDEO_A'length);
  IN_A <= CI0_UA & CI0_A when CI0_FIN = '0' else VIDEO_A(VIDEO_A'left downto 2);
  IN_DI <= CI0_D;
  IN_EN <= (others=>'0');
  IN_RW <= not CI0_STB when CI0_FIN = '0' else '1';

  process (VCLK, RESET)
    variable DELAY0: std_logic_vector(4 downto 0);
  begin
    if RESET = '1' then
      D_D <= (others=>'0');
      D_A <= (others=>'0');
      D_HSYNC <= '1';
      D_VSYNC <= '1';
      D_BLANK <= '1';
      DELAY0 := (others=>'1');
    elsif VCLK'event and VCLK = '1' then
      D_D <= IN_DO;
      D_A <= DELAY0(4 downto 3);
      D_HSYNC <= DELAY0(2);
      D_VSYNC <= DELAY0(1);
      D_BLANK <= DELAY0(0);
      DELAY0 := VIDEO_A(1 downto 0) & IN_HSYNC & IN_VSYNC & IN_BLANK;
    end if;
  end process;
  
  process (D_BLANK, D_D, D_A)
  begin
    if D_BLANK = '1' then
      VR <= '0';
      VG <= '0';
      VB <= '0';
    else
      case D_A is
        when "00" =>
	  VR <= D_D(0);
	  VG <= D_D(1);
	  VB <= D_D(2);
        when "01" =>
	  VR <= D_D(8);
	  VG <= D_D(9);
	  VB <= D_D(10);
        when "10" =>
	  VR <= D_D(16);
	  VG <= D_D(17);
	  VB <= D_D(18);
        when "11" =>
	  VR <= D_D(24);
	  VG <= D_D(25);
	  VB <= D_D(26);
	when others =>
	  VR <= '0';
	  VG <= '0';
	  VB <= '0';
      end case;
    end if;
  end process;

  HSYNC <= D_HSYNC;
  VSYNC <= D_VSYNC;

end RTL;
