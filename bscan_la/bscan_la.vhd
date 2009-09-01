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

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bscan_la is
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
end bscan_la;

architecture Behavioral of bscan_la is
	
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
	
signal cmd : std_logic_vector (39 downto 0);
signal memoryIn, memoryOut : std_logic_vector (31 downto 0);
signal output : std_logic_vector (31 downto 0);
signal read, write, execute, send, busy : std_logic;

signal din, dout : std_logic_vector(39 downto 0);
signal strobe : std_logic;

begin

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
			
	Inst_core: core PORT MAP(
		clock => clock,
		extReset => reset,
		cmd => cmd,
		execute => execute,
		input => input,
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
	
	bscan_sreg_inst : bscan_sreg
	Port map (
		CAPTURE_i => CAPTURE,
		DRCK_i => DRCK,
		SEL_i => SEL,
		SHIFT_i => SHIFT,
		UPDATE_i => UPDATE,
		TDI_i => TDI,
		TDO_o => TDO,
		clk_i => clock,
		Data_i => din,
		Data_o => dout,
		strobe_o => strobe
	);

	Inst_sram: sram_bram PORT MAP(
		clock => clock,
		input => memoryOut,
		output => memoryIn,
		read => read,
		write => write 
	);

end Behavioral;
