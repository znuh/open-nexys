-- Copyright 2009 Benedikt 'Hunz' Heinz - Zn000h@googlemail.com
--
-- simple BSCAN_SPARTAN3 USER1 sample for digilent nexys board
-- 8 Bit DR
--
-- references:
-- http://www.xilinx.com/itp/xilinx5/data/docs/lib/lib0061_45.html
-- http://www.xilinx.com/support/answers/10703.htm

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity top is
	Port (	led : out std_logic_vector(7 downto 0);
				switch : in std_logic_vector(7 downto 0) );
end top;

architecture Behavioral of top is

   component BSCAN_SPARTAN3
   port (CAPTURE : out STD_ULOGIC;
         DRCK1 : out STD_ULOGIC;
         DRCK2 : out STD_ULOGIC;
         RESET : out STD_ULOGIC;
         SEL1 : out STD_ULOGIC;
         SEL2 : out STD_ULOGIC;
         SHIFT : out STD_ULOGIC;
         TDI : out STD_ULOGIC;
         UPDATE : out STD_ULOGIC;
         TDO1 : in STD_ULOGIC;
         TDO2 : in STD_ULOGIC);
	end component; 

	signal CAPTURE: STD_ULOGIC;
	signal DRCK1: STD_ULOGIC;
	signal DRCK2: STD_ULOGIC;
	signal RESET: STD_ULOGIC;
	signal SEL1: STD_ULOGIC;
	signal SEL2: STD_ULOGIC;
	signal SHIFT: STD_ULOGIC;
	signal TDI: STD_ULOGIC;
	signal UPDATE: STD_ULOGIC;	
	signal TDO1: STD_ULOGIC;
	signal TDO2: STD_ULOGIC;
	
	signal shiftreg: std_logic_vector(7 downto 0);
begin

   BSCAN_SPARTAN3_inst : BSCAN_SPARTAN3
   port map (
      CAPTURE => CAPTURE, -- CAPTURE output from TAP controller
      DRCK1 => DRCK1,     -- Data register output for USER1 functions
      DRCK2 => DRCK2,     -- Data register output for USER2 functions
      RESET => RESET,     -- Reset output from TAP controller
      SEL1 => SEL1,       -- USER1 active output
      SEL2 => SEL2,       -- USER2 active output
      SHIFT => SHIFT,     -- SHIFT output from TAP controller
      TDI => TDI,         -- TDI output from TAP controller
      UPDATE => UPDATE,   -- UPDATE output from TAP controller
      TDO1 => TDO1,       -- Data input for USER1 function
      TDO2 => TDO2        -- Data input for USER2 function
   );
	
	--led <= CAPTURE & DRCK1 & SEL1 & SHIFT & TDI & UPDATE & "00";
	
	process(DRCK1,UPDATE,SEL1)
	begin
	
		if SEL1='1' then
	
			if UPDATE='1' then
				led <= shiftreg;
		
			elsif CAPTURE='1' then
				shiftreg <= switch;
		
			elsif rising_edge(DRCK1) then
				
				shiftreg <= TDI & shiftreg(7 downto 1);
				
				--if CAPTURE='1' then
				--	shiftreg <= switch;
				--end if;
		
			end if;
			
		end if;
	end process;

	TDO1 <= shiftreg(0);

end Behavioral;

