library ieee;
use ieee.std_logic_1164.all;


entity port0_fifo_block is
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
end entity;

architecture v1 of port0_fifo_block is

    component port0_rx_fifo
        generic (
            gAddress_width: natural
        );
        port (
            iClk: in std_logic;
            iReset: in std_logic;

            -- internal port
            iValid: in std_logic;
            iData: in std_logic_vector (8 downto 0);
            oAck: out std_logic;

            -- to regs
            oRxu: out std_logic;
            oRxe: out std_logic;
            oRxh: out std_logic;
            oRxf: out std_logic;

            iRx_rd: in std_logic;
            oRx_data: out std_logic_vector (8 downto 0)
        );
    end component;

    component port0_tx_fifo
        generic (
            gAddress_width: natural
        );
        port (
            iClk: in std_logic;
            iReset: in std_logic;

            -- internal port
            oValid: out std_logic;
            oData: out std_logic_vector (8 downto 0);
            iAck: in std_logic;

            -- to regs
            oTxo: out std_logic;
            oTxe: out std_logic;
            oTxh: out std_logic;
            oTxf: out std_logic;

            iTx_wr: in std_logic;
            iTx_data: in std_logic_vector (8 downto 0)
        );
    end component;

begin

    rx_fifo: port0_rx_fifo
        generic map (
            gAddress_width => gRx_fifo_address_width
        )
        port map (
            iClk => iClk,
            iReset => iReset,

            -- internal port
            iValid => iValid,
            iData => iData,
            oAck => oAck,

            oRxu => oRxu,
            oRxe => oRxe,
            oRxh => oRxh,
            oRxf => oRxf,

            iRx_rd => iRx_rd,
            oRx_data => oRx_data
        );

    tx_fifo: port0_tx_fifo
        generic map (
            gAddress_width => gTx_fifo_address_width
        )
        port map (
            iClk => iClk,
            iReset => iReset,

            -- internal port
            oValid => oValid,
            oData => oData,
            iAck => iAck,

            -- to regs
            oTxo => oTxo,
            oTxe => oTxe,
            oTxh => oTxh,
            oTxf => oTxf,

            iTx_wr => iTx_wr,
            iTx_data => iTx_data
        );

end v1;