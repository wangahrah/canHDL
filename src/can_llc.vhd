----------------------------------------------------------------------------------------------
--
-- VHDL CAN controller
-- Single wire (GMLAN), high, and low speed capabilities
-- Copyright Model Electronics, 615 East Crescent Ave, Ramsey, NJ 07446
-- This module written and developed by Michael Anfang
----------------------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
ENTITY can_protocol IS
  PORT (
   --general IO
    clk                     : in std_logic;
    reset                   : in std_logic;
    sw_tx                   : in std_logic;
    sw_rx                   : in std_logic;
    sw_m0                   : in std_logic;
    sw_m1                   : in std_logic;
    
    device_mode             : in std_logic_vector(3 downto 0);  --0 init+sniff, 1 sniffer only, 2-8 reserved
    
    tx_stdn_ext             : in std_logic; --0 is standard message, 1 is extended
    tx_remote               : in std_logic; --remote frame requested to be sent
    tx_indentifier          : in std_logic_vector(31 downto 0); --12 bits in standard, 32 in extended
    tx_dlc                  : in std_logic_vector(3 downto 0); --data length code
    tx_data                 : in std_logic_vector(63 downto 0); --data length code
    --status of message to be sent(do we need this?)
    tx_confim               : out std_logic; --triggers message sent/not sent
    tx_confim_status        : out std_logic; --confirm message sent
    tx_confirm_ident        : out std_logic_vector(31 downto 0); --ID of message confirmed
    
    rx_stdn_ext             : out std_logic; --0 is standard message, 1 is extended
    rx_remote               : out std_logic; --remote frame request received
    rx_indentifier          : out std_logic_vector(31 downto 0); --12 bits in standard, 32 in extended
    rx_dlc                  : out std_logic_vector(3 downto 0); --data length code
    rx_data                 : out std_logic_vector(63 downto 0); --data length code
        );
END ENTITY can_protocol;

architecture RTL OF c IS

component can_mac
  port(
    clk                     : in std_logic;
    reset                   : in std_logic;
    sw_tx                   : out std_logic;
    sw_rx                   : in std_logic;
    sw_m0                   : in std_logic;
    sw_m1                   : in std_logic;
    
    device_mode             : in std_logic_vector(3 downto 0);  --0 init+sniff, 1 sniffer only, 2-8 reserved
    
    tx_stdn_ext             : in std_logic; --0 is standard message, 1 is extended
    tx_remote               : in std_logic; --remote frame requested to be sent
    tx_indentifier          : in std_logic_vector(31 downto 0); --12 bits in standard, 32 in extended
    tx_dlc                  : in std_logic_vector(3 downto 0); --data length code
    tx_data                 : in std_logic_vector(63 downto 0); --data length code
    --status of message to be sent(do we need this?)
    tx_confim               : out std_logic; --triggers message sent/not sent
    tx_confim_status        : out std_logic; --confirm message sent
    tx_confirm_ident        : out std_logic_vector(31 downto 0); --ID of message confirmed
    
    rx_stdn_ext             : out std_logic; --0 is standard message, 1 is extended
    rx_remote               : out std_logic; --remote frame request received
    rx_indentifier          : out std_logic_vector(31 downto 0); --12 bits in standard, 32 in extended
    rx_dlc                  : out std_logic_vector(3 downto 0); --data length code
    rx_data                 : out std_logic_vector(63 downto 0); --data length code
        );
end component;




  signal sw_tx_s            : std_logic;   
  signal sw_rx_s            : std_logic;
  signal sw_m0_s            : std_logic;
  signal sw_m1_s            : std_logic;

begin



end architecture RTL;
