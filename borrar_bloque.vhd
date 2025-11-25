library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity borrar_bloque is
  Port (
    clk, reset   : in  std_logic;
    data_bloque  : in  std_logic_vector(7 downto 0);  -- dirección del bloque
    valid_bloque : in  std_logic;  
    ready_bloque : out std_logic; 
    WR_A         : out std_logic;                     -- habilita escritura
    ADDR_A       : out std_logic_vector(7 downto 0);  -- dirección del bloque
    data_in_A    : out std_logic                      -- '0' = borrar bloque
  );
end borrar_bloque;

architecture Behavioral of borrar_bloque is

  type tipo_estado is (REPOSO, ESCRIBIR);
  signal estado, p_estado : tipo_estado;

begin

  --------------------------------------------------------------------
  -- PROCESO SECUENCIAL
  --------------------------------------------------------------------
  proc_sec : process(clk, reset)
  begin
    if reset = '1' then
      estado <= REPOSO;
    elsif rising_edge(clk) then
      estado <= p_estado;
    end if;
  end process;

  --------------------------------------------------------------------
  -- PROCESO COMBINACIONAL
  --------------------------------------------------------------------
  proc_comb : process(estado, valid_bloque, data_bloque)
  begin
    -- Valores por defecto
    p_estado     <= estado;
    WR_A         <= '0';
    data_in_A    <= '0';                 -- solo importa cuando WR_A = '1'
    ADDR_A       <= data_bloque;         -- usamos la dirección de entrada
    ready_bloque <= '0';

    case estado is

      ------------------------------------------------------------
      when REPOSO =>
        ready_bloque <= '1';             -- listo para recibir orden

        if valid_bloque = '1' then
          -- ya tenemos data_bloque como dirección del bloque
          p_estado <= ESCRIBIR;
        end if;

      ------------------------------------------------------------
      when ESCRIBIR =>
        WR_A      <= '1';                
        data_in_A <= '0';                -- escribir 0 = borrar bloque
        -- ADDR_A sigue siendo data_bloque

        p_estado  <= REPOSO;

    end case;
  end process;

end Behavioral;
