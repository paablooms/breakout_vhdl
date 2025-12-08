----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 14.10.2025 19:51:22
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
        left       : in  std_logic;
        right      : in  std_logic;
        ejex       : in  std_logic_vector(9 downto 0); -- coordenada x de la bola
        ejey       : in  std_logic_vector(9 downto 0); -- coordenada y de la bola
        data_bola  : in  std_logic_vector(3 downto 0);
        valid_bola : in  std_logic;
        ready_bola : out std_logic;
        pierde_vida: out std_logic;
        RGBbola    : out std_logic_vector(11 downto 0)
        );
end bola;

architecture Behavioral of bola is

  ----------------------------------------------------------------
  -- SPRITE 8x8 (64 posiciones → 6 bits de dirección)
  ----------------------------------------------------------------
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
  constant TAM_BOLA : unsigned(9 downto 0) := to_unsigned(8,10);  -- bola 8x8
  constant XMIN     : unsigned(9 downto 0) := to_unsigned(0, 10);
  constant XMAX     : unsigned(9 downto 0) := to_unsigned(WIDTH-1, 10);
  constant YMIN     : unsigned(9 downto 0) := to_unsigned(0, 10);
  constant YMAX     : unsigned(9 downto 0) := to_unsigned(HEIGHT-1, 10);

  -- posición
  signal posx, p_posx : unsigned(9 downto 0);
  signal posy, p_posy : unsigned(9 downto 0);

  -- velocidad (ahora SÓLO un proceso las escribe)
  signal velx : unsigned(9 downto 0);
  signal vely : unsigned(9 downto 0);

  -- dirección
  signal arriba, p_arriba : std_logic; --1 (arriba), 0(abajo)
  signal dcha,   p_dcha   : std_logic; --1 (derecha), 0(izquierda)

  -- contador para cambiar velocidad tras perder vidas
  signal cnt : unsigned(1 downto 0);   -- 0..2
  signal pierde_vida_s : std_logic;

  -- Señales para la ROM del sprite
  signal sprite_addr : std_logic_vector(5 downto 0);
  signal sprite_rgb  : std_logic_vector(11 downto 0);

  type tipo_estado is (
       REPOSO, MOVER, CHOQUE_PALA, CHOQUE_BLOQUE, REPOSO_ABSOLUTO
  );
  signal estado, p_estado: tipo_estado;

begin

  ----------------------------------------------------------------
  -- INSTANCIA SPRITE
  ----------------------------------------------------------------
  U_sprite_bola : sprite_bola
    port map(
      clka  => clk,          -- reloj del sistema
      addra => sprite_addr,  -- dirección del píxel dentro del sprite
      douta => sprite_rgb    -- color leído de la ROM
    );

  ------------------------------------------------------------------
  -- PROCESO SECUENCIAL PRINCIPAL (estado, posición, dirección)
  ------------------------------------------------------------------
  sinc: process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        -- valores iniciales de la bola
        estado  <= REPOSO_ABSOLUTO;
        posx    <= to_unsigned(256,10); -- centro aprox
        posy    <= to_unsigned(440,10);
        arriba  <= '1';
        dcha    <= '1';
      else
        estado  <= p_estado;
        posx    <= p_posx;
        posy    <= p_posy;
        arriba  <= p_arriba;
        dcha    <= p_dcha;
      end if;
    end if;
  end process;
    
    pierde_vida <= pierde_vida_s;
  -----------------------------------------------------------
  -- PROCESO COMBINACIONAL (FSM de movimiento/colisiones)
  -----------------------------------------------------------
  process(estado, left, right, posx, posy, arriba, dcha,
          valid_bola, data_bola, refresh, velx, vely, ejex, ejey, pierde_vida_s)
          
    -- VARIABLES LOCALES
    variable ref_bloque_x : unsigned(4 downto 0);
    variable ref_bloque_y : unsigned(3 downto 0);
    variable choque_izq   : std_logic;
    variable choque_der   : std_logic;
    variable choque_arr   : std_logic;
    variable choque_ab    : std_logic;
    
    variable rebote_h     : std_logic;  -- hay rebote horizontal
    variable rebote_v     : std_logic;  -- hay rebote signal
    
  begin 
    
    -- VALORES POR DEFECTO
    p_estado   <= estado;
    p_posx     <= posx;
    p_posy     <= posy;
    p_arriba   <= arriba;
    p_dcha     <= dcha;
    ready_bola <= '0';
    pierde_vida_s <= '0';

    case estado is
       
      when REPOSO_ABSOLUTO =>
        if (left='1' or right='1') then 
          p_estado <= REPOSO;
        end if;
                
      when REPOSO =>
        ready_bola <= '1';
        if (valid_bola='1' and data_bola="0000") then
          p_estado <= CHOQUE_PALA;
        elsif (valid_bola='1' and data_bola="0001") then
          p_estado <= CHOQUE_BLOQUE;
        elsif (refresh='1') then
          p_estado <= MOVER;
        else
          p_estado <= REPOSO;
        end if;
                
      when MOVER =>
        ------------------------------------------------------
        -- Movimiento horizontal
        ------------------------------------------------------
        if dcha='1' then
          if (posx + velx <= XMAX) then
            p_posx <= posx + velx;
          else 
            p_posx <= XMAX;
            p_dcha <= '0'; -- rebote hacia la izquierda
          end if;
        else
          if (posx > XMIN + velx) then
            p_posx <= posx - velx;
          else
            p_posx <= XMIN;
            p_dcha <= '1';
          end if;
        end if;
                      
        ------------------------------------------------------
        -- Movimiento vertical (origen arriba-izquierda)
        ------------------------------------------------------
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
            -- TOCA SUELO: pierde una vida
            pierde_vida_s <= '1';
            
            -- Recolocamos la bola como al inicio
            p_posx   <= to_unsigned(256,10);
            p_posy   <= to_unsigned(440,10);
            p_arriba <= '1';
            p_dcha   <= '1';
            
            p_estado <= REPOSO_ABSOLUTO;
          end if;
        end if;

        -- si no ha tocado suelo, volvemos a REPOSO igualmente
        if pierde_vida_s = '0' then
          p_estado <= REPOSO;
        end if;
                
 -------------------------------------------------
      -- *** CÓDIGO MODIFICADO: CHOQUE_BLOQUE ***
      -------------------------------------------------
      when CHOQUE_BLOQUE =>

        -- Coordenadas locales dentro del bloque (32x16).
        ref_bloque_x := unsigned(ejex(4 downto 0));  -- 0 a 31 dentro del bloque
        ref_bloque_y := unsigned(ejey(3 downto 0));  -- 0 a 15

        -- Inicializamos las "flags" de choque
        choque_izq := '0';
        choque_der := '0';
        choque_arr := '0';
        choque_ab  := '0';

        -- ¿Está tocando el borde izquierdo o derecho del bloque?
        if ref_bloque_x = to_unsigned(0,5) then
          choque_izq := '1';
        elsif ref_bloque_x = to_unsigned(31,5) then
          choque_der := '1';
        end if;

        -- ¿Está tocando el borde superior o inferior del bloque?
        if ref_bloque_y = to_unsigned(0,4) then
          choque_arr := '1';
        elsif ref_bloque_y = to_unsigned(15,4) then
          choque_ab := '1';
        end if;

        -- Indicadores de si hay rebote horizontal / vertical
        if (choque_izq = '1') or (choque_der = '1') then
          rebote_h := '1';
        else
          rebote_h := '0';
        end if;

        if (choque_arr = '1') or (choque_ab = '1') then
          rebote_v := '1';
        else
          rebote_v := '0';
        end if;

        ----------------------------------------------------------------
        -- Rebote horizontal (solo si pegó en lados izq/der)
        ----------------------------------------------------------------
        if rebote_h = '1' then
          if choque_izq = '1' then
            -- venía desde la izquierda, rebota hacia la derecha
            p_dcha <= '1';
            p_posx <= posx + velx;  -- lo sacamos un poco del bloque
          elsif choque_der = '1' then
            -- venía desde la derecha, rebota hacia la izquierda
            p_dcha <= '0';
            p_posx <= posx - velx;
          end if;
        end if;
            
        ----------------------------------------------------------------
        -- Rebote vertical (solo si pegó arriba/abajo)
        ----------------------------------------------------------------
        if rebote_v = '1' then
          if arriba = '1' then
            -- venía subiendo, rebota hacia abajo
            p_arriba <= '0';
            p_posy   <= posy + vely;
          else
            -- venía bajando, rebota hacia arriba
            p_arriba <= '1';
            p_posy   <= posy - vely;
          end if;
        end if;

        ----------------------------------------------------------------
        -- Si por algún motivo no hemos detectado ni lateral ni vertical
        -- (por ejemplo, el contacto está "en el medio"), forzamos al menos
        -- un rebote vertical para que no atraviese el bloque.
        ----------------------------------------------------------------
        if (rebote_h = '0') and (rebote_v = '0') then
          if arriba = '1' then
            p_arriba <= '0';
            p_posy   <= posy + vely;
          else
            p_arriba <= '1';
            p_posy   <= posy - vely;
          end if;
        end if;

        -- Después de procesar el choque, volvemos a REPOSO
        p_estado <= REPOSO;
      when CHOQUE_PALA =>  
        ready_bola <= '0';
        p_arriba   <= '1';    -- después de la pala va hacia arriba      
        p_estado   <= REPOSO;   

    end case;   
  end process;

  ----------------------------------------------------------------
  -- PROCESO DE VELOCIDAD (depende de cuántas veces se ha caído)
  -- cnt = 00 → rápido, 01 → medio, 10 → lento
  ----------------------------------------------------------------
  vel : process(clk, reset)
  begin
    if reset = '1' then
      cnt  <= (others => '0');
      velx <= to_unsigned(8,10);  -- velocidad inicial
      vely <= to_unsigned(8,10);
    elsif rising_edge(clk) then
      -- cuenta cuántas veces ha perdido vida (máx 2)
      if pierde_vida_s = '1' then
        if cnt < "10" then
          cnt <= cnt + 1;
        else
          cnt <= cnt;  -- saturación
        end if;
      end if;

      -- ajusta velocidad según cnt
      case cnt is
        when "00" =>  -- 1ª vida: rápido
          velx <= to_unsigned(8,10);
          vely <= to_unsigned(8,10);
        when "01" =>  -- 2ª vida: medio
          velx <= to_unsigned(5,10);
          vely <= to_unsigned(5,10);
        when others => -- "10" o más: lento
          velx <= to_unsigned(3,10);
          vely <= to_unsigned(3,10);
      end case;
    end if;
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

      -- coordenadas locales dentro del sprite
      dx_full := x_pix - posx;    -- 0..7
      dy_full := y_pix - posy;    -- 0..7

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

end Behavioral;
