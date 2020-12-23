library ieee;
use ieee.std_logic_1164.all;


entity port0_tx_fifo is
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
end entity;

architecture v1 of port0_tx_fifo is

    component port0_tx_glue
        port (
            iEmpty: in std_logic;
            oRd: out std_logic;
            iData: in std_logic_vector (8 downto 0);

            oValid: out std_logic;
            oData: out std_logic_vector (8 downto 0);
            iAck: in std_logic
        );
    end component;

    component fifo
        generic (
            gAddress_width: natural
        );
        port (
            iClk: in std_logic;
            iReset: in std_logic;

            iWr: in std_logic;
            iData: in std_logic_vector (8 downto 0);

            iRd: in std_logic;
            oData: out std_logic_vector (8 downto 0);

            oEmpty: out std_logic;
            oHalf_empty: out std_logic;
            oFull: out std_logic;
            oUnderflow: out std_logic;
            oOverflow: out std_logic
        );
    end component;

    signal sEmpty: std_logic;
    signal sRd: std_logic;
    signal sData: std_logic_vector (8 downto 0);

begin

    oTxe <= sEmpty;

    glue: port0_tx_glue
        port map (
            iEmpty => sEmpty,
            oRd => sRd,
            iData => sData,

            oValid => oValid,
            oData => oData,
            iAck => iAck
        );

    fifo_inst: fifo
        generic map (
            gAddress_width => gAddress_width
        )
        port map (
            iClk => iClk,
            iReset => iReset,

            iWr => iTx_wr,
            iData => iTx_data,

            iRd => sRd,
            oData => sData,

            oEmpty => sEmpty,
            oHalf_empty => oTxh,
            oFull => oTxf,
            oOverflow => oTxo
        );

end v1;