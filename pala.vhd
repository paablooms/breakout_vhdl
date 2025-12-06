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

signal posp, p_posp : unsigned(9 downto 0) := "0011111111";
signal RGBpala : STD_LOGIC_VECTOR (11 downto 0);
signal velp, p_velp : unsigned (2 downto 0);
signal cycle_cnt : unsigned(5 downto 0);   -- cuenta hasta 4 (5 ciclos)

begin
sinc: process(clk, reset)
begin
    if reset = '1' then
        posp      <= to_unsigned(223,10);
        velp      <= "011";  -- velocidad inicial 3
        cycle_cnt <= (others => '0');

    elsif rising_edge(clk) then
        if refresh = '1' then
            posp      <= p_posp;
            velp      <= p_velp;
            cycle_cnt <= cycle_cnt;  -- actualizado abajo en comb
        end if;
    end if;
end process;


comb: process(posp, velp, cycle_cnt, left, right)
begin
    p_posp <= posp;
    p_velp <= velp;

    -- Si no pulsas, solo reinicia el contador, no la velocidad
    if left = '0' and right = '0' then
        cycle_cnt <= (others => '0');  -- reinicia contador
    else
        -- Mantengo pulsado → incrementar contador
        if cycle_cnt = "111011" then  -- 59 = ciclo 60
            cycle_cnt <= (others => '0');  -- reinicia contador
            if velp < "111" then           -- saturación a 7
                p_velp <= velp + 1;
            end if;
        else
            cycle_cnt <= cycle_cnt + 1;
        end if;
    end if;

    -- Movimiento horizontal
    if left = '1' then
        p_posp <= posp - velp;
    elsif right = '1' then
        p_posp <= posp + velp;
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
