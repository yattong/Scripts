/* This action checks whether an IP address is a valid IP v4 Address
* @Author Yattong Wu
* @Date 13 June 2019 * @param {string} ipAddress - IP Address 
* @return {string} validation messsage.
*/

// Check Params
if (!ipAddress){
	throw "IP Address has not been provided";
}

// Set Standard Logging
var objType = "Action";
var objName = "restCall"; // This must be set to the name of the action
var Logger = System.getModule("london.clouding.logging").standardisedLogger(objType,objName);
var log = new Logger(objType, objName);

/** Variable declaration block */
var msg = "IP Address : " + ipAddress + " is in the correct format";

// Start logging
log.debug("------ Starting " + objType + " : " + objName + " ------");

// Split Octets
var octets = ipAddress.split(".");

// Check if there are 4 octets
if (octets.length != 4){
	var errorCode = "IP Address is not in a valid format";
	log.error(errorCode);
	return errorCode;
}

// Run through each octet and validate between 1 and 254
var counter = 1;
for (octet in octets){
	if (counter == 1){
		if (parseInt(octet) == 0 || parseInt(octet) > 254){
			var errorCode = "IP Address is not in a valid format";
			log.error(errorCode);
			return errorCode;
		}
	} else {
		if (parseInt(octet) < 0 || parseInt(octet) > 254){
			var errorCode = "IP Address is not in a valid format";
			log.error(errorCode);
			return errorCode;
		}
	}
	counter++;
}

// Must be true if no return
log.debug(msg);
return msg;




