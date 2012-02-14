----------------------------------------------------------------------------------------------
--
-- VHDL CAN controller
-- Single wire (GMLAN), high, and low speed capabilities
-- Copyright Model Electronics, 615 East Crescent Ave, Ramsey, NJ 07446
-- This module written and developed by Michael Anfang
--
--USB Interface
--FTDI FT22232H USB IC
--Dual channel USB interface.
--One channel is configured as JTAG to program the FPGA EEPROM
--The other channel is programmed as asyncronous FIFO for CPU/FPGA comm
--USB IC is configured by its own EEPROM, which can be programmed through software.
--FTDI provides royalty-free drivers on their website for software to use.
--FPGA interface side is located here.
----------------------------------------------------------------------------------------------


LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
ENTITY can_usb IS
  PORT (
   --general IO
    clk_usb                 : in std_logic;
		usb_bus(7 downto 0)			: inout std_logic_vector(7 downto 0);
		rxf_n										: in std_logic;
		txe_n										: in std_logic;
		rd_n										: out std_logic;
		wr_n										: out std_logic;
		
		fifo_busy								: out std_logic; --high while message is transmitting
																						--this is done in order to not break up messages
		fifo_strobe						: in std_logic; --strobes on message ready to be sent.
		protocol_length				: in std_logic_vector(3 downto 0)
		
		discrete_strobe	  			: in std_logic; --individual blocks will stagger busy going low
																						--in order to avoid collisions
		
		receive_done_strobe			: out std_logic; --strobes when fifo # words >= header length specified
		
		in_fifo									: in std_logic_vector(7 downto 0);
		cpu_fifo  								: out std_logic_vector(7 downto 0);
        );
END ENTITY can_usb;

architecture RTL OF can_usb IS

component can_crc
  port(
    clk                     : in std_logic;
    reset                   : in std_logic;
    soc                     : in std_logic;
    crc_data_in             : in std_logic;
    data_valid              : in std_logic; --LOW on bit stuff
    eoc                     : in std_logic; --last data bit
    crc_out                 : out std_logic_vector(14 downto 0);
    crc_valid               : out std_logic;
        );
end component;

	signal tx_start
	
	
	type usb_states	is (IDLE, TX_STATE);
  signal USB_STATE					: usb_states;
	signal send_count					: integer range 0 to 32 := 16;
	signal send_count_fulll 	: integer range 0 to 32 := 16;

	
usb_busy <= '1' when USB_STATE = IDLE else '0'; --bus arbitration signal

--requires external start
begin
tx_usb : process (clk, reset)
begin
	if reset = '1' then
		USB_STATE <= IDLE;
		rdreq <= '0';
		wrreq <= '0';
		send_count <= 0;
		rd_n <= '1';
		wr_n <= '1';
		usb_bus <= tx_data; --defaults to transmit mode

	elsif rising_edge(clk) then
		CASE USB_STATE is
		
			when USB_IDLE =>
				full_message_sent <= '1'; --tx arbiter block gets this
				wrreq <= '0';
				rd_n <= '1';
				wr_n <= '1';
			if fifo_empty /= '1' AND txe_n = '0' then --if fifo has contents and IC ready
				rdreq <= '1';			
				usb_data <= tx_data;			
				USB_STATE <= USB_TX_1;
				if rx_fifo_full = '1' then
		  elsif rxf_n = '0' then --reading data from USB IC
					USB_STATE <= USB_ERROR;
					err_rx_full <= '1';
				else
				usb_data <= (others => 'Z');
				USB_STATE <= USB_RX;				
				end if;				
			end if;
		when USB_TX_1 => --when IC is ready to accept data, txe_n goes low
				rdreq <= '0'; --drop read strobe from FIFO
				wr_n <= '0';	--drop read strobe low
				USB_STATE <= USB_IDLE;
			end if;				
		when USB_RX =>
			data_in <= usb_data;
			rd_n <= '0';
			wrreq <= '1';
			USB_STATE <= USB_IDLE;
		when USB_ERROR =>
			USB_STATE <= USB_IDLE;
		end CASE;
	end if;
end process;

end architecture RTL;
