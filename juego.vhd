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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity juego is
    Generic(
           posx : unsigned(9 downto 0) := to_unsigned(455,10);
           posy : unsigned(9 downto 0) := to_unsigned(256,10)
           );
    Port ( clk,reset : in std_logic;
           left,right : in STD_LOGIC;
           ejex,ejey : in STD_LOGIC_VECTOR(9 downto 0);
           refresh : in STD_LOGIC;
           RGBin : out STD_LOGIC_VECTOR (11 downto 0));
end juego;

architecture Behavioral of juego is

--constant posx : unsigned ( 9 downto 0) := to_unsigned(455,10);
--constant posy : unsigned ( 9 downto 0) := to_unsigned(256,10);
component bola is
      Port (
        clk: in std_logic;
        reset: in std_logic;
        refresh: in std_logic;
        ejex: in std_logic_vector(9 downto 0); --coordenada x de la bola
        ejey: in std_logic_vector(9 downto 0); -- coordenada y de la bola
        data_bola: in std_logic_vector(3 downto 0);
        valid_bola: in std_logic;
        ready_bola: out std_logic;
        RGBbola: out std_logic_vector(11 downto 0)
        );
end component;

component control_juego is
Port (
    clk,reset : in std_logic;

-- RGBs de entrada (son los que tenemos que comparar)
    RGB_bola   : in  std_logic_vector(11 downto 0);
    RGB_bloque : in  std_logic_vector(11 downto 0);
    RGB_pala   : in  std_logic_vector(11 downto 0);

    -- Intercambio con bloques
    data_bloque  : out std_logic_vector(3 downto 0);
    valid_bloque : out std_logic;
    ready_bloque : in  std_logic;

    -- 
    RGB_in     : out std_logic_vector(11 downto 0);

    -- Interfaz con "bola"
    data_bola  : out std_logic_vector(3 downto 0);
    valid_bola : out std_logic;
    ready_bola : in  std_logic
      );
end component;

component pala is
    Port ( left : in STD_LOGIC;
           right : in STD_LOGIC;
           ejex : in STD_LOGIC_VECTOR(9 downto 0);
           ejey : in STD_LOGIC_VECTOR(9 downto 0);
           refresh : in STD_LOGIC;
           pos_p : out std_logic_vector(9 downto 0);
           RGBin : out STD_LOGIC_VECTOR (11 downto 0));
end component;

component fondo is
    Generic(
           posx : unsigned(9 downto 0) := to_unsigned(455,10);
           posy : unsigned(9 downto 0) := to_unsigned(256,10)
           );
    Port ( ejex : in STD_LOGIC_VECTOR(9 downto 0);
           ejey : in STD_LOGIC_VECTOR(9 downto 0);
           RGBin : out STD_LOGIC_VECTOR (11 downto 0));
end component;

signal posp : unsigned(9 downto 0) := "0011111111";
signal ex, ey : std_logic_vector(9 downto 0);
signal RGBfondo, RGBpala, RGBbola, RGBbloque : std_logic_vector(11 downto 0);
signal ref : std_logic;
signal posp_s : std_logic_vector(9 downto 0);

signal data_bola_s    : std_logic_vector(3 downto 0);
signal valid_bola_s   : std_logic;
signal ready_bola_s   : std_logic;

signal data_bloque_s  : std_logic_vector(3 downto 0);
signal valid_bloque_s : std_logic;
signal ready_bloque_s : std_logic;

begin


U1 : fondo
Port map(
    ejex => ex,
    ejey => ey,
    RGBin => RGBfondo
);

U3 : pala
    Port map(
        left    => left,   -- Señal izquierda
        right   => right,   -- Señal derecha
        ejex    => ex,   -- Coordenada X del VGA
        ejey    => ey,   -- Coordenada Y del VGA
        refresh => ref,   -- Señal de refresco del VGA
        pos_p   => posp_s,   -- Salida con la posición de la pala
        RGBin   => RGBpala    -- Color generado por la pala (12 bits)
    );

    
U4 : bola
    Port map(
        clk        => clk,   -- Reloj
        reset      => reset,   -- Reset
        refresh    => ref,   -- Señal de refresco del VGA
        ejex       => ex,   -- Coordenada X
        ejey       => ey,   -- Coordenada Y
        data_bola  => data_bola_s ,   -- Datos desde el control del juego
        valid_bola => valid_bola_s ,   -- Validación desde el control del juego
        ready_bola => ready_bola_s ,   -- Indica que la bola está lista
        RGBbola    => RGBbola    -- Color generado por la bola
    );

    
U5 : control_juego
    Port map(
        clk          => clk,   -- Reloj
        reset        => reset,   -- Reset

        RGB_bola     => RGBbola,   -- Color de la bola
        RGB_bloque   => RGBbloque,   -- Color del bloque (si tienes bloques)
        RGB_pala     => RGBpala,   -- Color de la pala

        data_bloque  => data_bloque_s,   -- Datos hacia el bloque
        valid_bloque => valid_bloque_s,   -- Valid
        ready_bloque => ready_bloque_s,   -- Ready

        RGB_in       => RGBin,   -- Salida final hacia el VGA

        data_bola    => data_bola_s ,   -- Datos hacia la bola
        valid_bola   => valid_bola_s ,   -- Valid para la bola
        ready_bola   => ready_bola_s     -- Ready desde la bola

    );

end Behavioral;
