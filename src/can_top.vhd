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
use work.canhdl_pkg.all;

ENTITY can_top IS
  PORT (
   --general IO
    clkin_12mhz             : in std_logic;   --12mhz
    reset                   : in std_logic;
		GPIN										: in std_logic_vector(7 downto 0); --GPIO header
		GPOUT										: out std_logic_vector(7 downto 0); --GPIO header
		
		--USB interface.  Async FIFO mode
		usb_bus(7 downto 0)			: inout std_logic_vector(7 downto 0);
		rxf_n										: in std_logic;
		txe_n										: in std_logic;
		rd_n										: out std_logic;
		wr_n										: out std_logic;
		
		--transceiver 1 (protocol configurable)
    bus1_rx                   : in std_logic;
    bus1_tx                   : out std_logic;
    bus1_ctl1                 : out std_logic;
    bus1_ctl2                 : out std_logic;
		
		--transceiver 1 (protocol configurable)
    bus2_rx                   : in std_logic;
    bus2_tx                   : out std_logic;
    bus2_ctl1                 : out std_logic;
    bus2_ctl2                 : out std_logic;
		
		
		---temp stuff for dev board
    --push buttons
    pb0                     : in std_logic;
    pb1                     : in std_logic;
    pb2                     : in std_logic;
    pb3                     : in std_logic;
    --user dip switches
    sw0                     : in std_logic;
    sw2                     : in std_logic;
    sw3                     : in std_logic;
		sw1                     : in std_logic;
    sw4                     : in std_logic;
    sw5                     : in std_logic;
    sw6                     : in std_logic;
    sw7                     : in std_logic
		);
END ENTITY can_top;

architecture RTL OF can_top IS

component usb_if;
  port(
    clk_usb                 : in std_logic;
		usb_bus(7 downto 0)			: inout std_logic_vector(7 downto 0);
		rxf_n										: in std_logic;
		txe_n										: in std_logic;
		rd_n										: out std_logic;
		wr_n										: out std_logic;
		
		fifo_busy								: out std_logic; --high while message is transmitting
																						--this is done in order to not break up messages
		fifo1_strobe						: in std_logic; --strobes on message ready to be sent.
		protocol_length_1				: in std_logic_vector(3 downto 0)
		
		fifo2_strobe						: in std_logic; --blocks will wait until  busy is low
		protocol_length_1				: in std_logic_vector(3 downto 0)
		discrete_strobe	  			: in std_logic; --individual blocks will stagger busy going low
																						--in order to avoid collisions
		
		receive_done_strobe			: out std_logic; --strobes when fifo # words >= header length specified
		
		infifo1									: in std_logic_vector(7 downto 0);
		infifo2									: in std_logic_vector(7 downto 0);
		discretefifo2						: in std_logic_vector(7 downto 0);
		cpufifo  								: out std_logic_vector(7 downto 0);
        );
end component;

component can_protocol
  port(
    clk                     : in std_logic;
    reset                   : in std_logic;
    bus1_rx                 : out std_logic;
    bus1_tx                 : in std_logic;
    bus1_ctl1               : out std_logic;
    bus1_ctl2               : out std_logic;
    bus2_rx                 : out std_logic;
    bus2_tx                 : in std_logic;
    bus2_ctl1               : out std_logic;
    bus2_ctl2               : out std_logic;
		
		infifo1									: out fifo_array;
		infifo2									: out fifo_array;
		cpufifo  								: in fifo_array;
		fifo1_strobe						: out std_logic;
		fifo2_strobe						: out std_logic;
		msgreceived_strobe			: in std_logic;
		
    device_mode             : in std_logic_vector(3 downto 0)  --0 init+sniff, 1 sniffer only, 2-8 reserved
            );
end component;

component discrete_ctl
  port(
    clk                     : in std_logic;
    reset                   : in std_logic;
		discretefifo  					: out fifo_array;
		cpufifo  								: in fifo_array;
		discrete_strobe 				: out std_logic;
		msgreceived_strobe			: in std_logic;
		GPIN										: in std_logic_vector(7 downto 0); --GPIO header
		GPOUT										: out std_logic_vector(7 downto 0); --GPIO header
            );
end component;

component usb_fifo_out
  port(
		aclr		: IN STD_LOGIC ;
		clock		: IN STD_LOGIC ;
		data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		rdreq		: IN STD_LOGIC ;
		wrreq		: IN STD_LOGIC ;
		almost_empty		: OUT STD_LOGIC ;
		almost_full		: OUT STD_LOGIC ;
		empty		: OUT STD_LOGIC ;
		full		: OUT STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		usedw		: OUT STD_LOGIC_VECTOR (9 DOWNTO 0)
            );
end component;

component usb_fifo_in
	PORT
	(
		clock		: IN STD_LOGIC ;
		data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		rdreq		: IN STD_LOGIC ;
		wrreq		: IN STD_LOGIC ;
		almost_full		: OUT STD_LOGIC ;
		empty		: OUT STD_LOGIC ;
		full		: OUT STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		usedw		: OUT STD_LOGIC_VECTOR (8 DOWNTO 0)
	);
end component;
	
begin



end architecture RTL;
