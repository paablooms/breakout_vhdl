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
-- señales (ejemplo)

signal cycle_cnt  : unsigned(2 downto 0);   -- contador de refresh (0..4)

-- constantes
constant MAX_POS  : unsigned(9 downto 0) := to_unsigned(448, 10);
constant ACC_TICKS: integer := 5;  -- cambiar cada 5 ciclos

begin
-- proceso secuencial: actualiza posp, velp y cycle_cnt en cada rising_edge cuando refresh='1'
sinc: process(clk, reset)
begin
    if reset = '1' then
        posp      <= to_unsigned(223,10);
        velp      <= (others => '0');
        cycle_cnt <= (others => '0');
    elsif rising_edge(clk) then
        if refresh = '1' then

            -- Si no hay botón presionado -> reset velocidad y contador
            if (left = '0') and (right = '0') then
                velp      <= (others => '0');
                cycle_cnt <= (others => '0');

            else
                -- Hay un botón presionado -> incrementar contador
                if cycle_cnt = to_unsigned(ACC_TICKS-1, cycle_cnt'length) then
                    -- cuando el contador llega a ACC_TICKS, hacemos un paso de aceleración
                    if velp < "11" then
                        velp <= velp + 1;  -- satura en 3 (2 bits)
                    else
                        velp <= velp;
                    end if;
                    cycle_cnt <= (others => '0'); -- reinicia contador
                else
                    cycle_cnt <= cycle_cnt + 1;
                end if;
            end if;

            -- Actualización de posición usando la velocidad actual (velp)
            if left = '1' then
                -- evitar underflow: comparo con velp convertido
                if posp > to_unsigned(0, posp'length) + resize(velp, posp'length) then
                    posp <= posp - resize(velp, posp'length);
                else
                    posp <= (others => '0');
                end if;

            elsif right = '1' then
                if posp < MAX_POS - resize(velp, posp'length) then
                    posp <= posp + resize(velp, posp'length);
                else
                    posp <= MAX_POS;
                end if;
            end if;

        end if; -- refresh
    end if; -- rising_edge
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
