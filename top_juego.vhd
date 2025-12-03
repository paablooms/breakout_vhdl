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

entity juego_top is
    Generic(
           posx : unsigned(9 downto 0) := to_unsigned(455,10);
           posy : unsigned(9 downto 0) := to_unsigned(256,10)
           );
    Port (clk : in STD_LOGIC;
        reset : in STD_LOGIC;
        left : in STD_LOGIC;
        right : in STD_LOGIC;
        VS : out STD_LOGIC;
        HS : out STD_LOGIC;
        RGB : out STD_LOGIC_VECTOR (12 downto 0)
        );
end juego_top;

architecture Behavioral of juego_top is

component VGA_driver is
    Port ( clk : in STD_LOGIC;
        reset : in STD_LOGIC;
        VS : out STD_LOGIC;
        HS : out STD_LOGIC;
        ejex_out : out STD_LOGIC_VECTOR(9 downto 0);
        ejey_out : out STD_LOGIC_VECTOR(9 downto 0);
        o1h : out STD_LOGIC;
        o1v: out STD_LOGIC;
        refresh_out : out STD_LOGIC);
end component;

component juego is
    Port ( left : in STD_LOGIC;
           right : in STD_LOGIC;
           ejex : in STD_LOGIC_VECTOR(9 downto 0);
           ejey : in STD_LOGIC_VECTOR(9 downto 0);
           refresh : in STD_LOGIC;
           RGBin : out STD_LOGIC_VECTOR (11 downto 0));
end component;

component gen_color is
    Port (         
        blank_h : in STD_LOGIC;
        blank_v : in STD_LOGIC;
        RGBin : in STD_LOGIC_VECTOR (11 downto 0);
        RGBout : out STD_LOGIC_VECTOR (11 downto 0));
end component;

signal ex, ey : std_logic_vector(9 downto 0);
signal RGBin, RGBout : std_logic_vector(11 downto 0);
signal ref : std_logic;
signal o1h_s, o1v_s : std_logic;

begin
U1 : VGA_driver
    Port map(
        clk => clk,
        reset => reset,
        VS => VS,
        HS => HS,
        o1h => o1h_s,  
        o1v => o1v_s,
        ejex_out => ex,
        ejey_out => ey,
        refresh_out => ref
        );

U2 : juego
    Port map(
        clk => clk,
        reset => reset,
        left => left,
        right => right,
        ejex => ex,
        ejey => ey,
        refresh => ref,
        RGBin => RGBin
        );

U3 : gen_color
    Port map(
        blank_h => o1h_s,
        blank_v => o1v_s,
        RGBin => RGBin,
        RGBout => RGBout
        );
        
end Behavioral;
