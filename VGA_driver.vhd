----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.10.2025 20:52:29
-- Design Name: 
-- Module Name: VGA_driver - Behavioral
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

entity VGA_driver is
    Port ( clk : in STD_LOGIC;
        reset : in STD_LOGIC;
        VS : out STD_LOGIC;
        HS : out STD_LOGIC;
        ejex_out : out STD_LOGIC_VECTOR(9 downto 0);
        ejey_out : out STD_LOGIC_VECTOR(9 downto 0);
        o1h : out STD_LOGIC;
        o1v: out STD_LOGIC;
        refresh_out : out STD_LOGIC);
end VGA_driver;

architecture Behavioral of VGA_driver is

component contador is
    Generic (Nbit: integer := 8);
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           enable : in STD_LOGIC;
           resets : in STD_LOGIC;
           Q : out STD_LOGIC_VECTOR (Nbit-1 downto 0));
end component;

component comparador is
    Generic (Nbit: integer;
    End_Of_Screen: integer;
    Start_Of_Pulse: integer;
    End_Of_Pulse: integer;
    End_Of_Line: integer);
    Port ( clk : in STD_LOGIC;
        reset : in STD_LOGIC;
        data : in STD_LOGIC_VECTOR (Nbit-1 downto 0);
        O1 : out STD_LOGIC;
        O2 : out STD_LOGIC;
        O3 : out STD_LOGIC);
end component;

component frec_pixel is
    Port ( clk : in STD_LOGIC;
        reset : in STD_LOGIC;
        clk_pixel : out STD_LOGIC);
end component;

signal clk_pixel_s,o1h_s,o2h_s,o3h_s,o1v_s,o2v_s,o3v_s,enable_s: std_logic;
signal eje_x_s,eje_y_s: std_logic_vector(9 downto 0);

begin

frecpixel: frec_pixel
    port map(
        clk => clk,
        reset => reset,
        clk_pixel => clk_pixel_s
        );

Conth: contador
    Generic map(Nbit => 10)
    port map(
        clk => clk,
        reset => reset,
        enable => clk_pixel_s,
        resets => enable_s,
        Q => eje_x_s
        );
        
Contv: contador
    Generic map(Nbit => 10)
    port map(
        clk => clk,
        reset => reset,
        enable => enable_s,
        resets => o3v_s,
        Q => eje_y_s
        );
        
Comph: comparador
    Generic map(Nbit => 10,
        End_Of_Screen => 639,
        Start_Of_Pulse => 655,
        End_Of_Pulse => 751,
        End_Of_Line => 799)
    port map(
        clk => clk,
        reset => reset,
        data => eje_x_s,
        O1 => o1h_s,
        O2 => o2h_s,
        O3 => o3h_s
        );
        
Compv: comparador
    Generic map(Nbit => 10,
        End_Of_Screen => 479,
        Start_Of_Pulse => 489,
        End_Of_Pulse => 491,
        End_Of_Line => 520)
    port map(
        clk => clk,
        reset => reset,
        data => eje_y_s,
        O1 => o1v_s,
        O2 => o2v_s,
        O3 => o3v_s
        );
        
enable_s <= o3h_s AND clk_pixel_s;

o1h <= o1h_s;
o1v <= o1v_s;
        
HS <= o2h_s;
VS <= o2v_s;

refresh_out <= o3v_s;

ejex_out <= eje_x_s;
ejey_out <= eje_y_s;
  
end Behavioral;
