-- $Id: aueu.vhd 1 2005-11-15 00:49:01Z yaegashi $

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_unsigned.ALL;

entity AUEU is
  port(CLK: in std_logic;
       D: out std_logic_vector(7 downto 0);
       AN: out std_logic_vector(3 downto 0);
       SEG: out std_logic_vector(0 to 7)); -- a, b, c, d, e, f, g, dp
end AUEU;

architecture RTL of AUEU is
  signal IN_D: std_logic_vector(31 downto 0);
begin
  
  D <= IN_D(31 downto 24);
  
  process (IN_D)
  begin
    case IN_D(16 downto 15) is -- 50MHz/2**16 => 763Hz
      when "00" =>
        AN <= "1110"; SEG <= "10000011"; -- U
      when "01" =>
        AN <= "1101"; SEG <= "01100001"; -- E
      when "10" =>
        AN <= "1011"; SEG <= "10000011"; -- U
      when "11" =>
        AN <= "0111"; SEG <= "00010001"; -- A
      when others =>
        AN <= (others=>'X'); SEG <= (others=>'X');
    end case;
  end process;
  
  process (CLK)
  begin
    if (CLK'event and CLK = '1') then
      IN_D <= IN_D + '1';
    end if;
  end process;
  
end RTL;
