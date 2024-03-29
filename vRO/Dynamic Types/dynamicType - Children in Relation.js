/* This is an example script to tell DT whether object has children
* @Author Yattong Wu
* @Date 26 April 2019 
* @param {string} parentType - type of object dynamically set when expanding DT heirachy
* @return {boolean} - result - Array of all ASA rule objects.
*/

// Set Standard Logging
var objType = "Action";
var objName = "restCall"; // This must be set to the name of the action
var Logger = System.getModule("london.clouding.logging").standardisedLogger(objType,objName);
var log = new Logger(objType, objName);

// Start logging
log.debug("------ Starting " + objType + " : " + objName + " ------");

// Execute retrieve items
if (parentType == "CiscoASA.Access Rule"){
	result = false;
} else {
	result = true;
}