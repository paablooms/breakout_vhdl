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
use IEEE.NUMERIC_STD.ALL;

entity bola is
  Port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        refresh    : in  std_logic;
        ejex       : in  std_logic_vector(9 downto 0); --coordenada x de la bola
        ejey       : in  std_logic_vector(9 downto 0); -- coordenada y de la bola
        data_bola  : in  std_logic_vector(3 downto 0);
        valid_bola : in  std_logic;
        ready_bola : out std_logic;
        RGBbola    : out std_logic_vector(11 downto 0)
        );
end bola;

architecture Behavioral of bola is

-- definimos constantes con la altura y ancho de la pantalla
constant WIDTH  : natural := 512;
constant HEIGHT : natural := 480;

-- constantes sobre los límites de pantalla (ORIGEN ARRIBA-IZQUIERDA)
-- XMIN/YMIN: parte superior-izquierda
-- XMAX/YMAX: parte inferior-derecha
constant XMIN      : unsigned(9 downto 0) := to_unsigned(0, 10);
constant XMAX      : unsigned(9 downto 0) := to_unsigned(WIDTH-1, 10);
constant YMIN      : unsigned(9 downto 0) := to_unsigned(0, 10);
constant YMAX      : unsigned(9 downto 0) := to_unsigned(HEIGHT-1, 10);

signal posx, p_posx : unsigned(9 downto 0);
signal posy, p_posy : unsigned(9 downto 0);
signal velx, p_velx : unsigned(9 downto 0); --cuántos pixeles le vamos a sumar cada vez que se mueve
signal vely, p_vely : unsigned(9 downto 0); -- cuántos pixeles se desplaza en vertical
signal arriba, p_arriba : std_logic; --1 (arriba), 0(abajo)
signal dcha,   p_dcha   : std_logic; --1 (derecha), 0(izquierda)

type tipo_estado is (
     REPOSO, MOVER, CHOQUE_PALA, CHOQUE_BLOQUE
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
                estado  <= REPOSO;
                posx    <= to_unsigned(256,10); -- centro aprox
                posy    <= to_unsigned(240,10);
                velx    <= to_unsigned(1,10);
                vely    <= to_unsigned(1,10);
                arriba  <= '1';
                dcha    <= '1';
            else
                estado  <= p_estado;
                posx    <= p_posx;
                posy    <= p_posy;
                velx    <= p_velx;
                vely    <= p_vely;
                arriba  <= p_arriba;
                dcha    <= p_dcha;   
            end if;
        end if;
    end process;
    
    -----------------------------------------------------------
    -- Proceso combinacional 
    -----------------------------------------------------------
    process(estado,posx,posy,arriba,dcha,valid_bola,data_bola,refresh,velx,vely)
    begin 
    
         -- VALORES POR DEFECTO (se copian los registros)
        p_estado <= estado;
        p_posx   <= posx;
        p_posy   <= posy;
        p_velx   <= velx;
        p_vely   <= vely;
        p_arriba <= arriba;
        p_dcha   <= dcha;
    
        ready_bola <= '0';  -- por defecto
    
        case estado is
       
            when REPOSO =>
                ready_bola <= '1';
                if(valid_bola='1' and data_bola="0000") then
                    p_estado <= CHOQUE_PALA;
                elsif (valid_bola='1' and data_bola="0001") then
                    p_estado <= CHOQUE_BLOQUE;
                elsif (refresh='1') then
                    p_estado <= MOVER;
                else
                    p_estado <= REPOSO;
                end if;
                
            when MOVER =>
                -- Movimiento horizontal (origen da igual, X crece hacia la derecha)
                if(dcha='1') then
                    -- condición de que no desborde por la derecha
                    if (posx + velx <= XMAX) then
                        p_posx <= posx + velx;
                    else 
                        p_posx <= XMAX;
                        p_dcha <= '0'; -- rebote hacia la izquierda
                    end if;
                else
                    -- Condición de que no desborde por la izquierda
                    if (posx > XMIN + velx) then
                        p_posx <= posx - velx;
                    else
                        p_posx <= XMIN;
                        p_dcha <= '1';
                    end if;
                end if;
                      
                -- Movimiento vertical con ORIGEN ARRIBA-IZQUIERDA
                -- Y crece hacia ABAJO.
                if (arriba = '1') then
                    -- Va hacia arriba: Y DECRECE
                    if (posy > YMIN + vely) then
                        p_posy <= posy - vely;
                    else
                        -- ha tocado el techo (parte de arriba)
                        p_posy   <= YMIN;
                        p_arriba <= '0';  -- ahora irá hacia abajo
                    end if;
                else
                    -- Va hacia abajo: Y CRECE
                    if (posy < YMAX - vely) then
                        p_posy <= posy + vely;
                    else
                        -- ha tocado el suelo (parte de abajo de la pantalla)
                        p_posy   <= YMAX;
                        p_arriba <= '1';  -- rebote hacia arriba
                        -- si en lugar de rebotar quieres "morir",
                        -- aquí podrías cambiar a un estado GAME_OVER, etc.
                    end if;
                end if;
               
               -- Nos vamos al estado de reposo
               p_estado <= REPOSO;  
               
            when CHOQUE_BLOQUE =>
                -- básico (si llega a este estado hay que invertir la dirección vertical)
                p_arriba   <= not arriba;
                ready_bola <= '0';
                p_estado   <= REPOSO;   
            
            when CHOQUE_PALA =>  
                ready_bola <= '0';
                p_arriba   <= '1';    -- después de la pala va hacia arriba      
                p_estado   <= REPOSO;   
        end case;   
     end process;
    

end Behavioral;
