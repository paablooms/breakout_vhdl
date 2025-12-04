----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 30.09.2025 19:12:12
-- Design Name: 
-- Module Name: frec_pixel - Behavioral
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

entity frec_pixel is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           clk_pixel : out STD_LOGIC);
end frec_pixel;



architecture Behavioral of frec_pixel is

signal cont : unsigned(1 downto 0);
signal clk_out : std_logic := '0';

begin
    process(clk,reset)
    begin
    if(reset = '1') then
        cont <= "00";
        clk_out <= '0';
        elsif rising_edge(clk) then
                if (cont = "11") then
                    clk_out <= '1';
                    cont <= "00";
                    else
                    clk_out <= '0';
                    cont <= cont+1;
                end if;
        end if;
    end process;
    
    clk_pixel <= clk_out;
end Behavioral;
