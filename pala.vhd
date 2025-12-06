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

    elsif rising_edge(clk) then
        if refresh = '1' then
            posp      <= p_posp;
            velp      <= p_velp;
        end if;
    end if;
end process;


comb: process(posp, velp, cycle_cnt, left, right)
begin
    p_posp <= posp;
    p_velp <= velp;
    
    -- Movimiento horizontal
    if left = '1' then
        p_posp <= posp - velp;
    elsif right = '1' then
        p_posp <= posp + velp;
    end if;
end process;

accel: process(clk, reset)
begin
    if reset = '1' then
        p_velp    <= to_unsigned(3, 3);    -- velocidad inicial 3
        cycle_cnt <= to_unsigned(0, 6);    -- contador de ciclos
    elsif rising_edge(clk) then
        if left = '1' or right = '1' then
            -- incremento del contador
            if cycle_cnt = to_unsigned(59, 6) then  -- cada 60 ciclos
                cycle_cnt <= to_unsigned(0, 6);     -- reinicia contador
                if velp < to_unsigned(7, 3) then    -- saturación máxima 7
                    p_velp <= velp + 1;
                end if;
            else
                cycle_cnt <= cycle_cnt + 1;
            end if;
        else
            -- no se pulsa ningún botón 
            p_velp <= to_unsigned(3, 3);
            cycle_cnt <= to_unsigned(0, 6);
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
