--------------------------------------------------------------------------------
-- Project : PROJECTNAME
-- Author : Donald MacIntyre - djm4912
-- Date : 7/9/2015
-- File : freq_dect.vhd
--------------------------------------------------------------------------------
-- Description :
--------------------------------------------------------------------------------
-- $Log$
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity freq_dect is
    Port (
        clk : in std_logic;
        rst_n : in std_logic;
        zero_crosssing : in std_logic;
        freq_dect : out std_logic_vector( 31 downto 0)
    );
end freq_dect;

architecture behav of freq_dect is

--------------------------------------------------------------------------------
-- Signal Declarations
--------------------------------------------------------------------------------
type states is (reset_state, latch_freq_dect, count);
signal state : states;

signal freq_dect_count : std_logic_vector(31 downto 0);
signal zero_crossing_re : std_logic;
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

zero_crosssing_edge : edge_dect
    Port map(
		clk 				=> clk,
		rst_n 				=> rst_n,	-- active low
		edge_dect_in		=> zero_crosssing,
		rising_edge_dect	=> zero_crossing_re,	-- high iff a rising edge is detected
		falling_edge_dect	=> open	-- high iff a falling edge is detected
    );

fsm : process(clk, rst_n)
begin
    if rst_n = '0' then
        state <= reset_state;
        freq_dect <= ( others => '0');
        freq_dect_count <= (others => '0');
    elsif rising_edge(clk) then
        case state is
            when reset_state =>
                freq_dect <= (others => '0');
                freq_dect_count <= (others => '0');
                if zero_crossing_re = '1' then
                    state <= count;
                else
                    state <= reset_state;
                end if;
             
            when count =>
                freq_dect_count <= freq_dect_count + '1';
                if zero_crossing_re = '1' then
                    state <= latch_freq_dect;
                else
                    state <= count;
                end if;

            when latch_freq_dect => 
                freq_dect <= freq_dect_count;
                freq_dect_count <= (others => '0');
                state <= count;
                
            when others =>
                state <= reset_state;
             
        end case;
    end if;
end process fsm;
                 
                

end behav;