----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 15.11.2025 18:52:19
-- Design Name: 
-- Module Name: pala - Behavioral
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

entity pala is
    Port ( clk : in std_logic;
           reset : in std_logic;
           left : in STD_LOGIC;
           right : in STD_LOGIC;
           ejex : in STD_LOGIC_VECTOR(9 downto 0);
           ejey : in STD_LOGIC_VECTOR(9 downto 0);
           refresh : in STD_LOGIC;
           pos_p : out std_logic_vector(9 downto 0);
           RGBin : out STD_LOGIC_VECTOR (11 downto 0));
end pala;

architecture Behavioral of pala is

  component sprite_pala is
    Port (
      clka  : in  std_logic;
      addra : in  std_logic_vector(11 downto 0);  -- profundidad 3072 
      douta : out std_logic_vector(11 downto 0)   -- color RRRRGGGGBBBB
    );
  end component;

  -- señales para el sprite de la pala 
  signal sprite_addr : std_logic_vector(11 downto 0);
  signal sprite_rgb  : std_logic_vector(11 downto 0);

  -- movimiento y color de la pala
  signal posp,  p_posp  : unsigned(9 downto 0) := "0011111111";
  signal velp,  p_velp  : unsigned(2 downto 0);         -- 0..7
  signal cycle_cnt, p_cycle_cnt : unsigned(5 downto 0); -- 0..63
  signal RGBpala : std_logic_vector(11 downto 0);

begin

  -- ROM del sprite
  U_sprite_pala : sprite_pala
    port map(
      clka  => clk,
      addra => sprite_addr,
      douta => sprite_rgb
    );

  ----------------------------------------------------------------
  -- PROCESO SECUENCIAL: registra posp, velp, cycle_cnt
  ----------------------------------------------------------------
  sinc : process(clk, reset)
  begin
    if reset = '1' then
      posp       <= to_unsigned(223, 10);  -- posición inicial
      velp       <= to_unsigned(3, 3);     -- velocidad inicial
      cycle_cnt  <= (others => '0');
    elsif rising_edge(clk) then
      if refresh = '1' then
        posp      <= p_posp;
        velp      <= p_velp;
        cycle_cnt <= p_cycle_cnt;
      end if;
    end if;
  end process;

  ----------------------------------------------------------------
  -- PROCESO COMBINACIONAL: calcula p_posp, p_velp, p_cycle_cnt
  ----------------------------------------------------------------
  comb : process(posp, velp, cycle_cnt, left, right)
  begin
    -- valores por defecto (mantener)
    p_posp       <= posp;
    p_velp       <= velp;
    p_cycle_cnt  <= cycle_cnt;

    if (left = '0' and right = '0') then
      -- sin pulsar: resetea velocidad a 3 y contador a 0
      p_velp      <= to_unsigned(3, 3);
      p_cycle_cnt <= (others => '0');

    else
      -- estamos pulsando alguna tecla: contamos ciclos para acelerar
      if cycle_cnt = to_unsigned(59, 6) then   -- cada 60 ciclos
        p_cycle_cnt <= (others => '0');
        if velp < to_unsigned(7, 3) then       -- saturación máxima 7
          p_velp <= velp + 1;
        end if;
      else
        p_cycle_cnt <= cycle_cnt + 1;
      end if;

      -- movimiento horizontal con saturación de límites
      if left = '1' then
        if posp > to_unsigned(0, 10) + resize(velp, 10) then
          p_posp <= posp - resize(velp, 10);
        else
          p_posp <= (others => '0'); -- tope izquierda
        end if;
      elsif right = '1' then
        if posp < to_unsigned(448, 10) - resize(velp, 10) then
          p_posp <= posp + resize(velp, 10);
        else
          p_posp <= to_unsigned(448, 10); -- tope derecha (480-32)... ajusta si quieres
        end if;
      end if;

    end if;
  end process;

  ----------------------------------------------------------------
  -- DIBUJO CON SPRITE
  ----------------------------------------------------------------
  rgb : process(ejex, ejey, posp, sprite_rgb)
    variable x_pix, y_pix   : unsigned(9 downto 0);
    variable dx_full, dy_full : unsigned(9 downto 0);
    variable dx6 : unsigned(5 downto 0);  -- 0..63
    variable dy4 : unsigned(3 downto 0);  -- 0..15
    variable addr_local : unsigned(9 downto 0);   -- 0..1023
    variable base       : unsigned(11 downto 0);  -- 2048
  begin
    x_pix := unsigned(ejex);
    y_pix := unsigned(ejey);

    -- valores por defecto
    RGBpala     <= (others => '0');
    sprite_addr <= (others => '0');

    -- zona de la pala: 64x16, en Y ~448..463
    if (x_pix >= posp) and
       (x_pix <  posp + to_unsigned(64,10)) and
       (y_pix >= to_unsigned(448,10)) and
       (y_pix <  to_unsigned(448+16,10)) then

      -- coordenadas locales dentro del sprite
      dx_full := x_pix - posp;                       -- 0..63
      dy_full := y_pix - to_unsigned(448,10);        -- 0..15

      dx6 := dx_full(5 downto 0);   -- 6 bits
      dy4 := dy_full(3 downto 0);   -- 4 bits

      -- dirección dentro del sprite (0..1023): dy*64 + dx = dy4 & dx6
      addr_local := dy4 & dx6;     -- 10 bits

      -- offset de la 2ª imagen (pala): 2048
      base := to_unsigned(2048, 12);

      sprite_addr <= std_logic_vector(base + resize(addr_local, 12));

      -- color leído de la ROM
      RGBpala <= sprite_rgb;
    end if;
  end process;

  pos_p <= std_logic_vector(posp);
  RGBin <= RGBpala;

end Behavioral;


