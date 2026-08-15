library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ir_rx is
    Port ( 
        clk      : in  STD_LOGIC;
        ir_in    : in  STD_LOGIC;
        tx_active: in  STD_LOGIC;  -- 发送活动信号
        data_out : out STD_LOGIC_VECTOR(7 downto 0)
    );
end ir_rx;

architecture Behavioral of ir_rx is
    type state_type is (IDLE, WAIT_START, SAMPLE_DATA, SHIELDED);
    signal state         : state_type := IDLE;
    signal sample_timer  : integer range 0 to 100000 := 0;
    signal bit_cnt       : integer range 0 to 7 := 0;
    signal captured_data : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal ir_reg        : STD_LOGIC_VECTOR(1 downto 0) := "00";
    signal shield_timer  : integer range 0 to 50000 := 0;
begin
    
    -- 边沿检测
    process(clk)
    begin
        if rising_edge(clk) then
            ir_reg <= ir_reg(0) & ir_in;
        end if;
    end process;
    
    process(clk)
    begin
        if rising_edge(clk) then
            case state is
                when IDLE =>
                    -- 如果正在发送，进入屏蔽状态
                    if tx_active = '1' then
                        state <= SHIELDED;
                        shield_timer <= 0;
                    elsif ir_reg = "10" then
                        sample_timer <= 0;
                        state <= WAIT_START;
                    end if;
                    
                when SHIELDED =>
                    -- 屏蔽自身发送的信号
                    if shield_timer < 49999 then
                        shield_timer <= shield_timer + 1;
                    else
                        state <= IDLE;
                    end if;
                    
                when WAIT_START =>
                    if sample_timer < 84999 then
                        sample_timer <= sample_timer + 1;
                    else
                        sample_timer <= 0;
                        bit_cnt <= 0;
                        state <= SAMPLE_DATA;
                    end if;
                    
                when SAMPLE_DATA =>
                    -- 如果在接收过程中开始发送，立即停止
                    if tx_active = '1' then
                        state <= SHIELDED;
                        shield_timer <= 0;
                    elsif sample_timer = 0 then
                        captured_data(bit_cnt) <= not ir_in;
                    end if;
                    
                    if sample_timer < 49999 then
                        sample_timer <= sample_timer + 1;
                    else
                        sample_timer <= 0;
                        if bit_cnt < 7 then
                            bit_cnt <= bit_cnt + 1;
                        else
                            data_out <= captured_data; 
                            state <= IDLE;
                        end if;
                    end if;
                    
                when others => 
                    state <= IDLE;
            end case;
        end if;
    end process;
    
end Behavioral;