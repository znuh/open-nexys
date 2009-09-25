library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

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
		btn : in std_logic_vector(3 downto 0);
		JA : in std_logic_vector(4 downto 1);
		JB : in std_logic_vector(4 downto 1);
		JC : out std_logic_vector(4 downto 1);
		JD : out std_logic_vector(4 downto 1)
	);
end top;

architecture Behavioral of top is
component fx2_usb is
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
end component;

COMPONENT mydcm
	PORT(
		CLKIN_IN : IN std_logic;
		RST_IN : IN std_logic;          
		CLKIN_IBUFG_OUT : OUT std_logic;
		CLK0_OUT : OUT std_logic;
		CLK2X_OUT : OUT std_logic;
		LOCKED_OUT : OUT std_logic
		);
	END COMPONENT;

	signal clk_int : std_logic;
	signal rst : std_logic;
	
	signal usb_pktend : std_logic;
	signal usb_din, usb_dout : std_logic_vector(7 downto 0);
	signal usb_wr_en, usb_rd_en : std_logic;
	signal usb_wr_full, usb_rd_empty : std_logic;
begin

	JC <= x"0";
	JD <= x"0";
	
	rst <= btn(0);
	usb_pktend <= btn(1);
	
	Led <= usb_wr_en & usb_rd_en & usb_wr_full & usb_rd_empty & x"0";

-------- reply code---------
	usb_din <= usb_dout;

	process(clk_int)
	begin
		if rising_edge(clk_int) then
			usb_rd_en <= '0';
			usb_wr_en <= '0';

------------ reply code -------------
			
			if usb_rd_empty = '0' and usb_wr_full = '0' and usb_wr_en = '0' and usb_rd_en = '0' then
				usb_rd_en <= '1';
			end if;
			
			if usb_rd_en = '1' then
				usb_wr_en <= '1';
			end if;

----------- counter code -----------
			
--			if usb_wr_full = '0' and usb_wr_en = '0' then
--				usb_wr_en <= '1';
--			end if;
			
--			if usb_wr_en = '1' then
--				usb_din <= usb_din + 1;
--			end if;
			
		end if;
	end process;

	Inst_mydcm: mydcm PORT MAP(
		CLKIN_IN => sys_clk,
		RST_IN => btn(0),
		CLKIN_IBUFG_OUT => open,
		CLK0_OUT => open,
		CLK2X_OUT => clk_int,
		LOCKED_OUT => open
	);
	
	Inst_fx2_usb : fx2_usb PORT MAP(
		clk_i => clk_int,
		rst_i => rst,
		fx2_wr_full_i => fx2_wr_full_i,
		fx2_rd_empty_i => fx2_rd_empty_i,
		fx2_data_io => fx2_data_io,
		fx2_clk_i => fx2_clk_i,
		fx2_slcs_o => fx2_slcs_o,
		fx2_slrd_o => fx2_slrd_o,
		fx2_sloe_o => fx2_sloe_o,
		fx2_slwr_o => fx2_slwr_o,
		fx2_pktend_o => fx2_pktend_o,
		fx2_fifo_addr_o => fx2_fifo_addr_o,
		din => usb_din,
		dout => usb_dout,
		wr_en => usb_wr_en,
		rd_en => usb_rd_en,
		wr_full => usb_wr_full,
		rd_empty => usb_rd_empty,
		pktend_i => usb_pktend
		);

end Behavioral;
