#!/usr/bin/env node

var spawn = require('child_process').spawn,
		request = require('request'),
		argv = require('optimist').argv;

if (!argv.location) {
	console.log("Please specify your location with --location \"LOCATION\"");
	process.exit(1);
}
var tcpdump = spawn('tcpdump', ['-e', '-l', '-In', '-i', 'en0', 'type', 'mgt', 'subtype', 'probe-req']);
tcpdump.stdout.on('data', function(data) {
	var raw =	data.toString().split("\n");
	for (var r in raw) {
		raw[r] = raw[r].split(" ");
		var probeIndex = raw[r].indexOf("Probe");
		if (probeIndex > -1) {
			if (raw[r][parseInt(probeIndex) + 1] === "Request") {
				if (raw[r][parseInt(probeIndex) + 2]) {
					var build = raw[r][parseInt(probeIndex) + 2].replace("(", "");
					if (build.replace(")", "") !== "") {
						if (raw[r][parseInt(probeIndex) + 2].indexOf(")") <= -1) {
							var found = false;
							var i = 3;
							while (!found) {
								if (raw[r][parseInt(probeIndex) + i]) {
									if (raw[r][parseInt(probeIndex) + i].indexOf(")") > -1) {
										build += " " + raw[r][parseInt(probeIndex) + i].replace(")", "");
										found = true;
									} else {
										build += " " + raw[r][parseInt(probeIndex) + i];
									}
									i += 1;
								} else {
									found = true;
									build = build.replace(")", "");
								}
							}
						} else {
							build = build.replace(")", "");
						}
						console.log(build);
						if (raw[r][parseInt(probeIndex) - 1].indexOf("SA") > -1) {
							var macBuild = raw[r][parseInt(probeIndex) - 1].replace("SA:", "").replace(/:/g,"");
							console.log(macBuild);
						}
						request({url: 'http://wifi-privacy.herokuapp.com/devices/mac-'+macBuild+'/networks', body: {'name':build,'location':argv.location}, json:true, method: 'post'});
					}
				}
			}
		}
	}
});
