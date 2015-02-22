-- $Id: d7seg.vhd 53 2005-11-29 19:31:59Z yaegashi $
-- vim: set sw=2 sts=2:

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_unsigned.ALL;

entity D7SEG is
  generic (
    DIVIDER: integer := 15;
    DIGITS: integer := 4);
  port (
    CLK, RESET: in std_logic;
    D: in std_logic_vector(DIGITS*4-1 downto 0);
    AN: out std_logic_vector(0 to DIGITS-1);
    LED: out std_logic_vector(0 to 7));
end;


architecture RTL of D7SEG is

  constant ZERO: std_logic_vector(DIVIDER-1 downto 0) := (others=>'0');
  signal COUNTER: std_logic_vector(DIVIDER-1 downto 0);
  signal DIGIT: integer range 0 to DIGITS-1;
  signal IN_D: std_logic_vector(3 downto 0);

begin

  process (RESET, CLK)
  begin
    if RESET = '1' then
      COUNTER <= (others=>'0');
      DIGIT <= 0;
    elsif CLK'event and CLK = '1' then
      COUNTER <= COUNTER + '1';
      if COUNTER = ZERO then
	if DIGIT = DIGITS-1 then
	  DIGIT <= 0;
	else
	  DIGIT <= DIGIT + 1;
	end if;
      end if;
    end if;
  end process;

  IN_D <= D(DIGIT*4+3 downto DIGIT*4);
  LED(7) <= '1';
  process (IN_D, DIGIT)
  begin
    case IN_D is
      when "0000" => LED(0 to 6) <= "0000001";
      when "0001" => LED(0 to 6) <= "1001111";
      when "0010" => LED(0 to 6) <= "0010010";
      when "0011" => LED(0 to 6) <= "0000110";
      when "0100" => LED(0 to 6) <= "1001100";
      when "0101" => LED(0 to 6) <= "0100100";
      when "0110" => LED(0 to 6) <= "0100000";
      when "0111" => LED(0 to 6) <= "0001111";
      when "1000" => LED(0 to 6) <= "0000000";
      when "1001" => LED(0 to 6) <= "0000100";
      when "1010" => LED(0 to 6) <= "0001000";
      when "1011" => LED(0 to 6) <= "1100000";
      when "1100" => LED(0 to 6) <= "0110001";
      when "1101" => LED(0 to 6) <= "1000010";
      when "1110" => LED(0 to 6) <= "0110000";
      when "1111" => LED(0 to 6) <= "0111000";
      when others => LED(0 to 6) <= (others=>'X');
    end case;
    for i in 0 to DIGITS-1 loop
      if i = DIGIT then
	AN(i) <= '0';
      else
        AN(i) <= '1';
      end if;
    end loop;
  end process;

end RTL;
