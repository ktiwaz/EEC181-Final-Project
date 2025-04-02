set_global_assignment -entity "pll2_125" -library "lib_pll2_125" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "pll2_125" -library "lib_pll2_125" -name IP_TOOL_VERSION "20.1"
set_global_assignment -entity "pll2_125" -library "lib_pll2_125" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_pll2_125" -name SPD_FILE [file join $::quartus(sip_path) "pll2_125.spd"]

set_global_assignment -library "lib_pll2_125" -name MISC_FILE [file join $::quartus(sip_path) "pll2_125_sim/pll2_125.vo"]
