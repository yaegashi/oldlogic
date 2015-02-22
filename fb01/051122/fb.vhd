-- $Id: fb.vhd 14 2005-11-22 21:08:39Z yaegashi $
-- vim: set sw=2 sts=2:

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_unsigned.ALL;
use IEEE.std_logic_arith.ALL;


entity FB is
  generic (RAM_DEPTH: integer := 18;
           RAM_WIDTH: integer := 32;
	   RAM_ENABLES: integer := 4;
	   CONFINIT_K: integer := 5;
	   CONFINIT_L: integer := 15;
	   CONFINIT_M: integer := 25281);
  port (CLK: in std_logic;
        VR, VG, VB, HSYNC, VSYNC: out std_logic;
	RAM_A: out std_logic_vector(RAM_DEPTH-1 downto 0);
	RAM_D: inout std_logic_vector(RAM_WIDTH-1 downto 0);
	RAM_EN: out std_logic_vector(RAM_ENABLES-1 downto 0);
	RAM_WE, RAM_OE, RAM_CE1, RAM_CE2: out std_logic;
	CDIN: in std_logic;
	CINIT, CCLK: out std_logic;
	LED: out std_logic_vector(7 downto 0));
end FB;


architecture RTL of FB is

  component CLKGEN
    port (CLK: in std_logic;
	  RESET, MCLK, VCLK: out std_logic);
  end component;

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

  component RAM16XYD
    generic (Y: integer := 32);
    port (WE, WCLK: in std_logic;
	  A, DPRA: in std_logic_vector(3 downto 0);
	  D: in std_logic_vector(Y-1 downto 0);
	  SPO, DPO: out std_logic_vector(Y-1 downto 0));
  end component;

  signal MCLK, VCLK, RESET: std_logic;
  signal IN_HSYNC, IN_VSYNC, IN_BLANK: std_logic;
  signal IN_HADDR, IN_VADDR, IN_MADDR: integer;

  signal IN_A: std_logic_vector(RAM_DEPTH-1 downto 0);
  signal IN_DI, IN_DO: std_logic_vector(RAM_WIDTH-1 downto 0);
  signal IN_EN: std_logic_vector(RAM_ENABLES-1 downto 0);
  signal IN_RW: std_logic;
  signal RAM_RW: std_logic;

  signal CI0_A: std_logic_vector(CONFINIT_L-1 downto 0);
  signal CI0_D: std_logic_vector(2**CONFINIT_K-1 downto 0);
  signal CI0_STB, CI0_FIN: std_logic;
  constant CI0_UA: std_logic_vector(RAM_DEPTH-CONFINIT_L-1 downto 0)
	           := (others=>'0');

  signal RD0_WE: std_logic;
  signal RD0_A, RD0_DPRA: std_logic_vector(3 downto 0);
  signal RD0_D, RD0_SPO, RD0_DPO: std_logic_vector(RAM_WIDTH-1 downto 0);

  signal IN_RSTATE: std_logic;
  signal IN_RA: std_logic_vector(RAM_DEPTH-1 downto 0);
  signal IN_MA: std_logic_vector(RAM_DEPTH+1 downto 0);

begin

  -- Clock generator
  CLKGEN0: CLKGEN port map (CLK => CLK,
			    RESET => RESET,
			    MCLK => MCLK,
                            VCLK => VCLK);

  -- CRT controller
  CRTC0: CRTC port map (CLK => VCLK,
                        RESET => RESET,
			HSYNC => IN_HSYNC,
			VSYNC => IN_VSYNC,
			BLANK => IN_BLANK,
			HADDR => IN_HADDR,
			VADDR => IN_VADDR,
			MADDR => IN_MADDR);

  IN_MA <= CONV_STD_LOGIC_VECTOR(IN_MADDR, IN_MA'length);

  -- Asynchronous SRAM controller
  ASRAMC0: ASRAMC generic map (DEPTH => RAM_DEPTH,
			       WIDTH => RAM_WIDTH,
			       ENABLES => RAM_ENABLES)
                  port map (CLK => MCLK,
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
  RAM_CE2 <= '0';

  -- Configuration RAM initializer
  CI0: CONFINIT generic map (K => CONFINIT_K,
			     L => CONFINIT_L,
			     M => CONFINIT_M)
                port map (CLK => MCLK,
			  RESET => RESET,
			  A => CI0_A,
			  D => CI0_D,
			  STB => CI0_STB,
			  FIN => CI0_FIN,
			  CDIN => CDIN,
			  CINIT => CINIT,
			  CCLK => CCLK);

  IN_A <= CI0_UA & CI0_A when CI0_FIN = '0' else IN_RA;
  IN_DI <= CI0_D;
  IN_EN <= (others=>'0');
  IN_RW <= not CI0_STB when CI0_FIN = '0' else '1';

  --
  RD0: RAM16XYD generic map (Y => RAM_WIDTH)
                port map (WCLK => MCLK,
		          WE => RD0_WE,
			  A =>RD0_A,
			  DPRA =>RD0_DPRA,
			  D => RD0_D,
			  SPO => RD0_SPO,
			  DPO => RD0_DPO);

  RD0_D <= IN_DO;

  --
  process (MCLK, RESET)
  begin
    if RESET = '1' then
      IN_RSTATE <= '0';
      IN_RA <= (others=>'0');
      RD0_WE <= '0';
      RD0_A <= (others=>'0');
    elsif MCLK'event and MCLK = '1' then
      if IN_RSTATE = '0' then
        if IN_BLANK = '0' and IN_MA(5 downto 0) = "000000" then
	  IN_RA(RAM_DEPTH-1 downto 4) <= IN_MA(RAM_DEPTH+1 downto 6);
	  IN_RSTATE <= '1';
	end if;
      else
        IN_RA(3 downto 0) <= IN_RA(3 downto 0) + '1';
        if IN_RA(3 downto 0) = "1111" then
	  IN_RSTATE <= '0';
	end if;
      end if;
      RD0_WE <= IN_RSTATE; -- delay
      RD0_A <= IN_RA(3 downto 0); -- delay
    end if;
  end process;

  process (VCLK, RESET)
   variable DELAY0: std_logic_vector(8 downto 0);
   variable D_MA: std_logic_vector(1 downto 0);
   variable D_BLANK, D_HSYNC, D_VSYNC: std_logic;
  begin
    if RESET = '1' then
      HSYNC <= '1';
      VSYNC <= '1';
      VR <= '0';
      VG <= '0';
      VB <= '0';
      RD0_DPRA <= (others=>'0');
      D_MA := "00";
      D_BLANK := '0';
      D_HSYNC := '0';
      D_VSYNC := '0';
    elsif VCLK'event and VCLK = '1' then
      HSYNC <= D_HSYNC;
      VSYNC <= D_VSYNC;
      if D_BLANK = '1' then
	VR <= '0';
	VG <= '0';
	VB <= '0';
      else
	case D_MA(1 downto 0) is
	  when "00" =>
	    VR <= RD0_DPO(0);
	    VG <= RD0_DPO(1);
	    VB <= RD0_DPO(2);
	  when "01" =>
	    VR <= RD0_DPO(8);
	    VG <= RD0_DPO(9);
	    VB <= RD0_DPO(10);
	  when "10" =>
	    VR <= RD0_DPO(16);
	    VG <= RD0_DPO(17);
	    VB <= RD0_DPO(18);
	  when "11" =>
	    VR <= RD0_DPO(24);
	    VG <= RD0_DPO(25);
	    VB <= RD0_DPO(26);
	  when others =>
	    VR <= '0';
	    VG <= '0';
	    VB <= '0';
	end case;
      end if;
      -- Insert two VCLK delay...
      RD0_DPRA <= DELAY0(8 downto 5);
      D_MA := DELAY0(4 downto 3);
      D_BLANK := DELAY0(2);
      D_HSYNC := DELAY0(1);
      D_VSYNC := DELAY0(0);
      DELAY0 := IN_MA(5 downto 0) & IN_BLANK & IN_HSYNC & IN_VSYNC;
    end if;
  end process;

  --
  LED(7 downto 2) <= (others=>'0');
  LED(1) <= '1';
  LED(0) <= IN_RSTATE;

end RTL;
