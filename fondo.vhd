----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 25.11.2025 13:32:17
-- Design Name: 
-- Module Name: fondo - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity fondo is
    Generic(
           posx : unsigned(9 downto 0) := to_unsigned(455,10);
           posy : unsigned(9 downto 0) := to_unsigned(256,10)
           );
    Port ( ejex : in STD_LOGIC_VECTOR(9 downto 0);
           ejey : in STD_LOGIC_VECTOR(9 downto 0);
           RGBin : out STD_LOGIC_VECTOR (11 downto 0));
end fondo;

architecture Behavioral of fondo is
 
signal RGBfondo : STD_LOGIC_VECTOR (11 downto 0);

begin process(ejex,ejey)
begin 

	if(unsigned(ejex)<511) then
		RGBfondo <= (others => '0');
	else
		RGBfondo <= (others => '1');
	end if;
end process;

RGBin <=  RGBfondo;

end Behavioral;
