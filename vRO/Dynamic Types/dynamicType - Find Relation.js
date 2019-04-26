/* This is an example script to find relational objects as part of Dynamic Types
* @Author Yattong Wu
* @Date 26 April 2019 
* @param {string} parentType - type of object dynamically set when expanding DT heirachy
* @param {string} parentId - ID of Parent Object dynamically set when expanding DT heirachy
* @param {string} relationName - Relation Name dynamically set when expanding DT heirachy
* @return {Array/DynamicTypes:DynamicObject} - resultObjs - Array of DT Objects.
*/

// Set Standard Logging
var objType = "Action";
var objName = "getDynamicTypeFindRelation"; // This must be set to the name of the action
var Logger = System.getModule("com.vodafone.agilecloud.library.util").logout(objType, objName);  //change Path
var log = new Logger(objType, objName);
// Start logging
log.debug("------ Starting " + objName + " ------");

// Set output of Dynamic Type
var resultObjs = [];

// Execute retrieve items
if (relationName == "namespace-children"){
	resultObjs.push(DynamicTypesManager.makeObject('CiscoASA', 'AccessRules', 'accessRulesFolder', 'Access Rules'));
}

if (relationName == "AccessRules-AccessRule"){
	//dynamicType - Get All Objects Example
	var dtObjects = GetAllObjectsExample(parentType);
}

// convert dynamicType
resultObjs = dtObjects;

// return object
return resultObjs;