set_global_assignment -entity "pll_main25" -library "lib_pll_main25" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "pll_main25" -library "lib_pll_main25" -name IP_TOOL_VERSION "13.1"
set_global_assignment -entity "pll_main25" -library "lib_pll_main25" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_pll_main25" -name SPD_FILE [file join $::quartus(sip_path) "pll_main25.spd"]

set_global_assignment -library "lib_pll_main25" -name MISC_FILE [file join $::quartus(sip_path) "pll_main25_sim/pll_main25.vo"]
