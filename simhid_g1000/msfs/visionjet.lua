local context = {
    g3000_view = require("visionjet/g3000"),
    tsc_view = require("visionjet/tsc"),
}

local common = require('lib/common')

function context.start(config, aircraft)
    local display = config.simhid_g1000_display
    local scale = config.simhid_g1000_display_scale

    context.device = common.open_simhid_g1000 {
        config = config,
        modifiers = {
            { class = "binary",   modtype = "button" },
            { class = "relative", modtype = "incdec" },
            { name = "EC6P",      modtype = "button", modparam = { longpress = 2000 } },
            { name = "EC8U",      modtype = "button", modparam = { repeat_interval = 150, repeat_delay = 500 } },
            { name = "EC8D",      modtype = "button", modparam = { repeat_interval = 150, repeat_delay = 500 } },
            { name = "EC8L",      modtype = "button", modparam = { repeat_interval = 150, repeat_delay = 500 } },
            { name = "EC8R",      modtype = "button", modparam = { repeat_interval = 150, repeat_delay = 500 } },
            { name = "SW11",      modtype = "button", modparam = { repeat_interval = 150, repeat_delay = 500 } },
            { name = "SW13",      modtype = "button", modparam = { repeat_interval = 150, repeat_delay = 500 } },
        },
    }
    local g1000 = context.device.events

    local global_mappings = {}
    msfs.mfwasm.add_observed_data(context.g3000_view.observed_data)
    global_mappings[#global_mappings + 1] = context.g3000_view.mappings
    context.g3000_view.init(context.device)
    msfs.mfwasm.add_observed_data(context.tsc_view.observed_data)
    global_mappings[#global_mappings + 1] = context.tsc_view.mappings
    context.tsc_view.init(context.device)

    local viewport_main = mapper.viewport {
        name = "Vision Jet Main Viewport",
        displayno = display,
        x = 0, y = 0,
        width = scale, height = scale,
        aspect_ratio = 16 / 12,
        horizontal_alignment = "center",
        vertical_alignment = "center",
    }
    context.views = {
        viewport_main:register_view(context.g3000_view.create_view("G3000 PFD", "PFD_1")),
        viewport_main:register_view(context.g3000_view.create_view("G3000 MFD", "MFD")),
        viewport_main:register_view(context.tsc_view.create_view("G3000 TSC 1", "WTG3000_GTC_1", "1")),
        viewport_main:register_view(context.tsc_view.create_view("G3000 TSC 2", "WTG3000_GTC_2", "2")),
    }

    context.current_view = 1
    local function change_view(d)
        if not context.views then return end
        context.current_view = context.current_view + d
        if context.current_view > #context.views then
            context.current_view = 1
        elseif context.current_view < 1 then
            context.current_view = #context.views
        end
        viewport_main:change_view(context.views[context.current_view])
    end

    viewport_main:set_mappings {
        { event = g1000.AUX1D.down,     action = function() change_view(1) end },
        { event = g1000.AUX1U.down,     action = function() change_view(-1) end },
        { event = g1000.AUX2D.down,     action = function() change_view(1) end },
        { event = g1000.AUX2U.down,     action = function() change_view(-1) end },

        -- Autopilot Controls
        { event = g1000.SW2.down,       action = msfs.mfwasm.rpn_executer("(A:AUTOPILOT DISENGAGED, Bool) ! if{ (>K:AP_MASTER) (A:AUTOPILOT MASTER, Bool) ! if{ (>H:Generic_Autopilot_Manual_Off) } els{ (A:AUTOPILOT YAW DAMPER, Bool) ! if{ (>K:YAW_DAMPER_TOGGLE) } } }") },
        { event = g1000.SW3.down,       action = msfs.mfwasm.rpn_executer("1 (>K:TOGGLE_FLIGHT_DIRECTOR)") },
        { event = g1000.SW4.down,       action = msfs.mfwasm.rpn_executer("(>K:AP_PANEL_HEADING_HOLD)") },
        { event = g1000.SW5.down,       action = msfs.mfwasm.rpn_executer("(>K:AP_ALT_HOLD)") },
        { event = g1000.SW6.down,       action = msfs.mfwasm.rpn_executer("(>K:AP_NAV1_HOLD)") },
        { event = g1000.SW7.down,       action = msfs.mfwasm.rpn_executer("(L:XMLVAR_VNAVButtonValue) ! (>L:XMLVAR_VNAVButtonValue)") },
        { event = g1000.SW8.down,       action = msfs.mfwasm.rpn_executer("(>K:AP_APR_HOLD)") },
        { event = g1000.SW9.down,       action = msfs.mfwasm.rpn_executer("(>K:AP_BC_HOLD)") },
        { event = g1000.SW10.down,      action = msfs.mfwasm.rpn_executer("(>K:AP_PANEL_VS_HOLD) 1 0 (>K:2:AP_VS_VAR_SET_ENGLISH)") },
        { event = g1000.SW12.down,      action = msfs.mfwasm.rpn_executer("(>K:FLIGHT_LEVEL_CHANGE) (A:AUTOPILOT FLIGHT LEVEL CHANGE, bool) if { (A:AIRSPEED INDICATED, knots) (>K:AP_SPD_VAR_SET) }") },
        { event = g1000.SW11.down,      action = msfs.mfwasm.rpn_executer("(>K:AP_SPD_VAR_DEC) (>K:AP_VS_VAR_INC)") },
        { event = g1000.SW13.down,      action = msfs.mfwasm.rpn_executer("(>K:AP_SPD_VAR_INC) (>K:AP_VS_VAR_DEC)") },


        -- TSC Menu
        { event = g1000.SW28.down,      action = msfs.mfwasm.rpn_executer("(>H:AS3X_Touch_1_Menu_Push)") },

        -- Auto Throttle
        { event = g1000.SW14.down,      action = msfs.mfwasm.rpn_executer("1 (>B:SF50_AUTOPILOT_AutoThrottle_Arm_Toggle)") },
        { event = g1000.SW15.down,      action = msfs.mfwasm.rpn_executer("1 (>B:SF50_AUTOPILOT_Man_Speed_Mode_Toggle)") },
        { event = g1000.SW16.down,      action = msfs.mfwasm.rpn_executer("1 (>B:SF50_AUTOPILOT_FMS_Speed_Mode_Toggle)") },
        { event = g1000.EC1P.down,      action = msfs.mfwasm.rpn_executer("1 (>B:SF50_AUTOPILOT_Man_Speed_Mode_Toggle)") },
        { event = g1000.EC1.increment,  action = msfs.mfwasm.rpn_executer("1 (>K:AP_SPD_VAR_INC)") },
        { event = g1000.EC1.decrement,  action = msfs.mfwasm.rpn_executer("1 (>K:AP_SPD_VAR_DEC)") },


        -- Heading
        { event = g1000.EC3.increment,  action = msfs.mfwasm.rpn_executer("1 (>K:HEADING_BUG_INC)") },
        { event = g1000.EC3.decrement,  action = msfs.mfwasm.rpn_executer("1 (>K:HEADING_BUG_DEC)") },
        { event = g1000.EC3P.down,      action = msfs.mfwasm.rpn_executer("(A:HEADING INDICATOR,degrees) (>K:HEADING_BUG_SET)") },

        -- Altitude
        { event = g1000.EC4X.increment, action = msfs.mfwasm.rpn_executer("100 (>K:AP_ALT_VAR_INC)") },
        { event = g1000.EC4X.decrement, action = msfs.mfwasm.rpn_executer("100 (>K:AP_ALT_VAR_DEC)") },
        { event = g1000.EC4Y.increment, action = msfs.mfwasm.rpn_executer("1000 (>K:AP_ALT_VAR_INC)") },
        { event = g1000.EC4Y.decrement, action = msfs.mfwasm.rpn_executer("1000 (>K:AP_ALT_VAR_DEC)") },
        { event = g1000.EC4P.down,      action = msfs.mfwasm.rpn_executer("(A:INDICATED ALTITUDE, feet) (>K:AP_ALT_VAR_SET_ENGLISH) (>H:AP_KNOB)") },

        -- Course / Baro
        { event = g1000.EC7X.increment, action = msfs.mfwasm.rpn_executer("(>H:AS3000_PFD_1_CRS_INC)") },
        { event = g1000.EC7X.decrement, action = msfs.mfwasm.rpn_executer("(>H:AS3000_PFD_1_CRS_DEC)") },
        { event = g1000.EC7P.down,      action = msfs.mfwasm.rpn_executer("(>H:AS3000_PFD_1_CRS_PUSH)") },
        { event = g1000.EC7Y.increment, action = msfs.mfwasm.rpn_executer("1 (>K:KOHLSMAN_INC) (>H:AP_BARO_Up)") },
        { event = g1000.EC7Y.decrement, action = msfs.mfwasm.rpn_executer("1 (>K:KOHLSMAN_DEC) (>H:AP_BARO_Down)") },

        -- TSC 1 Knobs
        { event = g1000.EC6Y.increment, action = msfs.mfwasm.rpn_executer("1 (>B:AS3000_TSC_1_FREQUENCY_KNOB_MHZ_Inc)") },
        { event = g1000.EC6Y.decrement, action = msfs.mfwasm.rpn_executer("1 (>B:AS3000_TSC_1_FREQUENCY_KNOB_MHZ_Dec)") },
        { event = g1000.EC6X.increment, action = msfs.mfwasm.rpn_executer("1 (>B:AS3000_TSC_1_FREQUENCY_KNOB_KHZ_Inc)") },
        { event = g1000.EC6X.decrement, action = msfs.mfwasm.rpn_executer("1 (>B:AS3000_TSC_1_FREQUENCY_KNOB_KHZ_Dec)") },
        { event = g1000.EC6P.up,        action = msfs.mfwasm.rpn_executer("1 (>B:AS3000_TSC_1_FREQUENCY_KNOB_Button)") },


        -- TSC 2 Knobs
        { event = g1000.EC6Y.increment, action = msfs.mfwasm.rpn_executer("1 (>B:AS3000_TSC_2_FREQUENCY_KNOB_MHZ_Inc)") },
        { event = g1000.EC6Y.decrement, action = msfs.mfwasm.rpn_executer("1 (>B:AS3000_TSC_2_FREQUENCY_KNOB_MHZ_Dec)") },
        { event = g1000.EC6X.increment, action = msfs.mfwasm.rpn_executer("1 (>B:AS3000_TSC_2_FREQUENCY_KNOB_KHZ_Inc)") },
        { event = g1000.EC6X.decrement, action = msfs.mfwasm.rpn_executer("1 (>B:AS3000_TSC_2_FREQUENCY_KNOB_KHZ_Dec)") },
        { event = g1000.EC6P.up,        action = msfs.mfwasm.rpn_executer("1 (>B:AS3000_TSC_2_FREQUENCY_KNOB_Button)") },

        { event = g1000.EC9Y.increment, action = msfs.mfwasm.rpn_executer("(>H:AS3000_TSC_Horizontal_1_BottomKnob_Small_INC)") },
        { event = g1000.EC9Y.decrement, action = msfs.mfwasm.rpn_executer("(>H:AS3000_TSC_Horizontal_1_BottomKnob_Small_DEC)") },
        { event = g1000.EC9X.increment, action = msfs.mfwasm.rpn_executer("(>H:AS3000_TSC_Horizontal_1_BottomKnob_Small_INC)") },
        { event = g1000.EC9X.decrement, action = msfs.mfwasm.rpn_executer("(>H:AS3000_TSC_Horizontal_1_BottomKnob_Small_DEC)") },
        { event = g1000.EC9P.down,      action = msfs.mfwasm.rpn_executer("(>H:AS3000_TSC_Horizontal_1_BottomKnob_Push)") },

        -- Map Zoom / TSC Joystick (Mapped to Range knob EC8)
        { event = g1000.EC8.increment,  action = msfs.mfwasm.rpn_executer("1 (>B:AS3000_TSC_2_MULTIFUNCTION_KNOB_Inc)") },
        { event = g1000.EC8.decrement,  action = msfs.mfwasm.rpn_executer("1 (>B:AS3000_TSC_2_MULTIFUNCTION_KNOB_Dec)") },
        { event = g1000.EC8P.down,      action = msfs.mfwasm.rpn_executer("(>B:AS3000_TSC_2_MULTIFUNCTION_KNOB_Button)") },
        -- {event=g1000.EC8U.down, action=msfs.mfwasm.rpn_executer("(>H:AS3000_TSC_Horizontal_1_Joystick_Up)")},
        -- {event=g1000.EC8D.down, action=msfs.mfwasm.rpn_executer("(>H:AS3000_TSC_Horizontal_1_Joystick_Down)")},
        -- {event=g1000.EC8L.down, action=msfs.mfwasm.rpn_executer("(>H:AS3000_TSC_Horizontal_1_Joystick_Left)")},
        -- {event=g1000.EC8R.down, action=msfs.mfwasm.rpn_executer("(>H:AS3000_TSC_Horizontal_1_Joystick_Right)")},

    }

    return {
        move_next_view = function() change_view(1) end,
        move_previous_view = function() change_view(-1) end,
        global_mappings = global_mappings,
        need_to_start_viewports = true,
    }
end

function context.stop()
    context.views = nil
    context.g3000_view.term()
    context.tsc_view.term()
    context.device:close()
    context.device = nil
    msfs.mfwasm.clear_observed_data()
end

return context
