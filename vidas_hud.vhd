library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vidas_hud is
  Port (
    ejex      : in  std_logic_vector(9 downto 0);
    ejey      : in  std_logic_vector(9 downto 0);
    num_vidas : in  unsigned(1 downto 0);              -- 0..3
    RGBvidas  : out std_logic_vector(11 downto 0)
  );
end vidas_hud;

architecture Behavioral of vidas_hud is

  constant C_BLACK : std_logic_vector(11 downto 0) := (others => '0');
  constant C_WHITE : std_logic_vector(11 downto 0) := (others => '1');
  constant C_GREEN : std_logic_vector(11 downto 0) := "000011110000"; -- como tu bola

begin

  process(ejex, ejey, num_vidas)
    variable x, y : integer;
    variable pixel_on : std_logic;
  begin
    x := to_integer(unsigned(ejex));
    y := to_integer(unsigned(ejey));

    -- por defecto: negro
    RGBvidas <= (others => '0');
    pixel_on := '0';

    -- ZONA DERECHA HUD: x de 512 a 639
    if x >= 512 then
        -- Fondo blanco
        RGBvidas <= C_WHITE;

        -- Texto "VIDAS" simple (barras, sin fuente complicada)
        -- Lo ponemos en y entre 40 y 70
        if (y >= 40) and (y < 70) then
            -- letra V (x 520..535)
            if (x >= 520 and x < 535) then
                if ( (y - 40) = (x - 520)/2 ) or ( (y - 40) = 15 - (x - 520)/2 ) then
                    pixel_on := '1';
                end if;
            end if;
            -- para no alargar, aquí podrías añadir I, D, A, S
            -- con rectángulos y líneas sencillas como hicimos con la pala y la bola
        end if;

        -- PUNTOS DE VIDAS (tres cuadraditos verdes bajo el texto)
        -- Vida 1: cuadrado en x 540..555, y 100..115
        if (num_vidas >= 1) and
           (x >= 540 and x < 555) and
           (y >= 100 and y < 115) then
            RGBvidas <= C_GREEN;
        end if;

        -- Vida 2: cuadrado en x 540..555, y 130..145
        if (num_vidas >= 2) and
           (x >= 540 and x < 555) and
           (y >= 130 and y < 145) then
            RGBvidas <= C_GREEN;
        end if;

        -- Vida 3: cuadrado en x 540..555, y 160..175
        if (num_vidas >= 3) and
           (x >= 540 and x < 555) and
           (y >= 160 and y < 175) then
            RGBvidas <= C_GREEN;
        end if;

        -- Si el texto "V" ha activado pixel_on, pintamos en negro encima del fondo blanco
        if pixel_on = '1' then
            RGBvidas <= C_BLACK;
        end if;
    else
        -- zona de juego (no tocamos nada desde este módulo)
        RGBvidas <= (others => '0');
    end if;
  end process;

end Behavioral;

