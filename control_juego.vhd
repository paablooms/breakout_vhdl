----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.11.2025 11:35:17
-- Design Name: 
-- Module Name: control_juego - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

--Para aclarar un poco lo que hace este programa. Estará controlado por otro más top,
--, irá recorriendo cada píxel de la pantalla y tendrá que ver cuándo quieren pintar en el 
-- mismo pixel un bloque y una pala, bloque-bola, etc...

entity control_juego is
 Port (
    clk,reset : in std_logic;

-- RGBs de entrada (son los que tenemos que comparar)
    RGB_bola   : in  std_logic_vector(11 downto 0);
    RGB_bloque : in  std_logic_vector(11 downto 0);
    RGB_pala   : in  std_logic_vector(11 downto 0);

    -- Intercambio con bloques
    data_bloque  : out std_logic_vector(3 downto 0);
    valid_bloque : out std_logic;
    ready_bloque : in  std_logic;

    -- 
    RGB_in     : out std_logic_vector(11 downto 0);

    -- Interfaz con "bola"
    data_bola  : out std_logic_vector(3 downto 0);
    valid_bola : out std_logic;
    ready_bola : in  std_logic
      );
end control_juego;

architecture Behavioral of control_juego is

type tipo_estado is (
     REPOSO, TX_AXI_BOLA_CHOQUE_LADRILLO, TX_AXI_BLOQUE_BORRAR,TX_AXI_BOLA_CHOQUE_PALA
);
signal estado, p_estado: tipo_estado;

begin


-- esto me chirría un poco porque funciona bien cuando no colisionan, pero si colisionan 
-- hace una mezcla de colores o algo así (corregir)
RGB_in <= RGB_bola or RGB_bloque or RGB_pala;


------------------------------------------------------------------
-- Proceso secuencial 
------------------------------------------------------------------
    sinc: process(clk)
    begin
        if rising_edge(clk) then
        
            if(reset='1') then
                --valores iniciales del programa (hay que modificarlo)
                estado <= reposo;
            
            else
                estado <= p_estado;  
            
            end if;
        end if;
    end process;


 -----------------------------------------------------------
    -- Proceso combinacional 
    -----------------------------------------------------------
    process(estado,ready_bola, ready_bloque, RGB_bloque, RGB_bola, RGB_pala)
    begin 
    
    data_bola    <= (others => '0');
    valid_bola   <= '0';

    data_bloque  <= (others => '0');
    valid_bloque <= '0';
    
        case estado is
       
            when REPOSO => 
                -- choque bola con bloque
                if(RGB_bola /= (others => '0')) and 
                (RGB_bloque /= (others => '0')) then
                    p_estado <= TX_AXI_BOLA_CHOQUE_LADRILLO;
                    
                -- choque bola con pala 
                elsif(RGB_bola /= (others => '0')) and
                (RGB_pala /= (others => '0')) then
                    p_estado <= TX_AXI_BOLA_CHOQUE_PALA;
                    
                end if;
                
            when TX_AXI_BOLA_CHOQUE_PALA => 
                data_bola <= "0000";
                valid_bola <= '1';
                
                -- aceptación del protocolo AXI
                if (ready_bola = '1') then
                    p_estado <= REPOSO;
                end if;
                
            when TX_AXI_BOLA_CHOQUE_LADRILLO => 
                data_bola <= "0001";
                valid_bola <= '1';
                
                if (ready_bola = '1') then
                    p_estado <= TX_AXI_BLOQUE_BORRAR;
                end if;
                
             when TX_AXI_BLOQUE_BORRAR =>
                -- esta parte es la que no sé las condiciones que tengo que poner 
                -- no entiendo muy bien qué hace data_bloque 
                -- voy a suponer un valor por ahora  
                data_bloque <= "0000";
                valid_bloque <= '1'; 
                
                if (ready_bloque = '1') then 
                    p_estado <= REPOSO;
                end if;
       end case;     
  end process;
                
                

end Behavioral;
