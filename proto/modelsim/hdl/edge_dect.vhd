--------------------------------------------------------------------------------
-- Project : PROJECTNAME
-- Author : Donald MacIntyre - djm4912
-- Date : 6/20/2015
-- File : edge_dect.vhd
--------------------------------------------------------------------------------
-- Description :
--------------------------------------------------------------------------------
-- $Log$
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity edge_dect is
    Port (
		clk 				: in std_logic;
		rst_n 				: in std_logic;		-- active low
		edge_dect_in		: in std_logic;
		rising_edge_dect	: out std_logic;	-- high iff a rising edge is detected
		falling_edge_dect	: out std_logic		-- high iff a falling edge is detected
    );
end edge_dect;

architecture behav of edge_dect is

--------------------------------------------------------------------------------
-- Signal Declarations
--------------------------------------------------------------------------------
signal input_sig : std_logic_vector(1 downto 0);
--------------------------------------------------------------------------------
-- Component Declarations
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------

begin

input_shift_proc : process(clk, rst_n)
begin
	if rst_n = '0' then
		input_sig <= "00";	
	elsif rising_edge(clk) then
		input_sig <= input_sig(0) & edge_dect_in;
	end if;
end process input_shift_proc;

edge_dect_proc : process(clk, rst_n)
begin
	if rst_n = '0' then
		rising_edge_dect <= '0';
		falling_edge_dect <= '1';
	elsif rising_edge(clk) then
		if input_sig = "10" then --falling edge
			falling_edge_dect <= '1';
			rising_edge_dect <= '0';
		elsif input_sig = "01" then -- rising_edge
			falling_edge_dect <= '0';
			rising_edge_dect <= '1';
		else
			falling_edge_dect <= '0';
			rising_edge_dect <= '0';
		end if;
	end if;
end process edge_dect_proc;

end behav;