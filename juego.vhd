----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 14.10.2025 19:51:22
-- Design Name: 
-- Module Name: juego - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
--   - Instancia:
--       * fondo       → fondo de pantalla
--       * pala        → la barra que controla el jugador
--       * bola        → la pelota que rebota
--       * bloques     → RAM + lógica para dibujarlos y borrarlos
--       * control_juego → detecta colisiones entre bola/pala/bloques
--       * HUD vidas   → dibuja las vidas restantes
--       * game over   → dibuja la pantalla de GAME OVER
--
--   - Decide finalmente qué RGB sale por pantalla (RGBin) en cada píxel.
--   - Gestiona las vidas y el estado de GAME OVER.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--library UNISIM;
--use UNISIM.VComponents.all;

----------------------------------------------------------------------------------
-- ENTIDAD
----------------------------------------------------------------------------------
entity juego is
  Generic(
    posx : unsigned(9 downto 0) := to_unsigned(455,10);
    posy : unsigned(9 downto 0) := to_unsigned(256,10)
  );
  Port (
    clk, reset : in  std_logic;
    left, right: in  std_logic;
    ejex, ejey : in  std_logic_vector(9 downto 0);      -- coordenadas del píxel actual
    refresh    : in  std_logic;                         -- pulso de refresco (para bola/pala)
    RGBin      : out std_logic_vector(11 downto 0)      -- color final hacia VGA
  );
end juego;

----------------------------------------------------------------------------------
-- ARQUITECTURA
----------------------------------------------------------------------------------
architecture Behavioral of juego is

  -------------------------------------------------------------------
  -- CONSTANTES
  -------------------------------------------------------------------
  constant CERO_RGB : std_logic_vector(11 downto 0) := (others => '0');

  --constant posx : unsigned ( 9 downto 0) := to_unsigned(455,10);
  --constant posy : unsigned ( 9 downto 0) := to_unsigned(256,10);

  -------------------------------------------------------------------
  -- DECLARACIÓN DE COMPONENTES (submódulos)
  -------------------------------------------------------------------

  -- Bola (lógica de movimiento + dibujo)
  component bola is
    Port (
      clk        : in  std_logic;
      reset      : in  std_logic;
      refresh    : in  std_logic;
      left       : in  std_logic;
      right      : in  std_logic;
      ejex       : in  std_logic_vector(9 downto 0); -- coordenada x del píxel
      ejey       : in  std_logic_vector(9 downto 0); -- coordenada y del píxel
      data_bola  : in  std_logic_vector(3 downto 0);
      valid_bola : in  std_logic;
      ready_bola : out std_logic;
      pierde_vida: out std_logic;
      RGBbola    : out std_logic_vector(11 downto 0)
    );
  end component;

  -- Control del juego (colisiones + multiplexado simple de colores)
  component control_juego is
    Port (
      clk, reset : in  std_logic;
      ejex, ejey : in  std_logic_vector(9 downto 0);

      -- RGBs de entrada (para comparar qué hay en cada píxel)
      RGB_bola   : in  std_logic_vector(11 downto 0);
      RGB_bloque : in  std_logic_vector(11 downto 0);
      RGB_pala   : in  std_logic_vector(11 downto 0);

      -- Intercambio con bloques (para borrar)
      data_bloque  : out std_logic_vector(7 downto 0);
      valid_bloque : out std_logic;
      ready_bloque : in  std_logic;

      -- RGB combinado que va hacia el top
      RGB_in       : out std_logic_vector(11 downto 0);

      -- Interfaz con "bola" (eventos de choque)
      data_bola  : out std_logic_vector(3 downto 0);
      valid_bola : out std_logic;
      ready_bola : in  std_logic
    );
  end component;

  -- Pala del jugador
  component pala is
    Port (
      clk     : in  std_logic;
      reset   : in  std_logic;
      left    : in  std_logic;
      right   : in  std_logic;
      ejex    : in  std_logic_vector(9 downto 0);
      ejey    : in  std_logic_vector(9 downto 0);
      refresh : in  std_logic;
      pos_p   : out std_logic_vector(9 downto 0);          -- posición horizontal de la pala
      RGBin   : out std_logic_vector(11 downto 0)          -- color de la pala
    );
  end component;

  -- Fondo de pantalla
  component fondo is
    Generic(
      posx : unsigned(9 downto 0) := to_unsigned(455,10);
      posy : unsigned(9 downto 0) := to_unsigned(256,10)
    );
    Port (
      ejex : in  std_logic_vector(9 downto 0);
      ejey : in  std_logic_vector(9 downto 0);
      RGBin: out std_logic_vector(11 downto 0)
    );
  end component;

  -- Dibujo de bloques a partir de una RAM de 1 bit por celda
  component draw_bloque is
    Port (
      clk        : in  std_logic;
      data_out_B : in  std_logic;                    -- bit leído de la RAM (hay/no hay bloque)
      ejex       : in  std_logic_vector(9 downto 0); -- coordenada x del píxel
      ejey       : in  std_logic_vector(9 downto 0); -- coordenada y del píxel
      ADDR_B     : out std_logic_vector(7 downto 0); -- dirección en memoria
      RGB_bloque : out std_logic_vector(11 downto 0) -- color del bloque
    );
  end component;

  -- Lógica que se encarga de "borrar" un bloque en la RAM
  component borrar_bloque is
    Port (
      clk, reset   : in  std_logic;
      data_bloque  : in  std_logic_vector(7 downto 0);  -- dirección del bloque
      valid_bloque : in  std_logic;
      ready_bloque : out std_logic;
      WR_A         : out std_logic;                     -- habilita escritura
      ADDR_A       : out std_logic_vector(7 downto 0);  -- dirección del bloque
      data_in_A    : out std_logic                      -- '0' = borrar bloque
    );
  end component;

  -- RAM de bloques (bit por celda)
  component blk_mem_gen_0 is
    Port(
      clka  : in  std_logic;
      wea   : in  std_logic_vector(0 downto 0);
      addra : in  std_logic_vector(7 downto 0);
      dina  : in  std_logic_vector(0 downto 0);
      clkb  : in  std_logic;
      addrb : in  std_logic_vector(7 downto 0);
      doutb : out std_logic_vector(0 downto 0)
    );
  end component;

  -- ROM con el sprite de GAME OVER (320x240 → 17 bits de dirección)
  component sprite_game_over is
    port (
      clka  : in  std_logic;
      addra : in  std_logic_vector(16 downto 0);
      douta : out std_logic_vector(11 downto 0)
    );
  end component;

  -- ROM para el sprite de “vida” (HUD)
  component blk_mem_gen_1 is
    port (
      clka  : in  std_logic;
      addra : in  std_logic_vector(7 downto 0);
      douta : out std_logic_vector(11 downto 0)
    );
  end component;

  -- HUD de vidas
  component vidas_hud is
    Port (
      ejex      : in  std_logic_vector(9 downto 0);
      ejey      : in  std_logic_vector(9 downto 0);
      num_vidas : in  unsigned(1 downto 0);              -- 0..3

      -- Interfaz hacia la memoria del sprite de vida
      vida_rgb  : in  std_logic_vector(11 downto 0);     -- dato leído de la BRAM
      vida_addr : out std_logic_vector(7 downto 0);      -- dirección 0..255

      RGBvidas  : out std_logic_vector(11 downto 0)
    );
  end component;

  -------------------------------------------------------------------
  -- SEÑALES INTERNAS
  -------------------------------------------------------------------

  -- HUD de vidas
  signal RGBvidas_s   : std_logic_vector(11 downto 0);
  signal vida_addr_s  : std_logic_vector(7 downto 0);
  signal vida_rgb_s   : std_logic_vector(11 downto 0);

  -- Game over (ROM + control)
  signal go_addr      : std_logic_vector(16 downto 0);
  signal go_rgb       : std_logic_vector(11 downto 0);

  -- Sistema de gestión de vidas y estado GAME OVER
  signal RGB_gameover : std_logic_vector(11 downto 0);
  signal vidas_reg    : unsigned(1 downto 0);      -- (3 vidas)
  signal pierde_vida_s: std_logic;
  signal game_over_s  : std_logic;

  -- Versiones "gateadas" de los controles, para congelar cuando hay GAME OVER
  signal left_g, right_g       : std_logic;
  signal refresh_bola_g        : std_logic;

  -- Coordenadas y otros
  signal posp   : unsigned(9 downto 0) := "0011111111"; 
  signal ex, ey : std_logic_vector(9 downto 0);         -- copia local de ejex, ejey

  -- RGB de cada capa
  signal RGBfondo  : std_logic_vector(11 downto 0);
  signal RGBpala   : std_logic_vector(11 downto 0);
  signal RGBbola   : std_logic_vector(11 downto 0);
  signal RGBbloque : std_logic_vector(11 downto 0);

  signal ref   : std_logic;
  signal posp_s: std_logic_vector(9 downto 0);   -- posición de la pala desde su módulo

  -- Interfaz entre control_juego y bola
  signal data_bola_s    : std_logic_vector(3 downto 0);
  signal valid_bola_s   : std_logic;
  signal ready_bola_s   : std_logic;

  -- Interfaz entre control_juego y borrar_bloque / RAM
  signal data_bloque_s  : std_logic_vector(7 downto 0);
  signal valid_bloque_s : std_logic;
  signal ready_bloque_s : std_logic;

  -- RGB combinado desde control_juego
  signal RGB_in_s       : std_logic_vector(11 downto 0);

  -- Señales que salen de borrar_bloque hacia la RAM
  signal data_in_A_s : std_logic;
  signal ADDR_A_s    : std_logic_vector(7 downto 0);
  signal WR_A_s      : std_logic;

  -- Señales de la memoria de bloques
  signal data_out_A_s : std_logic;                 -- no usada en este top
  signal data_out_B_s : std_logic;

  -- Señal desde draw_bloques a la RAM (dirección de lectura)
  signal ADDR_B_s     : std_logic_vector(7 downto 0);

  -- Adaptadores de 1 bit a std_logic_vector(0 downto 0) para la RAM
  signal wea_v, dina_v, doutb_v : std_logic_vector(0 downto 0);

begin

  -------------------------------------------------------------------
  -- “GATEO” DE CONTROLES EN GAME OVER
  -- Cuando game_over_s = '1', se congelan los inputs de movimiento
  -- y el refresh de la bola, para que todo quede quieto.
  -------------------------------------------------------------------
  left_g         <= left   when game_over_s = '0' else '0';
  right_g        <= right  when game_over_s = '0' else '0';
  refresh_bola_g <= ref    when game_over_s = '0' else '0';

  ex  <= ejex;
  ey  <= ejey;
  ref <= refresh;

  wea_v(0)      <= WR_A_s;
  dina_v(0)     <= data_in_A_s;
  data_out_B_s  <= doutb_v(0);

  -------------------------------------------------------------------
  -- INSTANCIAS
  -------------------------------------------------------------------

  -- Fondo de pantalla
  U1 : fondo
    Port map(
      ejex  => ex,
      ejey  => ey,
      RGBin => RGBfondo
    );

  -- Pala del jugador
  U3 : pala
    Port map(
      clk     => clk,
      reset   => reset,
      left    => left_g,   -- movimiento izquierda (congelado en game over)
      right   => right_g,  -- movimiento derecha (congelado en game over)
      ejex    => ex,
      ejey    => ey,
      refresh => ref,      -- refresco general (no el gateado de la bola)
      pos_p   => posp_s,   -- posición de la pala (no se usa más arriba)
      RGBin   => RGBpala   -- color generado por la pala
    );

  -- Bola
  U4 : bola
    Port map(
      clk         => clk,
      reset       => reset,
      right       => right_g,
      left        => left_g,
      refresh     => refresh_bola_g,   -- refresco de la bola (parado en game over)
      ejex        => ex,
      ejey        => ey,
      data_bola   => data_bola_s,
      valid_bola  => valid_bola_s,
      ready_bola  => ready_bola_s,
      pierde_vida => pierde_vida_s,    -- evento: se cayó la bola
      RGBbola     => RGBbola
    );

  -- Control de colisiones y mezcla de RGB_bola / RGB_bloque / RGB_pala
  U5 : control_juego
    Port map(
      clk          => clk,
      reset        => reset,
      ejex         => ex,
      ejey         => ey,
      RGB_bola     => RGBbola,
      RGB_bloque   => RGBbloque,
      RGB_pala     => RGBpala,

      data_bloque  => data_bloque_s,
      valid_bloque => valid_bloque_s,
      ready_bloque => ready_bloque_s,

      RGB_in       => RGB_in_s,

      data_bola    => data_bola_s,
      valid_bola   => valid_bola_s,
      ready_bola   => ready_bola_s
    );

  -- Módulo que manda escribir "0" en la RAM cuando un bloque se rompe
  U6 : borrar_bloque
    Port map(
      clk          => clk,
      reset        => reset,
      data_bloque  => data_bloque_s,
      valid_bloque => valid_bloque_s,
      ready_bloque => ready_bloque_s,
      WR_A         => WR_A_s,
      data_in_A    => data_in_A_s,
      ADDR_A       => ADDR_A_s
    );

  -- Dibujo de bloques (a partir de data_out_B_s)
  U7 : draw_bloque
    Port map(
      clk        => clk,
      ejex       => ex,
      ejey       => ey,
      data_out_B => data_out_B_s,
      RGB_bloque => RGBbloque,
      ADDR_B     => ADDR_B_s
    );

  -- RAM de bloques (bit por celda) con dos puertos:
  --   - Puerto A: escritura (borrar_bloque)
  --   - Puerto B: lectura (draw_bloque)
  U8 : blk_mem_gen_0
    Port map(
      clka  => clk,
      wea   => wea_v,
      addra => ADDR_A_s,
      dina  => dina_v,
      clkb  => clk,
      addrb => ADDR_B_s,
      doutb => doutb_v
    );

  -- ROM del sprite de GAME OVER (imagen grande centrada)
  U_GO : sprite_game_over
    Port map (
      clka  => clk,
      addra => go_addr,
      douta => go_rgb
    );

  -- ROM con el sprite de “corazón” / vida
  U_VIDAS_ROM : blk_mem_gen_1
    Port map (
      clka  => clk,
      addra => vida_addr_s,
      douta => vida_rgb_s
    );

  -- HUD de vidas (usa la ROM anterior)
  U10 : vidas_hud
    Port map(
      ejex      => ex,
      ejey      => ey,
      num_vidas => vidas_reg,    -- número de vidas restante
      vida_rgb  => vida_rgb_s,   -- dato leído de la ROM
      vida_addr => vida_addr_s,  -- dirección para la ROM
      RGBvidas  => RGBvidas_s
    );

  -------------------------------------------------------------------
  -- CONTROL DE VIDAS Y GAME OVER
  --
  -- Lógica sencilla:
  --   - Empezamos con 3 vidas (vidas_reg = 3)
  --   - Cada vez que la bola emite pierde_vida_s = '1':
  --       * decrementamos vidas_reg (hasta 0)
  --       * si pasamos de 1 a 0 → activamos game_over_s
  --   - Una vez en GAME OVER, nos quedamos ahí “para siempre”.
  -------------------------------------------------------------------
  process(clk, reset)
  begin
    if reset = '1' then
      vidas_reg   <= to_unsigned(3, 2);  -- 3 vidas al inicio
      game_over_s <= '0';
    elsif rising_edge(clk) then
      -- Si ya estamos en GAME OVER, no salimos
      if game_over_s = '1' then
        game_over_s <= '1';
      else
        -- Evento de muerte de la bola
        if pierde_vida_s = '1' then
          if vidas_reg > 0 then
            vidas_reg <= vidas_reg - 1;
          end if;

          -- Si justo estábamos en 1, al decrementar pasamos a 0 → GAME OVER
          if vidas_reg = to_unsigned(1,2) then
            game_over_s <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;

  -------------------------------------------------------------------
  -- DIBUJO DE LA IMAGEN DE GAME OVER
  --
  -- Dibuja un sprite de 320x240 centrado en la pantalla:
  --   - X: 160..479
  --   - Y: 120..359
  --
  -- Calcula la dirección en la ROM como:
  --   addr = ly * 320 + lx
  --        = (ly << 8) + (ly << 6) + lx
  -------------------------------------------------------------------
  gameover_draw : process(ejex, ejey, game_over_s, go_rgb)
    variable x, y   : unsigned(9 downto 0);
    variable lx, ly : unsigned(9 downto 0);      -- coords locales 0..319 / 0..239
    variable ly17   : unsigned(16 downto 0);
    variable addr   : unsigned(16 downto 0);
  begin
    -- Por defecto, negro y dirección 0
    RGB_gameover <= (others => '0');
    go_addr      <= (others => '0');

    if game_over_s = '1' then
      x := unsigned(ejex);
      y := unsigned(ejey);

      -- Ventana donde va la imagen de GAME OVER (centrada)
      if (x >= to_unsigned(160,10)) and (x < to_unsigned(480,10)) and
         (y >= to_unsigned(120,10)) and (y < to_unsigned(360,10)) then

        -- coordenadas locales dentro de la imagen 320x240
        lx := x - to_unsigned(160,10);  -- 0..319
        ly := y - to_unsigned(120,10);  -- 0..239

        -- dirección = ly * 320 + lx
        -- 320 = 256 + 64 => (ly<<8) + (ly<<6)
        ly17 := resize(ly, 17);
        addr := (ly17 sll 8) + (ly17 sll 6) + resize(lx, 17);

        go_addr      <= std_logic_vector(addr);
        RGB_gameover <= go_rgb;  -- color leído de la ROM

      else
        -- fuera del rectángulo de la imagen: blanco (como borde o fondo)
        RGB_gameover <= (others => '1');
      end if;
    end if;
  end process;

  -------------------------------------------------------------------
  -- MUX FINAL DE COLORES HACIA RGBin
  --
  -- Prioridad:
  --   1) Si estamos en GAME OVER → mostrar solo la imagen de GAME OVER.
  --   2) Si no, el HUD de vidas tiene preferencia.
  --   3) Si tampoco hay HUD en este píxel → fondo OR RGB_in_s
  --      (donde RGB_in_s ya viene de mezclar bola/pala/bloques).
  -------------------------------------------------------------------
  process(RGB_in_s, RGBfondo, RGB_gameover, RGBvidas_s, game_over_s)
  begin
    if game_over_s = '1' then
      -- Pantalla de GAME OVER (imagen de la ROM)
      RGBin <= RGB_gameover;
    else
      -- HUD de vidas tiene prioridad sobre el resto
      if RGBvidas_s /= CERO_RGB then
        RGBin <= RGBvidas_s;
      else
        -- fondo + resto de elementos del juego (bola, pala, bloques)
        RGBin <= RGBfondo or RGB_in_s;
      end if;
    end if;
  end process;

end Behavioral;
