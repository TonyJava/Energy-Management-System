--------------------------------------------------------------------------------
-- Project : PROJECTNAME
-- Author : Donald MacIntyre - djm4912
-- Date : 7/15/2015
-- File : adc_tb.vhd
--------------------------------------------------------------------------------
-- Description :
--------------------------------------------------------------------------------
-- $Log$
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity adc_tb is
end adc_tb;

architecture tb of adc_tb is

--------------------------------------------------------------------------------
-- Signal Declarations
--------------------------------------------------------------------------------
signal clk : std_logic := '0';
signal rst_n : std_logic;
signal start : std_logic;
signal not_busy : std_logic;
signal out_data : std_logic_vector (11 downto 0);
signal sclk : std_logic;
signal cs : std_logic;
signal din :std_logic;
signal dout : std_logic;
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

uut : adc128s022_interface 
    Port map(
        clk             => clk,
        rst_n           => rst_n,
        conv_start      => start,    -- request start of a conversion on rising edge
        channel_to_use  => "101", -- select channel to convert
        
        -- '1' if a conversion is in progress
        -- falling edge on this signal shall indicate conversion complete and data valid
        conv_in_progress    => not_busy,   
        adc_data            => out_data,
        
        -- ADC Physical Connections
        serial_dout_from_adc    => dout,     -- adc dout
        adc_sclk            => sclk,
        adc_cs              => cs,
        serial_din_to_adc   => din -- adc din
        
    );

gen_clk_proc : process
begin
    wait for 10 ns;
    clk <= not clk;
end process gen_clk_proc;

tb_stim_proc : process
begin
    start <= '0';
    rst_n <= '0';
    wait for 400 ns;
    rst_n <= '1';
    wait for 100 ns;
    for i in 0 to 10 loop
        wait for 5 ns;
        start <= '1';
        wait until not_busy = '1';
        start <= '0';
        wait until not_busy = '0';
    end loop;
    assert false report "Simulation is over" severity failure;
end process tb_stim_proc;

-- Mimic functionality of ADC
adc_hardware_imp : process
begin
dout <= '0';
wait until falling_edge(cs);
-- cycle 1
wait until falling_edge(sclk);
-- cycle 2 
wait until falling_edge(sclk);
-- cycle 3 
wait until falling_edge(sclk);
-- cycle 4
wait until falling_edge(sclk);
-- cycle 5
wait until falling_edge(sclk);
dout <= '1';
-- cycle 6
wait until falling_edge(sclk);
dout <= '0';
-- cycle 7
wait until falling_edge(sclk);
dout <= '1';
-- cycle 8
wait until falling_edge(sclk);
dout <= '0';
-- cycle 9
wait until falling_edge(sclk);
dout <= '1';
-- cycle 10
wait until falling_edge(sclk);
dout <= '0';
-- cycle 11
wait until falling_edge(sclk);
dout <= '1';
-- cycle 12
wait until falling_edge(sclk);
dout <= '0';
-- cycle 13
wait until falling_edge(sclk);
dout <= '1';
-- cycle 14
wait until falling_edge(sclk);
dout <= '0';
-- cycle 15
wait until falling_edge(sclk);
dout <= '1';
-- cycle 16
wait until falling_edge(sclk);
dout <= '0';
end process adc_hardware_imp;       

end tb;