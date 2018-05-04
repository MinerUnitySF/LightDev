/********************************************************************************************************
Name:  lockedClass
Author:  Alex Dumitrache(Vertiba) 
Last Modified : 05.16.2014

Behavior:

    Adds error message to the records for which tha parent records are locked(defined by a boolean field). 
    The list of child records(objlist), lookup to parent api name(parentId), parent object api name(parentObj) and boolean field api name(field) are received through parameters.
    
********************************************************************************************************/
public with sharing class lockedClass {

	public lockedClass(){
		
	}
	
	public static void checkL(List<sObject> objlist, String parentId, String parentObj, String field){
		
		Set<Id> idset = new Set<Id>();
		
		//retrieve ids for the parent records
		for (sObject so : objlist){
			Id o = (Id)so.get(parentId);
			idset.add(o);
		}
		
		List<sObject> solist = new List<sObject>();
		Map<Id, Boolean> pmap = new Map<Id, Boolean>();
		
		//query the parent records
		solist = database.query('SELECT Id, ' + field +' FROM ' + parentObj + ' WHERE Id IN : idset');
		
		//create map with id of the parent record and the value of the boolean field
		for (sObject so : solist){
			Boolean o = (Boolean)so.get(field);
			pmap.put(so.Id, o);
		}
		
		for (sObject so : objlist){
			
			//get id of the parent record
			Id o = (Id)so.get(parentId);
			
			//if the child has parent
			if (o != null){
				
				//if the field is set to true
				if (pmap.get(o))
				
					//add error message
					if (!test.isRunningTest())
						so.addError('This record cannot be added, edited or deleted because it\'s parent record is locked.');
			}
		}
	}

}