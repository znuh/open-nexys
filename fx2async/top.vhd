library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity top is
	port ( clk_i: in std_logic;
			fx2_wr_full_i : in  STD_LOGIC;
			fx2_rd_empty_i : in STD_LOGIC;
	        fx2_data_io : inout  STD_LOGIC_VECTOR (7 downto 0);
	        fx2_fifo_addr_o : out  STD_LOGIC_VECTOR (1 downto 0);
	        fx2_slwr_o : out  STD_LOGIC;
	        fx2_slrd_o : out std_logic;
	        fx2_sloe_o : out std_logic;
			  fx2_slcs_o : out std_logic;
    	    fx2_pktend_o : out  STD_LOGIC;
			 sw_i: in std_logic_vector(7 downto 0);
			 btn_i: in std_logic_vector(3 downto 0);
			 led_o: out std_logic_vector(7 downto 0)
			);
end top;

architecture Behavioral of top is
	component fx2async is
	Port(
			fx2_wr_full_i : in  STD_LOGIC;
			fx2_rd_empty_i : in STD_LOGIC;
	      fx2_data_io : inout  STD_LOGIC_VECTOR (7 downto 0);
	      fx2_fifo_addr_o : out  STD_LOGIC_VECTOR (1 downto 0);
	      fx2_slwr_o : out  STD_LOGIC;
	      fx2_slrd_o : out std_logic;
	      fx2_sloe_o : out std_logic;
			fx2_slcs_o : out std_logic;
    	   fx2_pktend_o : out  STD_LOGIC;
			 
			usb_data_i : in std_logic_vector(7 downto 0);
			usb_data_o : out std_logic_vector(7 downto 0);
			usb_wr_en_i : in std_logic;
			usb_rd_en_i : in std_logic;
			usb_wr_strobe_o : out std_logic;
			usb_rd_strobe_o : out std_logic;
			usb_pktend_i : in std_logic;
			usb_pktstart_o : out std_logic;
			 
			clk_i : in std_logic;
			rst_i : in std_logic
	);
	end component;

	signal usb_txd : std_logic_vector(7 downto 0);
	signal usb_rxd : std_logic_vector(7 downto 0);
	signal usb_wr : std_logic;
	signal usb_rd : std_logic;
	signal usb_wr_strobe : std_logic;
	signal usb_rd_strobe : std_logic;
	signal usb_pktend : std_logic;
	signal usb_pktstart: std_logic;

	signal rst : std_logic := '1';
	signal delay_cnt : std_logic_vector(15 downto 0) := (others => '0');

	signal sw_r1 : std_logic_vector(7 downto 0);
	signal sw_r2 : std_logic_vector(7 downto 0);
begin

	fx2async_inst : fx2async
   port map (
			-- einfach durchreichen...
			fx2_wr_full_i => fx2_wr_full_i,
			fx2_rd_empty_i => fx2_rd_empty_i,
	      fx2_data_io => fx2_data_io,
	      fx2_fifo_addr_o => fx2_fifo_addr_o,
	      fx2_slwr_o => fx2_slwr_o,
	      fx2_slrd_o => fx2_slrd_o,
	      fx2_sloe_o => fx2_sloe_o,
			fx2_slcs_o => fx2_slcs_o,
    	   fx2_pktend_o => fx2_pktend_o,
			
			-- user interface zum USB interface
			usb_data_i => usb_txd,
			usb_data_o => usb_rxd,
			usb_wr_en_i => usb_wr,
			usb_rd_en_i => usb_rd,
			usb_wr_strobe_o => usb_wr_strobe,
			usb_rd_strobe_o => usb_rd_strobe,
			usb_pktend_i => usb_pktend,
			usb_pktstart_o => usb_pktstart,
			 
			clk_i => clk_i,
			rst_i => rst
   );

	process
	begin
		wait until rising_edge(clk_i);
		
		-- reset generator for usb if
		if delay_cnt /= x"ffff" then
			delay_cnt <= delay_cnt + 1;
			rst <= '1';
		else
			rst <= '0';
		end if;
		
		-- we like well defined init states!
		if rst = '1' then
			usb_wr <= '0';
			usb_rd <= '0';
			usb_pktend <= '0';
			
		else
		
			-- always receive
			usb_rd <= '1';
			
			-- got a byte
			if usb_rd_strobe = '1' then
			
				-- output 1st byte on LEDs
				if usb_pktstart = '1' then
					led_o <= usb_rxd;
				end if;
			
			end if;
		
			-- always send
			usb_wr <= '1';
		
			-- sync switches
			sw_r1 <= sw_i;
			sw_r2 <= sw_r1;
			
			-- send switches
			usb_txd <= sw_r2;
		
		end if;
		
	end process;	

end Behavioral;
