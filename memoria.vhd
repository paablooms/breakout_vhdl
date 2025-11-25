library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memoria_bloques is
  port (
    clk      : in  std_logic;
    ADDR_A   : in  std_logic_vector(7 downto 0);  -- dirección de 8 bits
    datin_A  : in  std_logic;                     -- dato de entrada (1 bit)
    dout_A   : out std_logic;                     -- dato de salida (1 bit)
    WE_A     : in  std_logic                      -- write enable
  );
end entity;

architecture rtl of memoria_bloques is

  type ram_type is array (0 to 255) of std_logic; -- 256 bloques, 1 bit cada uno
  signal mem : ram_type := (others => '0');

  signal addr_i : integer range 0 to 255;

begin

  addr_i <= to_integer(unsigned(ADDR_A));

  process(clk)
  begin
    if rising_edge(clk) then
        -- escritura
        if WE_A = '1' then
            mem(addr_i) <= datin_A;
        end if;

        -- lectura síncrona
        dout_A <= mem(addr_i);
    end if;
  end process;

end architecture;
