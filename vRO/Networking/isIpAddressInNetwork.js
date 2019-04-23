/* This action checks whether an IP address is in a networkAddress address
* @Author Yattong Wu
* @Date 18 April 2019 * @param {string} ipAddress - IP Address 
* @param {string} networkAddress - Network Address e.g. 10.0.0.0/16
* @return {boolean} result.
*/

// Check Params
if (!ipAddress){
	throw "IP Address has not been provided";
}
if (!networkAddress || networkAddress.indexOf("/") == -1 || networkAddress.split("/")[1] > 32){
	throw "Network address has not been provided, or been provided in the wrong format";
}

/** Variable declaration block */
var logType = "Action";
var logName = "isIPAddressInNetwork"; // This must be set to the name of the action
var Logger = System.getModule("com.vodafone.agilecloud.library.util").standardisedLogger(logType, logName);
var log = new Logger(logType, logName);

// figure out networkAddress first
var cidr = parseInt(networkAddress.split("/")[1], 10);
var network = networkAddress.split("/")[0];
log.debug("Splitting up network address info :- cidr : " + cidr + ", " + "network : " + network, );

// function convert to binary
function convertToBinary(n){
	var binary = parseInt(n, 10).toString(2);
	return "00000000".substring(binary.length) + binary;
}

// comparison function
function compareOctet(a, b, c, d){  // a=octect, b=cidr, c=ipAddress, d=network
	log.debug("a (octect) : " + a + ", b (cidr) : " + b + ", c (ipAddress) : " + c + ", d (network) : " + d);
	if (b > 8 && b != 16 && b != 24 && b != 32){
		var e = b % 8;
		log.debug("remainder, e : " + e);
	} else {
		if (b < 8) {
			var e = b;
			log.debug("cidr is lower than 8, straight equals, e : " + e);
		} else {
			var e = 8;
			log.debug("hard code 8, e : " + e);
		}
	}
	var ipToCompare = convertToBinary(c.split(".")[a -1]).substring(0, e);
	log.debug("ip octect : " + a + "  binary to compare : " + ipToCompare);
	var netToCompare = convertToBinary(d.split(".")[a -1]).substring(0, e);
	log.debug("networkAddress octect : " + a + " binary to compare : " + netToCompare);
	if (ipToCompare == netToCompare){
		log.debug("ip Address networkAddress binary and networkAddress binary are the same");
		return true;
	} else {
		log.debug("ip Address networkAddress binary and networkAddress binary are NOT the same");
		return false;
	}
}

// figure out which Octet to check
if (cidr <= 8){
	var octetToCheck = 1;
	// convert IP Address octet 1 to binary
	var isTrue = compareOctet(1, cidr, ipAddress, network);
	if (!isTrue){
		log.debug("IP : " + ipAddress + " is not in networkAddress : " + networkAddress);
		return false;
	}
}
if (cidr > 8 && cidr <= 16){
	var octetToCheck = [1, 2];
	for (octet in octetToCheck){
		// ensure the full octet prefixed is compared
		if (octet != octetToCheck.length){
			var net = 8;
		} else {
			var net = cidr;
		}
		// Execute comparison
		var isTrue = compareOctet(octet, net, ipAddress, network);
		if (!isTrue){
			log.debug("IP : " + ipAddress + " is not in networkAddress : " + networkAddress);
			return false;
		}
	}
}
if (cidr > 16 && cidr <= 24){
	var octetToCheck = [1, 2, 3];
	for (octet in octetToCheck){
		// ensure the full octet prefixed is compared
		if (octet != octetToCheck.length){
			var net = 8;
		} else {
			var net = cidr;
		}
		// Execute comparison
		var isTrue = compareOctet(octet, net, ipAddress, network);
		if (!isTrue){
			log.debug("IP : " + ipAddress + " is not in networkAddress : " + networkAddress);
			return false;
		}
	}
}
if (cidr > 24 && cidr <= 32){
	var octetToCheck = [1, 2, 3, 4];
	for (octet in octetToCheck){
		// ensure the full octet prefixed is compared
		if (octet != octetToCheck.length){
			var net = 8;
		} else {
			var net = cidr;
		}
		// Execute comparison
		var isTrue = compareOctet(octet, net, ipAddress, network);
		if (!isTrue){
			log.debug("IP : " + ipAddress + " is not in networkAddress : " + networkAddress);
			return false;
		}
	}
}

// Must be true if no return
log.debug("IP : " + ipAddress + " is in networkAddress : " + networkAddress);
return true;




