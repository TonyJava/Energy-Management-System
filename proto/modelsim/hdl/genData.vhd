--------------------------------------------------------------------------------
-- Project : PROJECTNAME
-- Author : Donald MacIntyre - djm4912
-- Date : 7/8/2015
-- File : genData.vhd
--------------------------------------------------------------------------------
-- Description :
--------------------------------------------------------------------------------
-- $Log$
--------------------------------------------------------------------------------

library IEEE;
library std;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
use std.textio.all;  --include package textio.vhd
use IEEE.numeric_std.all;

entity genData is
    Port (
        clk : in std_logic;         -- 10 MHz clock
        rst_n : in std_logic;
        data_out : out std_logic_vector(11 downto 0);
        data_out_valid : out std_logic
    );
end genData;

architecture behav of genData is

--------------------------------------------------------------------------------
-- Signal Declarations
--------------------------------------------------------------------------------
signal counter : std_logic_vector(6 downto 0);
--------------------------------------------------------------------------------
-- Component Declarations
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------

begin

process(clk, rst_n)
begin
    if rst_n = '0' then
        counter <= (others => '0');
    elsif rising_edge(clk) then
        if counter = "1100100" then
            counter <= "0000000";
        else 
            counter <= counter + '1';
			end if;
    end if;
end process;

-- read process
reading : process(clk, rst_n)
    file infile : text is in "voltage_data_file.txt";
    variable inline : line;
    variable dataread : integer;
begin
    if rst_n = '0' then
        data_out <= (others => '0');
        data_out_valid <= '0';
	elsif rising_edge(clk) then
		if not endfile(infile) and counter = "1100100" then
			readline(infile,inline);
			read(inline,dataread);
			data_out <= std_logic_vector(to_unsigned(dataread,12));
			data_out_valid <= '1';
		else
			data_out_valid <= '0';
		end if;
	end if;
end process reading;      

end behav;