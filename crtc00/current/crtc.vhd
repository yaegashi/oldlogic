-- $Id: crtc.vhd 4 2005-11-16 18:28:02Z yaegashi $

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_unsigned.ALL;
use IEEE.std_logic_arith.ALL;

library UNISIM;
use UNISIM.vcomponents.ALL;


entity CRTC is
  generic (H0: integer := 640;
           H1: integer := 656;
	   H2: integer := 752;
	   H3: integer := 800;
	   V0: integer := 480;
	   V1: integer := 490;
	   V2: integer := 492;
	   V3: integer := 521;
	   WIDTH: integer := 6);
  port (CLK: in std_logic;
        VR, VG, VB, VH, VV: out std_logic);
end CRTC;


architecture RTL of CRTC is

  -- XXX: signals for the internal clock generation and reset.
  signal CLK0, RESET: std_logic;
  signal CLK_BUF, CLK_OUT, CLK0_BUF, CLK0_OUT, CLKDV_BUF, CLKDV_OUT: std_logic;

  -- CRTC signals.
  signal CH: integer range 0 to H3-1;
  signal CV: integer range 0 to V3-1;
  signal IH, IV, BH, BV: std_logic;

  -- Intermediate signals for a test pattern.
  signal AV, AH, HPV, HMV: std_logic_vector(WIDTH-1 downto 0);

begin

  -- Reset On Configuration
  ROC0: ROC port map (O => RESET);

  -- Global clock buffers
  IBUFG0: IBUFG port map (I => CLK_BUF, O => CLK_OUT);
  BUFG0: BUFG port map (I => CLK0_BUF, O => CLK0_OUT);
  BUFG1: BUFG port map (I => CLKDV_BUF, O => CLKDV_OUT);

  -- Digital Clock Manager
  DCM0: DCM generic map (CLKDV_DIVIDE => 2.0)
            port map (CLKIN => CLK_OUT,
	              CLKFB => CLK0_OUT,
		      CLK0 => CLK0_BUF,
		      CLKDV => CLKDV_BUF);

  CLK_BUF <= CLK;
  CLK0 <= CLKDV_OUT;

  -- Managing CRTC counters
  process (RESET, CLK0)
  begin
    if RESET = '1' then
      CH <= 0;
      CV <= 0;
    elsif CLK0'event and CLK0 = '1' then
      if CH = H3-1 then
        CH <= 0;
        if CV = V3-1 then
	  CV <= 0;
        else
	  CV <= CV + 1;
	end if;
      else
        CH <= CH + 1;
      end if;
    end if;
  end process;

  -- Generating H/V sync signals and blanking flags
  process (RESET, CLK0)
  begin
    if RESET = '1' then
      IH <= '1';
      IV <= '1';
      BH <= '0';
      BV <= '0';
    elsif CLK0'event and CLK0 = '1' then
      if CH = H1-1 or CH = H2-1 then
        IH <= not IH;
      end if;
      if CH = H0-1 or CH = H3-1 then
        BH <= not BH;
      end if;
      if CH = H3-1 then
        if CV = V1-1 or CV = V2-1 then
	  IV <= not IV;
	end if;
	if CV = V0-1 or CV = V3-1 then
	  BV <= not BV;
	end if;
      end if;
    end if;
  end process;

  VH <= IH;
  VV <= IV;

  -- Generating a test pattern
  AH <= CONV_STD_LOGIC_VECTOR(CH, AH'length);
  AV <= CONV_STD_LOGIC_VECTOR(CV, AV'length);
  HPV <= AH + AV;
  HMV <= AH - AV;

  process (BH, BV, HPV, HMV, AV)
  begin
    if BH = '1' or BV = '1' then
      VR <= '0';
      VG <= '0';
      VB <= '0';
    else
      VR <= HPV(HPV'left);
      VG <= HMV(HMV'left);
      VB <= AV(AV'left);
    end if;
  end process;
  
end RTL;
