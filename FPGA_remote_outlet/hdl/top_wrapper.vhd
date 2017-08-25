--------------------------------------------------------------------------------
-- Project : PROJECTNAME
-- Author : Donald MacIntyre - djm4912
-- Date : 10/9/2015
-- File : top_wrapper.vhd
--------------------------------------------------------------------------------
-- Description :
--------------------------------------------------------------------------------
-- $Log$
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity top_wrapper is
    Port (
		-- Inputs
		clk : in std_logic;
		push_btn 	: in std_logic_vector (1 downto 0);		-- active low push btns
		rx_interrupt : in std_logic;
		
		-- Outputs
		led 		: out std_logic_vector(7 downto 0);
		debug_output : out std_logic;
		
		-- ADC Inputs	
		sclk        : out std_logic;
		cs          : out std_logic;
		din			: out std_logic;
		dout        : in std_logic;
		
		sda         : inout std_logic;
		scl         : inout std_logic
    );
end top_wrapper;

architecture top of top_wrapper is

--------------------------------------------------------------------------------
-- Signal Declarations
--------------------------------------------------------------------------------
signal push_btn_sig : std_logic_vector(1 downto 0);
--------------------------------------------------------------------------------
-- Component Declarations
--------------------------------------------------------------------------------
component remote_outlet_module_top is
    Port (
		-- Inputs
		clk 		: in std_logic;	-- 50 MHZ clock
		push_btn 	: in std_logic_vector (1 downto 0);		-- active low push btns
		dip_switch	: in std_logic_vector(3 downto 0);
		por 		: in std_logic;		-- active high POR 
		rx_interrupt: in std_logic;
		
		-- Outputs
		triac_drive	: out std_logic;		-- active high to drive triac 
		led 		: out std_logic_vector(7 downto 0);
		debug_output : out std_logic;
		
		-- ADC Inputs	
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

romt : remote_outlet_module_top 
    Port map(
		-- Inputs
		clk 		=> clk,
		push_btn 	=> push_btn_sig,
		dip_switch	=> "0000",
		por 		=> '0',		-- active high POR 
		rx_interrupt => rx_interrupt,
		
		-- Outputs
		triac_drive	=> open,	-- active high to drive triac 
		led 		=> led,
		debug_output => debug_output,
		
		-- ADC Inputs	
		sclk        => sclk,
		cs          => cs,
		din			=> din,
		dout        => dout,
		
		-- I2C Inputs/Outputs
		sda			=> sda,
		scl			=> scl
		
    );
	
	push_btn_sig <= '1' & push_btn(0);

end top;