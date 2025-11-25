library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memoria_bloques is
  port (
    clk      : in  std_logic;
    ADDR_A   : in  std_logic_vector(11 downto 0); -- dirección de 12 bits
    datin_A  : in  std_logic_vector(11 downto 0); -- dato de entrada (12 bits)
    dout_A   : out std_logic_vector(11 downto 0); -- dato de salida (12 bits)
    WE_A     : in  std_logic                     -- write enable
  );
end entity;

architecture rtl of memoria_bloques is

  -- 4096 posiciones (porque 2^12)
  type ram_type is array (0 to 4095) of std_logic_vector(11 downto 0);
  signal mem : ram_type := (others => (others => '0'));

  signal addr_i : integer;

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
