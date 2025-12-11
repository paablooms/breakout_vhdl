library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

----------------------------------------------------------------------------------
-- Este módulo dibuja el HUD de vidas en la parte derecha de la pantalla.
--
-- Idea general:
--   - Solo actúa cuando x ≥ 512 (es decir, en la franja derecha 512..639).
--   - Pinta:
--       * Un fondo blanco en esa zona.
--       * Hasta 3 sprites de vida (corazones)
--         organizados en columna.
--
--   - Para los sprites de vida:
--       * Cada vida es un sprite 16x16.
--       * La dirección a la BRAM va de 0 a 255 (16x16 = 256 direcciones).
--       * Se reutiliza la misma ROM para todas las vidas, cambiando la posición
--         para cada una (pero el patrón de 16x16 es el mismo).
--
-- Señales importantes:
--   - ejex, ejey   → coordenadas del píxel actual (de VGA_driver).
--   - num_vidas    → cuántas vidas quedan (0..3).
--   - vida_addr    → dirección hacia la BRAM del sprite de vida.
--   - vida_rgb     → el color leído de la BRAM para esa dirección.
--   - RGBvidas     → color que este módulo aporta al píxel actual.
----------------------------------------------------------------------------------
entity vidas_hud is
  Port (
    ejex      : in  std_logic_vector(9 downto 0);
    ejey      : in  std_logic_vector(9 downto 0);
    num_vidas : in  unsigned(1 downto 0);              -- 0..3 vidas

    -- interfaz hacia la memoria del sprite de vida
    vida_rgb  : in  std_logic_vector(11 downto 0);     -- dato leído de la BRAM (16x16)
    vida_addr : out std_logic_vector(7 downto 0);      -- dirección 0..255

    -- color generado por el HUD de vidas para este píxel
    RGBvidas  : out std_logic_vector(11 downto 0)
  );
end vidas_hud;

architecture Behavioral of vidas_hud is

  -- Colores básicos
  constant C_BLACK : std_logic_vector(11 downto 0) := (others => '0');
  constant C_WHITE : std_logic_vector(11 downto 0) := (others => '1');
  constant CERO    : std_logic_vector(11 downto 0) := (others => '0');
begin

  ------------------------------------------------------------------------------
  -- PROCESO PRINCIPAL
  --
  -- Dado (ejex, ejey):
  --   - Decide si estamos dentro de la zona de HUD (x >= 512).
  --   - Si no lo estamos: RGBvidas = negro (transparente para el top).
  --   - Si sí lo estamos:
  --       * Fondo blanco por defecto.
  --       * Si el píxel está dentro de alguna de las 3 vidas activas:
  --            vida_addr = dirección dentro del sprite
  --            RGBvidas  = vida_rgb (si no es 0).
  ------------------------------------------------------------------------------
  process(ejex, ejey, num_vidas, vida_rgb)
    -- Coordenadas del píxel en enteros para operar más cómodo
    variable x, y      : integer;

    -- Marca si el píxel pertenece al dibujo de la "V" (texto)
    variable pixel_on  : std_logic;

    -- Coordenadas locales dentro del sprite de vida (0..15)
    variable sx, sy    : integer;

    -- Dirección interna para la ROM del sprite (0..255)
    variable addr_int  : integer range 0 to 255;
  begin
    -- Convertimos X e Y a integer
    x := to_integer(unsigned(ejex));
    y := to_integer(unsigned(ejey));

    -- Valores por defecto:
    --   - Fuera de la zona de HUD → negro (no dibuja nada)
    --   - pixel_on = '0' → asumimos que no está en el texto "V"
    --   - addr_int = 0  → dirección neutra por defecto hacia la BRAM
    RGBvidas <= (others => '0');
    pixel_on := '0';
    addr_int := 0;

    --------------------------------------------------------------------------
    -- ZONA DERECHA DEL HUD: x de 512 a 639
    --------------------------------------------------------------------------
    if x >= 512 then
      -- Fondo blanco por defecto en toda la franja derecha
      RGBvidas <= C_WHITE;

      ------------------------------------------------------------------------
      -- VIDA 1: sprite 16x16 en x 540..555, y 100..115
      --
      -- Se dibuja solo si num_vidas >= 1.
      --   - sx, sy son las coordenadas locales dentro del sprite (0..15).
      --   - addr_int = sy*16 + sx → índice en la ROM (0..255).
      --
      -- Si el valor de vida_rgb es distinto de 0 (CERO), se pinta ese color
      -- sobre el fondo blanco. Si es 0, se considera transparente.
      ------------------------------------------------------------------------
      if (num_vidas >= 1) and
         (x >= 540 and x < 556) and
         (y >= 100 and y < 116) then

        sx       := x - 540;            -- 0..15
        sy       := y - 100;            -- 0..15
        addr_int := sy*16 + sx;         -- 0..255

        -- usamos el color que viene de la BRAM
        if vida_rgb /= CERO then        -- 0 = transparente
          RGBvidas <= vida_rgb;
        end if;
      end if;

      ------------------------------------------------------------------------
      -- VIDA 2: sprite 16x16 en x 540..555, y 130..145
      --
      -- Igual que la VIDA 1 pero desplazada 30 px hacia abajo.
      ------------------------------------------------------------------------
      if (num_vidas >= 2) and
         (x >= 540 and x < 556) and
         (y >= 130 and y < 146) then

        sx       := x - 540;
        sy       := y - 130;
        addr_int := sy*16 + sx;

        if vida_rgb /= CERO then
          RGBvidas <= vida_rgb;
        end if;
      end if;

      ------------------------------------------------------------------------
      -- VIDA 3: sprite 16x16 en x 540..555, y 160..175
      --
      -- Igual que las anteriores, una tercera casilla más abajo.
      ------------------------------------------------------------------------
      if (num_vidas >= 3) and
         (x >= 540 and x < 556) and
         (y >= 160 and y < 176) then

        sx       := x - 540;
        sy       := y - 160;
        addr_int := sy*16 + sx;

        if vida_rgb /= CERO then
          RGBvidas <= vida_rgb;
        end if;
      end if;

      ------------------------------------------------------------------------
      -- Dibujo de la letra "V" en NEGRO por encima del fondo blanco
      --
      -- Si pixel_on = '1', este píxel pertenece a la letra de texto
      -- y tiene prioridad sobre el fondo blanco (y sobre cualquier otra cosa
      -- que no sea un sprite de vida que se haya pintado después).
      ------------------------------------------------------------------------
      if pixel_on = '1' then
        RGBvidas <= C_BLACK;
      end if;

    else
      ----------------------------------------------------------------------
      -- ZONA DE JUEGO (x < 512):
      -- Este módulo no pinta nada aquí → negro (transparente).
      ----------------------------------------------------------------------
      RGBvidas <= (others => '0');
    end if;

    ------------------------------------------------------------------------
    -- Salida de la dirección hacia la ROM del sprite de vida
    --
    -- addr_int ya se ha calculado según la vida (1,2,3) y la posición dentro
    -- del sprite, o bien se ha quedado a 0 por defecto si el píxel no está
    -- en ninguna de las zonas de vidas.
    ------------------------------------------------------------------------
    vida_addr <= std_logic_vector(to_unsigned(addr_int, 8));
  end process;

end Behavioral;
