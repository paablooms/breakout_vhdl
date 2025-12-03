----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.11.2025 18:55:41
-- Design Name: 
-- Module Name: draw_bloque - Behavioral
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

entity draw_bloque is
  Port (
    data_out_B: in std_logic;  --bit leído de la RAM que te dice si hay bloque ahí o no
    ejex: in std_logic_vector(9 downto 0); --coordenada x del píxel actual
    ejey: in std_logic_vector(9 downto 0); --coordenada y del píxel actual
    ADDR_B: out std_logic_vector(7 downto 0); --dirección en memoria
    RGB_bloque: out std_logic_vector(11 downto 0)); --ccolor del bloque
end draw_bloque;

architecture Behavioral of draw_bloque is

begin

process(ejex, ejey, data_out_b)
begin

    
    ADDR_B(3 downto 0) <= ejex(8 downto 5); --32 de ancho
    ADDR_B(7 downto 4) <= ejey(7 downto 4); --16 de alto
    
    --  ¿hay bloque? ¿está el bloque en la zona específica para los bloques?
    if (data_out_B = '1') and  (unsigned(ejex) < to_unsigned(512, 10)) and
   (unsigned(ejey) < to_unsigned(256, 10)) then
        RGB_bloque <= "000000001111"; --dibuja el bloque
    else
        RGB_bloque <= "000000000000"; -- no hagas nada
    end if;
    end process;  

end Behavioral;
