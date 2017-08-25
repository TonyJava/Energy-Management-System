--------------------------------------------------------------------------------
-- Project : PROJECTNAME
-- Author : Donald MacIntyre - djm4912
-- Date : 8/18/2015
-- File : adc_128S002_model.vhd
--------------------------------------------------------------------------------
-- Description :
--------------------------------------------------------------------------------
-- $Log$
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity adc_128S002_model is
    Port (
 		sclk : in std_logic;
		cs 	 : in std_logic;
		din  : in std_logic;
		dout : out std_logic;
		
		voltage_input : in std_logic_vector(11 downto 0);
		current_input : in std_logic_vector(11 downto 0)
    );
end adc_128S002_model;

architecture behav of adc_128S002_model is

--------------------------------------------------------------------------------
-- Signal Declarations
--------------------------------------------------------------------------------
signal address : std_logic_vector(1 downto 0);
signal data : std_logic_vector(11 downto 0);
--------------------------------------------------------------------------------
-- Component Declarations
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------

begin			
		
process
begin
		dout <= 'Z';
		wait until falling_edge(cs);
		address <= "00";
		-- cycle 0
		wait until rising_edge(sclk);
		-- cycle 1
		wait until rising_edge(sclk);
		-- cycle 2
		wait until rising_edge(sclk);
		address(1) <= din;
		-- cycle 3
		wait until rising_edge(sclk);
		address(0) <= din;
		-- cycle 4
		wait until falling_edge(sclk);
		-- voltage sense is to be sampled
		if address(1 downto 0) = "10" then
			data <= voltage_input;
		-- current sense
		elsif address(1 downto 0) = "11" then
		-- invalid channel
			data <= current_input;
		else
			data <= x"000";
		end if;
			wait for 1 ns;
			dout <= data(11);
		-- cycle 5
		wait until falling_edge(sclk);
		dout <= data(10);
		-- cycle 6
		wait until falling_edge(sclk);
		dout <= data(9);
		-- cycle 7
		wait until falling_edge(sclk);
		dout <= data(8);
		-- cycle 8
		wait until falling_edge(sclk);
		dout <= data(7);
		-- cycle 9
		wait until falling_edge(sclk);
		dout <= data(6);
		-- cycle 10
		wait until falling_edge(sclk);
		dout <= data(5);
		-- cycle 11
		wait until falling_edge(sclk);
		dout <= data(4);
		-- cycle 12
		wait until falling_edge(sclk);
		dout <= data(3);
		-- cycle 13
		wait until falling_edge(sclk);
		dout <= data(2);
		-- cycle 14
		wait until falling_edge(sclk);
		dout <= data(1);
		-- cycle 15
		wait until falling_edge(sclk);
		dout <= data(0);
		wait until rising_edge(cs);
		dout <= 'Z';
end process;

end behav;