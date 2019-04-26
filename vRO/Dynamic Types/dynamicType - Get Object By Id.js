/* This is an example script to get an object by Id as part of Dynamic Types
* @Author Yattong Wu
* @Date 26 April 2019 
* @param {string} type - type of object dynamically set when expanding DT heirachy.
* @param {string} id - id of object dynamically set when expanding DT heirachy.
* @return {DynamicTypes:CiscoASA.AccessRules} - resultObjFolder - Foldler for all Cisco ASA rule objects.
* @return {DynamicTypes:CiscoASA.AccessRule} - resultObj - Cisco ASA Rule Object.
*/

// Set Standard Logging
var objType = "Workflow";
var objName = "getDynamicTypeObjectById"; // This must be set to the name of the action
var Logger = System.getModule("com.vodafone.agilecloud.library.util").logout(objType, objName);  //change Path
var log = new Logger(objType, objName);
// Start logging
log.debug("------ Starting " + objName + " ------");

// Execute retrieve items
// Execute request
if (type.indexOf("Rules") > -1){
	resultObjFolder = DynamicTypesManager.makeObject('CiscoASA', 'AccessRules', 'accessRulesFolder', 'Access Rules');
} else {
	log.debug("Executing action : getCiscoASAAccessRuleById");
	var response = System.getModule("com.vodafone.agilecloud.library.ciscoasa.rest.accessrules").getCiscoASAAccessRuleById(id);
	
	// JSON parse response
	var jsonObj = JSON.parse(response);
	
	// Make DT object
	resultObj = DynamicTypesManager.makeObject("CiscoASA", "Access Rule", id)
	resultObj.setProperty("kind", jsonObj.kind.toString());
	resultObj.setProperty("id", jsonObj.objectId.toString());
	resultObj.setProperty("name", jsonObj.remarks[0].toString());
	resultObj.setProperty("position", jsonObj.position.toString());
	
	// Change type of object in Access Rule
	if (Array.isArray(jsonObj.sourceAddress)){
		var sourceAddresses = [];
		for each (sourceAddress in jsonObj.sourceAddress){
			if (sourceAddress.kind.toString().indexOf("object") > -1){
				sourceAddresses.push(sourceAddress.objectId.toString());
			} else {
				sourceAddresses.push(sourceAddress.value.toString());
			}
		}
		resultObj.setProperty("sourceAddress", sourceAddresses.join('\n'))
	} else {
		if (jsonObj.sourceAddress.kind.toString().indexOf("object") > -1){
			var sourceAddress = jsonObj.sourceAddress.objectId.toString();
		} else {
			var sourceAddress = jsonObj.sourceAddress.value.toString();
		}
		resultObj.setProperty("sourceAddress", sourceAddress);
	}
	
	// Change type of object in Access Rule
	if (Array.isArray(jsonObj.destinationAddress)){
		var destinationAddresses = [];
		for each (destinationAddress in jsonObj.destinationAddress){
			if (destinationAddress.kind.toString().indexOf("object") > -1){
				destinationAddresses.push(destinationAddress.objectId.toString());
			} else {
				destinationAddresses.push(destinationAddress.value.toString());
			}
		}
		resultObj.setProperty("destinationAddress", destinationAddresses.join('\n'));
	} else {
		if (jsonObj.destinationAddress.kind.toString().indexOf("object") > -1){
			var destinationAddress = jsonObj.destinationAddress.objectId.toString();
		} else {
			var destinationAddress = jsonObj.destinationAddress.value.toString();
		}
		resultObj.setProperty("destinationAddress", destinationAddress);
	}
	
	// Change type of object in Access Rule
	if (Array.isArray(jsonObj.destinationService)){
		var destinationServices = [];
		for each (destinationService in jsonObj.destinationService){
			if (destinationService.kind.toString().indexOf("object") > -1){
				destinationServices.push(destinationService.objectId.toString());
			} else {
				destinationServices.push(destinationService.value.toString());
			}
		}
		resultObj.setProperty("destinationService", destinationServices.join('\n'));
	} else {
		if (jsonObj.destinationService.kind.toString().indexOf("object") > -1){
			var destinationService = jsonObj.destinationService.objectId.toString();
		} else {
			var destinationService = jsonObj.destinationService.value.toString();
		}
		resultObj.setProperty("destinationService", destinationService);
	}
	
	log.debug("kind : " + resultObj.kind + ", name : " + resultObj.name + ", id : " + resultObj.id + ", sourceAddress : " + resultObj.sourceAddress
	 + ", destinationAddress : " + resultObj.destinationAddress + ", destinationServices : " + resultObj.destinationService);
}