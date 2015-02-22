---------------------------------------------------------------------
-- TITLE: Arithmetic Logic Unit
-- AUTHOR: Steve Rhoads (rhoadss@yahoo.com)
-- DATE CREATED: 2/8/01
-- FILENAME: alu.vhd
-- PROJECT: Plasma CPU core
-- COPYRIGHT: Software placed into the public domain by the author.
--    Software 'as is' without warranty.  Author liable for nothing.
-- DESCRIPTION:
--    Implements the ALU.
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.mlite_pack.all;

entity alu is
   generic(adder_type : string := "DEFAULT";
           alu_type   : string := "DEFAULT");
   port(a_in         : in  std_logic_vector(31 downto 0);
        b_in         : in  std_logic_vector(31 downto 0);
        alu_function : in  alu_function_type;
        c_alu        : out std_logic_vector(31 downto 0));
end; --alu

architecture logic of alu is
   signal aa, bb, sum : std_logic_vector(32 downto 0);
   signal do_add      : std_logic;
   signal sign_ext    : std_logic;
begin

   do_add <= '1' when alu_function = ALU_ADD else '0';
   sign_ext <= '0' when alu_function = ALU_LESS_THAN else '1';
   aa <= (a_in(31) and sign_ext) & a_in;
   bb <= (b_in(31) and sign_ext) & b_in;

   -- synthesis translate_off
   GENERIC_ALU: if alu_type = "DEFAULT" generate
   -- synthesis translate_on

      c_alu <= sum(31 downto 0) when alu_function=ALU_ADD or alu_function=ALU_SUBTRACT else
               ZERO(31 downto 1) & sum(32) when alu_function=ALU_LESS_THAN or alu_function=ALU_LESS_THAN_SIGNED else
               a_in or  b_in    when alu_function=ALU_OR else
               a_in and b_in    when alu_function=ALU_AND else
               a_in xor b_in    when alu_function=ALU_XOR else
               a_in nor b_in    when alu_function=ALU_NOR else
               ZERO;

   -- synthesis translate_off
   end generate;
   -- synthesis translate_on

   -- Get the synthesizer to infer a proper addsub primitive.
   primitive_addsub: if adder_type = "DEFAULT" generate
      sum <= aa + bb when do_add = '1' else aa - bb;
   end generate; --primitive_addsub

   -- synopsys synthesis_off

   AREA_OPTIMIZED_ALU: if alu_type="AREA_OPTIMIZED" generate
    
      c_alu <= sum(31 downto 0) when alu_function=ALU_ADD or alu_function=ALU_SUBTRACT else (others => 'Z');
      c_alu <= ZERO(31 downto 1) & sum(32) when alu_function=ALU_LESS_THAN or alu_function=ALU_LESS_THAN_SIGNED else (others => 'Z');
      c_alu <= a_in or  b_in    when alu_function=ALU_OR else (others => 'Z');
      c_alu <= a_in and b_in    when alu_function=ALU_AND else (others => 'Z');
      c_alu <= a_in xor b_in    when alu_function=ALU_XOR else (others => 'Z');
      c_alu <= a_in nor b_in    when alu_function=ALU_NOR else (others => 'Z');
      c_alu <= ZERO             when alu_function=ALU_NOTHING else (others => 'Z');
    
   end generate;
    
   generic_adder: if adder_type = "DEFAULT" generate
      sum <= bv_adder(aa, bb, do_add);
   end generate; --generic_adder
   
   --For Altera
   lpm_adder: if adder_type = "ALTERA" generate
      lpm_add_sub_component : lpm_add_sub
      GENERIC MAP (
         lpm_width => 33,
         lpm_direction => "UNUSED",
         lpm_type => "LPM_ADD_SUB",
         lpm_hint => "ONE_INPUT_IS_CONSTANT=NO"
      )
      PORT MAP (
         dataa => aa,
         add_sub => do_add,
         datab => bb,
         result => sum
      );
   end generate; --lpm_adder

   -- synopsys synthesis_on

end; --architecture logic

