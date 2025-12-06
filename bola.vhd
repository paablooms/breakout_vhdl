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
        left : in STD_LOGIC;
        right : in STD_LOGIC;
        ejex       : in  std_logic_vector(9 downto 0); --coordenada x de la bola
        ejey       : in  std_logic_vector(9 downto 0); -- coordenada y de la bola
        data_bola  : in  std_logic_vector(3 downto 0);
        valid_bola : in  std_logic;
        ready_bola : out std_logic;
        pierde_vida: out std_logic;
        RGBbola    : out std_logic_vector(11 downto 0)
        );
end bola;

architecture Behavioral of bola is


component sprite_bola is
  port (
    clka  : in  std_logic;
    addra : in  std_logic_vector(5 downto 0);
    douta : out std_logic_vector(11 downto 0)
  );
end component;

-- definimos constantes con la altura y ancho de la pantalla
constant WIDTH  : natural := 512;
constant HEIGHT : natural := 480;

-- constantes sobre los límites de pantalla (ORIGEN ARRIBA-IZQUIERDA)
-- XMIN/YMIN: parte superior-izquierda
-- XMAX/YMAX: parte inferior-derecha
constant TAM_BOLA : unsigned(9 downto 0) := to_unsigned(8,10);  -- bola 8x8
constant XMIN      : unsigned(9 downto 0) := to_unsigned(0, 10);
constant XMAX      : unsigned(9 downto 0) := to_unsigned(WIDTH-1, 10);
constant YMIN      : unsigned(9 downto 0) := to_unsigned(0, 10);
constant YMAX      : unsigned(9 downto 0) := to_unsigned(HEIGHT-1, 10);

signal pierde_vida_s: std_logic;
signal posx, p_posx : unsigned(9 downto 0);
signal posy, p_posy : unsigned(9 downto 0);
signal velx, p_velx : unsigned(9 downto 0); --cuántos pixeles le vamos a sumar cada vez que se mueve
signal vely, p_vely : unsigned(9 downto 0); -- cuántos pixeles se desplaza en vertical
signal arriba, p_arriba : std_logic; --1 (arriba), 0(abajo)
signal dcha,   p_dcha   : std_logic; --1 (derecha), 0(izquierda)

-- Señales para la ROM del sprite
signal sprite_addr : std_logic_vector(5 downto 0);
signal sprite_rgb  : std_logic_vector(11 downto 0);

signal cnt : unsigned(1 downto 0);  -- contador 0..2
signal p_cnt : unsigned(1 downto 0);

type tipo_estado is (
     REPOSO, MOVER, CHOQUE_PALA, CHOQUE_BLOQUE, REPOSO_ABSOLUTO
);
signal estado, p_estado: tipo_estado;



begin

U_sprite_bola : sprite_bola
    port map(
      clka  => clk,          -- reloj del sistema
      addra => sprite_addr,  -- dirección del píxel dentro del sprite
      douta => sprite_rgb    -- color leído de la ROM
    );

------------------------------------------------------------------
-- Proceso secuencial 
------------------------------------------------------------------
    sinc: process(clk)
    begin
        if rising_edge(clk) then
            if(reset='1') then
                --valores iniciales de la bola
                estado  <= REPOSO_ABSOLUTO;
                posx    <= to_unsigned(256,10); -- centro aprox
                posy    <= to_unsigned(450,10);
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
    process(estado,left,right,posx,posy,arriba,dcha,valid_bola,data_bola,refresh,velx,vely)
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
        pierde_vida <= '0';
    
        case estado is
       
            when REPOSO_ABSOLUTO =>
                if (left='1' or right='1') then 
                    p_estado <= REPOSO;
                end if;
                
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
                        p_estado <= REPOSO;
                    else 
                        p_posx <= XMAX;
                        p_dcha <= '0'; -- rebote hacia la izquierda
                        p_estado <= REPOSO;
                    end if;
                else
                    -- Condición de que no desborde por la izquierda
                    if (posx > XMIN + velx) then
                        p_posx <= posx - velx;
                        p_estado <= REPOSO;
                    else
                        p_posx <= XMIN;
                        p_dcha <= '1';
                        p_estado <= REPOSO;
                    end if;
                end if;
                      
                -- Movimiento vertical con ORIGEN ARRIBA-IZQUIERDA
                -- Y crece hacia ABAJO.
                if (arriba = '1') then
                    -- Va hacia arriba: Y DECRECE
                    if (posy > YMIN + vely) then
                        p_posy <= posy - vely;
                        p_estado <= REPOSO;
                    else
                        -- ha tocado el techo (parte de arriba)
                        p_posy   <= YMIN;
                        p_arriba <= '0';  -- ahora irá hacia abajo
                        p_estado <= REPOSO;
                    end if;
                else
                    -- Va hacia abajo: Y CRECE
                    if (posy < YMAX - vely) then
                        p_posy <= posy + vely;
                        p_estado <= REPOSO;
                    else
                        -- TOCA SUELO: pierde una vida
                        pierde_vida_s <= '1';
                        pierde_vida <= '1';
            
                        -- Recolocamos la bola como al inicio
                        p_posx   <= to_unsigned(256,10);
                        p_posy   <= to_unsigned(450,10);
                        p_arriba <= '1';
                        p_dcha   <= '1';
            
                        p_estado <= REPOSO_ABSOLUTO; -- igual que tras arriba 
                    end if;
                end if;
                
               
            when CHOQUE_BLOQUE =>
                -- Si venía subiendo (arriba='1'), ahora la mandamos hacia abajo y la sacamos un paso
                if arriba = '1' then
                    p_arriba <= '0';           -- ahora va hacia abajo
                    p_posy   <= posy + vely;   -- la sacamos un pixel (o vely) hacia abajo
                else
                    -- Si venía bajando (arriba='0'), ahora la mandamos hacia arriba y la sacamos un paso
                    p_arriba <= '1';           
                    p_posy   <= posy - vely;   -- la sacamos hacia arriba
                end if;
            
                ready_bola <= '0';
                p_estado   <= REPOSO;   
            
            when CHOQUE_PALA =>  
                ready_bola <= '0';
                p_arriba   <= '1';    -- después de la pala va hacia arriba      
                p_estado   <= REPOSO;   
        end case;   
     end process;

  ----------------------------------------------------------------
  -- DIBUJO BOLA CON SPRITE (8x8)
  ----------------------------------------------------------------
  draw_bola : process(ejex, ejey, posx, posy, sprite_rgb)
    variable x_pix, y_pix : unsigned(9 downto 0);
    variable dx_full, dy_full : unsigned(9 downto 0);
    variable dx, dy : unsigned(2 downto 0);  -- 3 bits: 0..7
  begin
    x_pix := unsigned(ejex);
    y_pix := unsigned(ejey);

    if (x_pix >= posx) and
       (x_pix <  posx + TAM_BOLA) and
       (y_pix >= posy) and
       (y_pix <  posy + TAM_BOLA) then

        -- resta completa
        dx_full := x_pix - posx;
        dy_full := y_pix - posy;

        -- solo los 3 bits LSB (0..7)
        dx := dx_full(2 downto 0);
        dy := dy_full(2 downto 0);

        -- dirección del sprite: dy*8 + dx = concatenación de 3+3 bits
        sprite_addr <= std_logic_vector(dy & dx);

        RGBbola <= sprite_rgb;
    else
        RGBbola <= (others => '0');
    end if;
  end process;
      
vel : process(clk, reset)
begin
    if reset = '1' then
        cnt    <= "00";
        p_velx <= "0000001000";  
        p_vely <= "0000001000";
    elsif rising_edge(clk) then
        if pierde_vida_s = '1' then
            if cnt = "10" then
                cnt <= "10";  
            else
                cnt <= unsigned(cnt) + 1;
            end if;
        end if;

        case cnt is
            when "00" =>
                p_velx <= "0000001000";  -- 8
                p_vely <= "0000001000";
            when "01" =>
                p_velx <= "0000000101";  -- 5
                p_vely <= "0000000101";
            when others =>  -- "10"
                p_velx <= "0000000011";  -- 3
                p_vely <= "0000000011";
        end case;
    end if;
end process;


end Behavioral;
