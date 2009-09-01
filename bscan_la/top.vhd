----------------------------------------------------------------------------------
-- la.vhd
--
-- Copyright (C) 2006 Michael Poppitz
-- 
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 2 of the License, or (at
-- your option) any later version.
--
-- This program is distributed in the hope that it will be useful, but
-- WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
-- General Public License for more details.
--
-- You should have received a copy of the GNU General Public License along
-- with this program; if not, write to the Free Software Foundation, Inc.,
-- 51 Franklin St, Fifth Floor, Boston, MA 02110, USA
--
----------------------------------------------------------------------------------
--
-- Details: http://www.sump.org/projects/analyzer/
--
-- Logic Analyzer top level module. It connects the core with the hardware
-- dependend IO modules and defines all inputs and outputs that represent
-- phyisical pins of the fpga.
--
-- It defines two constants FREQ and RATE. The first is the clock frequency 
-- used for receiver and transmitter for generating the proper baud rate.
-- The second defines the speed at which to operate the serial port.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity la is
	Port(
		xtalClock : in std_logic;

		exClock : in std_logic;
		input : in std_logic_vector(31 downto 0);
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
	
	COMPONENT core
	PORT(
		clock : IN std_logic;
		extReset : IN std_logic;
		cmd : IN std_logic_vector(39 downto 0);
		execute : IN std_logic;
		input : IN std_logic_vector(31 downto 0);
		inputClock : IN std_logic;
		sampleReady50 : OUT std_logic;
      output : out  STD_LOGIC_VECTOR (31 downto 0);
      outputSend : out  STD_LOGIC;
      outputBusy : in  STD_LOGIC;
		memoryIn : IN std_logic_vector(31 downto 0);          
		memoryOut : OUT std_logic_vector(31 downto 0);
		memoryRead : OUT std_logic;
		memoryWrite : OUT std_logic
		);
	END COMPONENT;
	
	COMPONENT sram_bram
	PORT(
		clock : IN std_logic;
		input : IN std_logic_vector(31 downto 0);
		output : OUT std_logic_vector(31 downto 0);
		read : IN std_logic;
		write : IN std_logic   
		);
	END COMPONENT;
	
	
signal cmd : std_logic_vector (39 downto 0);
signal memoryIn, memoryOut : std_logic_vector (31 downto 0);
signal probeInput : std_logic_vector (31 downto 0);
signal output : std_logic_vector (31 downto 0);
signal clock : std_logic;
signal read, write, execute, send, busy : std_logic;

signal test_counter : std_logic_vector (40 downto 0);

signal reset : std_logic := '1';
signal reset_cnt : std_logic_vector(15 downto 0) := (others => '0');

component bscan_sreg is
	GENERIC (
		SREG_LEN	: integer := 40
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
	
	signal din : std_logic_vector(39 downto 0);
	signal dout : std_logic_vector(39 downto 0);
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
		clk_i => clock,
		Data_i => din,
		Data_o => dout,
		strobe_o => strobe
	);
	
	Led <= send & busy & "000000";
	
	-- JTAG
	process(clock)
	begin
		if rising_edge(clock) then
			
			execute <= '0';
			
			-- update from jtag
			if strobe = '1' then
				
				busy <= '0';
				
				cmd <= dout;
			
				din(39) <= '0';
			
				if dout(7 downto 0) = x"02" then
					din <= x"80534c4131";
				else
					execute <= '1';
				end if;
			
			end if;
			
			-- TODO: this isn't safe yet!
			-- TODO: output -> din on strobe = '1'
			if send = '1' then
				busy <= '1';
				din <= x"80" & output;
			end if;
			
		end if;
	end process;
	
	-- generate reset
	process(clock)
	begin
		if rising_edge(clock) then
			if reset_cnt /= x"ffff" then
				reset_cnt <= reset_cnt + 1;
			else
				reset <= '0';
			end if;
		end if;
	end process;
	
	-- test counter
	process(clock)
	begin
		if rising_edge(clock) then
		   test_counter <= test_counter + 1;
		end if;
	end process;
	
	-- probeInput <= input;
	probeInput <= test_counter(31 downto 0); -- use this to connect a counter to the inputs
	
	Inst_clockman: clockman PORT MAP(
		clkin => xtalClock,
		clk0 => clock
	);
	
	Inst_core: core PORT MAP(
		clock => clock,
		extReset => reset,
		cmd => cmd,
		execute => execute,
		input => probeInput,
		inputClock => exClock,
		--sampleReady50 => ready50,
		output => output,
		outputSend => send,
		outputBusy => busy,
		memoryIn => memoryIn,
		memoryOut => memoryOut,
		memoryRead => read,
		memoryWrite => write
	);

	Inst_sram: sram_bram PORT MAP(
		clock => clock,
		input => memoryOut,
		output => memoryIn,
		read => read,
		write => write 
	);
	

end Behavioral;

