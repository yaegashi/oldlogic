-- $Id: fb.vhd 46 2005-11-29 04:07:40Z yaegashi $
-- vim: set sw=2 sts=2:

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_unsigned.ALL;
use IEEE.std_logic_arith.ALL;


entity FB is
  generic (
    WIDTH: integer := 32;
    DEPTH: integer := 18;
    DELAY: integer := 4;
    PACK: integer := 3);
  port (
    MCLK, VCLK, RESET: in std_logic;
    VR, VG, VB, HSYNC, VSYNC: out std_logic;
    ACTIVE: out std_logic;
    A: out std_logic_vector(DEPTH-1 downto 0);
    D: in std_logic_vector(WIDTH-1 downto 0);
    PAUSE: in std_logic);
end FB;


architecture RTL of FB is

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

  component RAM16XYD
    generic (Y: integer := 32);
    port (WE, WCLK: in std_logic;
	  A, DPRA: in std_logic_vector(3 downto 0);
	  D: in std_logic_vector(Y-1 downto 0);
	  SPO, DPO: out std_logic_vector(Y-1 downto 0));
  end component;

  signal IN_HSYNC, IN_VSYNC, IN_BLANK: std_logic;
  signal IN_HADDR, IN_VADDR, IN_MADDR: integer;

  signal RD0_WE: std_logic;
  signal RD0_A, RD0_DPRA: std_logic_vector(3 downto 0);
  signal RD0_DPO: std_logic_vector(WIDTH-1 downto 0);

  signal IN_RSTATE: std_logic;
  signal IN_RA: std_logic_vector(DEPTH-1 downto 0);
  signal IN_MA: std_logic_vector(DEPTH-1+PACK downto 0);

begin

  -- CRT controller
  CRTC0: CRTC
    port map (
      CLK => VCLK,
      RESET => RESET,
      HSYNC => IN_HSYNC,
      VSYNC => IN_VSYNC,
      BLANK => IN_BLANK,
      HADDR => IN_HADDR,
      VADDR => IN_VADDR,
      MADDR => IN_MADDR);

  IN_MA <= CONV_STD_LOGIC_VECTOR(IN_MADDR, IN_MA'length);

  --
  RD0: RAM16XYD
    generic map (
      Y => WIDTH)
    port map (
      WCLK => MCLK,
      WE => RD0_WE,
      A => RD0_A,
      DPRA =>RD0_DPRA,
      D => D,
      SPO => open,
      DPO => RD0_DPO);

  RD0_WE <= IN_RSTATE;
  RD0_A <= IN_RA(3 downto 0);

  --
  process (MCLK, RESET)
    constant ZERO: std_logic_vector(PACK+3 downto 0) := (others=>'0');
  begin
    if RESET = '1' then
      IN_RSTATE <= '0';
      IN_RA <= (others=>'0');
    elsif MCLK'event and MCLK = '1' then
      if IN_RSTATE = '0' then
        if IN_BLANK = '0' and IN_MA(PACK+3 downto 0) = ZERO then
	  IN_RA(DEPTH-1 downto 4) <= IN_MA(DEPTH-1+PACK downto 4+PACK);
	  IN_RSTATE <= '1';
	end if;
      elsif PAUSE = '0' then
        IN_RA(3 downto 0) <= IN_RA(3 downto 0) + '1';
        if IN_RA(3 downto 0) = "1111" then
	  IN_RSTATE <= '0';
	end if;
      end if;
    end if;
  end process;

  A <= IN_RA;
  ACTIVE <= IN_RSTATE;

  process (VCLK, RESET)
    subtype DELAYELEMENTTYPE is std_logic_vector(PACK+6 downto 0);
    type DELAYARRAYTYPE is array(0 to DELAY-1) of DELAYELEMENTTYPE;
    variable DELAYARRAY: DELAYARRAYTYPE;
    variable D_MA: std_logic_vector(PACK-1 downto 0);
    variable D_BLANK, D_HSYNC, D_VSYNC: std_logic;
  begin
    if RESET = '1' then
      HSYNC <= '1';
      VSYNC <= '1';
      VR <= '0';
      VG <= '0';
      VB <= '0';
      RD0_DPRA <= (others=>'0');
      D_MA := (others=>'0');
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
	-- XXX
	case D_MA(2 downto 0) is
	  when "000" =>
	    VR <= RD0_DPO(0);
	    VG <= RD0_DPO(1);
	    VB <= RD0_DPO(2);
	  when "001" =>
	    VR <= RD0_DPO(4);
	    VG <= RD0_DPO(5);
	    VB <= RD0_DPO(6);
	  when "010" =>
	    VR <= RD0_DPO(8);
	    VG <= RD0_DPO(9);
	    VB <= RD0_DPO(10);
	  when "011" =>
	    VR <= RD0_DPO(12);
	    VG <= RD0_DPO(13);
	    VB <= RD0_DPO(14);
	  when "100" =>
	    VR <= RD0_DPO(16);
	    VG <= RD0_DPO(17);
	    VB <= RD0_DPO(18);
	  when "101" =>
	    VR <= RD0_DPO(20);
	    VG <= RD0_DPO(21);
	    VB <= RD0_DPO(22);
	  when "110" =>
	    VR <= RD0_DPO(24);
	    VG <= RD0_DPO(25);
	    VB <= RD0_DPO(26);
	  when "111" =>
	    VR <= RD0_DPO(28);
	    VG <= RD0_DPO(29);
	    VB <= RD0_DPO(30);
	  when others =>
	    VR <= '0';
	    VG <= '0';
	    VB <= '0';
	end case;
      end if;
      -- Insert four VCLK delay...
      RD0_DPRA <= DELAYARRAY(0)(PACK+6 downto PACK+3);
      D_MA := DELAYARRAY(0)(PACK+2 downto 3);
      D_BLANK := DELAYARRAY(0)(2);
      D_HSYNC := DELAYARRAY(0)(1);
      D_VSYNC := DELAYARRAY(0)(0);
      for i in 0 to DELAY-2 loop
        DELAYARRAY(i) := DELAYARRAY(i+1);
      end loop;
      DELAYARRAY(DELAY-1) :=
	IN_MA(PACK+3 downto 0) & IN_BLANK & IN_HSYNC & IN_VSYNC;
    end if;
  end process;

end RTL;
