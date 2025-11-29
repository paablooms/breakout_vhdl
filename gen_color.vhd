----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.10.2025 20:53:28
-- Design Name: 
-- Module Name: gen_color - Behavioral
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

entity gen_color is
    Port (         
        blank_h : in STD_LOGIC;
        blank_v : in STD_LOGIC;
        RGBin : in STD_LOGIC_VECTOR (11 downto 0);
        RGBout : out STD_LOGIC_VECTOR (11 downto 0));
        
end gen_color;

architecture Behavioral of gen_color is

begin
    gen_color: process(Blank_H, Blank_V, RGBin)
    begin
        if (Blank_H='1' or Blank_V='1') then
            RGBout <= (others => '0'); 
        else
            RGBout <= RGBin;
        end if;
    end process;
end Behavioral;
