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
    Port ( clk : in std_logic;
           reset : in std_logic;
           left : in STD_LOGIC;
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
mov: process(clk, reset)
begin
    if reset = '1' then
        posp <= to_unsigned(223, 10);  -- posición inicial
    elsif rising_edge(clk) then
    -- valor por defecto para evitar latches
    posp <= posp;

    if refresh = '1' then
        if left = '1' then
            if posp > 0 then
                posp <= posp - 1;
            else
                posp <= posp;  -- alcanza límite inferior
            end if;

        elsif right = '1' then
            if posp < 512 then
                posp <= posp + 1;
            else
                posp <= posp;  -- alcanza límite superior
            end if;

        else
            posp <= posp;      -- ni left ni right
        end if;

    else
        posp <= posp;          -- sin refresh
    end if;
end if;
end process;


rgb: process(ejex,ejey,posp)
	begin
		if(unsigned(ejex) > posp and unsigned(ejex)<posp+64 and unsigned(ejey)>448 and unsigned(ejey)<464) then
			RGBpala <= "111100000000";
    else
			RGBpala <= (others => '0');
    end if;
    
end process;

RGBin <= RGBpala;

end Behavioral;
