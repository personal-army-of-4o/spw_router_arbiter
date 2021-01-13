library work;
use work.json.all;

package config is

    constant cPort_num: natural;
    constant cTimeout_ticks_width: natural;
    constant cLimit_width: natural;
    constant cTx_fifo_address_width: natural;
    constant cRx_fifo_address_width: natural;
    constant cAllow_loopback_routing: boolean;

end package;

package body config is

    constant cTimeout_tick_width_name: string := "timeout_cfg_width";
    constant cConfig_location: string := ".";
    constant cConfig_name: string := "config.json";
    constant cConfig_path: string := cConfig_location & "/" & cConfig_name;
    constant cConfig_str: T_JSON := jsonLoad (cConfig_path);

    function get_cfg (cfg: T_JSON; key: string) return natural is
        variable ret: natural;
    begin
        if jsonNoParserError (cfg) = false then
            assert false report jsonGetErrorMessage (cfg) severity failure;
        end if;
        return natural'value (jsonGetString (cfg, key));
    end function;

    function get_cfg (cfg: T_JSON; key: string) return boolean is
        variable ret: natural;
    begin
        if jsonNoParserError (cfg) = false then
            assert false report jsonGetErrorMessage (cfg) severity failure;
        end if;
        return jsonGetBoolean (cfg, key);
    end function;

    constant cPort_num: natural := get_cfg (cConfig_str, "port_number");
    constant cTimeout_ticks_width: natural := get_cfg (cConfig_str, "timeout_reg_width");
    constant cLimit_width: natural := get_cfg (cConfig_str, "limit_reg_width");
    constant cTx_fifo_address_width: natural := get_cfg (cConfig_str, "port0_tx_fifo_address_width");
    constant cRx_fifo_address_width: natural := get_cfg (cConfig_str, "port0_rx_fifo_address_width");
    constant cAllow_loopback_routing: boolean := get_cfg (cConfig_str, "allow_loopback_routing");

end package body;

