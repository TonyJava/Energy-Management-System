--------------------------------------------------------------------------------
-- Project : PROJECTNAME
-- Author : Donald MacIntyre - djm4912
-- Date : 8/17/2015
-- File : remote_outlet_module_top.vhd
--------------------------------------------------------------------------------
-- Description :
--------------------------------------------------------------------------------
-- $Log$
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_signed.all;

entity remote_outlet_module_top is
    Port (
		-- Inputs
		clk 		: in std_logic;	-- 50 MHZ clock
		push_btn 	: in std_logic_vector (1 downto 0);		-- active low push btns
		dip_switch	: in std_logic_vector(3 downto 0);
		por 		: in std_logic;		-- active high POR
		rx_interrupt : in std_logic;
		
		-- Outputs
		triac_drive	: out std_logic;		-- active high to drive triac 
		led 		: out std_logic_vector(7 downto 0);
		debug_output : out std_logic;
		
		-- ADC Inputs/Outputs	
		sclk        : out std_logic;
		cs          : out std_logic;
		din			: out std_logic;
		dout        : in std_logic;
		
		-- I2C Inputs/Outputs
		sda			: inout std_logic;
		scl			: inout std_logic
		
    );
end remote_outlet_module_top;

architecture wrapper of remote_outlet_module_top is

--------------------------------------------------------------------------------
-- Signal Declarations
--------------------------------------------------------------------------------
signal por_n : std_logic;

type load_switch_states is (load_switch_off, load_switch_on, load_switch_fault);
signal load_switch_state : load_switch_states;
signal next_load_state : load_switch_states;
signal load_switch_en_sig : std_logic;
signal software_rst_sig : std_logic;
signal current_lim_high_sig : std_logic_vector(11 downto 0);
signal current_lim_low_sig : std_logic_vector(11 downto 0);

type states is (idle, start_voltage_sample, capture_voltage, start_current_sample, capture_current,
	subtract_offset, calc_inst_power, sum_pwr, save_power_to_transmit);
signal state : states;
signal adc_data_sig : std_logic_vector(11 downto 0);
signal conv_in_progress_sig : std_logic;
signal channel_to_use_sig : std_logic_vector(2 downto 0);

constant VOLTAGE_CHANNEL : std_logic_vector (2 downto 0) := "101";
constant CURRENT_CHANNEL : std_logic_vector (2 downto 0) := "110";
constant CURRENT_OFFSET : std_logic_vector (12 downto 0) := '0' & x"825";
constant VOLTAGE_OFFSET: std_logic_vector (12 downto 0) := '0' & x"737"; 
--constant SYNC_PULSE_COUNT : std_logic_vector (15 downto 0) := x"03e7";		-- 20 us Pulse
constant SYNC_PULSE_COUNT : std_logic_vector(15 downto 0) := x"270F";	-- 200 us Pulse

signal conv_start_sig : std_logic;
signal voltage_adc : std_logic_vector(11 downto 0);
signal current_adc : std_logic_vector(11 downto 0);
signal current_minus_offset : std_logic_vector(12 downto 0);
signal voltage_minus_offset : std_logic_vector(12 downto 0);
signal inst_pwr : std_logic_vector (25 downto 0);
signal sum_inst_pwr : std_logic_vector (64 downto 0);
signal power_to_tx : std_logic_vector(31 downto 0);
signal current_to_tx : std_logic_vector(31 downto 0);
signal voltage_to_tx : std_logic_vector(31 downto 0);

signal power_output_valid : std_logic;

signal count : std_logic_vector(15 downto 0);


-- I2C
type i2c_states is (idle, start_i2c, set_i2c_payload, start_trans_two, request_transmission, set_i2c_payload2,start_trans_two2, wait_trans_done, collect_data);
signal i2c_state : i2c_states;
signal i2c_count : std_logic_vector (19 downto 0);

signal i2c_enable : std_logic;
signal i2c_addr : std_logic_vector(6 downto 0);
signal i2c_rw : std_logic;
signal i2c_data_wr : std_logic_vector(7 downto 0);
signal i2c_busy_sig : std_logic;
signal i2c_data_rd : std_logic_vector(7 downto 0);
signal i2c_ack_error : std_logic;

signal i2c_data_count : std_logic_vector(7 downto 0);


--constant SAMPLES_PER_CYCLE : std_logic_vector(15 downto 0) := x"4127"; -- 20 us sample
constant SAMPLES_PER_CYCLE : std_logic_vector(15 downto 0) := x"0690"; -- 200 us sample
signal sample_pulse : std_logic;
signal pulse_generation_count : std_logic_vector(15 downto 0);

-- Voltage/Current RMS Signals
signal voltage_squared : std_logic_vector(25 downto 0);
signal voltage_sum : std_logic_vector(64 downto 0);
signal current_squared : std_logic_vector(25 downto 0);
signal current_sum : std_logic_vector(64 downto 0);
--------------------------------------------------------------------------------
-- Component Declarations
--------------------------------------------------------------------------------
component adc128s022_interface is
    Port (
        clk             : in std_logic;     -- 50 MHz
        rst_n           : in std_logic;
        conv_start      : in std_logic;     -- request start of a conversion on rising edge
        channel_to_use  : in std_logic_vector(2 downto 0);  -- select channel to convert
        
        -- '1' if a conversion is in progress
        -- falling edge on this signal shall indicate conversion complete and data valid
        conv_in_progress    : out std_logic;    
        adc_data            : out std_logic_vector(11 downto 0);
        
        -- ADC Physical Connections
        serial_dout_from_adc    : in std_logic;     -- adc dout
        adc_sclk            : out std_logic; -- .8 MHz to 3.2 MHz clk to adc
        adc_cs              : out std_logic; -- adc cs
        serial_din_to_adc   : out std_logic -- adc din
        
    );
end component;

component plc_i2c_fsm is
    Port (
		clk 			: in std_logic;
		por_n 			: in std_logic;
		rx_interrupt 	: in std_logic;
		power_to_tx     : in std_logic_vector(31 downto 0);
		current_to_tx   : in std_logic_vector(31 downto 0);
		voltage_to_tx   : in std_logic_vector(31 downto 0);
		load_switch_en : out std_logic;
		software_rst   : out std_logic;
		current_lim_high : out std_logic_vector(11 downto 0);
		current_lim_low  : out std_logic_vector(11 downto 0);
		
		-- I2C Inputs/Outputs
		sda				: inout std_logic;
		scl				: inout std_logic;
		led            : out std_logic_vector(7 downto 0);
		debug_output   : out std_logic
    );
end component;
--------------------------------------------------------------------------------

begin

plc_fsm : plc_i2c_fsm
    Port map(
		clk 	=> clk,
		por_n 	=> por_n,
		rx_interrupt => rx_interrupt,
		power_to_tx  => power_to_tx,
		current_to_tx => current_to_tx,
		voltage_to_tx => voltage_to_tx,
		load_switch_en => load_switch_en_sig,
		software_rst => software_rst_sig,
		current_lim_high => current_lim_high_sig,
		current_lim_low  => current_lim_low_sig,
		
		-- I2C Inputs/Outputs
		sda			=> sda,
		scl			=> scl,
		
		led         => led,
		debug_output => debug_output
    );

adc : adc128s022_interface
    Port map(
        clk             => clk,   -- 50 MHz
        rst_n           => por_n,
        conv_start      => conv_start_sig,     -- request start of a conversion on rising edge
        channel_to_use  => channel_to_use_sig,  -- select channel to convert
        
        -- '1' if a conversion is in progress
        -- falling edge on this signal shall indicate conversion complete and data valid
        conv_in_progress    => conv_in_progress_sig,   
        adc_data            => adc_data_sig,
        
        -- ADC Physical Connections
        serial_dout_from_adc    =>  dout,    -- adc dout
        adc_sclk            	=> sclk, -- .8 MHz to 3.2 MHz clk to adc
        adc_cs              	=> cs, -- adc cs
        serial_din_to_adc   	=> din -- adc din
        
    );
	
-- Generate 200us Sample Pulse signal to control rate at which ADC samples
sample_rate_proc : process(clk)
begin
	if por_n = '0' then
		sample_pulse <= '0';
		pulse_generation_count <= x"0000";
	elsif rising_edge(clk) then
		pulse_generation_count <= pulse_generation_count + '1';
		if pulse_generation_count = SYNC_PULSE_COUNT then	-- If 1000 clock cycles have passed which means 200 us have passed
			pulse_generation_count <= x"0000";
			sample_pulse <= '1';
		else
			sample_pulse <= '0';
		end if;
	end if;
end process sample_rate_proc;

-- FSM Process
-- Get Data from the ADC (voltage and current) and then perform power calculation
fsm_proc : process(clk, por_n)
begin
	if por_n = '0' then
		state <= idle;
		voltage_adc <= x"000";
		current_adc <= x"000";
		count <= (others => '0');
		current_minus_offset <= (others => '0');
		voltage_minus_offset <= (others => '0');
		sum_inst_pwr <= (others => '0');
		channel_to_use_sig <= voltage_channel;
		inst_pwr <= (others => '0');
		conv_start_sig <= '0';
		power_output_valid <= '0';
		power_to_tx <= (others => '0');
		voltage_to_tx <= (others => '0');
		current_to_tx <= (others => '0');
		voltage_squared <= (others => '0');
		voltage_sum <= (others => '0');
		current_sum <= (others => '0');
	elsif rising_edge(clk) then
		case state is
			when idle => 
				-- go get more samples every 200 us
				if sample_pulse = '1' then
					-- make sure ADC not busy
					if conv_in_progress_sig = '0' then
						state <= start_voltage_sample;
					else
						state <= idle;
					end if;
				else
					state <= idle;
				end if;
			
			when start_voltage_sample =>
				channel_to_use_sig <= VOLTAGE_CHANNEL;
				if conv_in_progress_sig = '0' then
					conv_start_sig <= '1';
					state <= start_voltage_sample;
				else
					conv_start_sig <= '0';
					state <= capture_voltage;
				end if;
				
			when capture_voltage =>
				-- wait until conversion is complete
				if conv_in_progress_sig = '1' then
					state <= capture_voltage;
				-- conversion complete, capture data
				else
					voltage_adc <= adc_data_sig;
					state <= start_current_sample;
				end if;
				
			when start_current_sample =>
				channel_to_use_sig <= CURRENT_CHANNEL;
				if conv_in_progress_sig = '0' then
					conv_start_sig <= '1';
					state <= start_current_sample;
				else
					conv_start_sig <= '0';
					state <= capture_current;
				end if;
				
			when capture_current =>
				-- wait until conversion is complete
				if conv_in_progress_sig = '1' then
					state <= capture_current;
				-- conversion complete, capture data
				else
					current_adc <= adc_data_sig;
					state <= subtract_offset;
				end if;
				
			when subtract_offset =>
				current_minus_offset <= ('0' & current_adc) - CURRENT_OFFSET;
				voltage_minus_offset <= ('0' & voltage_adc) - VOLTAGE_OFFSET;
				state <= calc_inst_power;
				
			when calc_inst_power =>
				voltage_squared <= voltage_minus_offset * voltage_minus_offset;
				current_squared <= current_minus_offset * current_minus_offset;
				inst_pwr <= current_minus_offset * voltage_minus_offset;
				state <= sum_pwr;
				
			when sum_pwr =>
				voltage_sum <= voltage_sum + voltage_squared;
				current_sum <= current_sum + current_squared;
				sum_inst_pwr <= inst_pwr + sum_inst_pwr;
				count <= count + '1';
				if count = SAMPLES_PER_CYCLE then
					state <= save_power_to_transmit;
				else
					state <= idle;
				end if;
				
			when save_power_to_transmit =>
				count <= (others => '0');
				power_output_valid <= power_output_valid xor '1';
				power_to_tx <= sum_inst_pwr(31 downto 0);
				voltage_to_tx <= voltage_sum(31 downto 0);
				current_to_tx <= current_sum(31 downto 0);
				sum_inst_pwr <= (others => '0');
				voltage_sum <= (others => '0');
				current_sum <= (others => '0');
				state <= idle;
				
		end case;
	end if;
end process fsm_proc;
	
-- generate sychronous rst
rst_gen_proc : process(clk)
begin
	if rising_edge(clk) then
		-- if rst switch not pressed and remote outlet power is valid
		if push_btn(0) = '1' and por = '0' then
			por_n <= '1';
		-- assert the reset
		else
			por_n <= '0';
		end if;
	end if;
end process rst_gen_proc;

-- triac_drive_fsm
-- Set Next State
set_state : process(clk, por_n)
begin
	if por_n = '0' or software_rst_sig = '1' then
		load_switch_state <= load_switch_off;
	elsif rising_edge(clk) then
		load_switch_state <= next_load_state;
	end if;
end process set_state;

state_hand : process(load_switch_state)
begin
	case load_switch_state is
	
		when load_switch_off =>
			triac_drive <= '0';
			if load_switch_en_sig = '1' then
				next_load_state <= load_switch_on;
			else
				next_load_state <= load_switch_off;
			end if;
			
		when load_switch_on =>
			triac_drive <= '1';
			-- Add in current limit stuff
			if current_adc > current_lim_high_sig or current_adc < current_lim_low_sig then
				next_load_state <= load_switch_fault;
			elsif load_switch_en_sig = '0' then
				next_load_state <= load_switch_off;
			else 
				next_load_state <= load_switch_on;
			end if;
			
		when load_switch_fault =>
			triac_drive <= '0';
			next_load_state <= load_switch_fault;
			
	end case;
end process state_hand;
	
end wrapper;