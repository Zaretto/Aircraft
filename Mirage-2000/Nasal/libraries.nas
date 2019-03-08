# Mirage 2000 System Libraries

# It's magic, I don't know how it works!
var doMagicStartup = func {
	setprop("/instrumentation/mfd/modeL", 0);
	setprop("/instrumentation/mfd/modeR", 3);
	setprop("/controls/engines/engine[0]/cutoff", 0);
	setprop("/engines/engine[0]/out-of-fuel", 0);
	setprop("/engines/engine[0]/run", 1);

	setprop("/engines/engine[0]/cutoff", 0);
	setprop("/engines/engine[0]/starter", 0);

	setprop("/fdm/jsbsim/propulsion/set-running", 0);
}

# Prevent a JSB bug
var down = 1;
setlistener("/controls/gear/gear-down", func {
	down = getprop("/controls/gear/gear-down");
	if (!down and (getprop("/gear/gear[0]/wow") or getprop("/gear/gear[1]/wow") or getprop("/gear/gear[2]/wow"))) {
		setprop("/controls/gear/gear-down", 1);
	}
});

# AirBrake handling
controls.applyAirBrakes = func(v) {
    setprop("/fdm/jsbsim/fbw/speedbrake-brake", v);
}

# Brake handling
var fullBrakeTime = 0.5;
controls.applyBrakes = func(v, which = 0) {
	if (which <= 0) { 
		interpolate("/controls/gear/brake-left", v, fullBrakeTime);
	}
	if (which >= 0) {
		interpolate("/controls/gear/brake-right", v, fullBrakeTime);
	}
    if (getprop("/controls/gear/gear-down") != 0) {
		controls.applyAirBrakes(v); # Also deploy speedbrakes when gears is down
    }
}

# Timers for hydraulics
var hyd_emer_request = props.globals.getNode("/fdm/jsbsim/systems/hydraulics/emerg-electric-pump-start-request", 1);
var hyd_emer_elec_power = props.globals.getNode("/fdm/jsbsim/systems/hydraulics/emerg-electric-pump-power", 1);
var electropompe = props.globals.getNode("/fdm/jsbsim/systems/hydraulics/ep-running", 1);
var ep_6seconds = props.globals.getNode("/fdm/jsbsim/systems/hydraulics/ep-running-6seconds", 1);
var elapsedtime = props.globals.getNode("/sim/time/elapsed-sec", 1);
var cur_time = 0;
var cur_time_2 = 0;

var flag_1 = 0;
var flag_2 = 0;

var check_time = func() {
	if (elapsedtime.getValue() >= cur_time + 60) {
		check_time_timer.stop();
		hyd_emer_elec_power.setValue(0);
		# do not reset flag as battery is not rechargeable
	}
}

var check_time_2 = func() {
	if (elapsedtime.getValue() >= cur_time_2 + 6) {
		if (electropompe.getValue() == 1) {
			check_time_2_timer.stop();
			ep_6seconds.setValue(1);
			flag_2 = 0;
		}
	}
}

var checkEMEREP = func() {
	if (hyd_emer_request.getValue() == 0 or flag_1 == 1) { return; }
	print("[HYD] EP (RESERVE) ACTIVE");
	hyd_emer_elec_power.setValue(1);
	cur_time = elapsedtime.getValue();
	check_time_timer.start();
	flag_1 = 1;
}

var checkEP = func() {
	if (electropompe.getValue() == 0 or flag_2 == 1) { return; }
	print("[HYD] EP ACTIVE");
	cur_time_2 = elapsedtime.getValue();
	check_time_2_timer.start();
	flag_2 = 1;
}

var timer_checkEP = func() {
	checkEMEREP();
	checkEP();
}

setlistener("/sim/signals/fdm-initialized", func {
	checkEP_timer.start();
});

var checkEP_timer = maketimer(1, timer_checkEP);
checkEP_timer.simulatedTime = 1;

var check_time_timer = maketimer(1, check_time);
check_time_timer.simulatedTime = 1;

var check_time_2_timer = maketimer(1, check_time_2);
check_time_2_timer.simulatedTime = 1;
