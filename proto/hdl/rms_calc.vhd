--------------------------------------------------------------------------------
-- Project : PROJECTNAME
-- Author : Donald MacIntyre - djm4912
-- Date : 7/9/2015
-- File : rms_calc.vhd
--------------------------------------------------------------------------------
-- Description :
--------------------------------------------------------------------------------
-- $Log$
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity rms_calc is
    Port (
        clk : in std_logic;
        rst_n : in std_logic;
        count : in std_logic_vector ( 11 downto 0);
        rd_strb : out std_logic;
        rd_data : in std_logic_vector( 23 downto 0);
        rms_valid : out std_logic;
        rms : out std_logic_vector(15 downto 0)
    );
end rms_calc;

architecture behav of rms_calc is

--------------------------------------------------------------------------------
-- Signal Declarations
--------------------------------------------------------------------------------
type states is (idle, sum_data, divide_by_n, square_rt, report_rms);
signal state : states;

signal sum_data_count : std_logic_vector(11 downto 0);
signal fifo_sum_reg : std_logic_vector ( 31 downto 0);
signal fifo_sum_divide_reg : std_logic_vector(31 downto 0);
signal sqrt_res_reg : std_logic_vector( 15 downto 0);
--------------------------------------------------------------------------------
-- Component Declarations
--------------------------------------------------------------------------------
component sqrt IS
	PORT
	(
		radical		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
		remainder		: OUT STD_LOGIC_VECTOR (16 DOWNTO 0)
	);
END component;
--------------------------------------------------------------------------------

begin

sqrt_inst : sqrt
	PORT map
	(
		radical		=> fifo_sum_divide_reg,
		q		    => sqrt_res_reg, 
		remainder	=> open
	);

fsm : process( rst_n, clk)
begin
    if rst_n = '0' then
        state <= idle;
        rd_strb <= '0';
        rms_valid <= '0';
        sum_data_count <= x"000";
        fifo_sum_reg <= (others => '0');
        rms <= (others => '0');
    elsif rising_edge(clk) then
        case state is
            when idle =>
                rms_valid <= '0';
                sum_data_count <= x"000";
                fifo_sum_reg <= (others => '0');
                fifo_sum_divide_reg <= (others => '0');
                if count = x"0200" then
                    state <= sum_data;
                else 
                    state <= idle;
                end if;
                
            when sum_data =>
                rd_strb <= '1';
                sum_data_count <= sum_data_count + '1';
                fifo_sum_reg <= fifo_sum_reg + rd_data;
                if sum_data_count = x"0200" then
                    state <= divide_by_n;
                else    
                    state <= sum_data;
                end if;
                
            when divide_by_n =>
                rd_strb <= '0';
                fifo_sum_divide_reg <=  "000000000" & fifo_sum_reg(31 downto 9);
                state <= square_rt;
                
            when square_rt => 
                state <= report_rms;
                
            when report_rms =>
                rms <= sqrt_res_reg;
                rms_valid <= '1';
                state <= idle;            
                
            when others => 
                state <= idle;
        end case;
    end if;
end process fsm;

end behav;