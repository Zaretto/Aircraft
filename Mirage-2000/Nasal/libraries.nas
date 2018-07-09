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