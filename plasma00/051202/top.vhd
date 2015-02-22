-- $Id: top.vhd 54 2005-11-29 21:32:29Z yaegashi $
-- vim: set sw=2 sts=2:

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_unsigned.ALL;
use IEEE.std_logic_arith.ALL;

library work;
use work.mlite_pack.all;


entity TOP is
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
    RXD: in std_logic;
    TXD: out std_logic;
    LED: out std_logic_vector(7 downto 0);
    SEG_AN: out std_logic_vector(0 to 3);
    SEG_LED: out std_logic_vector(0 to 7));
end TOP;


architecture RTL of TOP is

  component CLKGEN
    port (CLK: in std_logic;
	  RESET, MCLK, VCLK: out std_logic);
  end component;

  component CONFINIT
    generic (
      K: integer := 5;
      L: integer := 14;
      M: integer := 16383);
    port (
      CLK, RESET: in std_logic;
      START: in std_logic;
      A: out std_logic_vector(L-1 downto 0);
      D: out std_logic_vector(2**K-1 downto 0);
      STB, FIN: out std_logic;
      CDIN: in std_logic;
      CINIT, CCLK: out std_logic);
  end component;

  component FB
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
  end component;

  component ASRAMC
    generic (
      DEPTH: integer := 18;
      WIDTH: integer := 32;
      ENABLES: integer := 4);
    port (
      CLK, RESET: in std_logic;
      A: in std_logic_vector(DEPTH-1 downto 0);
      DI: in std_logic_vector(WIDTH-1 downto 0);
      DO: out std_logic_vector(WIDTH-1 downto 0);
      EN: in std_logic_vector(ENABLES-1 downto 0);
      WR: in std_logic;
      BUSY: out std_logic;
      RAM_A: out std_logic_vector(DEPTH-1 downto 0);
      RAM_D: inout std_logic_vector(WIDTH-1 downto 0);
      RAM_EN: out std_logic_vector(ENABLES-1 downto 0);
      RAM_RW, RAM_OE: out std_logic);
  end component;

  component SERIO
    generic (W: integer := 5);
    port (CLK, RESET: in std_logic;
	  DIVIDER: in std_logic_vector(W-1 downto 0);
	  RXD: in std_logic;
	  TXD: out std_logic;
	  A, RD, WR: in std_logic;
	  DI: in std_logic_vector(7 downto 0);
	  DO: out std_logic_vector(7 downto 0));
  end component;

  component D7SEG
    generic (
      DIVIDER: integer := 15;
      DIGITS: integer := 4);
    port (
      CLK, RESET: in std_logic;
      D: in std_logic_vector(DIGITS*4-1 downto 0);
      AN: out std_logic_vector(0 to DIGITS-1);
      LED: out std_logic_vector(0 to 7));
  end component;

  constant ZERO32: std_logic_vector(31 downto 0) := (others=>'0');
  constant ONE32: std_logic_vector(31 downto 0) := (others=>'1');
  constant X32: std_logic_vector(31 downto 0) := (others=>'X');

  type SYSTEM_STATE is (
    AFTER_RESET, WAIT_CONFINIT, IN_OPERATION, WAIT_FB, WAIT_WRITE);
  signal SSTATE: SYSTEM_STATE;

  signal MCLK, VCLK, RESET: std_logic;

  signal RAM0_A: std_logic_vector(RAM_DEPTH-1 downto 0);
  signal RAM0_DI, RAM0_DO: std_logic_vector(RAM_WIDTH-1 downto 0);
  signal RAM0_EN: std_logic_vector(RAM_ENABLES-1 downto 0);
  signal RAM0_WR, RAM0_BUSY: std_logic;

  signal CI0_A: std_logic_vector(CONFINIT_L-1 downto 0);
  signal CI0_D: std_logic_vector(2**CONFINIT_K-1 downto 0);
  signal CI0_START, CI0_STB, CI0_FIN: std_logic;
  constant CI0_UA: std_logic_vector(RAM_DEPTH-CONFINIT_L-1 downto 0)
	           := (others=>'0');

  signal FB0_A: std_logic_vector(RAM_DEPTH-1 downto 0);
  signal FB0_D: std_logic_vector(RAM_WIDTH-1 downto 0);
  signal FB0_ACTIVE, FB0_PAUSE: std_logic;

  -- 57600*16 Hz = 25MHz / 27
  constant SERIO0_DIVIDER: std_logic_vector(4 downto 0) := "11011";
  signal SERIO0_DI, SERIO0_DO: std_logic_vector(7 downto 0);
  signal SERIO0_A, SERIO0_RD, SERIO0_WR: std_logic;

  signal MM0_INTR_IN, MM0_MEM_WRITE, MM0_PAUSE: std_logic;
  signal MM0_MEM_BYTE_SEL: std_logic_vector(RAM_ENABLES-1 downto 0);
  signal MM0_MEM_ADDRESS: std_logic_vector(31 downto 0);
  signal MM0_MEM_DATA_W, MM0_MEM_DATA_R: std_logic_vector(31 downto 0);

  signal SEG0_D: std_logic_vector(15 downto 0);

  signal CS_RAM0, CS_SERIO0: std_logic;

begin

  -- Clock generator
  CLKGEN0: CLKGEN
    port map (
      CLK => CLK,
      RESET => RESET,
      MCLK => open,
      VCLK => VCLK);
  MCLK <= VCLK;

  -- Asynchronous SRAM controller
  RAMC0: ASRAMC
    generic map (
      DEPTH => RAM_DEPTH,
      WIDTH => RAM_WIDTH,
      ENABLES => RAM_ENABLES)
    port map (
      CLK => MCLK,
      RESET => RESET,
      A => RAM0_A,
      DI => RAM0_DI,
      DO => RAM0_DO,
      EN => RAM0_EN,
      WR => RAM0_WR,
      BUSY => RAM0_BUSY,
      RAM_A => RAM_A,
      RAM_D => RAM_D,
      RAM_EN => RAM_EN,
      RAM_RW => RAM_WE,
      RAM_OE => RAM_OE);

  RAM_CE1 <= '0';
  RAM_CE2 <= '0';

  process (SSTATE, CI0_A, CI0_D, CI0_STB, MM0_MEM_ADDRESS, MM0_MEM_DATA_W,
           MM0_MEM_BYTE_SEL, MM0_MEM_WRITE, FB0_A, FB0_ACTIVE, CS_RAM0)
  begin
    if SSTATE = WAIT_CONFINIT then
      RAM0_A <= "0000" & CI0_A; -- XXX
      RAM0_DI <= CI0_D;
      RAM0_EN <= (others=>'1');
      RAM0_WR <= CI0_STB;
    elsif SSTATE = IN_OPERATION then
      RAM0_A <= MM0_MEM_ADDRESS(RAM_DEPTH+1 downto 2);
      RAM0_DI <= MM0_MEM_DATA_W;
      RAM0_EN <= MM0_MEM_BYTE_SEL;
      RAM0_WR <= MM0_MEM_WRITE and CS_RAM0 and not FB0_ACTIVE;
    elsif SSTATE = WAIT_FB then
      RAM0_A <= "11" & FB0_A(15 downto 0);
      RAM0_DI <= (others=>'X');
      RAM0_EN <= (others=>'X');
      RAM0_WR <= '0';
    elsif SSTATE = WAIT_WRITE then
      RAM0_A <= MM0_MEM_ADDRESS(RAM_DEPTH+1 downto 2);
      RAM0_DI <= MM0_MEM_DATA_W;
      RAM0_EN <= (others=>'X');
      RAM0_WR <= 'X';
    else
      RAM0_A <= (others=>'X');
      RAM0_DI <= (others=>'X');
      RAM0_EN <= (others=>'X');
      RAM0_WR <= 'X';
    end if;
  end process;

  -- Configuration RAM initializer
  CI0: CONFINIT
    generic map (
      K => CONFINIT_K,
      L => CONFINIT_L,
      M => CONFINIT_M)
    port map (
      CLK => MCLK,
      RESET => RESET,
      START => CI0_START,
      A => CI0_A,
      D => CI0_D,
      STB => CI0_STB,
      FIN => CI0_FIN,
      CDIN => CDIN,
      CINIT => CINIT,
      CCLK => CCLK);

  CI0_START <= '1' when SSTATE = AFTER_RESET else '0';

  -- FB
  FB0: FB
    generic map (
      WIDTH => RAM_WIDTH,
      DEPTH => RAM_DEPTH,
      DELAY => 6,
      PACK => 3)
    port map (
      MCLK => MCLK,
      VCLK => VCLK,
      RESET => RESET,
      VR => VR,
      VG => VG,
      VB => VB,
      HSYNC => HSYNC,
      VSYNC => VSYNC,
      ACTIVE => FB0_ACTIVE,
      A => FB0_A,
      D => FB0_D,
      PAUSE => FB0_PAUSE);

  FB0_D <= RAM0_DO;
  FB0_PAUSE <= '0' when SSTATE = WAIT_FB else '1';

  -- Serial I/O
  SERIO0: SERIO
    generic map (
      W => SERIO0_DIVIDER'length)
    port map (
      CLK => MCLK,
      RESET => RESET,
      DIVIDER => SERIO0_DIVIDER,
      RXD => RXD,
      TXD => TXD,
      DI => SERIO0_DI,
      DO => SERIO0_DO,
      A => SERIO0_A,
      RD => SERIO0_RD,
      WR => SERIO0_WR);

  SERIO0_DI <= MM0_MEM_DATA_W(7 downto 0);
  SERIO0_A <= MM0_MEM_ADDRESS(2);
  SERIO0_RD <= CS_SERIO0 and not MM0_MEM_WRITE;
  SERIO0_WR <= CS_SERIO0 and MM0_MEM_WRITE;

  -- mlite
  MM0: mlite_cpu
    generic map (
      memory_type => "DUAL_PORT_XILINX_XC4000XLA")
    port map (
      clk => MCLK,
      reset_in => RESET,
      intr_in => MM0_INTR_IN,
      mem_address => MM0_MEM_ADDRESS,
      mem_data_w => MM0_MEM_DATA_W,
      mem_data_r => MM0_MEM_DATA_R,
      mem_byte_sel => MM0_MEM_BYTE_SEL,
      mem_write => MM0_MEM_WRITE,
      mem_pause => MM0_PAUSE);

  MM0_MEM_DATA_R <= RAM0_DO when CS_RAM0 = '1' else
		    X32(31 downto 8) & SERIO0_DO when CS_SERIO0 = '1' else
		    (others=>'X');
  MM0_INTR_IN <= '0';
  process (SSTATE, MM0_MEM_WRITE, RAM0_BUSY)
  begin
    if SSTATE = IN_OPERATION then
      MM0_PAUSE <= CS_RAM0 and MM0_MEM_WRITE;
    elsif SSTATE = WAIT_WRITE then
      MM0_PAUSE <= RAM0_BUSY;
    else
      MM0_PAUSE <= '1';
    end if;
  end process;

  --
  SEG0: D7SEG
    port map (
      CLK => MCLK,
      RESET => RESET,
      D => SEG0_D,
      AN => SEG_AN,
      LED => SEG_LED);

  process (MCLK)
  begin
    if MCLK'event and MCLK = '1' then
      SEG0_D <= MM0_MEM_ADDRESS(15 downto 0);
    end if;
  end process;
  
  -- Chip/device selectors
  CS_RAM0 <= not MM0_MEM_ADDRESS(30);
  CS_SERIO0 <= MM0_MEM_ADDRESS(30);

  -- State machine for the system
  process (MCLK, RESET)
  begin
    if RESET = '1' then
      SSTATE <= AFTER_RESET;
    elsif MCLK'event and MCLK = '1' then
      if SSTATE = AFTER_RESET then
        if CI0_FIN = '0' then
	  SSTATE <= WAIT_CONFINIT;
	end if;
      elsif SSTATE = WAIT_CONFINIT then
        if SKIP_CONFINIT or CI0_FIN = '1' then
	  SSTATE <= WAIT_WRITE;
	end if;
      elsif SSTATE = IN_OPERATION then
        if FB0_ACTIVE = '1' then
	  SSTATE <= WAIT_FB;
	elsif CS_RAM0 = '1' and MM0_MEM_WRITE = '1' then
	  SSTATE <= WAIT_WRITE;
	end if;
      elsif SSTATE = WAIT_FB then
	if FB0_ACTIVE = '0' then
	  SSTATE <= IN_OPERATION;
	end if;
      elsif SSTATE = WAIT_WRITE then
        if RAM0_BUSY = '0' then
          SSTATE <= IN_OPERATION;
        end if;
      end if;
    end if;
  end process;

  --
  process(MCLK)
  begin
    if MCLK'event and MCLK = '1' then
      LED(3 downto 0) <= MM0_MEM_ADDRESS(19 downto 16);
      case SSTATE is
	when IN_OPERATION =>
	  LED(6 downto 4) <= "001";
	when WAIT_FB =>
	  LED(6 downto 4) <= "010";
	when WAIT_WRITE =>
	  LED(6 downto 4) <= "100";
	when others =>
	  LED(6 downto 4) <= "000";
      end case;
      LED(7) <= MM0_MEM_WRITE;
    end if;
  end process;

end RTL;
