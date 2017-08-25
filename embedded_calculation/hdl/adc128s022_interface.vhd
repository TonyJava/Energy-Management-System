--------------------------------------------------------------------------------
-- Project : PROJECTNAME
-- Author : Donald MacIntyre - djm4912
-- Date : 7/15/2015
-- File : adc128s022_interface.vhd
--------------------------------------------------------------------------------
-- Description :
--------------------------------------------------------------------------------
-- $Log$
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity adc128s022_interface is
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
end adc128s022_interface;

architecture behav of adc128s022_interface is

--------------------------------------------------------------------------------
-- Signal Declarations
--------------------------------------------------------------------------------
signal clk_counter : std_logic_vector (3 downto 0);
signal sclk_sig : std_logic;
signal sclk_sig_re : std_logic;
signal sclk_sig_fe : std_logic;
signal conv_start_re : std_logic;
signal sclk_en : std_logic;
signal latched_address : std_logic_vector (2 downto 0);

signal shift_counter : std_logic_vector(3 downto 0);
signal adc_shiftin_data : std_logic_vector(11 downto 0);
type states is (idle, start_conv, add2, add1, add0,shift_in_data, conv_complete);
signal state : states;
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

conv_start_inst : edge_dect
    Port map(
		clk 				=> clk,
		rst_n 				=> rst_n,
		edge_dect_in		=> conv_start,
		rising_edge_dect	=> conv_start_re,
		falling_edge_dect	=> open
    );
    
conv_cs_inst : edge_dect
    Port map(
		clk 				=> clk,
		rst_n 				=> rst_n,
		edge_dect_in		=> sclk_sig,
		rising_edge_dect	=> sclk_sig_re,
		falling_edge_dect	=> sclk_sig_fe
    );

-- Generate 3.125 MHz clock from 50 MHz clock
gen_sclk_proc : process(clk, rst_n)
begin
    if rst_n = '0' or sclk_en = '0' then
        sclk_sig <= '1';
        clk_counter <= "0000";
    elsif rising_edge(clk) then
        clk_counter <= clk_counter + '1';
        if clk_counter < x"8" then
            sclk_sig <= '1';
        else
            sclk_sig <= '0';
        end if;
    end if;
end process gen_sclk_proc;

-- FSM to control IO to adc
fsm_sm_proc : process(clk, rst_n)
begin
    if rst_n = '0' then
        state <= idle;
        conv_in_progress <= '1';
        adc_data <= x"000";
        shift_counter <= "0000";
        adc_cs <= '1';
        serial_din_to_adc <= '0';
        adc_shiftin_data <= x"000";
		  latched_address <= "000";
        
    elsif rising_edge(clk) then
       
        case state is 
            
            when idle =>
                -- look for request of a conversion
                if conv_start_re = '1' then
                    state <= start_conv;
                else
                    state <= idle;
                end if;
                conv_in_progress <= '0';
                adc_cs <= '1';
                serial_din_to_adc <= '0';
                adc_shiftin_data <= x"000";
                sclk_en <= '0';
                
            when start_conv => 
                sclk_en <= '1';
                conv_in_progress <= '1';
                adc_cs <= '0';
                serial_din_to_adc <= '0';
                if sclk_sig_fe = '1' then
                    shift_counter <= shift_counter + '1';
                end if;
                if shift_counter = x"2" then
						  latched_address <= channel_to_use;
                    state <= add2;
                else
                    state <= start_conv;
                end if;
                
            when add2 =>
                conv_in_progress <= '1';
                sclk_en <= '1';
                adc_cs <= '0';
                -- change at shift counter = 3
                if sclk_sig_fe = '1' then
                    serial_din_to_adc <= latched_address(2);
                    shift_counter <= shift_counter + '1';
                    state <= add1;
                else    
                    state <= add2;
                end if;
                    
            when add1 => 
                conv_in_progress <= '1';
                sclk_en <= '1';
                adc_cs <= '0';
                -- change at shift counter = 4
                if sclk_sig_fe = '1' then
                    serial_din_to_adc <= latched_address(1);
                    shift_counter <= shift_counter + '1';
                    state <= add0;
                else
                    state <= add1;
                end if;
                
            -- read in last bit of a0 and shift in result    
            when add0 =>
                conv_in_progress <= '1';
                sclk_en <= '1';
                adc_cs <= '0';
                -- change at shift counter = 5
                if sclk_sig_fe = '1' then 
                    serial_din_to_adc <= latched_address(0);
                    state <= shift_in_data;
                end if;
            
			when shift_in_data =>
				conv_in_progress <= '1';
                sclk_en <= '1';
                adc_cs <= '0';
				if sclk_sig_re = '1' then
					adc_shiftin_data <= adc_shiftin_data(10 downto 0) & serial_dout_from_adc;
					shift_counter <= shift_counter + '1';
				if shift_counter = x"F" then
                        state <= conv_complete;
                    else 
                        state <= shift_in_data;
                    end if;
                end if;
				
			when conv_complete =>
                conv_in_progress <= '1';
                sclk_en <= '0';
                adc_cs <= '1';
                adc_data <= adc_shiftin_data;
                state <= idle;
                
            when others => 
                state <= idle;
        
        end case;
    end if;
        
        
end process fsm_sm_proc;

adc_sclk <= sclk_sig;
                        
end behav;