library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--=====================================================================
entity measure_distance is
	port(
		 reset:in std_logic;
		 echo:in std_logic;
		 clk:in std_logic;
		 trig:out std_logic;
		 dig:out std_logic_vector(2 downto 0);
		 f:out std_logic_vector(6 downto 0)
		 );
end measure_distance;
--=====================================================================
architecture abc of measure_distance is
	signal temp:std_logic:='0';--Trigger进程中的中间信号
	signal count_1,count_2,count_3:integer:=0;
	signal last_echo:std_logic:='0';
	signal distance:integer:=0;
	constant clk_freq:integer:=50000000;--50mhz时钟频率（周期数/s）
	constant speed_of_sound:integer:=34000;--cm/s
	constant ticks_per_cm:integer:=clk_freq/speed_of_sound;--周期数/cm
	signal clk_1:std_logic:='0';-- 数码管刷新时钟
	signal temp_1:std_logic:='0';--Refresh_clock进程中的中间信号
	signal digit:integer:=0;-- 当前扫描的数码
begin
--=====================================================================
--发射45us的脉冲信号
trigger:process(clk)
	begin
		if rising_edge(clk) then
			if count_1<=2249 then
				temp<='1';count_1<=count_1+1;--输出一段45us高电平
			elsif count_1=500000 then
				temp<='0';count_1<=0;--每隔0.01s发送一次（包含45us）
			else
				count_1<=count_1+1;
			end if;
		end if;
	end process trigger;	
--=====================================================================
--检测回波信号并计算距离
distance_calculate:process(clk,echo)
	begin
		if rising_edge(clk) then
			last_echo<=echo;--更新echo状态
			if echo='1' and last_echo='0' then
				count_2<=count_2+1;--开始计数
			elsif echo='1' and last_echo='1' then
				count_2<=count_2+1;
			elsif echo='0' and last_echo='1' then
				distance<=count_2/(ticks_per_cm*2);
				count_2<=0;--计数器置零
			else count_2<=0;
			end if;
		end if;
	end process distance_calculate;
--=====================================================================
--主时钟分频为50hz
refresh_clock:process(clk)
	begin
		if rising_edge(clk) then
			count_3<=count_3+1;
			if count_3<=49999 then
				temp_1<='1';
			elsif count_3>49999 and count_3<=999999 then
				temp_1<='0';
				count_3<=0;
			end if;
		end if;
		clk_1<=temp_1;
	end process refresh_clock;
--=====================================================================
-- 数码管动态显示
Digital_LED_display:process(clk_1,reset)
	begin
		if reset='0' then
			dig<="111";
			f<="1111111";
			digit<=0;
		elsif rising_edge(clk_1) then
			if digit <2 then--数码管选择信号循环
				digit<=digit+1;
			else
				digit<=0;
			end if;
         dig<= "111"; -- 默认关闭所有数码管
         case digit is
				when 0 =>dig(0) <= '0'; -- 启用个位数码管
					case distance mod 10 is
                  when 0 => F <= "0111111"; -- 显示 0
                  when 1 => F <= "0000110"; -- 显示 1
                  when 2 => F <= "1011011"; -- 显示 2
                  when 3 => F <= "1001111"; -- 显示 3
                  when 4 => F <= "1100110"; -- 显示 4
                  when 5 => F <= "1101101"; -- 显示 5
                  when 6 => F <= "1111101"; -- 显示 6
                  when 7 => F <= "0000111"; -- 显示 7
                  when 8 => F <= "1111111"; -- 显示 8
                  when 9 => F <= "1101111"; -- 显示 9
                  when others => F <= "0000000"; -- 清零
               end case;
            when 1 =>dig(1) <= '0'; -- 启用十位数码管
					case (distance/10) mod 10 is
                  when 0 => F <= "0111111";
                  when 1 => F <= "0000110";
                  when 2 => F <= "1011011"; 
                  when 3 => F <= "1001111"; 
                  when 4 => F <= "1100110"; 
                  when 5 => F <= "1101101"; 
                  when 6 => F <= "1111101";
                  when 7 => F <= "0000111"; 
                  when 8 => F <= "1111111"; 
						when 9 => F <= "1101111"; 
						when others => F <= "0000000"; 
					end case;
				when 2 =>dig(2) <= '0'; -- 启用百位数码管
					case distance/100 is
                  when 0 => F <= "0111111"; 
                  when 1 => F <= "0000110"; 
                  when 2 => F <= "1011011"; 
                  when 3 => F <= "1001111"; 
                  when 4 => F <= "1100110"; 
                  when 5 => F <= "1101101"; 
                  when 6 => F <= "1111101"; 
                  when 7 => F <= "0000111"; 
                  when 8 => F <= "1111111"; 
                  when 9 => F <= "1101111"; 
                  when others => F <= "0000000"; 
					end case;
				when others =>
					dig <= "111"; -- 全部数码管关闭
               F <= "0000000"; -- 清零显示
			end case;
		end if;
	end process Digital_LED_display;
--=====================================================================
trig<=temp;
end abc;
