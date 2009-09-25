library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity fx2_usb is
	Port (
		clk_i : in std_logic;
		rst_i : in std_logic;
		fx2_wr_full_i : in std_logic;
		fx2_rd_empty_i : in std_logic;
		fx2_data_io : inout std_logic_vector(7 downto 0);
		fx2_clk_i : in std_logic;
		fx2_slcs_o : out std_logic;
		fx2_slrd_o : out std_logic;
		fx2_sloe_o : out std_logic;
		fx2_slwr_o : out std_logic;
		fx2_pktend_o : out std_logic;
		fx2_fifo_addr_o : out std_logic_vector(1 downto 0);
		din : in std_logic_vector(7 downto 0);
		dout : out std_logic_vector(7 downto 0);
		wr_en : in std_logic;
		rd_en : in std_logic;
		wr_full : out std_logic;
		rd_empty : out std_logic;
		pktend_i : in std_logic
	);
end fx2_usb;

architecture Behavioral of fx2_usb is
component tiny_fifo
	port (
	din: IN std_logic_VECTOR(7 downto 0);
	rd_clk: IN std_logic;
	rd_en: IN std_logic;
	rst: IN std_logic;
	wr_clk: IN std_logic;
	wr_en: IN std_logic;
	dout: OUT std_logic_VECTOR(7 downto 0);
	empty: OUT std_logic;
	full: OUT std_logic);
end component;

	signal tx_dout : std_logic_vector(7 downto 0);
	signal tx_empty, rx_full : std_logic;
	signal tx_rd_en, rx_wr_en : std_logic;
	type mode is (IDLE, RD, DELAY, PKTEND);
	signal state : mode;
	signal tx_fifo_selected : std_logic;
		
	signal pktend_r1 : std_logic;
	signal pktend_r2 : std_logic;
	signal pktend_r3 : std_logic;
	signal pktend_pending : std_logic;
	
	signal pktend_delay : integer;
begin

	fx2_slcs_o <= '0';

	fx2_sloe_o <= '0' when tx_fifo_selected = '0' else '1';
	fx2_data_io <= tx_dout when tx_fifo_selected = '1' else (others => 'Z');
	fx2_fifo_addr_o <= "10" when tx_fifo_selected = '1' else "00";
				
	process(fx2_clk_i)
	begin
		if rising_edge(fx2_clk_i) then
			
			fx2_slwr_o <= not tx_rd_en;
			fx2_slrd_o <= '1';
			fx2_pktend_o <= '1';
			
			pktend_r1 <= pktend_i;
			pktend_r2 <= pktend_r1;
			pktend_r3 <= pktend_r2;
			
			if pktend_r3 = '0' and pktend_r2 = '1' then
				pktend_pending <= '1';
			end if;
									
			rx_wr_en <= '0';
			tx_rd_en <= '0';
			
			if rst_i = '1' then
				tx_fifo_selected <= '0';				
				state <= IDLE;
				pktend_pending <= '0';
			else
			
				-- always go back to idle state
				state <= IDLE;
			
				case state is
				
					when IDLE =>
					
						-- pktend?
						if fx2_wr_full_i = '1' and pktend_pending = '1' then
							pktend_pending <= '0';
							pktend_delay <= 4;
							tx_fifo_selected <= '1';
							state <= PKTEND;
					
						-- send
						elsif fx2_wr_full_i = '1' and tx_empty = '0' and tx_fifo_selected = '1' then
							tx_rd_en <= '1';
							state <= DELAY;
						
						-- receive
						elsif fx2_rd_empty_i = '1' and rx_full = '0' and tx_fifo_selected = '0' then
							rx_wr_en <= '1';
							state <= RD;
						
						-- switch to sending
						elsif fx2_wr_full_i = '1' and tx_empty = '0' then
							tx_fifo_selected <= '1';
							state <= DELAY;
							
						-- switch to receiving
						elsif fx2_rd_empty_i = '1' and rx_full = '0' then
							tx_fifo_selected <= '0';
							state <= DELAY;
						
						end if;
						
					when RD =>
						fx2_slrd_o <= '0';
					
					when DELAY => null;
					
					when PKTEND =>
						state <= PKTEND;
						pktend_delay <= pktend_delay - 1;
						if pktend_delay = 0 then
							fx2_pktend_o <= '0';
							state <= IDLE;
						end if;
				
				end case;
			
			end if;
			
		end if;
	end process;

	rx_fifo : tiny_fifo
		port map (
			din => fx2_data_io,
			rd_clk => clk_i,
			rd_en => rd_en,
			rst => rst_i,
			wr_clk => fx2_clk_i,
			wr_en => rx_wr_en,
			dout => dout,
			empty => rd_empty,
			full => rx_full);

	tx_fifo : tiny_fifo
		port map (
			din => din,
			rd_clk => fx2_clk_i,
			rd_en => tx_rd_en,
			rst => rst_i,
			wr_clk => clk_i,
			wr_en => wr_en,
			dout => tx_dout,
			empty => tx_empty,
			full => wr_full);

end Behavioral;
