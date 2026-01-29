library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity anomaly_detector is
  generic (
    N           : integer := 8;   -- window size
    WIDTH       : integer := 12;  -- sample width

    -- alpha = ALPHA_NUM / 2^ALPHA_SHIFT  (npr. 1/2 => 1 i 1)
    ALPHA_NUM   : integer := 1;
    ALPHA_SHIFT : integer := 1
  );
  port (
    clk          : in  std_logic;
    rst          : in  std_logic;
    sample_valid : in  std_logic;
    sample_in    : in  std_logic_vector(WIDTH-1 downto 0);
    anomaly_flag : out std_logic
  );
end entity;

architecture rtl of anomaly_detector is

  type window_t is array (0 to N-1) of unsigned(WIDTH-1 downto 0);
  signal mem     : window_t := (others => (others => '0'));

  signal wr_ptr  : integer range 0 to N-1 := 0;

  -- running sum treba biti širi: WIDTH + log2(N) + malo rezerve
  signal sum_r   : unsigned(WIDTH+8 downto 0) := (others => '0');
  signal min_r   : unsigned(WIDTH-1 downto 0) := (others => '0');
  signal max_r   : unsigned(WIDTH-1 downto 0) := (others => '0');

  -- da znamo kad je prozor “pun” (da ne detektuje na nulama na startu)
  signal count_r : integer range 0 to N := 0;

begin

  process(clk)
    variable x_new      : unsigned(WIDTH-1 downto 0);
    variable x_old      : unsigned(WIDTH-1 downto 0);

    variable avg_v      : unsigned(WIDTH-1 downto 0);
	 variable avg_full : unsigned(sum_r'length-1 downto 0);

    variable diff_v     : unsigned(WIDTH downto 0);
    variable range_v    : unsigned(WIDTH downto 0);
    variable thresh_v   : unsigned(WIDTH+8 downto 0); -- šire zbog množenja

    variable need_remin : boolean;
    variable need_remax : boolean;

    variable min_tmp    : unsigned(WIDTH-1 downto 0);
    variable max_tmp    : unsigned(WIDTH-1 downto 0);
    variable i          : integer;
	 
	 variable mult_full : unsigned(range_v'length + 8 - 1 downto 0);


  begin
    if rising_edge(clk) then
      if rst = '1' then
        mem          <= (others => (others => '0'));
        wr_ptr       <= 0;
        sum_r        <= (others => '0');
        min_r        <= (others => '0');
        max_r        <= (others => '0');
        count_r      <= 0;
        anomaly_flag <= '0';

      elsif sample_valid = '1' then
        x_new := unsigned(sample_in);
        x_old := mem(wr_ptr);  -- ovo se “izbacuje” iz prozora

        -- 1) upiši novi uzorak u ciklični bafer
        mem(wr_ptr) <= x_new;

        -- 2) update pointer
        if wr_ptr = N-1 then
          wr_ptr <= 0;
        else
          wr_ptr <= wr_ptr + 1;
        end if;

        -- 3) running sum (dok se prozor ne napuni ne oduzimamo “stari”)
        if count_r < N then
          sum_r   <= sum_r + resize(x_new, sum_r'length);
          count_r <= count_r + 1;
        else
          sum_r <= sum_r + resize(x_new, sum_r'length) - resize(x_old, sum_r'length);
        end if;

        -- 4) min/max update + pametan recompute samo kad treba
        need_remin := false;
        need_remax := false;

        if count_r = 0 then
          -- prvi uzorak
          min_r <= x_new;
          max_r <= x_new;
        else
          -- provjeri da li je izbačeni bio min/max
          if count_r >= N then
            if x_old = min_r then need_remin := true; end if;
            if x_old = max_r then need_remax := true; end if;
          end if;

          -- brzi update sa novim uzorkom
          if x_new < min_r then
            min_r <= x_new;
            need_remin := false;
          end if;

          if x_new > max_r then
            max_r <= x_new;
            need_remax := false;
          end if;

          -- ako smo izbacili baš min ili max, recompute kroz cijeli prozor
          if need_remin or need_remax then
            min_tmp := mem(0);
            max_tmp := mem(0);
            for i in 0 to N-1 loop
              if mem(i) < min_tmp then min_tmp := mem(i); end if;
              if mem(i) > max_tmp then max_tmp := mem(i); end if;
            end loop;

            -- ali pošto smo već upisali x_new u mem(wr_ptr), mem sadrži novi prozor
            if need_remin then min_r <= min_tmp; end if;
            if need_remax then max_r <= max_tmp; end if;
          end if;
        end if;

        -- 5) detekcija tek kad je prozor pun
        if count_r < N then
          anomaly_flag <= '0';
        else
          -- average
          avg_full := sum_r / N;
			 avg_v    := avg_full(WIDTH-1 downto 0);


          -- range = max - min
          range_v := ('0' & max_r) - ('0' & min_r);


			 -- threshold = (range * ALPHA_NUM) >> ALPHA_SHIFT
			-- množenje (13 * 8 → 21 bit)
			mult_full := range_v * to_unsigned(ALPHA_NUM, 8);

			-- shift pa DODELA (bez dodatnog resize-a)
			thresh_v  := shift_right(mult_full, ALPHA_SHIFT);



          -- |x - avg|
          if x_new >= avg_v then
            diff_v := ('0' & x_new) - ('0' & avg_v);
          else
            diff_v := ('0' & avg_v) - ('0' & x_new);
          end if;

          if resize(diff_v, thresh_v'length) > thresh_v then
            anomaly_flag <= '1';
          else
            anomaly_flag <= '0';
          end if;
        end if;

      end if;
    end if;
  end process;

end architecture;