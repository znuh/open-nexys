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
		sw: in std_logic_vector(7 downto 0)
	);
end top;

architecture Behavioral of top is
component bscan_sreg is
	GENERIC (
		SREG_LEN	: integer := 16
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
	
	signal din : std_logic_vector(15 downto 0);
	signal dout : std_logic_vector(15 downto 0);
	signal strobe : std_logic;
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
		clk_i => sys_clk,
		Data_i => din,
		Data_o => dout,
		strobe_o => strobe
	);

	process(sys_clk)
	begin
		if rising_edge(sys_clk) then
			if strobe = '1' then
				din <= dout;
				case dout(15 downto 8) is
					when x"00" => din(7 downto 0) <= sw;
					when x"81" => Led <= dout(7 downto 0);
					when others => null;
				end case;
			end if;
		end if;
	end process;

end Behavioral;

