--------------------------------------------------------------------------------
-- Project : PROJECTNAME
-- Author : Donald MacIntyre - djm4912
-- Date : 7/8/2015
-- File : populate_fifo.vhd
--------------------------------------------------------------------------------
-- Description :
--------------------------------------------------------------------------------
-- $Log$
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_signed.all;

entity populate_fifo is
    Port (
		clk 	: in std_logic;
		rst_n 	: in std_logic;
		data_in : in std_logic_vector(11 downto 0);
		data_valid : in std_logic;
		wr_strb	: out std_logic;
		fifo_data_to_write : out std_logic_vector(23 downto 0)
    );
end populate_fifo;

architecture behav of populate_fifo is

--------------------------------------------------------------------------------
-- Signal Declarations
--------------------------------------------------------------------------------
type states is (idle, subtract, square, store);
signal state : states;

signal data_sub_offset : std_logic_vector(11 downto 0); 
signal data_valid_re : std_logic;
signal mult_reg		: std_logic_vector(23 downto 0);
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

component mult IS
	PORT
	(
		data		: IN STD_LOGIC_VECTOR (11 DOWNTO 0);
		result		: OUT STD_LOGIC_VECTOR (23 DOWNTO 0)
	);
END component;
--------------------------------------------------------------------------------

begin

edge_inst : edge_dect
    Port map(
		clk 				=> clk,
		rst_n 				=> rst_n,		-- active low
		edge_dect_in		=> data_valid,
		rising_edge_dect	=> data_valid_re,	-- high iff a rising edge is detected
		falling_edge_dect	=> open		-- high iff a falling edge is detected
    );

mult_inst : mult 
	PORT map
	(
		data		=> data_sub_offset,
		result		=> mult_reg
	);
	
fsm : process(clk, rst_n)
begin
	if rst_n = '0' then
		state <= idle;
		wr_strb <= '0';
		data_sub_offset <= (others => '0');
	elsif rising_edge(clk) then
		case state is
			when idle =>
				wr_strb <= '0';
				if data_valid_re = '1' then
					state <= subtract;
				else	
					state <= idle;
				end if;
			
			when subtract => 
				wr_strb <= '0';
				data_sub_offset <= data_in - x"200";
				state <= square;
				
			when square =>
				wr_strb <= '0';
				state <= store;
				
			when store =>
				wr_strb <= '1';
				fifo_data_to_write <= mult_reg;
				state <= idle;
				
			when others =>
				state <= idle;
		end case;
	end if;
end process fsm;

end behav;