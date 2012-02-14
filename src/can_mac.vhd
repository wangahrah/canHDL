----------------------------------------------------------------------------------------------
--
-- VHDL CAN controller
-- Single wire (GMLAN), high, and low speed capabilities
-- Copyright Model Electronics, 615 East Crescent Ave, Ramsey, NJ 07446
-- This module written and developed by Michael Anfang
----------------------------------------------------------------------------------------------

-- Flow of this code is top to bottom. Processess closer to the top of the code
--tend to control process lower down.
--
--Serial data is received from a CAN transceiver as either dominant or recessive.
--The clock process is set by software dependent on bit rate of CAN.
--
--The incoming data is filtered through the remove_stuff_bit process.
--This process removes the stuff bit.  Sorry it's so confusingly named.
--The process registers the serial data for the analysis block.
--
--The analyzeframe process parses the registered data to determine what bits
--are ident, DLC, and data.  It activates the CRC block at the appropriate time,
--triggers sending a message to the LLC when the message is complete, then 
--resets the buffer to prepare for next transmission.
--
--The CRC block receives serial data, and the remove_stuff_bit block disables
--it for a cycle when it should ignore a stuff bit.  The analyze_frame and 
--build_frame blocks activate it for rx and tx cycles respectively.


LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
ENTITY can_mac IS
  PORT (
   --general IO
    clk                     : in std_logic; --4Mhz max
    reset                   : in std_logic;
    sw_tx                   : out std_logic;
    sw_rx                   : in std_logic;
    sw_m0                   : out std_logic;   --m1 m0   mode pins set operating mode
    sw_m1                   : out std_logic;   --0 0 sleep mode
                                               --0 1 high speed
											   --1 0 high voltage wake up
											   --1 1 normal mode
											   
    device_mode             : in std_logic_vector(3 downto 0);  --0 init+sniff, 1 sniffer only, 2-8 reserved
    
    tx_start	            : in std_logic; --rising edge triggers TX message on bus
    tx_stdn_ext             : in std_logic; --0 is standard message, 1 is extended
    tx_remote               : in std_logic; --remote frame requested to be sent
    tx_indentifier          : in std_logic_vector(28 downto 0); --12 bits in standard, 32 in extended
    tx_dlc                  : in std_logic_vector(3 downto 0); --data length code
    tx_data                 : in std_logic_vector(63 downto 0); --data length code
    --status of message to be sent(do we need this?)
    tx_confim               : out std_logic; --triggers message sent/not sent
    tx_confim_status        : out std_logic; --confirm message sent
    tx_confirm_ident        : out std_logic_vector(28 downto 0); --ID of message confirmed
    
    rx_received             : out std_logic; --rising edge triggers LLC that message is received
    rx_stdn_ext             : out std_logic; --0 is standard message, 1 is extended
    rx_remote               : out std_logic; --remote frame request received
    rx_indentifier          : out std_logic_vector(28 downto 0); --12 bits in standard, 32 in extended
    rx_dlc                  : out std_logic_vector(3 downto 0); --data length code
    rx_data                 : out std_logic_vector(63 downto 0); --data length code
    can_busy                : out std_logic; --busy is busy (either 
        );
END ENTITY can_mac;

architecture RTL OF c IS

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

  signal transmit_buf		: std_logic_vector(165 downto 0);
  signal tx_data_buf		: std_logic_vector(165 downto 0);
  signal sw_tx_s            : std_logic;   
  signal sw_rx_s            : std_logic;
  signal sw_m0_s            : std_logic;
  signal sw_m1_s            : std_logic;
  signal delay	            : std_logic;
  
	--sample clock process signals
	signal sample_clk_en				: std_logic;
  signal sample_clock	        : integer range 0 to 127; 
  signal sample_clockfull     : integer range 0 to 127;  --counts to timescale representing 1 bit time
  signal sample_point         : integer range 0 to 127;   --value at which actual sample is taken
	
	
	
  --stuff bit removal signals
  signal sample_clk_en				: std_logic;
  signal rx_error_trigger			: std_logic;
  signal sample_count	        : integer range 0 to 256;
  signal frame_buffer	        : std_logic_vector(126 downto 0);
  type bitstuff_type	is (idle, sample);
  signal BITSTUFF_REMOVE_ST		: receive_type;
	
	--frame analyzer signals
	signal frame_end 						:std_logic;
	signal reset_buffer; 				:std_logic;
	
	
	type rx_type	is (IDLE, IDENT, REMOTE, DLC, EXTFRAME, DATA, CRC, EOF);
  signal RX_STATE							: rx_type;
begin
--dominant signal is low. sw_tx at logic 0 sends a dominant, 1 sends a recessive.
sw_tx <= NOT sw_tx_s; --we are inverting, so 1 on sw_tx_s results in dominant transmission

--standard frame is max 83 bits
crc_build(102 downto 20) <= '1'&tx_identifier(28 downto 17)&tx_remote&'1'&'0'&tx_dlc&tx_data&
--extended frame is max 102 bits
crc_build(102 downto 0) <= '1'&tx_identifier(28 downto 18)&tx_remote&'0'&tx_identifier(17 downto 0)&
							'0'&'0'&tx_dlc&tx_data;

sampleclock: process (clk, reset)
begin
	if reset = '1' then
		sample_clock <= 0;
	elsif rising_edge(clk) then
		if sample_clk_en = '1' then
			if sample_clock = sample clock full then
				sample_clock <= 0;
				sample <= '0';
			elsif sample_clock = sample_point then
				sample <= '1';
				sample_clock <= sample_clock + 1;
			else
				sample_clock <= sample_clock + 1;
			end if;
		else
			sample_clock <= 0;
			sample <= 0;
		end if;
	end if;
end process;
			
				
				
--This block detects SOF and passes serial data through with stuff bit removed.
--In the case of an error, it will trigger an error frame if in active error mode
remove_stuff_bit: process (clk, reset)
begin
	if reset = '1' then
		sample_clk_en 		<= '0';
		rx_error_trigger 	<= '0';
		sample_count 		<= 0;
		RX_ST 				<= IDLE;
	elsif rising_edge(clk) then
		case BITSTUFF_REMOVE_ST is
			when IDLE =>
				rx_error_trigger <= '0';
				sample_clk_en <= '0';
				if reset_buffer <= '1' then
					frame_buffer <= (others => '0');
				elsif  = '1' then
					BITSTUFF_REMOVE_ST <= SAMPLE;
					frame_buffer(0) <= sw_rx;
					last_sample <= sw_rx;	--stores first dominant bit
					sample_count <= sample_count + 1;
				else
				BITSTUFF_REMOVE_ST <= IDLE;
				end if;
				
			when SAMPLE =>
				sample_clk_en <= '1';
				if frame_end = '1' then	--triggered by data parser
					BITSTUFF_REMOVE_ST <= IDLE;
				elsif sample = '1' then					
					if stuffcount = 5 then				--if 5 last bits have been the same, next
						stuffcount <= 0;				--bit is a stuff bit to be ignored
						data_valid_s <= '0';			--turns off CRC generator for a cycle to skip it
						last_sample <=sw_rx;
						if sw_rx = last_sample then		-- if stuff bit is missing, ERROR.
							rx_error_trigger <= '1';	--trigger error frame
							BITSTUFF_REMOVE_ST <= IDLE;
						end if;
						
					else 
						data_valid_s <= '1';			--CRC generator is on
						sample_count <= sample_count + 1;
						frame_buffer(sample_count) <= sw_rx;
						if sw_rx = last_sample then
							stuffcount <= stuffcount + 1;
						else
							stuffcount <= 0;
						end if;
					
					end if;
				end if;
			others =>
				null;
		end case;
	end if;
end process;

analyzeframe : process (clk, reset)
begin
	if reset = '1' then
		frame_end <= '0';
		reset_buffer <= '0';
		
	elsif rising_edge(clk) then
		CASE RX_STATE is --(IDLE, IDENT, REMOTE, DLC, EXTFRAME, DATA, CRC, EOF);
			when IDENT =>
			if sample_count = 14 then --SOF, IDENT, RTR/STR, IDE;
				rx_identifier(28 downto 17) <= frame_buffer(11 downto 1);
				rx_remote <= frame_buffer(12);
				rx_stdn_ext <= frame_buffer(13);
				if frame_buffer(13) = '0' then
					RX_STATE <= DLC;
				else
					RX_STATE <= EXTFRAME;
				end if;
				
		when DLC =>
			if frame_buffer(13) = '1' then
				if sample_count = 19 then
					rx_dlc <= frame_buffer(18 downto 15);
						if frame_buffer(18 downto 15) = "0000"
							rx_data <= (others <= '0');
							RX_DATA <= CRC
						else
							data_count <= frame_buffer(18 downto 15);
							RX_DATA <= DATA;
				end if;
			end if;
			
			elsif frame_buffer(13) = '0' then
						
	

end architecture RTL;
