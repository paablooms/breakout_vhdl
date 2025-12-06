library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity game_over_text is
  Port (
    ejex     : in  std_logic_vector(9 downto 0);
    ejey     : in  std_logic_vector(9 downto 0);
    enable   : in  std_logic;                       -- game_over_s
    RGB_text : out std_logic_vector(11 downto 0)    -- salida de color
  );
end game_over_text;

architecture Behavioral of game_over_text is

  -- Colores
  constant C_BLACK : std_logic_vector(11 downto 0) := (others => '0');
  constant C_WHITE : std_logic_vector(11 downto 0) := "111111111111"; -- blanco

  -- Parámetros del texto
  constant CHAR_W : integer := 8;
  constant CHAR_H : integer := 8;
  constant NUM_CHARS : integer := 9;  -- "GAME OVER" = 9 caracteres (incluye espacio)

  -- Zona donde se dibuja el texto (centrado aprox en la zona de juego 512x480)
  constant X0 : integer := 220;       -- coordenada X de inicio
  constant Y0 : integer := 200;       -- coordenada Y de inicio

  subtype char_row is std_logic_vector(7 downto 0);
  type char_bitmap is array (0 to 7) of char_row;    -- 8 filas de 8 bits
  type glyph_array is array (0 to NUM_CHARS-1) of char_bitmap;

  -- Definimos los caracteres G, A, M, E, (espacio), O, V, E, R
  -- 1 = píxel encendido, 0 = apagado
  -- bit 7 = píxel de la izquierda, bit 0 = píxel de la derecha
  constant GLYPHS : glyph_array := (
    -- 0: 'G'
    (
      "01111110",
      "01000010",
      "01000000",
      "01001110",
      "01000010",
      "01000010",
      "01111110",
      "00000000"
    ),
    -- 1: 'A'
    (
      "00011000",
      "00100100",
      "01000010",
      "01000010",
      "01111110",
      "01000010",
      "01000010",
      "00000000"
    ),
    -- 2: 'M'
    (
      "01000010",
      "01100110",
      "01011010",
      "01000010",
      "01000010",
      "01000010",
      "01000010",
      "00000000"
    ),
    -- 3: 'E'
    (
      "01111110",
      "01000000",
      "01000000",
      "01111100",
      "01000000",
      "01000000",
      "01111110",
      "00000000"
    ),
    -- 4: ' ' (espacio)
    (
      "00000000",
      "00000000",
      "00000000",
      "00000000",
      "00000000",
      "00000000",
      "00000000",
      "00000000"
    ),
    -- 5: 'O'
    (
      "00111100",
      "01000010",
      "01000010",
      "01000010",
      "01000010",
      "01000010",
      "00111100",
      "00000000"
    ),
    -- 6: 'V'
    (
      "01000010",
      "01000010",
      "01000010",
      "00100100",
      "00100100",
      "00011000",
      "00011000",
      "00000000"
    ),
    -- 7: 'E' (otra vez)
    (
      "01111110",
      "01000000",
      "01000000",
      "01111100",
      "01000000",
      "01000000",
      "01111110",
      "00000000"
    ),
    -- 8: 'R'
    (
      "01111100",
      "01000010",
      "01000010",
      "01111100",
      "01001000",
      "01000100",
      "01000010",
      "00000000"
    )
  );

begin

  process(ejex, ejey, enable)
    variable x, y       : integer;
    variable x_rel, y_rel : integer;
    variable char_idx   : integer;   -- 0..8
    variable col_idx    : integer;   -- 0..7
    variable row_idx    : integer;   -- 0..7
    variable bit_on     : std_logic;
  begin
    -- por defecto, nada
    RGB_text <= C_BLACK;

    if enable = '1' then
      x := to_integer(unsigned(ejex));
      y := to_integer(unsigned(ejey));

      -- ¿estamos dentro de la caja del texto?
      if (x >= X0) and (x < X0 + NUM_CHARS*CHAR_W) and
         (y >= Y0) and (y < Y0 + CHAR_H) then

        x_rel := x - X0;
        y_rel := y - Y0;

        char_idx := x_rel / CHAR_W;      -- columna de carácter (0..8)
        col_idx  := x_rel mod CHAR_W;    -- columna dentro del carácter (0..7)
        row_idx  := y_rel;               -- fila dentro del carácter (0..7)

        -- bit 7 es el píxel de más a la izquierda
        bit_on := GLYPHS(char_idx)(row_idx)(7 - col_idx);

        if bit_on = '1' then
          RGB_text <= C_WHITE;
        else
          RGB_text <= C_BLACK;
        end if;
      else
        RGB_text <= C_BLACK;
      end if;
    else
      RGB_text <= C_BLACK;
    end if;
  end process;

end Behavioral;
