library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bscan_sreg is
	GENERIC (
		SREG_LEN	: integer := 8
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
end bscan_sreg;

architecture Behavioral of bscan_sreg is
	signal SREG: std_logic_vector((SREG_LEN - 1) downto 0);
	signal UPDATE_s1 : std_logic := '0';
	signal UPDATE_s2 : std_logic := '0';
	signal UPDATE_s3 : std_logic := '0';
	signal SEL_s1 : std_logic := '0';
	signal SEL_s2 : std_logic := '0';
begin

	process(clk_i)
	
	begin
		
		if rising_edge(clk_i) then
		
			strobe_o <= '0';
		
			-- synchronize
			UPDATE_s1 <= UPDATE_i;
			UPDATE_s2 <= UPDATE_s1;
			UPDATE_s3 <= UPDATE_s2;
			
			SEL_s1 <= SEL_i;
			SEL_s2 <= SEL_s1;
			
			-- detect a rising edge on UPDATE
			if UPDATE_s2 = '1' and UPDATE_s3 = '0' and SEL_s2 = '1' then
				Data_o <= SREG;
				strobe_o <= '1';
			end if;
	
		end if;
	
	end process;
	
	-------------------------------

	process(DRCK_i, CAPTURE_i, SEL_i)
	
	begin
	
		TDO_o <= SREG(SREG_LEN - 1);
	
		if SEL_i = '1' then
		
			if CAPTURE_i = '1'  then
				SREG <= Data_i;
			
			elsif rising_edge(DRCK_i) then
				if SHIFT_i = '1' and UPDATE_i /= '1' then
					SREG <= SREG((SREG_LEN - 2) downto 0) & TDI_i;
				end if;
			
			end if;
			
		end if;
	
	end process;

end Behavioral;
