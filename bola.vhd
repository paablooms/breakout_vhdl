----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.11.2025 15:12:28
-- Design Name: 
-- Module Name: bola - Behavioral
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


entity bola is
  Port (
        clk: in std_logic;
        reset: in std_logic;
        refresh: in std_logic;
        ejex: in std_logic_vector(9 downto 0); --coordenada x de la bola
        ejey: in std_logic_vector(9 downto 0); -- coordenada y de la bola
        data_bola: in std_logic_vector(3 downto 0);
        valid_bola: in std_logic;
        ready_bola: out std_logic;
        RGBbola: out std_logic_vector(12 downto 0)
        );
end bola;

architecture Behavioral of bola is

-- definimos constantes con la altura y ancho de la pantalla
constant WIDTH  : natural := 512;
constant HEIGHT : natural := 480;

-- constantes sobre los límites de pantalla
-- una vez tengamos el radio de la bola los deberíamos modificar
constant XMIN      : unsigned(9 downto 0) := to_unsigned(0, 10);
constant XMAX      : unsigned(9 downto 0) := to_unsigned(WIDTH-1, 10);
constant YMIN      : unsigned(9 downto 0) := to_unsigned(0, 10);
constant YMAX      : unsigned(9 downto 0) := to_unsigned(HEIGHT-1, 10);

signal posx, p_posx: unsigned(9 downto 0);
signal posy, p_posy: unsigned(9 downto 0);
signal velx, p_velx: unsigned(9 downto 0); --cuántos pixeles le vamos a sumar cada vez que se mueve
signal vely, p_vely: unsigned(9 downto 0); -- cuántos pixeles se desplaza a la izquierda
signal arriba, p_arriba: std_logic; --1 (arriba), 0(abajo)
signal dcha, p_dcha: std_logic; --1 (derecha), 0(abajo)
type tipo_estado is (
     REPOSO, MOVER, CHOQUE_PALA
);
signal estado, p_estado: tipo_estado;

begin


------------------------------------------------------------------
-- Proceso secuencial 
------------------------------------------------------------------
    sinc: process(clk)
    begin
        if rising_edge(clk) then
        
            if(reset='1') then
                --valores iniciales de la bola
                estado <= reposo;
                posx <= to_unsigned(256,10); --la ponemos en el arriba
                posy <= to_unsigned(240,10);
                velx <= to_unsigned(1,10);
                vely <= to_unsigned(1,10);
                arriba <= '1';
                dcha <= '1';
            
            else
                estado <= p_estado;
                posx <= p_posx;
                posy <= p_posy;
                velx <= p_velx;
                vely <= p_vely;
                arriba <= p_arriba;
                dcha <= p_dcha;   
            
            end if;
        end if;
    end process;
    
    
    
    -----------------------------------------------------------
    -- Proceso combinacional 
    -----------------------------------------------------------
    process(estado,posx,posy,arriba,dcha)
    begin 
        case estado is
       
            when REPOSO =>
                ready_bola <= '1';
                if(valid_bola='1' and data_bola="0000") then
                    p_estado <= CHOQUE_PALA;
                elsif (refresh='1') then
                    p_estado <= MOVER;
                else
                    p_estado <= REPOSO;
                end if;
                
            when MOVER =>
                -- aquí hay que hacer toda la lógica dependiendo de arriba
                -- velocidad y todas esas cosas
                
                -- Comprobamos primero el derecha/izquierda
                if(dcha='1') then
                    -- condición de que no desborde ( mi pantalla va a ser de 512X480)
                       if (posx + velx <= XMAX) then
                          p_posx <= posx + velx;
                       else 
                          p_posx <= XMAX;
                          p_dcha <= '0'; -- rebote hacia el otro lado
                       end if;
                else
                    -- Condición de que no desborde por la izquierda
                      if (posx - velx <= XMIN) then
                          p_posx <= XMIN;
                          p_dcha <= '1';
                      else
                          p_posx <= posx - velx;
                      end if;
                 end if;
                      
                -- Comprobamos si va para arriba o para abajo
                if (arriba = '1') then
                    -- comprobamos que no desborde por arriba
                    if (<no desborda por arriba>) then
                        p_posy <= posy + vely;
                    else
                        p_arriba <= '0';
                    end if;
                
               else
                    -- comprobamos que no desborde por abajo
                    if (posy - vely >= YMIN) then
                        p_posy <= posy - vely;
                    else
                        -- aquí se supone que debo morir porque he tocado el suelo
                        p_arriba <= '1';
                    end if;
               end if;
               
               -- Nos vamos al estado de reposo
               p_estado <= REPOSO;  
            
            when CHOQUE_PALA =>  
                ready_bola <= '0';
                p_arriba <= '1';        
                p_estado <= REPOSO;   
        end case;   
     end process;
    

end Behavioral;
