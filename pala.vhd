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
signal velp : unsigned (1 downto 0);
signal p_velp    : unsigned(1 downto 0);   -- siguiente velocidad
signal cycle_cnt : unsigned(2 downto 0);   -- cuenta hasta 4 (5 ciclos)

begin
sinc: process(clk, reset)
begin
    if reset = '1' then
        posp      <= to_unsigned(223,10);
        velp      <= (others => '0');
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

    p_posp    <= posp;
    p_velp    <= velp;

    if left = '0' and right = '0' then
        -- si suelto botones → velocidad a 0 y contador a 0
        p_velp       <= (others => '0');
        cycle_cnt    <= (others => '0');

    else
        -- mantengo pulsado → incrementar contador
        if cycle_cnt = "100" then   -- valor 4 (ciclo número 5)
            cycle_cnt <= (others => '0');   -- reinicia para la próxima aceleración

            -- acelerar con saturación a "11"
            if velp < "11" then
                p_velp <= velp + 1;
            else
                p_velp <= velp;
            end if;

        else
            cycle_cnt <= cycle_cnt + 1;
        end if;
    end if;

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
