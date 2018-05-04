/*
 *   @programer:    Rodrigo Birriel
 *   @description:  sharing records utils, ONLY WORK FOR CUSTOM OBJECT AND FOR SPECIFIC STANDARD OBJECT: WORK ORDER
 *   @date:         01/14/2016
 *   reference: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_bulk_sharing_creating_with_apex.htm 
 *   
 *   TODO:  1. remove the parameter sobjecttype from methods, and use dynamic code to create it using descriptors.
 *          2. support for standard objects.           
 */
public with sharing class UNITY_SharingUtil {
    
    public static void manualShareDelete(List<SObject> records,Schema.SObjectType sObjectShare) {
        
        if(!records.isEmpty() && (sObjectShare!=null )) {
            String objName = sObjectShare.getDescribe().getName();
            List<Id> recordIds = UNITY_Utils.joiningByIdList(records);
            String queryString = 'SELECT Id FROM '+objName+' WHERE RowCause = \'Manual\' and ParentId IN :recordIds';
            System.debug('queryString'+queryString);
            try {
                 delete Database.query(queryString);
            }catch(Exception ex) {
                for(Integer index=0; index<records.size(); index++){
                    SObject currentObject = records.get(index);
                    currentObject.addError('An internal error has ocurred. Please contact to your administrator.');  
                }
            }
            
        }
    }
    
    public static List<Boolean> manualShareCreateReadWriteBulk(List<SObject> records, List<Id> userOrGroupIds, Schema.SObjectType sObjectShare) {
        return manualShareCreateBulk(records,userOrGroupIds,'Edit',sObjectShare);
    }
    
    public static List<Boolean> manualShareCreateReadOnlyBulk(List<SObject> records, List<Id> userOrGroupIds, Schema.SObjectType sObjectShare) {
        return manualShareCreateBulk(records,userOrGroupIds,'Read',sObjectShare);
    }
    
    public static List<Boolean> manualShareCreateFullAccessBulk(List<SObject> records, List<Id> userOrGroupIds, Schema.SObjectType sObjectShare) {
        return manualShareCreateBulk(records,userOrGroupIds,'All',sObjectShare);
    }
    
    // generic manual sharing in bulk process, records and userGroupIds must have the same size
    private static List<Boolean> manualShareCreateBulk(List<SObject> records, List<Id> userOrGroupIds,String accessLevel, Schema.SObjectType sObjectShare){
        List<Boolean> successList = new List<Boolean>();
        if(records.size() == userOrGroupIds.size() && !records.isEmpty()) {
            List<SObject> shareObjects = new List<SObject>();
            for(Integer index=0; index<records.size(); index++){
                SObject record = records.get(index);
                Id userOrGroupId = userOrGroupIds.get(index);
                
                if(userOrGroupId != NULL && record.get('Id') != NULL) {
                    // Create new sharing object list for the sobjecttype.
                    SObject shareObject = sObjectShare.newSobject();
                    
                    // Set the ID of record being shared.
                    shareObject.put('ParentId',record.get('Id'));
                    // Set the ID of user or group being granted access.
                    shareObject.put('UserOrGroupId',userOrGroupId);
                    // Set the access level.
                    shareObject.put('AccessLevel',accessLevel);
                    
                    // Set rowCause to 'manual' for manual sharing.
                    // This line can be omitted as 'manual' is the default value for sharing objects.
                    shareObject.put('RowCause','Manual');
                    System.debug('Creating a new share record'+shareObject);
                    shareObjects.add(shareObject);   
                }
            }
            
                // Insert the sharing records and capture the save result.
            try {
                if(!shareObjects.isEmpty()) {
                    List<Database.SaveResult> resultList = Database.insert(shareObjects);   
                }
            }catch(Exception ex) {
                for(Integer index=0; index<records.size(); index++){
                    SObject currentObject = records.get(index);
                    currentObject.addError('An internal error has ocurred. Please contact to your administrator.');  
                }
            }
     
        }
        return successList;
   }
   
}