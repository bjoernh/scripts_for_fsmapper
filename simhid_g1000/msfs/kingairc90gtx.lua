local g1000_context = {}

local common = require('lib/common')

function g1000_context.start(config)
    g1000_context.device = common.open_simhid_g1000{
        config = config,
        modifiers = {
            {class = "binary", modtype = "button"},
            {class = "relative", modtype = "incdec"},
        },
    }
    local g1000 = g1000_context.device.events

    local displayno = config.simhid_g1000_display
    local scale = config.simhid_g1000_display_scale

    ---------------------------------------------------------------------------
    -- Two side-by-side viewports (A32NX-style layout)
    -- PFD on the left, MFD on the right, both landscape
    ---------------------------------------------------------------------------
    local viewport_pfd = mapper.viewport({
        name = "King Air C90 PFD",
        displayno = displayno,
        x = 0, y = 0,
        width = 0.5 * scale, height = scale,
        aspect_ratio = 2 / 3,
        horizontal_alignment = "right",
        vertical_alignment = "center",
    })
    viewport_pfd:register_view({
        name = "PFD",
        elements = {{object = mapper.captured_window({name = "PL21 PFD", window_title="WT21_PFD_1"})}},
        mappings = {},
    })

    local viewport_mfd = mapper.viewport({
        name = "King Air C90 MFD",
        displayno = displayno,
        x = 0.5 * scale, y = 0,
        width = 0.5 * scale, height = scale,
        aspect_ratio = 2 / 3,
        horizontal_alignment = "left",
        vertical_alignment = "center",
    })
    viewport_mfd:register_view({
        name = "MFD",
        elements = {{object = mapper.captured_window({name = "PL21 MFD", window_title="WT21_MFD_1"})}},
        mappings = {},
    })

    ---------------------------------------------------------------------------
    -- Mappings (applied to PFD viewport, shared across all controls)
    ---------------------------------------------------------------------------
    viewport_pfd:set_mappings{
        -- Autopilot Controls
        {event=g1000.SW2.down, action=msfs.mfwasm.rpn_executer("(A:AUTOPILOT DISENGAGED, Bool) ! if{ (>K:AP_MASTER) (A:AUTOPILOT MASTER, Bool) ! if{ (>H:Generic_Autopilot_Manual_Off) } els{ (A:AUTOPILOT YAW DAMPER, Bool) ! if{ (>K:YAW_DAMPER_TOGGLE) } } }")},
        {event=g1000.SW3.down, action=msfs.mfwasm.rpn_executer("1 (>K:TOGGLE_FLIGHT_DIRECTOR)")},
        {event=g1000.SW4.down, action=msfs.mfwasm.rpn_executer("(>K:AP_PANEL_HEADING_HOLD)")},
        {event=g1000.SW5.down, action=msfs.mfwasm.rpn_executer("(>K:AP_ALT_HOLD)")},
        {event=g1000.SW6.down, action=msfs.mfwasm.rpn_executer("(>K:AP_NAV1_HOLD)")},
        {event=g1000.SW7.down, action=msfs.mfwasm.rpn_executer("(L:XMLVAR_VNAVButtonValue) ! (>L:XMLVAR_VNAVButtonValue)")},
        {event=g1000.SW8.down, action=msfs.mfwasm.rpn_executer("(>K:AP_APR_HOLD)")},
        {event=g1000.SW9.down, action=msfs.mfwasm.rpn_executer("(>K:AP_BC_HOLD)")},
        {event=g1000.SW10.down, action=msfs.mfwasm.rpn_executer("(>K:AP_PANEL_VS_HOLD) 1 0 (>K:2:AP_VS_VAR_SET_ENGLISH)")},
        {event=g1000.SW11.down, action=msfs.mfwasm.rpn_executer("(>K:AP_SPD_VAR_DEC) (>K:AP_VS_VAR_INC)")},
        {event=g1000.SW12.down, action=msfs.mfwasm.rpn_executer("(>K:FLIGHT_LEVEL_CHANGE) (A:AUTOPILOT FLIGHT LEVEL CHANGE, bool) if { (A:AIRSPEED INDICATED, knots) (>K:AP_SPD_VAR_SET) }")},
        {event=g1000.SW13.down, action=msfs.mfwasm.rpn_executer("(>K:AP_SPD_VAR_INC) (>K:AP_VS_VAR_DEC)")},

        -- Heading Bug
        {event=g1000.EC3.increment, action=msfs.mfwasm.rpn_executer("1 (>K:HEADING_BUG_INC)")},
        {event=g1000.EC3.decrement, action=msfs.mfwasm.rpn_executer("1 (>K:HEADING_BUG_DEC)")},
        {event=g1000.EC3P.down, action=msfs.mfwasm.rpn_executer("(A:HEADING INDICATOR,degrees) (>K:HEADING_BUG_SET)")},

        -- Altitude Select (EC4: fine ±100, coarse ±1000)
        {event=g1000.EC4X.increment, action=msfs.mfwasm.rpn_executer("100 (>K:AP_ALT_VAR_INC)")},
        {event=g1000.EC4X.decrement, action=msfs.mfwasm.rpn_executer("100 (>K:AP_ALT_VAR_DEC)")},
        {event=g1000.EC4Y.increment, action=msfs.mfwasm.rpn_executer("1000 (>K:AP_ALT_VAR_INC)")},
        {event=g1000.EC4Y.decrement, action=msfs.mfwasm.rpn_executer("1000 (>K:AP_ALT_VAR_DEC)")},
        {event=g1000.EC4P.down, action=msfs.mfwasm.rpn_executer("(A:INDICATED ALTITUDE, feet) (>K:AP_ALT_VAR_SET_ENGLISH) (>H:AP_KNOB)")},

        -- Course 1 (VOR1) / Baro
        {event=g1000.EC7X.increment, action=msfs.mfwasm.rpn_executer("(>K:VOR1_OBI_INC)")},
        {event=g1000.EC7X.decrement, action=msfs.mfwasm.rpn_executer("(>K:VOR1_OBI_DEC)")},
        {event=g1000.EC7P.down, action=msfs.mfwasm.rpn_executer("(A:HEADING INDICATOR,degrees) (>K:VOR1_SET)")},
        {event=g1000.EC7Y.increment, action=msfs.mfwasm.rpn_executer("1 (>K:KOHLSMAN_INC) (>H:AP_BARO_Up)")},
        {event=g1000.EC7Y.decrement, action=msfs.mfwasm.rpn_executer("1 (>K:KOHLSMAN_DEC) (>H:AP_BARO_Down)")},

        -- Map Range
        {event=g1000.EC8.increment, action=msfs.mfwasm.rpn_executer("1 (>B:AS3000_UPPER_1_RANGE_Inc)")},
        {event=g1000.EC8.decrement, action=msfs.mfwasm.rpn_executer("1 (>B:AS3000_UPPER_1_RANGE_Dec)")},

        -- FMS Speed
        {event=g1000.EC1.increment, action=msfs.mfwasm.rpn_executer("1 (>B:AUTOPILOT_SPEED_Inc)")},
        {event=g1000.EC1.decrement, action=msfs.mfwasm.rpn_executer("1 (>B:AUTOPILOT_SPEED_Dec)")},

        -- PFD Softkeys (left side)
        {event=g1000.SW14.down, action=msfs.mfwasm.rpn_executer("1 (>B:INSTRUMENT_PFD_SOFTKEY_PFD1_1L_PUSH)")},
        {event=g1000.SW15.down, action=msfs.mfwasm.rpn_executer("1 (>B:INSTRUMENT_PFD_SOFTKEY_PFD1_2L_PUSH)")},
        {event=g1000.SW16.down, action=msfs.mfwasm.rpn_executer("1 (>B:INSTRUMENT_PFD_SOFTKEY_PFD1_3L_PUSH)")},
        {event=g1000.SW17.down, action=msfs.mfwasm.rpn_executer("1 (>B:INSTRUMENT_PFD_SOFTKEY_PFD1_4L_PUSH)")},

        -- PFD Softkeys (right side)
        {event=g1000.SW22.down, action=msfs.mfwasm.rpn_executer("1 (>B:INSTRUMENT_PFD_SOFTKEY_PFD1_1R_PUSH)")},
        {event=g1000.SW23.down, action=msfs.mfwasm.rpn_executer("1 (>B:INSTRUMENT_PFD_SOFTKEY_PFD1_2R_PUSH)")},
        {event=g1000.SW24.down, action=msfs.mfwasm.rpn_executer("1 (>B:INSTRUMENT_PFD_SOFTKEY_PFD1_3_PUSH)")},
        {event=g1000.SW25.down, action=msfs.mfwasm.rpn_executer("1 (>B:INSTRUMENT_PFD_SOFTKEY_PFD1_4R_PUSH)")},

        -- MFD Softkeys
        {event=g1000.SW27.down, action=msfs.mfwasm.rpn_executer("1 (>B:INSTRUMENT_PFD_SOFTKEY_MFD1_1L_PUSH)")},
        {event=g1000.SW28.down, action=msfs.mfwasm.rpn_executer("1 (>B:INSTRUMENT_PFD_SOFTKEY_MFD1_1R_PUSH)")},
        {event=g1000.SW30.down, action=msfs.mfwasm.rpn_executer("1 (>B:INSTRUMENT_PFD_SOFTKEY_MFD1_2R_PUSH)")},
        {event=g1000.SW32.down, action=msfs.mfwasm.rpn_executer("1 (>B:INSTRUMENT_PFD_SOFTKEY_MFD1_3R_PUSH)")},

        -- Terrain / Weather
        {event=g1000.EC9P.down, action=msfs.mfwasm.rpn_executer("1 (>B:AS3000_UPPER_1_TERR_WX_PUSH)")},
        -- PFD Menue / Data
        {event=g1000.EC9X.increment, action=msfs.mfwasm.rpn_executer("1 (>B:AS3000_UPPER_1_DATA_Inc)")},
        {event=g1000.EC9X.decrement, action=msfs.mfwasm.rpn_executer("1 (>B:AS3000_UPPER_1_DATA_Dec)")},
        {event=g1000.EC9Y.increment, action=msfs.mfwasm.rpn_executer("1 (>B:AS3000_UPPER_1_TILT_Inc)")},
        {event=g1000.EC9Y.decrement, action=msfs.mfwasm.rpn_executer("1 (>B:AS3000_UPPER_1_TILT_Dec)")},
    }

    return {
        move_next_view = function () end,
        move_previous_view = function () end,
        global_mappings = {},
        need_to_start_viewports = true,
    }
end

function g1000_context.stop()
    g1000_context.device:close()
    g1000_context.device = nil
end

return g1000_context
