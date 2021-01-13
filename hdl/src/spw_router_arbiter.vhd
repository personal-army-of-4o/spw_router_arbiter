library ieee;
use ieee.std_logic_1164.all;
library work;
use work.config.all;


entity spw_router_arbiter is
    port (
        iClk: in std_logic;
        iReset: in std_logic;

        oTimeout_ticks: out std_logic_vector (cPort_num*cTimeout_ticks_width-1 downto 0); -- len = port_num*timeout_width
        oLimit: out std_logic_vector (cPort_num*cLimit_width-1 downto 0); -- len = port_num*limit_width
        iRequest_mux: in std_logic_vector (cPort_num-1 downto 0); -- len = port_num
        iPath: in std_logic_vector (cPort_num*8-1 downto 0); -- len = port_num*8
        oGranted: out std_logic_vector (cPort_num-1 downto 0); -- len = port_num
        oDiscard: out std_logic_vector (cPort_num-1 downto 0); -- len = port_num
        oMux_en: out std_logic_vector (cPort_num-1 downto 0); -- len = port_num
        oMux_onehot: out std_logic_vector (cPort_num*cPort_num-1 downto 0); -- len = port_num*port_num

        -- internal port
        iValid: in std_logic;
        iData: in std_logic_vector (8 downto 0);
        oAck: out std_logic;

        oValid: out std_logic;
        oData: out std_logic_vector (8 downto 0);
        iAck: in std_logic
    );
end entity;

architecture v1 of spw_router_arbiter is

	constant cPort_num: natural := iRequest_mux'length;
	constant cRegs_num: natural := 4+4*cPort_num;

    component port0_fifo_block
        generic (
            gTx_fifo_address_width: natural;
            gRx_fifo_address_width: natural
        );
        port (
            iClk: in std_logic;
            iReset: in std_logic;

            -- internal port
            iValid: in std_logic;
            iData: in std_logic_vector (8 downto 0);
            oAck: out std_logic;

            oValid: out std_logic;
            oData: out std_logic_vector (8 downto 0);
            iAck: in std_logic;

            -- to regs
            oTxo: out std_logic;
            oTxe: out std_logic;
            oTxh: out std_logic;
            oTxf: out std_logic;

            oRxu: out std_logic;
            oRxe: out std_logic;
            oRxh: out std_logic;
            oRxf: out std_logic;

            iRx_rd: in std_logic;
            oRx_data: out std_logic_vector (8 downto 0);

            iTx_wr: in std_logic;
            iTx_data: in std_logic_vector (8 downto 0)
        );
    end component;

    component spw_router_regs_device
        generic (
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
    end component;

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

    signal sRd: std_logic_vector (cRegs_num-1 downto 0); -- onehot rd
    signal sRd_data: std_logic_vector (cRegs_num*32-1 downto 0);

    signal sWr: std_logic_vector (cRegs_num-1 downto 0); -- onehot wr
    signal sWr_data: std_logic_vector (cRegs_num*32-1 downto 0);

begin

    fifos: port0_fifo_block
        generic map (
            gTx_fifo_address_width => cTx_fifo_address_width,
            gRx_fifo_address_width => cRx_fifo_address_width
        )
        port map (
            iClk => iClk,
            iReset => iReset,

            -- internal port
            iValid => iValid,
            iData => iData,
            oAck => oAck,

            oValid => oValid,
            oData => oData,
            iAck => iAck,

            -- to regs
            oTxo => sTxo,
            oTxe => sTxe,
            oTxh => sTxh,
            oTxf => sTxf,

            oRxu => sRxu,
            oRxe => sRxe,
            oRxh => sRxh,
            oRxf => sRxf,

            iRx_rd => sRx_rd,
            oRx_data => sRx_data,

            iTx_wr => sTx_wr,
            iTx_data => sTx_data
        );

    regs_device: spw_router_regs_device
        generic map (
            gAllow_backroute => cAllow_loopback_routing
        )
        port map (
            iClk => iClk,
            iReset => iReset,

            oTimeout_ticks => oTimeout_ticks,
            oLimit => oLimit,
            iRequest_mux => iRequest_mux,
            iPath => iPath,
            oGranted => oGranted,
            oDiscard => oDiscard,
            oMux_en => oMux_en,
            oMux_onehot => oMux_onehot,

            -- internal port fifo
            iTxo => sTxo,
            iTxe => sTxe,
            iTxh => sTxh,
            iTxf => sTxf,

            iRxu => sRxu,
            iRxe => sRxe,
            iRxh => sRxh,
            iRxf => sRxf,

            oRx_rd => sRx_rd,
            iRx_data => sRx_data,

            oTx_wr => sTx_wr,
            oTx_data => sTx_data,

            -- to bus device
            iRd => sRd,
            oRd_data => sRd_data,

            iWr => sWr,
            iWr_data => sWr_data
        );

end v1;
