library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vidas_hud is
  Port (
    ejex      : in  std_logic_vector(9 downto 0);
    ejey      : in  std_logic_vector(9 downto 0);
    num_vidas : in  unsigned(1 downto 0);              -- 0..3

    -- interfaz hacia la memoria del sprite de vida
    vida_rgb  : in  std_logic_vector(11 downto 0);     -- dato leído de la BRAM
    vida_addr : out std_logic_vector(7 downto 0);      -- dirección 0..255

    RGBvidas  : out std_logic_vector(11 downto 0)
  );
end vidas_hud;

architecture Behavioral of vidas_hud is

  constant C_BLACK : std_logic_vector(11 downto 0) := (others => '0');
  constant C_WHITE : std_logic_vector(11 downto 0) := (others => '1');
  constant CERO: std_logic_vector(11 downto 0) := (others => '0');
begin

  process(ejex, ejey, num_vidas, vida_rgb)
    variable x, y : integer;
    variable pixel_on : std_logic;

    variable sx, sy : integer;
    variable addr_int : integer range 0 to 255;
  begin
    x := to_integer(unsigned(ejex));
    y := to_integer(unsigned(ejey));

    -- por defecto: fuera del HUD nada
    RGBvidas <= (others => '0');
    pixel_on := '0';
    addr_int := 0;                  -- dirección por defecto

    -- ZONA DERECHA HUD: x de 512 a 639
    if x >= 512 then
        -- Fondo blanco por defecto
        RGBvidas <= C_WHITE;

        ----------------------------------------------------------------
        -- Texto "VIDAS" (solo letra V como tenías)
        ----------------------------------------------------------------
        if (y >= 40) and (y < 70) then
            -- letra V (x 520..535)
            if (x >= 520 and x < 535) then
                if ( (y - 40) = (x - 520)/2 ) or ( (y - 40) = 15 - (x - 520)/2 ) then
                    pixel_on := '1';
                end if;
            end if;
        end if;

        ----------------------------------------------------------------
        -- VIDA 1: sprite 16x16 en x 540..555, y 100..115
        ----------------------------------------------------------------
        if (num_vidas >= 1) and
           (x >= 540 and x < 556) and
           (y >= 100 and y < 116) then

            sx      := x - 540;            -- 0..15
            sy      := y - 100;            -- 0..15
            addr_int := sy*16 + sx;        -- 0..255

            -- usamos el color que viene de la BRAM
            -- si tratas 0 como transparente:
            if vida_rgb /= CERO then
              RGBvidas <= vida_rgb;
            end if;
        end if;

        ----------------------------------------------------------------
        -- VIDA 2: sprite 16x16 en x 540..555, y 130..145
        ----------------------------------------------------------------
        if (num_vidas >= 2) and
           (x >= 540 and x < 556) and
           (y >= 130 and y < 146) then

            sx      := x - 540;
            sy      := y - 130;
            addr_int := sy*16 + sx;

            if vida_rgb /= CERO then
              RGBvidas <= vida_rgb;
            end if;
        end if;

        ----------------------------------------------------------------
        -- VIDA 3: sprite 16x16 en x 540..555, y 160..175
        ----------------------------------------------------------------
        if (num_vidas >= 3) and
           (x >= 540 and x < 556) and
           (y >= 160 and y < 176) then

            sx      := x - 540;
            sy      := y - 160;
            addr_int := sy*16 + sx;

            if vida_rgb /= CERO then
              RGBvidas <= vida_rgb;
            end if;
        end if;

        ----------------------------------------------------------------
        -- Texto "V" en negro por encima del fondo blanco
        ----------------------------------------------------------------
        if pixel_on = '1' then
            RGBvidas <= C_BLACK;
        end if;
    else
        -- zona de juego (no dibuja nada desde este módulo)
        RGBvidas <= (others => '0');
    end if;

    -- sacar dirección hacia la BRAM
    vida_addr <= std_logic_vector(to_unsigned(addr_int, 8));
  end process;

end Behavioral;
