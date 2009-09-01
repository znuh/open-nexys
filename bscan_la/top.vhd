library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity la is
	Port(
		xtalClock : in std_logic;

		Led : out std_logic_vector(7 downto 0);
		sw : in std_logic_vector(7 downto 0);
		btn : in std_logic_vector(3 downto 0)
	);
end la;

architecture Behavioral of la is
	COMPONENT clockman
	PORT(
		clkin : in  STD_LOGIC;
		clk0 : out std_logic
		);
	END COMPONENT;
	
	component bscan_la is
	Port(
		clock : in std_logic;
		exClock : in std_logic;
		input : in std_logic_vector(31 downto 0);
		reset : in std_logic;
		CAPTURE : in std_logic;
		DRCK : in std_logic;
		SEL : in std_logic;
		SHIFT : in std_logic;
		UPDATE : in std_logic;
		TDO : out std_logic;
		TDI : in std_logic
	);
	end component;
	
	signal CAPTURE : std_logic;
	signal DRCK : std_logic;
	signal SEL : std_logic;
	signal SHIFT : std_logic;
	signal UPDATE : std_logic;
	signal TDO : std_logic;
	signal TDI : std_logic;
	
	signal clock : std_logic;
	signal test_counter : std_logic_vector(31 downto 0);
begin

	process(clock)
	begin
		if rising_edge(clock) then
			test_counter <= test_counter + 1;
		end if;
	end process;

	-- there's nothing useful here to put on the LEDs...
	Led <= x"00";

	-- instantiated in toplevel module
	-- as the 2nd user instruction may be used for another thing
   BSCAN_SPARTAN3_inst : BSCAN_SPARTAN3
   port map (
      CAPTURE => CAPTURE, -- CAPTURE output from TAP controller
      DRCK1 => DRCK,     -- Data register output for USER1 functions
      DRCK2 => open,     -- Data register output for USER2 functions
      RESET => open,     -- Reset output from TAP controller
      SEL1 => SEL,       -- USER1 active output
      SEL2 => open,       -- USER2 active output
      SHIFT => SHIFT,     -- SHIFT output from TAP controller
      TDI => TDI,         -- TDI output from TAP controller
      UPDATE => UPDATE,   -- UPDATE output from TAP controller
      TDO1 => TDO,       -- Data input for USER1 function
      TDO2 => open        -- Data input for USER2 function
   );
	
	-- instantiated in toplevel module
	-- as there might be more components needind the system clock
	Inst_clockman: clockman PORT MAP(
		clkin => xtalClock,
		clk0 => clock
	);

	bscan_la_inst: bscan_la
	port map (
		clock => clock,
		exClock => '0',
		input => test_counter,
		reset => btn(0),
		CAPTURE => CAPTURE,
		DRCK => DRCK,
		SEL => SEL,
		SHIFT => SHIFT,
		UPDATE => UPDATE,
		TDO => TDO,
		TDI => TDI
	);
	
end Behavioral;

