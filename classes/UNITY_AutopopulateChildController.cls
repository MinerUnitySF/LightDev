public with sharing class UNITY_AutopopulateChildController {
    
    public String sourceSObject;
    public String targetSObject;
    public String urlEncodedParameters;
    
    public Id parentId;
    
    public String baseUrl;
    
    public String getTargetSObject(){
        return targetSObject;
    }
    
    public static final Integer MAX_PARENTS = 10;
    
    /** default constructor to be called when used in a VF page */
    public UNITY_AutopopulateChildController(){
        
        Map<String, String> params = ApexPages.currentPage().getParameters();

        parentId = params.get('parentId');
        sourceSObject = params.get('sourceSObject'); 
        targetSObject = params.get('targetSObject');
        urlEncodedParameters = params.get('urlEncodedParameters');
        baseUrl = params.get('baseUrl');
        System.debug(LoggingLevel.INFO,'<AK> : urlEncodedParameters : '+urlEncodedParameters);
            
    }
    
    /** constructor to be called from another class */
    public UNITY_AutopopulateChildController(String sourceObject, String targetObject, Id parentId){
        
        this.sourceSObject = sourceObject;
        this.targetSObject = targetObject;
        
        this.parentId = parentId;
    }
    
    public UNITY_AutopopulateChildController(String targetObject){
        
        this.targetSObject = targetObject;
    }
    
    /** retrieves the autopopulate mapping from the custom setting for the specific sourceSObject and targetSObject*/
    public List<UNITY_Autopopulate_Mapping__c> getMappingSettings(){
        
        List<UNITY_Autopopulate_Mapping__c> settingList = new List<UNITY_Autopopulate_Mapping__c>();
        List<UNITY_Autopopulate_Mapping__c> temp = UNITY_Autopopulate_Mapping__c.getAll().values();
        for(UNITY_Autopopulate_Mapping__c iter :temp){
            if(iter.Target_Object__c == targetSObject && iter.Source_Object__c == sourceSObject){
                settingList.add(iter);
            }
        }
        return settingList; 
    }
    
    /** retrieves the autopopulate mapping from the custom setting */
    public static List<UNITY_Autopopulate_Mapping__c> getMappingSettingsAnySourceObject(String targetSObject){
        
        List<UNITY_Autopopulate_Mapping__c> settingList = new List<UNITY_Autopopulate_Mapping__c>();
        List<UNITY_Autopopulate_Mapping__c> temp = UNITY_Autopopulate_Mapping__c.getAll().values();
        for(UNITY_Autopopulate_Mapping__c iter :temp){
            if(iter.Target_Object__c == targetSObject){
                settingList.add(iter);
            }
        }
        return settingList;        
    }
    
    /* returns Map<relatedObject, List<UNITY_Autopopulate_Mapping__c>> */ 
    public static Map<String, List<UNITY_Autopopulate_Mapping__c>> getMappingSettingsForSpecificTarget(String targetSObject){
        
        Map<String, List<UNITY_Autopopulate_Mapping__c>> result = new Map<String, List<UNITY_Autopopulate_Mapping__c>>();
        
        List<UNITY_Autopopulate_Mapping__c> temp = UNITY_Autopopulate_Mapping__c.getAll().values();
        for(UNITY_Autopopulate_Mapping__c iter :temp){
            if(iter.Target_Object__c == targetSObject){
                if (result.get(iter.Source_Object__c) == null){
                    result.put(iter.Source_Object__c, new List<UNITY_Autopopulate_Mapping__c>());
                }
                
                result.get(iter.Source_Object__c).add(iter);
            }
        }
        
        return result;        
    }
    
    /** url hack to autopopulate the sobject field before inserting the record*/
    public String getMapFieldsAndRedirect(){
        
        String url = baseUrl;
        
        String sObjectPreffix = Schema.getGlobalDescribe().get(targetSObject).getDescribe().getKeyPrefix();
        
        List<UNITY_Autopopulate_Mapping__c> settings = getMappingSettings();
        
        sObject record = getSobject(settings);
        
        String urlParams = '';
        
        for (UNITY_Autopopulate_Mapping__c iter: settings){
            
            String targetField = iter.Target_Field__c;
            String targetLayoutId = iter.Target_Field_Layout_Id__c;
            
            String value = getValue(iter.Source_Field__c, record);
            
            
            if (value != '' && value != null){
                urlParams += '&'+targetLayoutId+'='+EncodingUtil.urlEncode(value,'UTF-8');        
            }
            
        }
        
        if (urlEncodedParameters!=null && urlEncodedParameters!=''){
            urlParams += EncodingUtil.urlDecode(urlEncodedParameters,'UTF-8');
        }

        System.debug('#urlParams '+urlParams);
        
        //PageReference pageRef = new PageReference(url+urlParams);
        
        return url+urlParams;
        
        //System.debug('#pageRef '+pageRef);
        
        //return pageRef.getUrl();   
    }
    
    /** given a field and a record, returns the field value as a string */
    public static String getValue(String sourceField, sObject record){
        
        String result = '';
        
        if (record == null){
            return result;
        }
        
        if (sourceField.contains('.')){
            List<String> fieldComponents =  sourceField.split('\\.');
            
            sObject genericSObject = record.getSObject(fieldComponents[0]);
            
            if (genericSObject != null && genericSObject.get(fieldComponents[1]) != null){
                
                result = String.valueOf(genericSObject.get(fieldComponents[1]));
            }
        }
        else{
            result = String.valueOf(record.get(sourceField));
        }
        return result;
    }
    
    /** retrieves the sobject with the fields defined in the autopopulate custom setting */
    public sObject getSobject(List<UNITY_Autopopulate_Mapping__c> settings){
        
        Set<String> fieldsProcessed = new Set<String>();
        
        String fieldsToQuery;
        
        for (UNITY_Autopopulate_Mapping__c iter: settings){
            
            if (!fieldsProcessed.contains(iter.Source_Field__c)){
                
                if (fieldsToQuery == null) {
                    fieldsToQuery = iter.Source_Field__c;
                }else {
                    fieldsToQuery += ','+ iter.Source_Field__c;
                }
                
                fieldsProcessed.add(iter.Source_Field__c);
            }            
        }
        
        if (fieldsToQuery == null){
            fieldsToQuery = 'id';
        }
        
        String queryString = 'Select '+fieldsToQuery+' from '+sourceSObject+' where Id=\''+parentId+'\'';
        
        System.debug('#queryString '+queryString);
        
        List<sObject> recordList = Database.query(queryString);
        
        if (!recordList.isEmpty()){
            return recordList.get(0);
        }
        
        return null;
    }
    

    public static Map<String, String> getRelationshipLookupMap(Set<String> parents, String child){
        
        Map<String, String> result = new Map<String, String>();
        
        //List<UNITY_TemplateConfigRelationshipLookups__c> settings = [select UNITY_Parent_Object__c, UNITY_Child_Object__c, UNITY_Parent_Lookup_Field__c from UNITY_TemplateConfigRelationshipLookups__c where UNITY_Child_Object__c =: child];
        
        for (UNITY_TemplateConfigRelationshipLookups__c iter: UNITY_TemplateConfigRelationshipLookups__c.getAll().values()){
            
            if (iter.UNITY_Child_Object__c == child){
                result.put(iter.UNITY_Parent_Object__c, iter.UNITY_Parent_Lookup_Field__c);
            }  
        }
        
        return result;
    }
    
    
    
    public static void autopopulateFieldsIfApplicableBulkified(List<sObject> recordList, String sObjectType){
        
        System.debug('#recordList '+recordList);
        
        // see what sobjects (parent) are related with the target (child) in the autopopulate mapping
        List<UNITY_Autopopulate_Mapping__c> settings = getMappingSettingsAnySourceObject(sObjectType);
        
        //related sObjects
        Set<String> relatedParent = new Set<String>();
        
        for (UNITY_Autopopulate_Mapping__c iter: settings){
            
            relatedParent.add(iter.Source_Object__c);
        }
        
        System.debug('#relatedParent '+relatedParent);
        
        //get the field name for the lookup relationship with the parent
        Map<String, String> lookupMap = getRelationshipLookupMap(relatedParent, sObjectType);
        
        //get settings for the specific sObjectType
        Map<String, List<UNITY_Autopopulate_Mapping__c>> settingsMap = getMappingSettingsForSpecificTarget(sObjectType);
        
        //Map<parentObjectName, List<parentId>>
        Map<String, List<Id>> parentIdMap = new  Map<String, List<Id>>();
        
        System.debug('#lookupMap '+lookupMap);
        
        for (String iter: relatedParent){
            
            System.debug('#parent '+iter);
            
            parentIdMap.put(iter, new List<Id>());
            
            String lookupField = lookupMap.get(iter);
            
            for (sObject record: recordList){ 
                
                System.debug('#lookupField '+lookupField);
                
                if ((lookupField != null) && (record.get(lookupField) != null)){
                    
                    String parentId = (Id)record.get(lookupField);
                   
                    parentIdMap.get(iter).add(parentId);
                }
            }        
        }
        
        //get target object field map
        Map<String, Schema.sObjectField> targetFieldMap = Schema.getGlobalDescribe().get(sObjectType).getDescribe().fields.getMap();
        
        Integer parentCount = 0;
            
        //populate fields from parent to target records
        for (String iter: relatedParent){
            
            if (parentCount == MAX_PARENTS){
                break;
            }
            parentCount++;
            
            //get related parents
            Map<Id, sObject> parentMap = getParents(settingsMap.get(iter), parentIdMap.get(iter), iter);
        
            String lookupField = lookupMap.get(iter);
            
            for (sObject record: recordList){ 
                
                if (record.get(lookupField) != null){
                    
                    String parentId = (Id)record.get(lookupField);
                    
                    autopopulateFieldsOnChildBulkified(record, settingsMap.get(iter), parentMap.get(parentId), targetFieldMap);
                }
            }        
        }
    }
    
    public static Map<Id, sObject> getParents(List<UNITY_Autopopulate_Mapping__c> settings, List<Id> parentIds, String sObjectType){
        
        Map<Id, sObject> result = new Map<Id, sObject>();
        
        Set<String> fieldsProcessed = new Set<String>();
        
        String fieldsToQuery;
        
        for (UNITY_Autopopulate_Mapping__c iter: settings){
            
            if (!fieldsProcessed.contains(iter.Source_Field__c)){
                
                if (fieldsToQuery == null) {
                    fieldsToQuery = iter.Source_Field__c;
                }else {
                    fieldsToQuery += ','+ iter.Source_Field__c;
                }
                
                fieldsProcessed.add(iter.Source_Field__c);
            }            
        }
        
        if (fieldsToQuery == null){
            fieldsToQuery = 'id';
        }
        
        String queryString = 'Select '+fieldsToQuery+' from '+sObjectType+' where Id in:parentIds';
        
        System.debug('#queryString '+queryString);
        
        List<sObject> recordList = Database.query(queryString);
        
        for (sObject iter: recordList){
            result.put(iter.Id, iter);
        }
        
        return result;
    }
    
    public static void autopopulateFieldsOnChildBulkified(sObject targetRecord, List<UNITY_Autopopulate_Mapping__c> settings, sObject parentRecord, Map<String, Schema.sObjectField> targetFieldMap){
        
        System.debug('#targetRecord '+targetRecord);
        
        if (!settings.isEmpty()){
            
            if (targetRecord != null){
                
                for (UNITY_Autopopulate_Mapping__c iter: settings){
                    
                    String targetField = iter.Target_Field__c;
                    
                    if (iter.UI_Only__c == false ){
                        
                        System.debug('#iter.Source_Field__c '+iter.Source_Field__c);
                        
                        String value = getValue(iter.Source_Field__c, parentRecord);
                        
                        System.debug('#targetField '+targetField);
                        
                        if (value!= '' && value != 'null' && value != null){
                            
                            if(targetFieldMap.containsKey(targetField)){
                                Schema.DisplayType targetFieldType = targetFieldMap.get(targetField).getDescribe().getType();
                                
                                //if(!targetFieldMap.get(targetField).getDescribe().isUpdateable()) {
                                //    throw new AutopopulateException('Autopopulate from '+iter.Source_Object__c+' to '+iter.Target_Object__c+'. '+targetField+' is not Editable.');
                                //}
                                if(targetFieldMap.get(targetField).getDescribe().isUpdateable() && (targetRecord.get(targetField) == null || (targetRecord.get(targetField) != null && !iter.UNITY_DoNotOverwrite__c)) ) {
                                    
                                    if(targetFieldType == Schema.DisplayType.Currency || targetFieldType == Schema.DisplayType.Double|| targetFieldType == Schema.DisplayType.Percent){
                                        targetRecord.put(targetField, Decimal.valueOf(value)); 
                                    }
                                    else if(targetFieldType == Schema.DisplayType.Boolean){
                                        targetRecord.put(targetField, Boolean.valueOf(value)); 
                                    }                   
                                    else if(targetFieldType == Schema.DisplayType.Date){
                                        targetRecord.put(targetField, Date.valueOf(value)); 
                                    }                
                                    else{
                                        targetRecord.put(targetField,value);
                                    }
                                }
                            }
                        }
                    }                 
                }
            }
        }
        
        System.debug('#record '+targetRecord);
        
    }
    
    public class AutopopulateException extends Exception {}
}