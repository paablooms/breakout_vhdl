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
-----------------------------------------------------------------------------------
-- Módulo: bola
--
-- Este módulo controla la bola del juego:
--   - Lleva su posición (posx, posy) y su dirección (arriba/abajo, izquierda/derecha).
--   - Gestiona la velocidad en función de las vidas perdidas.
--   - Reacciona a colisiones:
--       * Con la pala      (código "0000" en data_bola)
--       * Con un bloque    (código "0001" en data_bola)
--   - Dibuja la bola en pantalla usando un sprite 8x8 (sprite_bola).
--
-- Entradas clave:
--   - ejex, ejey: coordenadas del píxel que se está pintando ahora mismo.
--   - refresh: "pulso" que indica cuándo toca actualizar la posición de la bola.
--   - data_bola + valid_bola: eventos de colisión que vienen del control_juego.
--
-- Salidas clave:
--   - RGBbola: color de la bola en el píxel actual (o negro si no hay bola).
--   - pierde_vida: indica que la bola ha tocado el suelo.
--   - ready_bola: handshake hacia el módulo que le envía data_bola.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

----------------------------------------------------------------------------------
-- ENTIDAD
----------------------------------------------------------------------------------
entity bola is
  Port (
    clk        : in  std_logic;
    reset      : in  std_logic;
    refresh    : in  std_logic;
    left       : in  std_logic;
    right      : in  std_logic;

    -- Coordenadas actuales del píxel que estamos generando (no de la bola)
    ejex       : in  std_logic_vector(9 downto 0);
    ejey       : in  std_logic_vector(9 downto 0);

    -- Interfaz con control_juego (eventos de colisión)
    data_bola  : in  std_logic_vector(3 downto 0); -- código de evento (pala/bloque)
    valid_bola : in  std_logic;                    -- 1 => data_bola válido
    ready_bola : out std_logic;                    -- handshake hacia control_juego

    -- Señal al resto del sistema de que se ha perdido una vida (bola tocó suelo)
    pierde_vida: out std_logic;

    -- Color de la bola en el píxel actual
    RGBbola    : out std_logic_vector(11 downto 0)
  );
end bola;

----------------------------------------------------------------------------------
-- ARQUITECTURA
----------------------------------------------------------------------------------
architecture Behavioral of bola is

  ----------------------------------------------------------------
  -- SPRITE 8x8 (64 posiciones → 6 bits de dirección)
  -- ROM que guarda los colores del dibujo de la bola
  ----------------------------------------------------------------
  component sprite_bola is
    port (
      clka  : in  std_logic;
      addra : in  std_logic_vector(5 downto 0);    -- índice 0..63
      douta : out std_logic_vector(11 downto 0)    -- color RGB del píxel del sprite
    );
  end component;

  ----------------------------------------------------------------
  -- CONSTANTES DE PANTALLA / BOLA
  ----------------------------------------------------------------
  constant WIDTH  : natural := 512;
  constant HEIGHT : natural := 480;

  -- Límites de la pantalla (origen arriba-izquierda)
  constant TAM_BOLA : unsigned(9 downto 0) := to_unsigned(8,10);   -- bola 8x8
  constant XMIN     : unsigned(9 downto 0) := to_unsigned(0, 10);
  constant XMAX     : unsigned(9 downto 0) := to_unsigned(WIDTH-1, 10);
  constant YMIN     : unsigned(9 downto 0) := to_unsigned(0, 10);
  constant YMAX     : unsigned(9 downto 0) := to_unsigned(HEIGHT-1, 10);

  ----------------------------------------------------------------
  -- POSICIÓN DE LA BOLA
  ----------------------------------------------------------------
  signal posx, p_posx : unsigned(9 downto 0);  -- posición X actual / siguiente
  signal posy, p_posy : unsigned(9 downto 0);  -- posición Y actual / siguiente

  ----------------------------------------------------------------
  -- VELOCIDAD DE LA BOLA
  -- (solo un proceso escribe velx/vely)
  ----------------------------------------------------------------
  signal velx : unsigned(9 downto 0);
  signal vely : unsigned(9 downto 0);

  ----------------------------------------------------------------
  -- DIRECCIÓN DE LA BOLA
  --   arriba = '1' → se mueve hacia arriba (Y decrece)
  --   dcha   = '1' → se mueve hacia la derecha (X crece)
  ----------------------------------------------------------------
  signal arriba, p_arriba : std_logic;
  signal dcha,   p_dcha   : std_logic;

  ----------------------------------------------------------------
  -- CONTADOR DE VIDAS / VELOCIDAD
  -- cnt = 00 → 1ª vida  → rápido
  -- cnt = 01 → 2ª vida  → velocidad media
  -- cnt = 10 → 3ª vida+ → lento
  ----------------------------------------------------------------
  signal cnt : unsigned(1 downto 0);   -- 0 a 2
  signal pierde_vida_s : std_logic;    -- versión interna de pierde_vida

  ----------------------------------------------------------------
  -- SEÑALES PARA LA ROM DEL SPRITE
  ----------------------------------------------------------------
  signal sprite_addr : std_logic_vector(5 downto 0); -- dirección dentro del sprite
  signal sprite_rgb  : std_logic_vector(11 downto 0);-- color leído de la ROM

  ----------------------------------------------------------------
  -- MÁQUINA DE ESTADOS PRINCIPAL
  ----------------------------------------------------------------
  type tipo_estado is (
    REPOSO,           -- esperando eventos / refresh
    MOVER,            -- actualizar posición de la bola
    CHOQUE_PALA,      -- procesar rebote sobre la pala
    CHOQUE_BLOQUE,    -- procesar rebote sobre un bloque
    REPOSO_ABSOLUTO   -- bola parada esperando primer movimiento (start)
  );
  signal estado, p_estado : tipo_estado;

begin

  ----------------------------------------------------------------
  -- INSTANCIA DEL SPRITE DE LA BOLA
  ----------------------------------------------------------------
  U_sprite_bola : sprite_bola
    port map(
      clka  => clk,          -- reloj del sistema
      addra => sprite_addr,  -- dirección del píxel dentro del sprite (0..63)
      douta => sprite_rgb    -- color leído de la ROM
    );

  ------------------------------------------------------------------
  -- PROCESO SECUENCIAL PRINCIPAL
  -- Registra: estado, posición y dirección
  ------------------------------------------------------------------
  sinc : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        -- Estado inicial de la bola tras un reset
        estado  <= REPOSO_ABSOLUTO;
        posx    <= to_unsigned(256,10); -- centro aproximado en X
        posy    <= to_unsigned(440,10); -- cerca de la parte baja
        arriba  <= '1';                 -- empieza subiendo
        dcha    <= '1';                 -- y yendo a la derecha
      else
        -- Avanza al siguiente estado y actualiza posición/dirección
        estado  <= p_estado;
        posx    <= p_posx;
        posy    <= p_posy;
        arriba  <= p_arriba;
        dcha    <= p_dcha;
      end if;
    end if;
  end process;

  -- Sacamos pierde_vida al exterior
  pierde_vida <= pierde_vida_s;

  -----------------------------------------------------------
  -- PROCESO COMBINACIONAL
  -- FSM de movimiento y reacción a colisiones
  -----------------------------------------------------------
  process(estado, left, right, posx, posy, arriba, dcha,
          valid_bola, data_bola, refresh, velx, vely, ejex, ejey, pierde_vida_s)

    -- VARIABLES LOCALES PARA CÁLCULOS DE CHOQUE CON BLOQUES
    variable ref_bloque_x : unsigned(4 downto 0);  -- 0 a 31 dentro del bloque
    variable ref_bloque_y : unsigned(3 downto 0);  -- 0 a 15

    -- Flags de Zona de impacto
    variable choque_izq   : std_logic;
    variable choque_der   : std_logic;
    variable choque_arr   : std_logic;
    variable choque_ab    : std_logic;

    -- Flags de rebote global (horizontal / vertical)
    variable rebote_h     : std_logic;  -- hay rebote horizontal (lateral)
    variable rebote_v     : std_logic;  -- hay rebote vertical (arriba/abajo)

  begin

    ----------------------------------------------------------------
    -- VALORES POR DEFECTO 
    ----------------------------------------------------------------
    p_estado   <= estado;
    p_posx     <= posx;
    p_posy     <= posy;
    p_arriba   <= arriba;
    p_dcha     <= dcha;
    ready_bola <= '0';
    pierde_vida_s <= '0';

    ----------------------------------------------------------------
    -- MÁQUINA DE ESTADOS
    ----------------------------------------------------------------
    case estado is

      ----------------------------------------------------------------
      -- REPOSO_ABSOLUTO:
      -- Bola totalmente parada, como "pantalla de inicio".
      -- Solo cuando el jugador pulsa left o right, pasamos a REPOSO
      -- y empezamos a jugar en serio.
      ----------------------------------------------------------------
      when REPOSO_ABSOLUTO =>
        if (left = '1' or right = '1') then
          p_estado <= REPOSO;
        end if;

      ----------------------------------------------------------------
      -- REPOSO:
      -- Estado base "normal":
      --   - Avisamos de que estamos listos para recibir eventos de colisión
      --     (ready_bola = '1').
      --   - Si llega valid_bola = '1', reaccionamos según data_bola:
      --        "0000" → choque con pala
      --        "0001" → choque con bloque
      --   - Si no hay evento de colisión pero llega refresh = '1',
      --     pasamos a MOVER para actualizar la posición de la bola.
      ----------------------------------------------------------------
      when REPOSO =>
        ready_bola <= '1';

        -- Evento: choque con pala
        if (valid_bola = '1' and data_bola = "0000") then
          p_estado <= CHOQUE_PALA;

        -- Evento: choque con bloque
        elsif (valid_bola = '1' and data_bola = "0001") then
          p_estado <= CHOQUE_BLOQUE;

        -- Si no hay colisión nueva pero toca refresh, movemos bola
        elsif (refresh = '1') then
          p_estado <= MOVER;

        else
          p_estado <= REPOSO;
        end if;

      ----------------------------------------------------------------
      -- MOVER:
      -- Actualizamos la posición de la bola en X e Y según:
      --   - sentido actual (arriba/abajo, izq/der)
      --   - velocidad actual (velx, vely)
      --
      -- Gestiona:
      --   - Rebotes contra las paredes laterales y techo.
      --   - Caída por el suelo → pierde_vida.
      ----------------------------------------------------------------
      when MOVER =>

        ------------------------------------------------------
        -- Movimiento horizontal 
        ------------------------------------------------------
        if dcha = '1' then
          -- Va hacia la derecha
          if (posx + velx <= XMAX) then
            p_posx <= posx + velx;
          else
            -- Choca con el borde derecho
            p_posx <= XMAX;
            p_dcha <= '0'; -- a partir de ahora irá a la izquierda
          end if;
        else
          -- Va hacia la izquierda
          if (posx > XMIN + velx) then
            p_posx <= posx - velx;
          else
            -- Choca con el borde izquierdo
            p_posx <= XMIN;
            p_dcha <= '1'; -- a partir de ahora irá a la derecha
          end if;
        end if;

        ------------------------------------------------------
        -- Movimiento vertical (Y)
        ------------------------------------------------------
        if (arriba = '1') then
          -- Va hacia arriba: Y DECRECE
          if (posy > YMIN + vely) then
            p_posy <= posy - vely;
          else
            -- Ha tocado el techo
            p_posy   <= YMIN;
            p_arriba <= '0';  -- ahora irá hacia abajo
          end if;
        else
          -- Va hacia abajo: Y CRECE
          if (posy < YMAX - vely) then
            p_posy <= posy + vely;
          else
            -- Ha tocado el suelo → pierde una vida
            pierde_vida_s <= '1';

            -- Recolocamos la bola como al inicio
            p_posx   <= to_unsigned(256,10);
            p_posy   <= to_unsigned(440,10);
            p_arriba <= '1';
            p_dcha   <= '1';

            p_estado <= REPOSO_ABSOLUTO;
          end if;
        end if;

        -- Si no hemos tocado suelo, volvemos a REPOSO tras mover
        if pierde_vida_s = '0' then
          p_estado <= REPOSO;
        end if;

      ----------------------------------------------------------------
      -- CHOQUE_BLOQUE:
      -- Procesa el rebote contra un bloque:
      --   - Calcula en qué parte del bloque ha golpeado (lateral, arriba, abajo)
      --   - En función de eso:
      --       * invierte dirección horizontal (dcha) si golpea en izquierda/derecha
      --       * invierte dirección vertical (arriba) si golpea en arriba/abajo.
      ----------------------------------------------------------------
      when CHOQUE_BLOQUE =>

        -- Coordenadas locales dentro del bloque (de tamaño 32x16).
        -- Usamos los bits menos significativos de ejex/ejey para saber
        -- si estamos cerca del borde del bloque.
        ref_bloque_x := unsigned(ejex(4 downto 0));  -- 0..31 (ancho)
        ref_bloque_y := unsigned(ejey(3 downto 0));  -- 0..15 (alto)

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
          rebote_v_

