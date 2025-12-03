----------------------------------------------------------------------------------
-- Module Name: bola - Behavioral
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bola is
    Port (
        refresh    : in  std_logic;
        eje_x      : in  STD_LOGIC_VECTOR (9 downto 0);
        eje_y      : in  STD_LOGIC_VECTOR (9 downto 0);
        data_bola  : in  STD_LOGIC_VECTOR(3 downto 0);
        valid_bola : in  STD_LOGIC;
        ready_bola : out STD_LOGIC;
        RED_bola   : out STD_LOGIC_VECTOR (3 downto 0);
        GRN_bola   : out STD_LOGIC_VECTOR (3 downto 0);
        BLU_bola   : out STD_LOGIC_VECTOR (3 downto 0);
        clk        : in  std_logic;
        reset      : in  std_logic
    );
end bola;

architecture Behavioral of bola is

    ----------------------------------------------------------------
    -- Registros de posición y dirección
    ----------------------------------------------------------------
    signal posx   : unsigned(9 downto 0);
    signal posy   : unsigned(9 downto 0);
    signal dcha   : std_logic;  -- '1' derecha, '0' izquierda
    signal arriba : std_logic;  -- '1' arriba,   '0' abajo

    -- Contadores de choques con bloques en este frame
    signal cnt_lat  : unsigned(3 downto 0);  -- impactos laterales
    signal cnt_vert : unsigned(3 downto 0);  -- impactos verticales

    ----------------------------------------------------------------
    -- Constantes de velocidad y límites
    ----------------------------------------------------------------
    constant VEL    : unsigned(9 downto 0) := to_unsigned(2,10);   -- 2 píxeles
    constant X_MIN  : unsigned(9 downto 0) := to_unsigned(0,10);
    constant X_MAX  : unsigned(9 downto 0) := to_unsigned(504,10); -- 512-8
    constant Y_MIN  : unsigned(9 downto 0) := to_unsigned(0,10);
    constant Y_MAX  : unsigned(9 downto 0) := to_unsigned(472,10); -- 480-8

begin

    -- La bola siempre está "ready"
    ready_bola <= '1';

    ----------------------------------------------------------------
    -- PROCESO SÍNCRONO ÚNICO
    ----------------------------------------------------------------
    proc_bola: process(clk, reset)
        variable locx, locy : integer;
        variable dx,  dy    : integer;
        variable ax,  ay    : integer;
        variable dir_x, dir_y : std_logic;
        variable new_posx, new_posy : unsigned(9 downto 0);
    begin
        if (reset = '1') then
            -- Bola apoyada sobre la pala
            posx   <= "0011111111"; -- 255
            posy   <= "0110011111"; -- ~415
            dcha   <= '1';          -- hacia la derecha
            arriba <= '1';          -- hacia arriba

            cnt_lat  <= (others => '0');
            cnt_vert <= (others => '0');

        elsif rising_edge(clk) then

            ----------------------------------------------------------------
            -- 1) ACUMULAR CHOQUES CON BLOQUES (data_bola = "0001")
            --    Clasificamos lateral vs vertical comparando |dx| y |dy|
            ----------------------------------------------------------------
            if (valid_bola = '1') and (data_bola = "0001") then
                -- Coordenadas locales del píxel dentro de la bola (0..7)
                locx := to_integer(unsigned(eje_x)) - to_integer(posx);
                locy := to_integer(unsigned(eje_y)) - to_integer(posy);

                if (locx >= 0) and (locx <= 7) and
                   (locy >= 0) and (locy <= 7) then

                    -- Centro aprox en (3,3)
                    dx := locx - 3;
                    dy := locy - 3;

                    -- Módulos
                    if dx < 0 then ax := -dx; else ax := dx; end if;
                    if dy < 0 then ay := -dy; else ay := dy; end if;

                    -- Contadores saturados (máx 15)
                    if (ax > ay) then
                        if cnt_lat /= "1111" then
                            cnt_lat <= cnt_lat + 1;
                        end if;
                    elsif (ay > ax) then
                        if cnt_vert /= "1111" then
                            cnt_vert <= cnt_vert + 1;
                        end if;
                    else
                        -- esquina -> cuenta como ambos
                        if cnt_lat /= "1111" then
                            cnt_lat <= cnt_lat + 1;
                        end if;
                        if cnt_vert /= "1111" then
                            cnt_vert <= cnt_vert + 1;
                        end if;
                    end if;
                end if;
            end if;

            ----------------------------------------------------------------
            -- 2) CHOQUE CON PALA (data_bola = "0000")
            --    Rebote vertical hacia arriba
            ----------------------------------------------------------------
            if (valid_bola = '1') and (data_bola = "0000") then
                arriba <= '1';
            end if;

            ----------------------------------------------------------------
            -- 3) EN CADA PULSO REFRESH:
            --       * decidir rebote según cnt_lat / cnt_vert
            --       * aplicar paredes
            --       * mover bola
            --       * resetear contadores
            ----------------------------------------------------------------
            if (refresh = '1') then

                -- Direcciones base (antes del choque con bloque)
                dir_x := dcha;
                dir_y := arriba;

                -- Elegir tipo de rebote con bloque usando los contadores
                if (cnt_lat > 0) or (cnt_vert > 0) then
                    if (cnt_lat > cnt_vert) then
                        -- choque predominantemente lateral:
                        -- invertir X, mantener Y
                        dir_x := not dcha;
                        dir_y := arriba;
                    elsif (cnt_vert > cnt_lat) then
                        -- choque predominantemente vertical:
                        -- invertir Y, mantener X
                        dir_x := dcha;
                        dir_y := not arriba;
                    else
                        -- empate (esquina clara): invertir ambos
                        dir_x := not dcha;
                        dir_y := not arriba;
                    end if;
                end if;

                ----------------------------------------------------------------
                -- Movimiento en X con paredes (usando dir_x local)
                ----------------------------------------------------------------
                new_posx := posx;

                if (dir_x = '1') then
                    -- hacia la derecha
                    if (posx + VEL <= X_MAX) then
                        new_posx := posx + VEL;
                    else
                        -- choca con pared derecha -> invierte X
                        new_posx := X_MAX;
                        dir_x    := '0';
                    end if;
                else
                    -- hacia la izquierda
                    if (posx >= X_MIN + VEL) then
                        new_posx := posx - VEL;
                    else
                        -- choca con pared izquierda -> invierte X
                        new_posx := X_MIN;
                        dir_x    := '1';
                    end if;
                end if;

                ----------------------------------------------------------------
                -- Movimiento en Y con techo/suelo (usando dir_y local)
                ----------------------------------------------------------------
                new_posy := posy;

                if (dir_y = '1') then
                    -- subiendo
                    if (posy >= Y_MIN + VEL) then
                        new_posy := posy - VEL;
                    else
                        -- techo -> invierte Y
                        new_posy := Y_MIN;
                        dir_y    := '0';
                    end if;
                else
                    -- bajando
                    if (posy + VEL <= Y_MAX) then
                        new_posy := posy + VEL;
                    else
                        -- suelo (aquí podrías gestionar GAME OVER)
                        new_posy := Y_MAX;
                    end if;
                end if;

                -- Aplicar nuevas posiciones y direcciones
                posx   <= new_posx;
                posy   <= new_posy;
                dcha   <= dir_x;
                arriba <= dir_y;

                -- Resetear contadores para el siguiente frame
                cnt_lat  <= (others => '0');
                cnt_vert <= (others => '0');

            end if; -- refresh

        end if; -- rising_edge
    end process;

    ----------------------------------------------------------------
    -- DIBUJO BOLA (8x8 verde)
    ----------------------------------------------------------------
    draw_bola: process(eje_x, eje_y, posx, posy)
    begin
        if ( (unsigned(eje_x) >= posx) and
             (unsigned(eje_x) <  posx + to_unsigned(8,10)) and
             (unsigned(eje_y) >= posy) and
             (unsigned(eje_y) <  posy + to_unsigned(8,10)) ) then

            RED_bola <= "0000";
            GRN_bola <= "1111";
            BLU_bola <= "0000";
        else
            RED_bola <= (others => '0');
            GRN_bola <= (others => '0');
            BLU_bola <= (others => '0');
        end if;
    end process;

end Behavioral;
