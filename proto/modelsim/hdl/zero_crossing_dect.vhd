--------------------------------------------------------------------------------
-- Project : PROJECTNAME
-- Author : Donald MacIntyre - djm4912
-- Date : 7/9/2015
-- File : zero_crossing_dect.vhd
--------------------------------------------------------------------------------
-- Description :
--------------------------------------------------------------------------------
-- $Log$
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity zero_crossing_dect is
    Port (
        clk : in std_logic;
        rst_n : std_logic;
        data_in : std_logic_vector(11 downto 0);
        data_in_valid : in std_logic;
        zero_crossing_dect : out std_logic
    );
end zero_crossing_dect;

architecture behav of zero_crossing_dect is

--------------------------------------------------------------------------------
-- Signal Declarations
--------------------------------------------------------------------------------
signal raw_zero_crossing : std_logic;
signal zero_crossing_reg : std_logic_vector(3 downto 0);
signal data_in_re : std_logic;
signal zero_crossing_dect_sig : std_logic;
--------------------------------------------------------------------------------
-- Component Declarations
--------------------------------------------------------------------------------
component edge_dect is
    Port (
		clk 				: in std_logic;
		rst_n 				: in std_logic;		-- active low
		edge_dect_in		: in std_logic;
		rising_edge_dect	: out std_logic;	-- high iff a rising edge is detected
		falling_edge_dect	: out std_logic		-- high iff a falling edge is detected
    );
end component;
--------------------------------------------------------------------------------

begin

data_valid_edge_dect : edge_dect 
    Port map(
		clk 				=> clk,
		rst_n 				=> rst_n,	-- active low
		edge_dect_in		=> data_in_valid,
		rising_edge_dect	=> data_in_re,	-- high iff a rising edge is detected
		falling_edge_dect	=> open		-- high iff a falling edge is detected
    );

determine_zero_cross : process(clk, rst_n)
begin
    if rst_n = '0' then
        raw_zero_crossing <= '0';
    elsif rising_edge(clk) then
        if data_in_re = '1' then
            if data_in > x"0200" then
                raw_zero_crossing <= '1';
            else
                raw_zero_crossing <= '0';
            end if;
        else
            raw_zero_crossing <= raw_zero_crossing;
        end if;
    end if;
end process determine_zero_cross;

shift_reg_zero_cross : process(clk, rst_n)
begin
    if rst_n = '0' then
        zero_crossing_reg <= (others => '0');
    elsif rising_edge(clk) then
        if data_in_re = '1' then
            zero_crossing_reg <= zero_crossing_reg(2 downto 0) & raw_zero_crossing;
        else
            zero_crossing_reg <= zero_crossing_reg;
        end if;
    end if;
end process shift_reg_zero_cross;

debounce_shift_reg_out : process(clk, rst_n)
begin
    if rst_n = '0' then
        zero_crossing_dect_sig <= '0';
    elsif rising_edge(clk) then
        if zero_crossing_reg = "1111" then
            zero_crossing_dect_sig <= '1';
        elsif zero_crossing_reg = "0000" then
            zero_crossing_dect_sig <= '0';
        else
            zero_crossing_dect_sig <= zero_crossing_dect_sig;
        end if;
    end if;
end process debounce_shift_reg_out;

zero_crossing_dect <= zero_crossing_dect_sig;
     
end behav;