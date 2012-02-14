Library IEEE;
Use IEEE.std_logic_1164.All;
Use IEEE.NUMERIC_STD.All;
library work;
  use work.receive_function_pkg.all;

--
Package fpga_comp_pkg Is


  Component adc_interface
    Port (clk80M       : In  std_logic;
          clk_en       : In  std_logic;
          reset_hi     : In  std_logic;
          sum_ovr_a    : In  std_logic;
          diff_ovr_a   : In  std_logic;
          sum_ovr_b    : In  std_logic;
          diff_ovr_b   : In  std_logic;
          diff_data_a  : In  std_logic_vector(13 Downto 0);
          diff_data_b  : In  std_logic_vector(13 Downto 0);
          sum_data_a   : In  std_logic_vector(13 Downto 0);
          sum_data_b   : In  std_logic_vector(13 Downto 0);
          sum_i_offset : In  std_logic_vector(13 Downto 0);
          sum_q_offset : In  std_logic_vector(13 Downto 0);
          dif_i_offset : In  std_logic_vector(13 Downto 0);
          dif_q_offset : In  std_logic_vector(13 Downto 0);
          overfl_si    : Out std_logic;
          overfl_di    : Out std_logic;
          overfl_sq    : Out std_logic;
          overfl_dq    : Out std_logic;
          diff_i_dat   : Out std_logic_vector(13 Downto 0);
          diff_q_dat   : Out std_logic_vector(13 Downto 0);
          sum_i_dat    : Out std_logic_vector(13 Downto 0);
          sum_q_dat    : Out std_logic_vector(13 Downto 0));
  End Component;

  Component reset_sync
    Port (clk       : In  std_logic;
          reset_in  : In  std_logic;
          reset_out : Out std_logic);
  End Component;


  
End Package fpga_comp_pkg;

Package Body fpga_comp_pkg Is

End fpga_comp_pkg;
