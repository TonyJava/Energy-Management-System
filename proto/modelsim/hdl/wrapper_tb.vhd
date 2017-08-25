--------------------------------------------------------------------------------
-- Project : PROJECTNAME
-- Author : Donald MacIntyre - djm4912
-- Date : 7/8/2015
-- File : wrapper_tb.vhd
--------------------------------------------------------------------------------
-- Description :
--------------------------------------------------------------------------------
-- $Log$
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity wrapper_tb is
end wrapper_tb;

architecture tb of wrapper_tb is

--------------------------------------------------------------------------------
-- Signal Declarations
--------------------------------------------------------------------------------
signal clk : std_logic := '0';
signal rst_n : std_logic := '0';
--------------------------------------------------------------------------------
-- Component Declarations
--------------------------------------------------------------------------------
component top_level_wrapper is
    Port (
		clk : in std_logic;		-- 10 MHz
		rst_n : in std_logic
    );
end component;
--------------------------------------------------------------------------------

begin

uut : top_level_wrapper 
    Port map(
		clk => clk,		-- 10 MHz
		rst_n => rst_n
    );

rst : process
begin
	rst_n <= '0';
	wait for 200 ns;
	rst_n <= '1';
	wait for 2 sec;
end process rst;

clk_gen : process
begin
	wait for 50 ns;
	clk <= not clk;
end process clk_gen;

end tb;