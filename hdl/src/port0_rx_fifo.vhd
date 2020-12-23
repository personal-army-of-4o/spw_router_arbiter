library ieee;
use ieee.std_logic_1164.all;


entity port0_rx_fifo is
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

        oRxu: out std_logic;
        oRxe: out std_logic;
        oRxh: out std_logic;
        oRxf: out std_logic;

        iRx_rd: in std_logic;
        oRx_data: out std_logic_vector (8 downto 0)
    );
end entity;

architecture v1 of port0_rx_fifo is

    component port0_rx_glue
        port (
            iClk: in std_logic;
            iReset: in std_logic;

            iValid: in std_logic;
            iData: in std_logic_vector (8 downto 0);
            oAck: out std_logic;

            iFull: in std_logic;
            oWr: out std_logic;
            oData: out std_logic_vector (8 downto 0)
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

    signal sWr: std_logic;
    signal sData: std_logic_vector (8 downto 0);
    signal sFull: std_logic;

begin

    oRxf <= sFull;

    glue: port0_rx_glue
        port map (
            iClk => iClk,
            iReset => iReset,

            iValid => iValid,
            iData => iData,
            oAck => oAck,

            iFull => sFull,
            oWr => sWr,
            oData => sData
        );

    fifo_inst: fifo
        generic map (
            gAddress_width => gAddress_width
        )
        port map (
            iClk => iClk,
            iReset => iReset,

            iWr => sWr,
            iData => sData,

            iRd => iRx_rd,
            oData => oRx_data,

            oEmpty => oRxe,
            oHalf_empty => oRxh,
            oFull => sFull,
            oUnderflow => oRxu
        );

end v1;