--------------------------------------------------------------------------------
-- Project : PROJECTNAME
-- Author : Donald MacIntyre - djm4912
-- Date : 10/16/2015
-- File : plc_i2c_fsm.vhd
--------------------------------------------------------------------------------
-- Description :
--------------------------------------------------------------------------------
-- $Log$
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity plc_i2c_fsm is
    Port (
		clk 			: in std_logic;
		por_n 			: in std_logic;
		rx_interrupt 	: in std_logic;
		power_to_tx : in std_logic_vector(31 downto 0);
		voltage_to_tx : in std_logic_vector(31 downto 0);
		current_to_tx : in std_logic_vector(31 downto 0);
		load_switch_en : out std_logic;
		software_rst   : out std_logic;
		current_lim_high : out std_logic_vector(11 downto 0);
		current_lim_low  : out std_logic_vector(11 downto 0);
		
		-- I2C Inputs/Outputs
		sda				: inout std_logic;
		scl				: inout std_logic;
		led            : out std_logic_vector(7 downto 0);
		debug_output   : out std_logic
    );
end plc_i2c_fsm;

architecture behav of plc_i2c_fsm is

--------------------------------------------------------------------------------
-- Signal Declarations
--------------------------------------------------------------------------------
-- Generate 1kHz clock of 50 MHz clock
signal slow_clk_1khz : std_logic;
signal slow_clk_count : std_logic_vector(15 downto 0);

signal rx_interrupt_past : std_logic;
signal rx_interrupt_sig : std_logic;

signal tx_pulse_past : std_logic;
signal tx_interrupt_sig : std_logic;

signal tx_pulse : std_logic;
signal tx_pulse_count : std_logic_vector(15 downto 0);
signal tx_offset : std_logic_vector(13 downto 0);
signal tx_threshold : std_logic_vector(15 downto 0);
signal tx_offset_pi : std_logic_vector(5 downto 0);

signal load_switch_en_sig : std_logic;
signal software_rst_sig : std_logic;
signal current_lim_term2 : std_logic_vector(13 downto 0);
signal current_lim_term3 : std_logic_vector(11 downto 0);

-- I2C
type plc_states is (idle, start_rx, start_tx, calc_avg_pwr_to_tx, wait_trans_done, request_read, collect_data, process_op, request_plc_write, latch_in_write_payload1,
	payload1_write_in_prog, latch_in_write_payload2,payload2_write_in_prog, latch_in_write_payload3, payload3_write_in_prog, latch_in_write_payload4, payload4_write_in_prog,
	wait_payload_done, send_plc_rx_cmd, latch_in_plc_rx_cmd, plc_rx_cmd_in_progress, wait_rx_cmd_done);
signal plc_state : plc_states;

signal i2c_enable : std_logic;
signal i2c_addr : std_logic_vector(6 downto 0);
signal i2c_rw : std_logic;
signal i2c_data_wr : std_logic_vector(7 downto 0);
signal i2c_busy_sig : std_logic;
signal i2c_data_rd : std_logic_vector(7 downto 0);
signal i2c_ack_error : std_logic;

signal counter : std_logic_vector(7 downto 0);

signal power_to_transmit : std_logic_vector(31 downto 0);
signal op_code : std_logic_vector(7 downto 0);
signal loop_count : std_logic_vector (1 downto 0);
--------------------------------------------------------------------------------
-- Component Declarations
--------------------------------------------------------------------------------
component i2c_master_djm IS
  GENERIC(
    input_clk : INTEGER := 50_000_000; --input clock speed from user logic in Hz
    bus_clk   : INTEGER := 400_000);   --speed the i2c bus (scl) will run at in Hz
  PORT(
    clk       : IN     STD_LOGIC;                    --system clock
    reset_n   : IN     STD_LOGIC;                    --active low reset
    ena       : IN     STD_LOGIC;                    --latch in command
    addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
    rw        : IN     STD_LOGIC;                    --'0' is write, '1' is read
    data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
    busy      : OUT    STD_LOGIC;                    --indicates transaction in progress
    data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
    --ack_error : BUFFER STD_LOGIC;                    --flag if improper acknowledge from slave
    ack_error : OUT    STD_LOGIC;					 -- flag if improper acknowledge from slave
	sda       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
   scl       : INOUT  STD_LOGIC);                   --serial clock output of i2c bus
END component;
--------------------------------------------------------------------------------

begin

i2c : i2c_master_djm
  GENERIC map(
    input_clk => 50_000_000, --input clock speed from user logic in Hz
    bus_clk   => 100_000)   --speed the i2c bus (scl) will run at in Hz
  PORT map(
    clk       => clk,                     --system clock
    reset_n   => por_n,                   --active low reset
    ena       => i2c_enable,              --latch in command
    addr      => i2c_addr,				  --address of target slave
    rw        => i2c_rw,                  --'0' is write, '1' is read
    data_wr   => i2c_data_wr,			  --data to write to slave
    busy      => i2c_busy_sig,            --indicates transaction in progress
    data_rd   => i2c_data_rd,			  --data read from slave
    --ack_error : BUFFER STD_LOGIC;       --flag if improper acknowledge from slave
    ack_error => i2c_ack_error,			  -- flag if improper acknowledge from slave
	sda       => sda,                     --serial data output of i2c bus
    scl       => scl
	 );                   --serial clock output of i2c bus

gen_1kHZ_clock : process(clk, por_n)
begin
	if por_n = '0' then
		slow_clk_1khz <= '1';
		slow_clk_count <= (others => '0');
	elsif rising_edge(clk) then
		if slow_clk_count > x"61A6" then
			slow_clk_1khz <= not slow_clk_1khz;
			slow_clk_count <= (others => '0');
		else
			slow_clk_count <= slow_clk_count + '1';
		end if;
	end if;
end process gen_1kHZ_clock;
		
-- Generate TX Pulse(Pulse Ranging Anywhere from 1 second to 16.75 seconds)
-- Need to generate base pulse of 1 second + offset pulse based on command passed in from I2C
-- Offset shall be 6 bits long, with a resolution of 250 ms per bit 
gen_tx_pulse : process(slow_clk_1khz, por_n)
begin
		if por_n = '0' then
			tx_pulse <= '0';
			tx_pulse_count <= (others => '0');
		elsif rising_edge(slow_clk_1khz) then
			if tx_pulse_count > tx_threshold then
			tx_pulse <= '1';
				tx_pulse_count <= (others =>'0');
			else
				tx_pulse <= '0';
				tx_pulse_count <= tx_pulse_count + '1';
			end if;
		end if;
end process gen_tx_pulse;

-- Generate RX Interrupt 
-- Goes high from PLC rising edge interrupt and goes low for after interupt is processed
rx_interrupt_proc : process(clk, por_n)
begin
	if por_n = '0' then
		rx_interrupt_past <= '0';
		rx_interrupt_sig <= '0';
	elsif rising_edge(clk) then
		rx_interrupt_past <= rx_interrupt;
		if rx_interrupt = '0' and rx_interrupt_past = '1' then
			rx_interrupt_sig <= '1';
		elsif rx_interrupt_sig = '1' and plc_state /= start_rx then
			rx_interrupt_sig <= '1';
		else
			rx_interrupt_sig <= '0';
		end if;
	end if;
end process rx_interrupt_proc;

-- Generate TX Interrupt 
-- Goes high on a rising edge of tx_pulse and goes low after interrupt is processed
tx_interrupt_proc : process(clk, por_n)
begin
	if por_n = '0' then
		tx_interrupt_sig <= '0';
	elsif rising_edge(clk) then
		tx_pulse_past <= tx_pulse;
		if tx_pulse_past = '0' and tx_pulse = '1' then
			tx_interrupt_sig <= '1';
		elsif tx_interrupt_sig = '1' and plc_state /= start_tx then
			tx_interrupt_sig <= '1';
		else
			tx_interrupt_sig <= '0';
		end if;
	end if;
end process tx_interrupt_proc;


-- 00F8 corresponds to 250 for 250 ms per tx_offset passed in from I2c
tx_offset <= "000000" * x"F8"; 		-- "0100" number needs to be changed to op-code value
tx_threshold <= tx_offset + x"0001";--x"03e6";

plc_i2c_fsm : process(clk, por_n)
begin
	-- RST condition here
	if por_n = '0' then
		plc_state <= idle;
		i2c_addr <= "0101110";
		i2c_rw <= '0';
		i2c_enable <= '0';
		i2c_data_wr <= x"00";
		power_to_transmit <= (others => '0');
		led <= x"00";
		op_code <= x"00";
		counter <= x"00";
		load_switch_en_sig <= '0';
		software_rst_sig <= '0';
		tx_offset_pi <= "111111";
		current_lim_term2 <= "00" & x"7d9";
		current_lim_term3 <= x"00a";
		loop_count <= "00";
	elsif rising_edge(clk) then
		case plc_state is 
			
			when idle =>
				i2c_enable <= '0';
				if rx_interrupt_sig = '1' then 
					plc_state <= start_rx;
				elsif tx_interrupt_sig = '1' then
					plc_state <= start_tx;
				else
					plc_state <= idle;
				end if;
				
			when start_tx =>
				plc_state <= calc_avg_pwr_to_tx;
				
			when calc_avg_pwr_to_tx =>
				--power_to_transmit <= counter;
				power_to_transmit <= power_to_tx;
				counter <= counter + '1';
				plc_state <= request_plc_write;
			
			when request_plc_write =>
				i2c_addr <= "0010111";
				i2c_rw <= '0';
				i2c_data_wr <= x"11";
				i2c_enable <= '1';
				if i2c_busy_sig = '0' then
					plc_state <= request_plc_write;
				else
					plc_state <= latch_in_write_payload1;
				end if;
				
			-- latch in the initial write and wait for initial write done
			when latch_in_write_payload1 =>
				i2c_data_wr <= power_to_transmit(31 downto 24);
				if i2c_busy_sig = '0' then
					plc_state <= payload1_write_in_prog;
				else
					plc_state <= latch_in_write_payload1;
				end if;
				
			when payload1_write_in_prog =>
				if i2c_busy_sig = '1' then
					i2c_data_wr <= power_to_transmit(23 downto 16);
					plc_state <= latch_in_write_payload2;
				else
					plc_state <= payload1_write_in_prog;
				end if;
				
			when latch_in_write_payload2 =>
				if i2c_busy_sig = '0' then
					plc_state <= payload2_write_in_prog;
				else
					plc_state <= latch_in_write_payload2;
				end if;
				
			when payload2_write_in_prog =>
				if i2c_busy_sig = '1' then
					i2c_data_wr <= power_to_transmit(15 downto 8);
					plc_state <= latch_in_write_payload3;
				else
					plc_state <= payload2_write_in_prog;
				end if;
				
			when latch_in_write_payload3 =>
				if i2c_busy_sig = '0' then
					plc_state <= payload3_write_in_prog;
				else
					plc_state <= latch_in_write_payload3;
				end if;
				
			when payload3_write_in_prog =>
				if i2c_busy_sig = '1' then
					i2c_data_wr <= power_to_transmit(7 downto 0);
					plc_state <= latch_in_write_payload4;
				else
					plc_state <= payload3_write_in_prog;
				end if;
				
			when latch_in_write_payload4 =>
				if i2c_busy_sig = '0' then
					plc_state <= payload4_write_in_prog;
				else
					plc_state <= latch_in_write_payload4;
				end if;
				
			when payload4_write_in_prog =>
				if i2c_busy_sig = '1' then
					loop_count <= loop_count + '1';
					if loop_count = x"10" then
						plc_state <= wait_payload_done;
					else
						plc_state <= latch_in_write_payload1;
						if loop_count = "00" then
							power_to_transmit <= voltage_to_tx;
						else
							power_to_transmit <= current_to_tx;
						end if;
					end if;
				else
					plc_state <= payload4_write_in_prog;
				end if;
				
			when wait_payload_done =>
				loop_count <= "00";
				i2c_enable <= '0';
				if i2c_busy_sig = '0' then
					plc_state <= send_plc_rx_cmd;
				else
					plc_state <= wait_payload_done;
				end if;
				
			when send_plc_rx_cmd =>
				i2c_addr <= "0010111";
				i2c_rw <= '0';
				i2c_data_wr <= x"06";
				i2c_enable <= '1';
				if i2c_busy_sig = '0' then
					plc_state <= send_plc_rx_cmd;
				else
					plc_state <= latch_in_plc_rx_cmd;
				end if;
				
			when latch_in_plc_rx_cmd =>
				i2c_data_wr <= x"8C";					-- 4 bytes
				if i2c_busy_sig = '0' then
					plc_state <= plc_rx_cmd_in_progress;
				else
					plc_state <= latch_in_plc_rx_cmd;
				end if;
				
			when plc_rx_cmd_in_progress =>
				if i2c_busy_sig = '1' then
					plc_state <= wait_rx_cmd_done;
				else
					plc_state <= plc_rx_cmd_in_progress;
				end if;
				
			when wait_rx_cmd_done =>
				i2c_enable <= '0';
				if i2c_busy_sig = '0' then
					plc_state <= idle;
				else
					plc_state <= wait_rx_cmd_done;
				end if;
			
			when start_rx =>
				i2c_addr <= "0010111";
				i2c_rw <= '0';
				i2c_data_wr <= x"4A";
				i2c_enable <= '1';
				if i2c_busy_sig = '0' then
					plc_state <= start_rx;
				else
					plc_state <= wait_trans_done;
				end if;
				
			when wait_trans_done =>
				i2c_enable <= '0';
				if i2c_busy_sig = '1' then
					plc_state <= wait_trans_done;
				else
					plc_state <= request_read;
				end if;
				
			when request_read =>
				i2c_enable <= '1';
				i2c_rw <= '1';
				i2c_addr <= "0010111";
				if i2c_busy_sig = '0' then
					plc_state <= request_read;
				else
					plc_state <= collect_data;
				end if;
				
			when collect_data =>
				if i2c_busy_sig = '0' then
					plc_state <= process_op;
					op_code <= i2c_data_rd;
				else
					plc_state <= collect_data;
				end if;
				
			when process_op =>
				-- Need to put case statement here to process op-code
				led <= op_code;
				case op_code(7 downto 6) is
					-- Turn Outlet ON/OFF
					when "00" =>
						if op_code(5 downto 0) = "101010" then
						    load_switch_en_sig <= '1';
						else
						    load_switch_en_sig <= '0';
					   end if;
					-- Set Current Limit
				   when "01" =>
						-- 0x823 is base (0A)
						-- 0x041 is offset corresponding to 0.5A
						current_lim_term2 <= op_code(5 downto 0) * x"29";
						current_lim_term3 <= "00000000" & op_code(5 downto 2);
				   -- Set Time Interval to Transmit At
					when "10" =>
						tx_offset_pi <= op_code(5 downto 0);
					
					-- Software RST
					when "11" => 
						if op_code(5 downto 0) = "111111" then
							software_rst_sig <= '1';
						else
							software_rst_sig <= '0';
						end if;
						
					when others => null;						 
				end case;
				plc_state <= idle;				
					
			when others =>
				plc_state <= idle;
			
		end case;
	end if;
		
end process plc_i2c_fsm;

load_switch_en <= load_switch_en_sig;
software_rst <= software_rst_sig;
current_lim_low <= x"823" - current_lim_term2(11 downto 0) + current_lim_term3;
current_lim_high <= x"824" + current_lim_term2(11 downto 0) - current_lim_term3;

debug_output <= tx_interrupt_sig;

end behav;