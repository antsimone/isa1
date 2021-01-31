library ieee;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;

package iir_df2_sos_pkg is 
   constant N  : natural               := 8;
   constant NI : natural               := 11;

   constant b0 : signed(NI-1 downto 0) := to_signed(208, NI);
   constant b1 : signed(NI-1 downto 0) := to_signed(494, NI);
   constant b2 : signed(NI-1 downto 0) := to_signed(364, NI);
   constant b3 : signed(NI-1 downto 0) := to_signed(78 , NI);
   constant a1 : signed(NI-1 downto 0) := to_signed(-56, NI);
   constant a2 : signed(NI-1 downto 0) := to_signed(75 , NI);


end package; 
