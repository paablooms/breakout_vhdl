----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.11.2025 11:35:17
-- Design Name: 
-- Module Name: control_juego - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- Este módulo se encarga de decidir:
--   - Qué color sacar finalmente por RGB_in en cada píxel.
--   - Cuándo se produce una colisión:
--        * bola vs bloque   -> avisar a la bola y decir qué bloque borrar.
--        * bola vs pala     -> avisar a la bola.
--
-- La idea general es:
--   Hay otro módulo "top" que va barriendo la pantalla píxel a píxel (ejex, ejey).
--   Para cada píxel, este módulo recibe:
--      - El color de la bola       (RGB_bola)
--      - El color de un bloque     (RGB_bloque)
--      - El color de la pala       (RGB_pala)
--   Y con eso decide:
--      - Qué color mostrar (RGB_in).
--      - Si hay colisión entre objetos.

--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- use IEEE.NUMERIC_STD.ALL;  -- de momento no hace falta aritmética con unsigned/signed

----------------------------------------------------------------------------------
-- ENTIDAD
----------------------------------------------------------------------------------
entity control_juego is
  Port (
    clk, reset : in  std_logic;
    ejex, ejey : in  std_logic_vector(9 downto 0);  -- coordenadas actuales del píxel

    -- RGBs de entrada (los que comparamos para ver quién está "dibujado" en el píxel)
    RGB_bola   : in  std_logic_vector(11 downto 0);
    RGB_bloque : in  std_logic_vector(11 downto 0);
    RGB_pala   : in  std_logic_vector(11 downto 0);

    -- Intercambio con módulo de bloques (para indicar qué bloque hay que borrar)
    data_bloque  : out std_logic_vector(7 downto 0); -- "índice/dirección" del bloque
    valid_bloque : out std_logic;                    -- 1 => data_bloque válido
    ready_bloque : in  std_logic;                    -- handshake del otro lado

    -- Color final que se va a pintar en pantalla en este píxel
    RGB_in     : out std_logic_vector(11 downto 0);

    -- Interfaz con el módulo "bola"
    -- data_bola será un pequeño "código" que la bola interpreta como:
    --   "0000" -> choque con pala
    --   "0001" -> choque con ladrillo/bloque
    data_bola  : out std_logic_vector(3 downto 0);
    valid_bola : out std_logic;
    ready_bola : in  std_logic
  );
end control_juego;

----------------------------------------------------------------------------------
-- ARQUITECTURA
----------------------------------------------------------------------------------
architecture Behavioral of control_juego is

  ----------------------------------------------------------------------------
  -- Definición de estados de la máquina de estados
  ----------------------------------------------------------------------------
  type tipo_estado is (
    REPOSO,                     -- estado base: vigilando colisiones
    TX_AXI_BOLA_CHOQUE_LADRILLO,-- avisamos a la bola de choque con ladrillo
    TX_AXI_BLOQUE_BORRAR,      -- avisamos al módulo de bloques para borrar
    TX_AXI_BOLA_CHOQUE_PALA    -- avisamos a la bola de choque con la pala
  );

  -- Constante para representar "color negro" o "no hay nada dibujado"
  constant CERO : std_logic_vector(11 downto 0) := (others => '0');

  -- Estado actual y próximo estado
  signal estado, p_estado : tipo_estado;

begin

  ----------------------------------------------------------------------------
  -- Combinación de colores en el píxel actual
  ----------------------------------------------------------------------------
  RGB_in <= RGB_bola or RGB_bloque or RGB_pala;

  ----------------------------------------------------------------------------
  -- PROCESO SECUENCIAL (REGISTRO DE ESTADO)
  ----------------------------------------------------------------------------
  sinc : process(clk)
  begin
    if rising_edge(clk) then
      if (reset = '1') then
        -- Estado inicial de la máquina:
        -- arrancamos siempre en REPOSO.
        estado <= REPOSO;
      else
        -- Avanzamos al siguiente estado decidido en el proceso combinacional
        estado <= p_estado;
      end if;
    end if;
  end process;

  ----------------------------------------------------------------------------
  -- PROCESO COMBINACIONAL (LÓGICA DE CONTROL / MÁQUINA DE ESTADOS)
  ----------------------------------------------------------------------------
  process(estado, ready_bola, ready_bloque, RGB_bloque, RGB_bola, RGB_pala, ejex, ejey)
  begin
    -- Valores por defecto:
    -- Si este ciclo no se cambia nada, la máquina se queda como está
    p_estado <= estado;

    -- Por defecto, no enviamos nada a la bola
    data_bola  <= (others => '0');
    valid_bola <= '0';

    -- Por defecto, no enviamos nada al módulo de bloques
    data_bloque  <= (others => '0');
    valid_bloque <= '0';

    ------------------------------------------------------------------------
    -- Máquina de estados
    ------------------------------------------------------------------------
    case estado is

      ----------------------------------------------------------------------
      -- REPOSO:
      -- En este estado miramos simplemente si hay colisiones.
      --
      -- Estrategia:
      --   - Si bola y bloque tienen color ≠ 0 en el mismo píxel:
      --        => choque bola-ladrillo.
      --   - Si bola y pala tienen color ≠ 0 en el mismo píxel:
      --        => choque bola-pala.
      ----------------------------------------------------------------------
      when REPOSO =>

        -- choque bola con bloque (bola y bloque presentes en este píxel)
        if (RGB_bola /= CERO) and (RGB_bloque /= CERO) then
          p_estado <= TX_AXI_BOLA_CHOQUE_LADRILLO;

        -- choque bola con pala (bola y pala presentes en este píxel)
        elsif (RGB_bola /= CERO) and (RGB_pala /= CERO) then
          p_estado <= TX_AXI_BOLA_CHOQUE_PALA;
        end if;

      ----------------------------------------------------------------------
      -- TX_AXI_BOLA_CHOQUE_PALA:
      -- Avisamos a la bola de que ha chocado con la pala.
      --
      --   data_bola = "0000" -> choque con pala
      --
      -- Protocolo
      --   - Ponemos data_bola y valid_bola = '1'
      --   - Esperamos a que ready_bola = '1'
      --     para dar por completada la transferencia.
      ----------------------------------------------------------------------
      when TX_AXI_BOLA_CHOQUE_PALA =>

        data_bola  <= "0000";  -- código para "choque con pala"
        valid_bola <= '1';     -- indicamos que data_bola es válido

        -- Si la bola ha aceptado el dato (handshake correcto),
        -- volvemos a REPOSO.
        if (ready_bola = '1') then
          p_estado <= REPOSO;
        end if;

      ----------------------------------------------------------------------
      -- TX_AXI_BOLA_CHOQUE_LADRILLO:
      -- Avisamos a la bola de que ha chocado con un ladrillo/bloque.
      --
      -- Codificación elegida:
      --   data_bola = "0001" -> choque con ladrillo
      --
      -- Después de avisar a la bola, pasamos a avisar al módulo de bloques
      -- para que borre el bloque implicado (TX_AXI_BLOQUE_BORRAR).
      ----------------------------------------------------------------------
      when TX_AXI_BOLA_CHOQUE_LADRILLO =>

        data_bola  <= "0001";  -- código para "choque con ladrillo"
        valid_bola <= '1';

        -- Una vez la bola acepta el dato, pasamos a enviar info al módulo
        -- de bloques para borrar el ladrillo correspondiente.
        if (ready_bola = '1') then
          p_estado <= TX_AXI_BLOQUE_BORRAR;
        end if;

      ----------------------------------------------------------------------
      -- TX_AXI_BLOQUE_BORRAR:
      -- Aquí indicamos qué bloque se tiene que borrar.
      --
      -- data_bloque:
      --   De momento se está componiendo concatenando bits de ejey y ejex:
      --       data_bloque <= ejey(7 downto 4) & ejex(8 downto 5);
      --
      -- 
      --     - ejey(7 downto 4): 4 bits para filas de bloques
      --     - ejex(8 downto 5): 4 bits para columnas de bloques
      --
      --   Es decir, se divide la pantalla en una rejilla de 16x16 celdas,
      --   y cada celda se asocia a un bloque.
      --
      -- Protocolo con borrar_bloque:
      --   - Enviamos data_bloque
      --   - Activamos valid_bloque = '1'
      --   - Esperamos a que ready_bloque = '1' para volver a REPOSO.
      ----------------------------------------------------------------------
      when TX_AXI_BLOQUE_BORRAR =>

        -- Aquí se codifica qué bloque corresponde a la posición (ejex, ejey)
        -- en la parrilla de bloques.
        data_bloque  <= ejey(7 downto 4) & ejex(8 downto 5);
        valid_bloque <= '1';

        -- Cuando el módulo de bloques acepta el dato, volvemos a REPOSO.
        if (ready_bloque = '1') then
          p_estado <= REPOSO;
        end if;

    end case;
  end process;

end Behavioral;


