library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_anomaly_detector is
end entity;

architecture sim of tb_anomaly_detector is

  -- parametri (moraju pratiti DUT)
  constant N     : integer := 8;
  constant WIDTH : integer := 12;

  -- alpha = 1/2
  constant ALPHA_NUM   : integer := 1;
  constant ALPHA_SHIFT : integer := 1;

  signal clk          : std_logic := '0';
  signal rst          : std_logic := '1';
  signal sample_valid : std_logic := '0';
  signal sample_in    : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
  signal anomaly_flag : std_logic;

  constant CLK_PERIOD : time := 20 ns; -- 50 MHz

begin

  -- DUT instanca
  dut: entity work.anomaly_detector
    generic map (
      N           => N,
      WIDTH       => WIDTH,
      ALPHA_NUM   => ALPHA_NUM,
      ALPHA_SHIFT => ALPHA_SHIFT
    )
    port map (
      clk          => clk,
      rst          => rst,
      sample_valid => sample_valid,
      sample_in    => sample_in,
      anomaly_flag => anomaly_flag
    );

  -- clock generator
  clk <= not clk after CLK_PERIOD/2;

  -- stimulus
  stim: process
    variable i : integer;
    variable v : integer;
  begin
    -- reset
    rst <= '1';
    wait for 5*CLK_PERIOD;
    wait until rising_edge(clk);
    rst <= '0';
    wait until rising_edge(clk);

    ----------------------------------------------------------------
    -- 1) NORMALNO STANJE: stabilni podaci, flag treba ostati 0
    ----------------------------------------------------------------
    report "TEST 1: Normalno stanje (stabilno 120)";
    for i in 0 to 30 loop
      sample_in    <= std_logic_vector(to_unsigned(120, WIDTH));
      sample_valid <= '1';
      wait until rising_edge(clk);
      sample_valid <= '0';
      wait until rising_edge(clk);

      if i > N then
        assert anomaly_flag = '0'
          report "Greska: anomaly_flag=1 u normalnom stanju!"
          severity error;
      end if;
    end loop;

    ----------------------------------------------------------------
    -- 2) SPORI DRIFT: od 100 do 200 kroz 50 ciklusa, bez anomalija
    ----------------------------------------------------------------
    report "TEST 2: Spori drift (100->200 kroz 50 uzoraka)";
    for i in 0 to 50 loop
      v := 100 + 2*i;
      sample_in    <= std_logic_vector(to_unsigned(v, WIDTH));
      sample_valid <= '1';
      wait until rising_edge(clk);
      sample_valid <= '0';
      wait until rising_edge(clk);

      if i > N then
        assert anomaly_flag = '0'
          report "Greska: anomaly_flag=1 tokom sporog drifta!"
          severity error;
      end if;
    end loop;

    ----------------------------------------------------------------
    -- 3) ANOMALIJA: stabilno 100, onda jedan skok na 500
    ----------------------------------------------------------------
    report "TEST 3: Anomalija (stabilno 100 pa skok na 500)";
    for i in 0 to 20 loop
      sample_in    <= std_logic_vector(to_unsigned(100, WIDTH));
      sample_valid <= '1';
      wait until rising_edge(clk);
      sample_valid <= '0';
      wait until rising_edge(clk);
    end loop;

    -- skok
    sample_in    <= std_logic_vector(to_unsigned(500, WIDTH));
    sample_valid <= '1';
    wait until rising_edge(clk);
    sample_valid <= '0';
    wait until rising_edge(clk);

    assert anomaly_flag = '1'
      report "Greska: anomaly_flag nije postao 1 na anomaliji!"
      severity error;

    -- povratak na normalu
    for i in 0 to 10 loop
      sample_in    <= std_logic_vector(to_unsigned(100, WIDTH));
      sample_valid <= '1';
      wait until rising_edge(clk);
      sample_valid <= '0';
      wait until rising_edge(clk);
    end loop;

    report "SVA 3 TESTA SU PROSLA." severity note;
    wait;
  end process;

end architecture;
