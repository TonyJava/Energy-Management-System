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
		
		-- Outputs
		triac_drive	: out std_logic;		-- active high to drive triac 
		led 		: out std_logic_vector(7 downto 0);
		
		-- ADC Inputs	
		sclk        : out std_logic;
		cs          : out std_logic;
		din			: out std_logic;
		dout        : in std_logic
		
    );
end remote_outlet_module_top;

architecture wrapper of remote_outlet_module_top is

--------------------------------------------------------------------------------
-- Signal Declarations
--------------------------------------------------------------------------------
signal por_n : std_logic;

type states is ();
signal state : states;
signal adc_data_sig : std_logic_vector(11 downto 0);
signal conv_in_progress_sig : std_logic;
signal channel_to_use_sig : std_logic_vector(2 downto 0);
signal conv_start_sig : std_logic;
signal voltage_adc : std_logic_vector(11 downto 0);
signal current_adc : std_logic_vector(11 downto 0);
signal count : std_logic_vector(15 downto 0);

constant SAMPLES_PER_CYCLE : std_logic_vector(15 downto 0) := 0x"ffff";
signal sample_pulse : std_logic;
signal pulse_generation_count : std_logic_vector(15 downto 0);
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

--------------------------------------------------------------------------------

begin

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
        adc_sclk            => sclk, -- .8 MHz to 3.2 MHz clk to adc
        adc_cs              => cs, -- adc cs
        serial_din_to_adc   => din -- adc din
        
    );
	
-- Generate 200us Sample Pulse signal to control rate at which ADC samples
sample_rate_proc : process(clk)
begin
	if por_n = '0' then
		sample_pulse <= '0';
	elsif rising_edge(clk) then
		pulse_generation_count <= pulse_generation_count + '1';
		if pulse_generation_count = 0x"3E8";		-- If 1000 clock cycles have passed which means 200 us have passed
			pulse_generation_count <= (others => '0');
			sample_pulse <= '1';
		else
			sample_pulse <= '0';
		end if;
	end if;
end process sample_rate_proc;

-- FSM Process
-- Get Data from the ADC (voltage and current) and then perform power calculation
fsm_sm : process(clk)
begin
	if por_n = '0' then
		state <= rst_state;
		conv_start_sig <= '0';
		current_adc <= (others => '0');
		voltage_adc <= (others => '0');
		channel_to_use_sig <= "101";
	elsif rising_edge(clk) then
		case adc_state is 
			
			when rst_state =>
		
				if por_n = '0' then 
					adc_state <= rst_state;
				else	
					adc_state <= setup;
				end if;
				
			when setup =>
				-- voltage mode
				data_valid <= '0';
				if channel_to_use_sig = "110" then
					channel_to_use_sig <= "101";
				else
					channel_to_use_sig <= "110";
				end if;
				adc_state <= init_conversion;
				
			when init_conversion =>
				if conv_in_progress_sig = '1' then
					conv_start_sig <= '0';
					adc_state <= wait_conversion_complete;
				else
					conv_start_sig <= '1';
					adc_state <= init_conversion;
				end if;
				
			when wait_conversion_complete =>
				if conv_in_progress_sig = '0' then
					adc_state <= setup;
					data_valid <= '1';
					if channel_to_use_sig = "101" then
						voltage_adc <= voltage_adc;
						current_adc <= adc_data_sig;
					else
						current_adc <= current_adc;
						voltage_adc <= adc_data_sig;
					end if;
				else	
					adc_state <= wait_conversion_complete;
				end if;
				
			when others =>
				adc_state <= rst_state;
		end case;
	end if;
end process adc_sm;
	
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

-- triac_drive
triac_drive_proc : process(clk)
begin
	if por_n = '0' then
		triac_drive <= '0';
	elsif rising_edge(clk) then
		triac_drive <= not push_btn(1);
	end if;
end process triac_drive_proc;			
	
end wrapper;