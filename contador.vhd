----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 30.09.2025 18:09:47
-- Design Name: 
-- Module Name: contador - Behavioral
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

entity contador is
    GENERIC (Nbit: INTEGER := 8);
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           enable : in STD_LOGIC;
           resets : in STD_LOGIC;
           Q : out std_logic_vector(Nbit-1 downto 0)
           );
end contador;

architecture Behavioral of contador is

signal cuenta: unsigned(Nbit-1 downto 0);

begin

Process(clk,reset, resets, cuenta)
    begin
        if(reset = '1') then
            cuenta <= (others=>'0');
        elsif(rising_edge(clk)) then
            if (resets='1') then
                    cuenta <= (others=>'0');
            else
            if(enable = '0') then
                cuenta <= cuenta;     
                else
                    cuenta <= cuenta + 1;
                end if;
            end if;
        end if;
                
        Q <= std_logic_vector(cuenta);
        
end process;

end Behavioral;
