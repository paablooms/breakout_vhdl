----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.10.2025 20:32:13
-- Design Name: 
-- Module Name: comparador - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- ==============================================================
--  Entity: comparador
--  Description: Genera señales de blanking y sincronismo (HS/VS)
--               según el valor actual del contador de píxeles o líneas.
-- ==============================================================

entity comparador is
    Generic (
        Nbit           : integer := 8;    -- Bits del contador
        End_Of_Screen  : integer := 10;   -- Fin de zona visible
        Start_Of_Pulse : integer := 20;   -- Inicio de pulso de sincronismo
        End_Of_Pulse   : integer := 30;   -- Fin de pulso de sincronismo
        End_Of_Line    : integer := 40    -- Fin de línea/pantalla completa
    );
    Port (
        clk   : in  STD_LOGIC;
        reset : in  STD_LOGIC;
        data  : in  STD_LOGIC_VECTOR (Nbit-1 downto 0);
        O1    : out STD_LOGIC;
        O2    : out STD_LOGIC;
        O3    : out STD_LOGIC
    );
end comparador;

-- ==============================================================
--  Architecture
-- ==============================================================

architecture Behavioral of comparador is
    signal data_p : unsigned(Nbit-1 downto 0);
begin
    -- Conversión del bus de entrada a tipo unsigned
    data_p <= unsigned(data);

    comp : process(clk, reset)
    begin
        if reset = '1' then
            O1 <= '0';
            O2 <= '0';
            O3 <= '0';
        elsif rising_edge(clk) then
            if (data_p > End_Of_Screen) then
                O1 <= '1';
            else
                O1 <= '0';
            end if;

            if ((data_p > Start_Of_Pulse) and (data_p < End_Of_Pulse)) then
                O2 <= '0';
            else
                O2 <= '1';
            end if;

            if (data_p = End_Of_Line) then
                O3 <= '1';
            else
                O3 <= '0';
            end if;

        end if;
    end process;
end Behavioral;