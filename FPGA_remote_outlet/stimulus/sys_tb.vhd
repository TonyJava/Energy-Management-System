--------------------------------------------------------------------------------
-- Project : PROJECTNAME
-- Author : Donald MacIntyre - djm4912
-- Date : 8/18/2015
-- File : sys_tb.vhd
--------------------------------------------------------------------------------
-- Description :
--------------------------------------------------------------------------------
-- $Log$
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.math_real.all;
use ieee.numeric_std.all;

entity sys_tb is
end sys_tb;

architecture tb of sys_tb is

--------------------------------------------------------------------------------
-- Signal Declarations
--------------------------------------------------------------------------------
signal my_time : real := 0.0;

-- voltage
signal voltage_sense : real;
signal int_voltage_sense : integer;
signal voltage_vec : std_logic_vector(11 downto 0);

--current
signal current_sense : real;
signal int_current_sense : integer;
signal current_vec : std_logic_vector(11 downto 0);

-- ADC Signals
signal sclk_sig : std_logic;
signal cs_sig : std_logic;
signal din_sig : std_logic;
signal dout_sig : std_logic;

-- I2C Signals
signal sda_sig : std_logic;
signal scl_sig : std_logic;

-- UUT signals
signal clk_sig : std_logic := '0';
signal por_sig : std_logic := '1';
signal triac_drive_sig : std_logic;
signal led_sig : std_logic_vector( 7 downto 0);
signal channel_to_use_sig : std_logic_vector (2 downto 0);
signal cur_adc_sig : std_logic_vector(11 downto 0);
signal vol_adc_sig : std_logic_vector(11 downto 0);

signal rx_interrupt_sig : std_logic := '0';
--------------------------------------------------------------------------------
-- Component Declarations
--------------------------------------------------------------------------------
component adc_128S002_model is
    Port (
		sclk : in std_logic;
		cs 	 : in std_logic;
		din  : in std_logic;
		dout : out std_logic;
		
		voltage_input : in std_logic_vector(11 downto 0);
		current_input : in std_logic_vector(11 downto 0)
    );
end component;

component remote_outlet_module_top is
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
end component;
--------------------------------------------------------------------------------

begin

uut : remote_outlet_module_top
    Port map(
		-- Inputs
		clk 		=> clk_sig,	-- 50 MHZ clock
		push_btn 	=> "11",		-- active low push btns
		dip_switch	=> "1111",
		por 		=> por_sig,	-- active high POR 
		rx_interrupt => rx_interrupt_sig,
		
		
		-- Outputs
		triac_drive	=> triac_drive_sig,		-- active high to drive triac 
		led 		=> led_sig,
		debug_output => open,
		
		-- ADC Inputs	
		sclk        => sclk_sig,
		cs          => cs_sig,
		din			=> din_sig,
		dout        => dout_sig,
		
		-- I2C Inputs/Outputs
		sda			=> sda_sig,
		scl			=> scl_sig
		
    );

adc_model : adc_128S002_model 
    Port map(
		sclk => sclk_sig,
		cs 	 => cs_sig,
		din  => din_sig,
		dout => dout_sig,
		
		voltage_input => voltage_vec,
		current_input => current_vec
    );


-- nano-second counter process
time_gen_proc : process
begin
	wait for 1 us;
	my_time <= my_time + 0.000001;
end process time_gen_proc;

-- voltage sense generation process (120V RMS 60 Hz)
process(my_time,voltage_sense,int_voltage_sense)
begin
	voltage_sense <= 1.264*sin(2 * 60 * 3.14 * my_time)+1.488;
	int_voltage_sense <= integer((voltage_sense/3.3)*4096.0);
	voltage_vec <= std_logic_vector(to_unsigned(int_voltage_sense,12));
end process;

-- current sense generation process
process(my_time,current_sense,int_current_sense)
begin
	current_sense <= 1.445*sin(2 * 60 * 3.14 * my_time)+1.6784;
	int_current_sense <= integer((current_sense/3.3)*4096.0);
	current_vec <= std_logic_vector(to_unsigned(int_current_sense,12));
end process;

clk_gen : process
begin
	wait for 10 ns;
	clk_sig <= not clk_sig;
end process clk_gen;

por_gen : process
begin
	wait for 500 ns;
	por_sig <= '0';
	wait;
end process por_gen;

rx_proc : process
begin
	wait for 1 ms;
	rx_interrupt_sig <= '1';
	wait for 7 us;
	rx_interrupt_sig <= '0';
end process rx_proc;

end tb;