library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ir_tx is
    Port ( 
        clk       : in  STD_LOGIC;
        key       : in  STD_LOGIC;  -- 新增：按键输入
        data_in   : in  STD_LOGIC_VECTOR(7 downto 0);
        ir_out    : out STD_LOGIC;
        tx_active : out STD_LOGIC -- 输出当前是否正在发光，用于屏蔽本地接收
    );
end ir_tx;

architecture Behavioral of ir_tx is
    signal clk_38k      : STD_LOGIC := '0';
    signal carrier_cnt  : integer range 0 to 700 := 0;
    signal baud_cnt     : integer range 0 to 50000 := 0;
    signal bit_idx      : integer range 0 to 1000 := 0; -- 增加范围实现长间隔
    signal tx_envelope  : STD_LOGIC := '0';
    signal data_latch   : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal key_sync     : STD_LOGIC := '1';  -- 按键同步信号
    signal key_pressed  : STD_LOGIC := '0';  -- 按键按下标志
    signal tx_en        : STD_LOGIC := '0';  -- 发送使能
begin
    
    -- 0. 按键处理
    process(clk)
    begin
        if rising_edge(clk) then
            -- 按键同步（两拍消抖）
            key_sync <= key;
            
            -- 按键下降沿检测（假设按键按下为低电平）
            if key_sync = '1' and key = '0' then
                key_pressed <= '1';
            elsif key_sync = '0' and key = '1' then
                key_pressed <= '0';
            end if;
        end if;
    end process;
    
    -- 按键按下时启动发送，松开后继续发送完当前帧
    process(clk)
    begin
        if rising_edge(clk) then
            if key_pressed = '1' then
                tx_en <= '1';  -- 按键按下，启动发送
            elsif bit_idx = 800 then  -- 发送完一帧后停止
                tx_en <= '0';
            end if;
        end if;
    end process;
    
    -- 1. 产生38kHz载波
    process(clk)
    begin
        if rising_edge(clk) then
            if carrier_cnt < 657 then
                carrier_cnt <= carrier_cnt + 1;
            else
                carrier_cnt <= 0;
                clk_38k <= not clk_38k;
            end if;
        end if;
    end process;
    
    -- 2. 发送状态机（带长空闲期）
    process(clk)
    begin
        if rising_edge(clk) then
            if tx_en = '1' then  -- 只有发送使能时才工作
                if baud_cnt < 49999 then
                    baud_cnt <= baud_cnt + 1;
                else
                    baud_cnt <= 0;
                    if bit_idx < 800 then
                        bit_idx <= bit_idx + 1;
                    else
                        bit_idx <= 0;
                    end if;
                end if;
                
                case bit_idx is
                    when 0 => 
                        tx_envelope <= '1'; 
                        data_latch <= data_in; -- 起始位并缓存
                    when 1 => tx_envelope <= data_latch(0); -- LSB First
                    when 2 => tx_envelope <= data_latch(1);
                    when 3 => tx_envelope <= data_latch(2);
                    when 4 => tx_envelope <= data_latch(3);
                    when 5 => tx_envelope <= data_latch(4);
                    when 6 => tx_envelope <= data_latch(5);
                    when 7 => tx_envelope <= data_latch(6);
                    when 8 => tx_envelope <= data_latch(7);
                    when 9 => tx_envelope <= '0'; -- 停止位
                    when others => tx_envelope <= '0'; -- 漫长的休息时间
                end case;
            else
                -- 发送禁止时复位状态
                baud_cnt <= 0;
                bit_idx <= 0;
                tx_envelope <= '0';
            end if;
        end if;
    end process;
    
    ir_out <= clk_38k and tx_envelope;
    tx_active <= tx_envelope; -- 传给顶层做屏蔽逻辑
    
end Behavioral;