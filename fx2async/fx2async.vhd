library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity fx2async is
	port (
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
end fx2async;

architecture Behavioral of fx2async is
	type mode is (USB_RD1, USB_RD2, USB_WR1, USB_WR2);
	signal state: mode;
	signal wr, rd: std_logic;
	signal rd_empty, wr_full: std_logic;
	signal delay: std_logic_vector(3 downto 0);
	signal data_i, data_i_r1, data_i_r2 : std_logic_vector(7 downto 0);
	signal rd_empty_r1, rd_empty_r2 : std_logic;
	signal wr_full_r1, wr_full_r2 : std_logic;
	signal pktend_pending : std_logic;
	signal usb_rd_strobe, usb_wr_strobe : std_logic;
begin

	fx2_slcs_o <= '0';
	
	fx2_slrd_o <= not rd;
	fx2_sloe_o <= not rd;
	
	fx2_slwr_o <= not wr;
	
	usb_wr_strobe_o <= usb_wr_strobe;
	usb_rd_strobe_o <= usb_rd_strobe;
	
	process
	begin
		wait until rising_edge(clk_i);
		
		-- flags und daten eintakten
		rd_empty_r1 <= fx2_rd_empty_i;
		rd_empty_r2 <= rd_empty_r1;
		rd_empty <= rd_empty_r2;
		
		wr_full_r1 <= fx2_wr_full_i;
		wr_full_r2 <= wr_full_r1;
		wr_full <= wr_full_r2;
		
		data_i_r1 <= fx2_data_io;
		data_i_r2 <= data_i_r1;
		data_i <= data_i_r2;
		
		usb_wr_strobe <= '0';
		usb_rd_strobe <= '0';
		
		if usb_rd_strobe = '1' and rd_empty = '1' then
			usb_pktstart_o <= '0';
		end if;
		
		if rd_empty = '0' then
			usb_pktstart_o <= '1';
		end if;
		
		if rst_i = '1' then
			wr <= '0';
			rd <= '0';
			
			fx2_data_io <= (others => 'Z');
			
			fx2_pktend_o <= '1';
			
			state <= USB_RD1;
			fx2_fifo_addr_o <= "00"; -- read - write: 10
			
			pktend_pending <= '0';
		else
		
			if usb_pktend_i = '1' then
				pktend_pending <= '1';
			end if;
		
			delay <= delay + 1;
			if delay = "0000" then
			
				wr <= '0';
				rd <= '0';
		
				fx2_data_io <= (others => 'Z');
				
				fx2_pktend_o <= '1';
				
				if pktend_pending = '1' then
					fx2_pktend_o <= '0';
					pktend_pending <= '0';
				end if;
				
				case state is
					when USB_RD1 =>
						if usb_rd_en_i = '1' and rd_empty = '1' then
							rd <= '1';
							state <= USB_RD2;
						elsif usb_wr_en_i = '1' and wr_full = '1' then
							state <= USB_WR1;
							fx2_fifo_addr_o <= "10";
						end if;
						
					when USB_RD2 =>
						usb_data_o <= data_i;
						usb_rd_strobe <= '1';
						state <= USB_RD1;
						
					when USB_WR1 =>
						if usb_wr_en_i = '1' and wr_full = '1' then
							fx2_data_io <= usb_data_i;
							usb_wr_strobe <= '1';
							wr <= '1';
							state <= USB_WR2;
						elsif usb_rd_en_i  = '1' and rd_empty = '1' then
							state <= USB_RD1;
							fx2_fifo_addr_o <= "00";
						end if;
					when USB_WR2 =>
						state <= USB_WR1;
					
				end case;
				
			end if;
		end if;
	end process;
	
end Behavioral;
