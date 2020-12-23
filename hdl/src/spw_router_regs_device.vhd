-- 0    - [ reserved | alr |  pn | tic | trc ]
-- widths [    16    |  1  |  5  |  5  |  5  ]
-- mode   [    r     |  r  |  r  |  r  |  r  ]
-- alr - allow loopback routing. if alr = 1 then pending pkg could be routed
--       to a port it came from. otherwise - discaded
-- pn - number of ports. defines the number of port-related sections in reg map
-- tic - tm field width in bits
-- trc - lim field width in bits
--
-- 4    - [ reserved | txo | txe | txh | txf | rxu | rxe | rxh | rxf ]
-- widths [    24    |  1  |  1  |  1  |  1  |  1  |  1  |  1  |  1  ]
-- mode   [    r     |  r  |  r  |  r  |  r  |  r  |  r  |  r  |  r  ]
-- txo - port 0 tx fifo overflow
-- txe - port 0 tx fifo empty
-- txh - port 0 tx fifo half full
-- txf - port 0 tx fifo full
-- rxu - port 0 rx fifo underflow
-- rxe - port 0 rx fifo empty
-- rxh - port 0 rx fifo half empty
-- rxf - port 0 rxfifo full
--
-- 8    - [ reserved | data ]
-- widths [    24    |  8   ]
-- mode   [    r     | r/w  ]
-- data - port 0 fifo access. readin shifts rx fifo, writing puts symbol into tx fifo
--
-- C - reserved
--
-- x+0  - [ reserved | req | gra | dis | path ]
-- widths [    21    |  1  |  1  |  1  |  8   ]
-- mode   [     r    |  r  |  w  |  w  |  r   ]
-- req - routing request
-- gra - routing request satisfied
-- dis - routing request rejected, pending package should be discarded
-- path - address word from pending package
--
-- x+4 - [     mc    ]
-- mode  [      w    ]
-- mc - mux config, onehot setting for sink-side mux
--
-- x+8 - [     tm    ]
-- mode  [    r/w    ]
-- tm - timeout, discard ongoing package if port is idle for tm ticks. disabled if tm = 0
--
-- x+C - [    lim    ]
-- mode  [    r/w    ]
-- lim - truncate package after lim symbols. truncator disabled if lim = 0

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity spw_router_regs_device is
    generic (
        gReset_active_lvl: std_logic := '0';
        gAllow_backroute: boolean -- allow a pkg to be routed to source port
    );
    port (
        iClk: in std_logic;
        iReset: in std_logic;

        oTimeout_ticks: out std_logic_vector; -- len = port_num*timeout_width
        oLimit: out std_logic_vector; -- len = port_num*limit_width
        iRequest_mux: in std_logic_vector; -- len = port_num
        iPath: in std_logic_vector; -- len = port_num*8
        oGranted: out std_logic_vector; -- len = port_num
        oDiscard: out std_logic_vector; -- len = port_num
        oMux_en: out std_logic_vector; -- len = port_num
        oMux_onehot: out std_logic_vector; -- len = port_num*port_num

        -- internal port fifo
        iTxo: in std_logic;
        iTxe: in std_logic;
        iTxh: in std_logic;
        iTxf: in std_logic;

        iRxu: in std_logic;
        iRxe: in std_logic;
        iRxh: in std_logic;
        iRxf: in std_logic;

        oRx_rd: out std_logic;
        iRx_data: in std_logic_vector (8 downto 0);

        oTx_wr: out std_logic;
        oTx_data: out std_logic_vector (8 downto 0);

        -- to bus device
        iRd: in std_logic_vector; -- onehot rd for 132 words
        oRd_data: out std_logic_vector;

        iWr: in std_logic_vector; -- onehot wr for 132 words
        iWr_data: in std_logic_vector
    );
end entity;

architecture v1 of spw_router_regs_device is

    constant cPn: natural := oGranted'length;
    constant cRn: natural := 4+4*cPn;
    constant cTic: natural := oTimeout_ticks'length/cPn;
    constant cTrc: natural := oLimit'length/cPn;
    constant cMc_w: natural := oMux_onehot'length/cPn;

    type tAr is array (cRn-1 downto 0) of std_logic_vector (31 downto 0);

    signal sRd_data: tAr;
    signal sWr_data: tAr;

    signal sTxo: std_logic;
    signal sTxe: std_logic;
    signal sTxh: std_logic;
    signal sTxf: std_logic;

    signal sRxu: std_logic;
    signal sRxe: std_logic;
    signal sRxh: std_logic;
    signal sRxf: std_logic;

    signal sRx_rd: std_logic;
    signal sRx_data: std_logic_vector (8 downto 0);

    signal sTx_wr: std_logic;
    signal sTx_data: std_logic_vector (8 downto 0);

begin

    -- populate rd and wr arrays
    words: for i in 0 to cRn-1 generate
        oRd_data ((i+1)*32-1 downto i*32) <= sRd_data (i);
        sWr_data (i) <= iWr_data ((i+1)*32-1 downto i*32);
    end generate;

-- 0    - [ reserved | alr |  pn | tic | trc ]
-- widths [    16    |  1  |  5  |  5  |  5  ]
-- mode   [    r     |  r  |  r  |  r  |  r  ]
    c1: if gAllow_backroute generate
        sRd_data (0) (15) <= '1';
    end generate;
    c0: if not gAllow_backroute generate
        sRd_data (0) (15) <= '0';
    end generate;
    sRd_data (0) (14 downto 10) <= std_logic_vector(to_unsigned(cPn, 5));
    sRd_data (0) (9 downto 5) <= std_logic_vector(to_unsigned(cTic, 5));
    sRd_data (0) (4 downto 0) <= std_logic_vector(to_unsigned(cTrc, 5));

-- 4    - [ reserved | txo | txe | txh | txf | rxu | rxe | rxh | rxf ]
-- widths [    24    |  1  |  1  |  1  |  1  |  1  |  1  |  1  |  1  ]
-- mode   [    r     |  r  |  r  |  r  |  r  |  r  |  r  |  r  |  r  ]
    sRd_data (1) (7) <= iTxo;
    sRd_data (1) (6) <= iTxe;
    sRd_data (1) (5) <= iTxh;
    sRd_data (1) (4) <= iTxf;
    sRd_data (1) (3) <= iRxu;
    sRd_data (1) (2) <= iRxe;
    sRd_data (1) (1) <= iRxh;
    sRd_data (1) (0) <= iRxf;

-- 8    - [ reserved | data ]
-- widths [    24    |  8   ]
-- mode   [    r     | r/w  ]
    oRx_rd <= iRd (2);
    oTx_wr <= iWr (2);
    sRd_data (2) (8 downto 0) <= iRx_data;
    oTx_data <= sWr_data (2) (8 downto 0);

    ports: for i in 0 to cPn-1 generate
        signal sTimeout_ticks: std_logic_vector (cTic-1 downto 0);
        signal sLimit: std_logic_vector (cTrc-1 downto 0);
    begin
-- x+0  - [ reserved | req | gra | dis | path ]
-- widths [    21    |  1  |  1  |  1  |  8   ]
-- mode   [     r    |  r  |  w  |  w  |  r   ]
        sRd_data (4+i*4) (10) <= iRequest_mux (i);
        sRd_data (4+i*4) (7 downto 0) <= iPath ((i+1)*8-1 downto i*8);
        oGranted (i) <= iWr (4+i*4) and sWr_data (4+i*4) (9);
        oDiscard (i) <= iWr (4+i*4) and sWr_data (4+i*4) (8);
--
-- x+4 - [     mc    ]
-- mode  [      w    ]
        oMux_en (i) <= iWr (4+i*4+1);
        oMux_onehot ((i+1)*cMc_w-1 downto i*cMc_w) <= sWr_data (4+i*4+1) (cMc_w-1 downto 0);
--
-- x+8 - [     tm    ]
-- mode  [    r/w    ]
        oTimeout_ticks ((i+1)*cTic-1 downto i*cTic) <= sTimeout_ticks;
        sRd_data (4+i*4+2) (cTic-1 downto 0) <= sTimeout_ticks;

        process (iClk, iReset)
        begin
            if iReset = gReset_active_lvl then
                sTimeout_ticks <= (others => '0');
            else
                if iClk'event and iClk = '1' then
                    if iWr (4+i*4+2) = '1' then
                        sTimeout_ticks <= sWr_data (4+i*4+2) (cTic-1 downto 0);
                    end if;
                end if;
            end if;
        end process;

--
-- x+C - [    lim    ]
-- mode  [    r/w    ]
        oLimit ((i+1)*cTrc-1 downto i*cTrc) <= sLimit;
        sRd_data (4+i*4+3) (cTrc-1 downto 0) <= sLimit;

        process (iClk, iReset)
        begin
            if iReset = gReset_active_lvl then
                sLimit <= (others => '0');
            else
                if iClk'event and iClk = '1' then
                    if iWr (4+i*4+3) = '1' then
                        sLimit <= sWr_data (4+i*4+3) (cTrc-1 downto 0);
                    end if;
                end if;
            end if;
        end process;

    end generate;

end v1;