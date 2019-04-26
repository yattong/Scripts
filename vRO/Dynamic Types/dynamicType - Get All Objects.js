/* This is an example script to get all objects as part of Dynamic Types
* @Author Yattong Wu
* @Date 26 April 2019 
* @param {string} type - type of object dynamically set when expanding DT heirachy
* @return {Array/DynamicTypes:CiscoASA.AccessRules} - resultObjs - Array of all ASA rule objects.
*/

// Set Standard Logging
var objType = "Action";
var objName = "getDynamicTypeAllObjects"; // This must be set to the name of the action
var Logger = System.getModule("com.vodafone.agilecloud.library.util").logout(objType, objName);  //change Path
var log = new Logger(objType, objName);
// Start logging
log.debug("------ Starting " + objName + " ------");

// Execute retrieve items
try {
	// Execute Request
	var response = System.getModule("com.vodafone.agilecloud.library.ciscoasa.rest.accessrules").getCiscoASAAccessRules();
	var accessRules = JSON.parse(response);
}
catch(e) {
	throw("Obtaining Access Rules: Exception with details: " + e);
}

// Enumerate Output
var resultObjs = [];

// Propagate values into DT Object
for each (object in accessRules.items){
	var id = object.objectId.toString();
	var name = object.remarks[0].toString();
		
	// Make DT object
	var obj = DynamicTypesManager.makeObject("CiscoASA", "Access Rule", id, name)  // key attributes when making object
	obj.setProperty("kind", object.kind.toString());
	obj.setProperty("position", object.position.toString());
	
	// Change type of object in Access Rule
	if (Array.isArray(object.sourceAddress)){
		var sourceAddresses = [];
		for each (sourceAddress in object.sourceAddress){
			if (sourceAddress.kind.toString().indexOf("object") > -1){
				sourceAddresses.push(sourceAddress.objectId.toString());
			} else {
				sourceAddresses.push(sourceAddress.value.toString());
			}
		}
		obj.setProperty("sourceAddress", sourceAddresses.join('\n'));
	} else {
		if (object.sourceAddress.kind.toString().indexOf("object") > -1){
			var sourceAddress = object.sourceAddress.objectId.toString();
		} else {
			var sourceAddress = object.sourceAddress.value.toString();
		}
		obj.setProperty("sourceAddress", sourceAddress);
	}
	
	// Change type of object in Access Rule
	if (Array.isArray(object.destinationAddress)){
		var destinationAddresses = [];
		for each (destinationAddress in object.destinationAddress){
			if (destinationAddress.kind.toString().indexOf("object") > -1){
				destinationAddresses.push(destinationAddress.objectId.toString());
			} else {
				destinationAddresses.push(destinationAddress.value.toString());
			}
		}
		obj.setProperty("destinationAddress", destinationAddresses.join('\n'));
	} else {
		if (object.destinationAddress.kind.toString().indexOf("object") > -1){
			var destinationAddress = object.destinationAddress.objectId.toString();
		} else {
			var destinationAddress = object.destinationAddress.value.toString();
		}
		obj.setProperty("destinationAddress", destinationAddress);
	}
		
	// Change type of object in Access Rule
	if (Array.isArray(object.destinationService)){
		var destinationServices = [];
		for each (destinationService in object.destinationService){
			if (destinationService.kind.toString().indexOf("object") > -1){
				destinationServices.push(destinationService.objectId.toString());
			} else {
				destinationServices.push(destinationService.value.toString());
			}
		}
		obj.setProperty("destinationService", destinationServices.join('\n'));
	} else {
		if (object.destinationService.kind.toString().indexOf("object") > -1){
			var destinationService = object.destinationService.objectId.toString();
		} else {
			var destinationService = object.destinationService.value.toString();
		}
		obj.setProperty("destinationService", destinationService);
	}
	
    log.debug("kind : " + obj.kind + ", name : " + obj.name + ", id : " + obj.id + ", sourceAddress : "
     + obj.sourceAddress + ", destinationAddress : " + obj.destinationAddress + ", destinationServices : " + obj.destinationService);
    
     // Push object into array
	resultObjs.push(obj);
}
