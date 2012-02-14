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
    
		--FPGA to software FIFO controls
		fifo_out_busy						: out std_logic; --high when writing to fifo
    aclr_out                : out std_logic; 
    data_out                : out std_logic_vector(7 downto 0); 
    wrreq_out               : out std_logic; 
    fifo_out_full           : in std_logic; 
		
		--incoming FIFO from software controls
		fifo_notyou							: in std_logic;
		fifo_busy								: out std_logic;
    data_in                 : in std_logic_vector(7 downto 0); --remote frame requested to be sent
    rdreq_in                : out std_logic; 
    fifo_in_empty           : in std_logic; 
    fifo_in_usedw           : in std_logic_vector(9 downto 0); 
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

	type protocol_data_array IS array (12 downto 0) of std_logic_vector(7 downto 0);
	
	signal protocol_1_data 		: protocol_data_array;
	signal protocol_2_data 		: protocol_data_array;
	--receive fifo signals
	signal tx_byte_length 		: integer range 0 to 12 := 0;
	signal byte_in_count    		: integer range 0 to 12 := 0;
begin

--get data from FIFO
build_from_fifo : process (clk, reset)
begin
	if reset = '1' then
		rdreq_in <= '0'; --read strobe from FIFO
		byte_in_count <= 0; --message will be this length + 2 bits for standard
		usb_bus <= tx_data; --defaults to transmit mode
	elsif rising_edge(clk) then
	ok babw
		CASE FIFO_BUILD is
		
				start_transmission <= '0';
			when IDLE =>
				if fifo_notyou = '0' and data_in(7 downto 6) = "00" then --decodes to protocol 1 message
					if fifo_in_usedw >= data_in(3 downto 0) then --this means message will be for protocl one, but message incomplete
						FIFO_BUILD <= PROTOCOL_1;
						num_bytes_in_full <= to_integer(unsigned(data_in(3 downto 0);
						protocol_1_data(0)
					else 
					  FIFO_BUILD <= IDLE;	--stays in idle until fifo has full message
					end if;
				elsif fifo_notyou = '0' and data_in(7 downto 6) = "01" then --decodes to protocol 2 message
					if fifo_in_usedw >= data_in(3 downto 0) then --this means message will be for protocl one, but message incomplete
						FIFO_BUILD <= PROTOCOL_2;
						protocol_2_data(0)
						num_bytes_in_full <= to_integer(unsigned(data_in(3 downto 0);
					else 
					  FIFO_BUILD <= IDLE;	--stays in idle until fifo has full message
					end if;
				else
					FIFO_BUILD <= IDLE;
				end if;
			
			when PROTOCOL_1 =>
				if byte_in_count = num_bytes_in_full then
					byte_in_count <= 1;
					start_transmission <= '1';
					rdreq_in <= '0';
					FIFO_BUILD <= IDLE;
				else
					rdreq_in <= '1';
					byte_in_count <= byte_in_count + 1;
					protocol_1_data(byte_in_count);
				end if;
				
			when PROTOCOL_2 =>
				if byte_in_count = num_bytes_in_full then
					byte_in_count <= 1;
					start_transmission <= '1';
					rdreq_in <= '0';
					FIFO_BUILD <= IDLE;
				else
					rdreq_in <= '1';
					byte_in_count <= byte_in_count + 1;
					protocol_2_data(byte_in_count);
				end if;
					


end architecture RTL;
