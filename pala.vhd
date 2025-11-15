----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 15.11.2025 18:52:19
-- Design Name: 
-- Module Name: pala - Behavioral
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

entity pala is
    Port ( left : in STD_LOGIC;
           right : in STD_LOGIC;
           ejex : in STD_LOGIC_VECTOR(9 downto 0);
           ejey : in STD_LOGIC_VECTOR(9 downto 0);
           refresh : in STD_LOGIC;
           pos_p : out std_logic_vector(9 downto 0);
           RGBin : out STD_LOGIC_VECTOR (11 downto 0));
end pala;

architecture Behavioral of pala is

signal posp : unsigned(9 downto 0) := "0011111111";
signal RGBpala : STD_LOGIC_VECTOR (11 downto 0);

begin 
mov: process(left,right,refresh)
begin

	if (left = '1' and posp > 32 and refresh = '1') then
		posp <= posp - 1;
	else
		posp <= posp;
	end if;
	if (right = '1' and posp < 480 and refresh = '1') then
		posp <= posp + 1;
	else
		posp <= posp;
	end if;
	
end process;

rgb: process(ejex,ejey)
	begin
		if(unsigned(ejex) > posp-40 and unsigned(ejex)<posp+40 and unsigned(ejey)>10 and unsigned(ejey)<30) then
			RGBpala <= "111100000000";
    else
			RGBpala <= (others => '0');

    end if;
end process;

RGBin <= RGBpala;

end Behavioral;
