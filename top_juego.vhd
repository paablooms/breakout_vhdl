----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 14.10.2025 20:13:51
-- Design Name: 
-- Module Name: juego_top - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- Este es el top de todo el proyecto.
-- 
-- Se encarga de:
--   - Conectar el driver VGA (VGA_driver), que genera:
--       * las señales de sincronismo HS / VS
--       * las coordenadas de píxel (ejex, ejey)
--       * las señales de blanking (o1h, o1v)
--       * una señal de refresh para el juego
--   - Instanciar el módulo "juego", que:
--       * recibe las coordenadas de píxel
--       * calcula el color RGB de ese píxel según el estado del juego
--   - Pasar ese RGB por "gen_color", que:
--       * aplica el blanking horizontal/vertical
--       * y saca el RGB final hacia la salida física.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--library UNISIM;
--use UNISIM.VComponents.all;

----------------------------------------------------------------------------------
-- ENTIDAD
----------------------------------------------------------------------------------
entity juego_top is
  Generic(
    posx : unsigned(9 downto 0) := to_unsigned(455,10);
    posy : unsigned(9 downto 0) := to_unsigned(256,10)
  );
  Port (
    clk   : in  std_logic;                         -- reloj principal
    reset : in  std_logic;                         -- reset global
    left  : in  std_logic;                         -- control izquierda
    right : in  std_logic;                         -- control derecha

    VS    : out std_logic;                         -- sincronismo vertical VGA
    HS    : out std_logic;                         -- sincronismo horizontal VGA
    RGB   : out std_logic_vector(11 downto 0)      -- color final hacia el monitor
  );
end juego_top;


architecture Behavioral of juego_top is

  ------------------------------------------------------------------
  -- DECLARACIÓN DE COMPONENTES
  ------------------------------------------------------------------

  -- Driver VGA: genera HS, VS, coordenadas de píxel y blanking
  component VGA_driver is
    Port (
      clk        : in  std_logic;
      reset      : in  std_logic;
      VS         : out std_logic;
      HS         : out std_logic;
      ejex_out   : out std_logic_vector(9 downto 0); -- X del píxel activo
      ejey_out   : out std_logic_vector(9 downto 0); -- Y del píxel activo
      o1h        : out std_logic;                    -- blanking horizontal
      o1v        : out std_logic;                    -- blanking vertical
      refresh_out: out std_logic                     -- pulso de refresco para el juego
    );
  end component;

  -- Núcleo del juego (lógica + dibujo)
  component juego is
    Port (
      clk     : in  std_logic;
      reset   : in  std_logic;
      left    : in  std_logic;
      right   : in  std_logic;
      ejex    : in  std_logic_vector(9 downto 0);    -- coordenada X del píxel
      ejey    : in  std_logic_vector(9 downto 0);    -- coordenada Y del píxel
      refresh : in  std_logic;                       -- pulso de refresco de lógica
      RGBin   : out std_logic_vector(11 downto 0)    -- color generado por el juego
    );
  end component;

  -- Módulo que aplica blanking y saca el RGB final
  component gen_color is
    Port (
      blank_h : in  std_logic;                        -- 0/1 según zona visible horizontal
      blank_v : in  std_logic;                        -- 0/1 según zona visible vertical
      RGBin   : in  std_logic_vector(11 downto 0);    -- color "lógico"
      RGBout  : out std_logic_vector(11 downto 0)     -- color que va al monitor
    );
  end component;

  ------------------------------------------------------------------
  -- SEÑALES INTERNAS
  ------------------------------------------------------------------
  signal ex, ey      : std_logic_vector(9 downto 0);  -- coordenadas X/Y desde VGA_driver
  signal RGBin       : std_logic_vector(11 downto 0); -- color desde "juego"
  signal RGBout      : std_logic_vector(11 downto 0); 
  signal ref         : std_logic;                     -- pulso de refresco
  signal o1h_s       : std_logic;                     -- blanking horizontal
  signal o1v_s       : std_logic;                     -- blanking vertical

begin

  ------------------------------------------------------------------
  -- INSTANCIA DEL DRIVER VGA
  --
  -- Genera:
  --   - HS, VS para el monitor.
  --   - ex, ey para decir en qué píxel estamos.
  --   - o1h_s, o1v_s para indicar si estamos en zona visible u “off-screen”.
  --   - refresh
  ------------------------------------------------------------------
  U1 : VGA_driver
    Port map(
      clk         => clk,
      reset       => reset,
      VS          => VS,
      HS          => HS,
      o1h         => o1h_s,
      o1v         => o1v_s,
      ejex_out    => ex,
      ejey_out    => ey,
      refresh_out => ref
    );

  ------------------------------------------------------------------
  -- INSTANCIA DEL NÚCLEO DEL JUEGO
  --
  -- Recibe coordenadas de píxel y el pulso de refresh generado por
  -- el driver VGA, además de las entradas de control del usuario
  -- (left / right). Devuelve el color que debería pintarse ahí.
  ------------------------------------------------------------------
  U2 : juego
    Port map(
      clk     => clk,
      reset   => reset,
      left    => left,
      right   => right,
      ejex    => ex,
      ejey    => ey,
      refresh => ref,
      RGBin   => RGBin
    );

  ------------------------------------------------------------------
  -- INSTANCIA DEL GENERADOR DE COLOR FINAL
  --   - Saca finalmente el RGB hacia el monitor.
  ------------------------------------------------------------------
  U3 : gen_color
    Port map(
      blank_h => o1h_s,
      blank_v => o1v_s,
      RGBin   => RGBin,
      RGBout  => RGB
    );

end Behavioral;
