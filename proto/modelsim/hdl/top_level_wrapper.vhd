--------------------------------------------------------------------------------
-- Project : PROJECTNAME
-- Author : Donald MacIntyre - djm4912
-- Date : 7/8/2015
-- File : top_level_wrapper.vhd
--------------------------------------------------------------------------------
-- Description :
--------------------------------------------------------------------------------
-- $Log$
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity top_level_wrapper is
    Port (
		clk : in std_logic;		-- 10 MHz
		rst_n : in std_logic
    );
end top_level_wrapper;

architecture behav of top_level_wrapper is

--------------------------------------------------------------------------------
-- Signal Declarations
--------------------------------------------------------------------------------
signal data_out_sig : std_logic_vector(11 downto 0);
signal data_out_valid_sig : std_logic;
signal rd_sig : std_logic;
signal wr_sig : std_logic;
signal data_wr : std_logic_vector (23 downto 0);
signal data_rd : std_logic_vector (23 downto 0);
signal count : std_logic_vector( 11 downto 0);
signal zero_crossing_dect_sig : std_logic;
signal freq_dect_sig : std_logic_vector(31 downto 0);
signal v_rms_valid : std_logic;
signal v_rms : std_logic_vector(15 downto 0);
--------------------------------------------------------------------------------
-- Component Declarations
--------------------------------------------------------------------------------
component genData is
    Port (
        clk : in std_logic;         -- 10 MHz clock
        rst_n : in std_logic;
        data_out : out std_logic_vector(11 downto 0);
        data_out_valid : out std_logic
    );
end component;

component fifo IS
	PORT
	(
		clock		: IN STD_LOGIC ;
		data		: IN STD_LOGIC_VECTOR (23 DOWNTO 0);
		rdreq		: IN STD_LOGIC ;
		wrreq		: IN STD_LOGIC ;
		empty		: OUT STD_LOGIC ;
		full		: OUT STD_LOGIC ;
		q			: OUT STD_LOGIC_VECTOR (23 DOWNTO 0);
		usedw		: OUT STD_LOGIC_VECTOR (11 DOWNTO 0)	-- number of words in fifo
	);
END component;

component populate_fifo is
    Port (
		clk 	: in std_logic;
		rst_n 	: in std_logic;
		data_in : in std_logic_vector(11 downto 0);
		data_valid : in std_logic;
		wr_strb	: out std_logic;
		fifo_data_to_write : out std_logic_vector(23 downto 0)
    );
end component;

component zero_crossing_dect is
    Port (
        clk : in std_logic;
        rst_n : std_logic;
        data_in : std_logic_vector(11 downto 0);
        data_in_valid : in std_logic;
        zero_crossing_dect : out std_logic
    );
end component;

component freq_dect is
    Port (
        clk : in std_logic;
        rst_n : in std_logic;
        zero_crosssing : in std_logic;
        freq_dect : out std_logic_vector( 31 downto 0)
    );
end component;

component rms_calc is
    Port (
        clk : in std_logic;
        rst_n : in std_logic;
        count : in std_logic_vector ( 11 downto 0);
        rd_strb : out std_logic;
        rd_data : in std_logic_vector( 23 downto 0);
        rms_valid : out std_logic;
        rms : out std_logic_vector(15 downto 0)
    );
end component;
--------------------------------------------------------------------------------

begin

v_rms_inst : rms_calc
    Port map(
        clk     => clk,
        rst_n   => rst_n,
        count   => count,
        rd_strb => rd_sig,
        rd_data => data_rd,
        rms_valid => v_rms_valid,
        rms     => v_rms
    );

genDatainst : genData 
    Port map(
        clk 		=> clk,        -- 10 MHz clock
        rst_n 		=> rst_n,
        data_out 	=> data_out_sig,
        data_out_valid => data_out_valid_sig
    );

pop_fifo_inst : populate_fifo
    Port map(
		clk 	=> clk,
		rst_n 	=> rst_n,
		data_in => data_out_sig,
		data_valid => data_out_valid_sig,
		wr_strb	=> wr_sig,
		fifo_data_to_write => data_wr
    );	
	
fifo_inst : fifo
	PORT map
	(
		clock		=> clk,
		data		=> data_wr,
		rdreq		=> rd_sig,
		wrreq		=> wr_sig,
		empty		=> open,
		full		=> open,
		q		   	=> data_rd,
		usedw		=> count
	);

v_zero_cross_inst : zero_crossing_dect 
    Port map(
        clk     => clk,
        rst_n   => rst_n,
        data_in => data_out_sig,
        data_in_valid => data_out_valid_sig,
        zero_crossing_dect => zero_crossing_dect_sig
    );   

v_freq_dect_inst : freq_dect
    Port map(
        clk => clk,
        rst_n => rst_n,
        zero_crosssing => zero_crossing_dect_sig,
        freq_dect => freq_dect_sig
    );
    
end behav;