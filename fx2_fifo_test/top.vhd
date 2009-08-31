library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity top is
	Port (
		sys_clk : in std_logic;
		Led: out std_logic_vector(7 downto 0);
		sw: in std_logic_vector(7 downto 0);
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
		btn : in std_logic_vector(3 downto 0)
	);
end top;

architecture Behavioral of top is
component bscan_sreg is
	GENERIC (
		SREG_LEN	: integer := 24
	);
	Port (
		CAPTURE_i : in std_logic;
		DRCK_i : in std_logic;
		SEL_i : in std_logic;
		SHIFT_i : in std_logic;
		UPDATE_i : in std_logic;
		TDI_i : in std_logic;
		TDO_o: out std_logic;
		
		clk_i : in std_logic;
		Data_i : in std_logic_vector((SREG_LEN - 1) downto 0);
		Data_o : out std_logic_vector((SREG_LEN - 1) downto 0);
		strobe_o : out std_logic
	);
end component;

	signal CAPTURE : std_logic;
	signal DRCK1 : std_logic;
	signal SEL1 : std_logic;
	signal SHIFT : std_logic;
	signal UPDATE : std_logic;
	signal TDO1 : std_logic;
	signal TDI : std_logic;
	
	signal din : std_logic_vector(23 downto 0);
	signal dout : std_logic_vector(23 downto 0);
	signal strobe : std_logic;
	
	signal fx2_dout : std_logic_vector(7 downto 0);
	signal fx2_wr : std_logic := '0';
	
	signal fx2_wr_cnt : std_logic_vector(15 downto 0);
	signal fx2_notfull_cnt : std_logic_vector(15 downto 0);
	signal fx2_wasfull : std_logic := '0';
	
	signal fx2_stop_on_full : std_logic := '0';
	signal fx2_no_delay : std_logic := '0';
	signal run : std_logic := '0';
	signal autostop : std_logic := '1';
	signal fx2_last_full : std_logic;
	signal delay : std_logic_vector(3 downto 0);
	signal delay_cnt : std_logic_vector(3 downto 0);
begin

   BSCAN_SPARTAN3_inst : BSCAN_SPARTAN3
   port map (
      CAPTURE => CAPTURE, -- CAPTURE output from TAP controller
      DRCK1 => DRCK1,     -- Data register output for USER1 functions
      DRCK2 => open,     -- Data register output for USER2 functions
      RESET => open,     -- Reset output from TAP controller
      SEL1 => SEL1,       -- USER1 active output
      SEL2 => open,       -- USER2 active output
      SHIFT => SHIFT,     -- SHIFT output from TAP controller
      TDI => TDI,         -- TDI output from TAP controller
      UPDATE => UPDATE,   -- UPDATE output from TAP controller
      TDO1 => TDO1,       -- Data input for USER1 function
      TDO2 => open        -- Data input for USER2 function
   );

	bscan_sreg_inst : bscan_sreg
	Port map (
		CAPTURE_i => CAPTURE,
		DRCK_i => DRCK1,
		SEL_i => SEL1,
		SHIFT_i => SHIFT,
		UPDATE_i => UPDATE,
		TDI_i => TDI,
		TDO_o => TDO1,
		clk_i => fx2_clk_i, --sys_clk,
		Data_i => din,
		Data_o => dout,
		strobe_o => strobe
	);

	fx2_fifo_addr_o <= "10";
	
	fx2_slcs_o <= '0';
	
	fx2_slrd_o <= '1';
	fx2_sloe_o <= '1';
	
	Led <= fx2_wr & (not fx2_wr_full_i) & fx2_wasfull & fx2_stop_on_full & fx2_no_delay & "000";
	
	process(fx2_clk_i)
	begin
		if rising_edge(fx2_clk_i) then
			
			-- FX2 default signals
			fx2_slwr_o <= '1';
			fx2_data_io <= (others => 'Z');
			fx2_pktend_o <= '1';
			fx2_wr <= '0';
			
			if fx2_wr_full_i = '0' then
				fx2_wasfull <= '1';
			end if;
			
			-- did a write cycle
			if fx2_wr = '1' then
							
				if fx2_wr_full_i = '1' and fx2_wasfull = '0' then
					fx2_notfull_cnt <= fx2_notfull_cnt + 1;
				end if;
				
			end if;
			
			-- start button
			if btn(0) = '1' then
				run <= '1';
			end if;
			
			fx2_last_full <= fx2_wr_full_i;
			
			-- insert delay after frame
			if fx2_last_full = '1' and fx2_wr_full_i = '0' then
				delay_cnt <= delay;
			end if;

			-- write?
			if delay_cnt /= "000" then
				delay_cnt <= delay_cnt - 1;
			elsif fx2_wr_cnt /= x"0000" or autostop = '0' then
				if (run = '1') and (fx2_wr = '0' or fx2_no_delay = '1') then
					if (fx2_wr_full_i = '1' or fx2_last_full = '1' or fx2_stop_on_full = '0') then
						fx2_data_io <= fx2_dout;
						fx2_dout <= fx2_dout + 1;
						fx2_slwr_o <= '0';
						fx2_wr <= '1';
						fx2_wr_cnt <= fx2_wr_cnt - 1;	
					end if;
				end if;
			else
				run <= '0';
			end if;
			
			-- JTAG strobe
			if strobe = '1' then
				
				din <= dout;
				
				-- reg. addr
				case dout(23 downto 16) is
				
					-- FX2 ctl
					when x"80" => 	fx2_stop_on_full <= dout(0);
										fx2_no_delay <= dout(1);
										-- some kind of raw mode...
										fx2_slwr_o <= not dout(2);
										fx2_wr <= dout(3);
										fx2_pktend_o <= not dout(4);
										autostop <= not dout(5);
										delay <= dout(11 downto 8);
				
					-- FX2 status
					when x"00" => 	din(7 downto 0) <= "000000" & fx2_wr_full_i & fx2_rd_empty_i;
					
					-- FX2 write count
					when x"81" => 	fx2_wr_cnt <= dout(15 downto 0);
										fx2_notfull_cnt <= x"0000";
										fx2_wasfull <= '0';
					
					-- FX2 written count
					when x"01" => 	din(15 downto 0) <= fx2_notfull_cnt;
					
					-- FX2 data out
					when x"82" => 	fx2_dout <= dout(7 downto 0);
					
					-- FX2 data out
					when x"02" => 	din(7 downto 0) <= fx2_dout;
					
					when others => null;
				end case;
			end if;
			
		end if;
	end process;

end Behavioral;

