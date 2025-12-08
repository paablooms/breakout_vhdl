library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

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

  type tipo_estado is (INIT, REPOSO, ESCRIBIR);
  signal estado, p_estado : tipo_estado;

  signal init_addr, p_init_addr : unsigned(7 downto 0);

begin

  --------------------------------------------------------------------
  -- PROCESO SECUENCIAL
  --------------------------------------------------------------------
  proc_sec : process(clk, reset)
  begin
    if reset = '1' then
      estado    <= INIT;               -- tras reset, ir a inicializar RAM
      init_addr <= (others => '0');
    elsif rising_edge(clk) then
      estado    <= p_estado;
      init_addr <= p_init_addr;
    end if;
  end process;

  --------------------------------------------------------------------
  -- PROCESO COMBINACIONAL
  --------------------------------------------------------------------
  proc_comb : process(estado, valid_bloque, data_bloque, init_addr)
  begin
    -- Valores por defecto
    p_estado      <= estado;
    p_init_addr   <= init_addr;

    WR_A          <= '0';
    data_in_A     <= '0';          -- por defecto, da igual
    ADDR_A        <= (others => '0');
    ready_bloque  <= '0';

    case estado is

      ------------------------------------------------------------
      -- 1) FASE DE INICIALIZACIÓN: ESCRIBE '1' EN TODAS LAS DIRECCIONES
      ------------------------------------------------------------
      when INIT =>
        WR_A      <= '1';
        data_in_A <= '1';                              -- 1 = hay bloque
        ADDR_A    <= std_logic_vector(init_addr);

        -- avanzamos dirección
        if init_addr = to_unsigned(255, 8) then
          p_init_addr <= init_addr;
          p_estado    <= REPOSO;                       -- cuando llego al final, ya he inicializado todo
        else
          p_init_addr <= init_addr + 1;
          p_estado    <= INIT;
        end if;

      ------------------------------------------------------------
      -- 2) REPOSO: espera eventos de colisión para borrar bloques
      ------------------------------------------------------------
      when REPOSO =>
        ADDR_A <= data_bloque;       -- preparamos la dirección por si hay que borrar

        if valid_bloque = '1' then
          p_estado <= ESCRIBIR;      -- voy a escribir un 0 para borrar
        end if;

      ------------------------------------------------------------
      -- 3) ESCRIBIR: se borra el bloque concreto
      ------------------------------------------------------------
      when ESCRIBIR =>
        ready_bloque <= '1';       -- ya estoy atendiendo la petición
        WR_A      <= '1';
        data_in_A <= '0';          -- 0 = borrar bloque
        ADDR_A    <= data_bloque;

        p_estado  <= REPOSO;

    end case;
  end process;

end Behavioral;
