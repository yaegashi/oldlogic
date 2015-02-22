-- $Id: top.vhd 31 2005-11-28 15:56:09Z yaegashi $
-- vim: set sw=2 sts=2:

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_unsigned.ALL;
use IEEE.std_logic_arith.ALL;

entity SRAM is
  generic (W: integer := 18);
  port (
    D: inout std_logic_vector(31 downto 0);
    A: in std_logic_vector(W-1 downto 0);
    CE1, UB1, LB1, CE2, UB2, LB2, WE, OE: in std_logic);
end;

architecture behavior of sram is

  subtype RAMWORD is std_logic_vector(31 downto 0);
  type RAMARRAY is array (0 to 2**W-1) of RAMWORD;

  signal ADDRESS: integer := 0;
  signal RAMDATA: RAMARRAY := (
    "00000000000000000010100000100001", --     0: move      a1,zero
    "00111100000001100000000000001100", --     4: lui       a2,0xc
    "00111100000000100000000000001100", --     8: lui       v0,0xc
    "00110100010000100000001010000000", --     c: ori       v0,v0,0x280
    "00110000101001000000000011111111", --    10: andi      a0,a1,0xff
    "00110100110000110000000101000000", --    14: ori       v1,a2,0x140
    "10100000011001000000000000000000", --    18: sb        a0,0(v1)
    "00100100011000110000000000000001", --    1c: addiu     v1,v1,1
    "00010100011000101111111111111101", --    20: bne       v1,v0,18
    "00000000000000000000000000000000", --    24: nop
    "00001000000000000000000000000100", --    28: j 10
    "00100100101001010000000000000001", --    2c: addiu     a1,a1,1
    --
    "00000000000000000001100000100001",
    "10100000010000100000000010000000",
    "00001000000000000000000000000001",
    "00100100010000100000000000000001",
    others=>(others=>'0'));

begin

  ADDRESS <= conv_integer(A);
  
  process (WE)
  begin
    if WE'event and WE = '1' then
      if CE2 = '0' then
        if UB2 = '0' then
          RAMDATA(ADDRESS)(31 downto 24) <= D(31 downto 24);
        end if;
        if LB2 = '0' then
          RAMDATA(ADDRESS)(23 downto 16) <= D(23 downto 16);
        end if;
      end if;
      if CE1 = '0' then
        if UB1 = '0' then
          RAMDATA(ADDRESS)(15 downto 8) <= D(15 downto 8);
        end if;
        if LB1 = '0' then
          RAMDATA(ADDRESS)(7 downto 0) <= D(7 downto 0);
        end if;
      end if;
    end if;
  end process;

  process (CE1, LB1, UB1, CE2, LB2, UB2, OE, WE, ADDRESS)
  begin
    if CE2 = '0' and UB2 = '0' and OE = '0' and WE = '1' then
      D(31 downto 24) <= RAMDATA(ADDRESS)(31 downto 24);
    else
      D(31 downto 24) <= (others=>'Z');
    end if;
    if CE2 = '0' and LB2 = '0' and OE = '0' and WE = '1' then
      D(23 downto 16) <= RAMDATA(ADDRESS)(23 downto 16);
    else
      D(23 downto 16) <= (others=>'Z');
    end if;
    if CE1 = '0' and UB1 = '0' and OE = '0' and WE = '1' then
      D(15 downto 8) <= RAMDATA(ADDRESS)(15 downto 8);
    else
      D(15 downto 8) <= (others=>'Z');
    end if;
    if CE1 = '0' and LB1 = '0' and OE = '0' and WE = '1' then
      D(7 downto 0) <= RAMDATA(ADDRESS)(7 downto 0);
    else
      D(7 downto 0) <= (others=>'Z');
    end if;
  end process;

end behavior;
