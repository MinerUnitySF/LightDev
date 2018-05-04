/**
 *   @programer:    Rodrigo Birriel 
 *   @description: Wrapper class to access the custom setting UNITY SL Mapping.
 *   @date:         02/12/2015
 */
global with sharing class UNITY_Mule2SalesforceMappingUtils {
    
    static {
        buildMultipleMaps();
    }
    
    public static String MU_CUSTOMER            = 'Customer';
    public static String MU_VENDOR              = 'Vendor';
    public static String MU_INVOICE             = 'Invoice';
    public static String MU_INVOICE_LINE        = 'InvoiceLine';
    
    public static String MU_PURCHASE_ORDER      = 'PurchaseOrder';
    public static String MU_PURCHASE_ORDER_LINE = 'PurchaseOrderLine';
    
    public static String SF_ACCOUNT             = 'Account';
    public static String SF_INVOICE             = 'UNITY_Invoice__c';
    public static String SF_INVOICE_LINE        = 'UNITY_Invoice_Line_Item__c';
    public static String SF_PURCHASE_ORDER      = 'Order';
    public static String SF_PURCHASE_ORDER_LINE = 'OrderItem';
    
    private static Map<String, Map<String,List<String>>>    sourceFieldToTargetFieldMap;
    private static Map<String, List<String>>        sourceListFieldsMap;
    private static Map<String, Map<String,List<String>>>    targetFieldToSourceFieldMap;
    private static Map<String, List<String>>        targetListFieldsMap; 
    private static Map<String, Map<String,String>>  pickListMap;
    
    //only support one extra tag per object
    private static Map<String, List<String>>        siblingTagsMuleMap;
    private static Map<String, List<String>>        siblingsFieldMap;
    
    //only support one level parent-children
    private static Map<String, Set<String>>        hierarchyMap;
    
    private static Map<String, String>              mule2SFMap;
    private static Map<String, String>              sf2MuleMap;
    private static Map<String, String>              tagsMuleMap;
    
    /**
     *  Given a sourcetype string value,
     *  returns the source fields related to it.
     */ 
    public static List<String> getSourceFields(String sourceTypeName) {
        List<String> fields = new List<String>();
        if(sourceListFieldsMap.get(sourceTypeName) != null) {
            fields = sourceListFieldsMap.get(sourceTypeName);
        }
        return fields;
    }
    
    /**
     *  Given a targettype string value,
     *  returns the target fields related to it.
     */ 
    public static List<String> getTargetFields(String targetTypeName) {
        System.debug('targetListFieldsMap:targetTypeName --->'+targetListFieldsMap+':'+targetTypeName);
        List<String> fields = new List<String>();
        if(targetListFieldsMap.get(targetTypeName) != null) {
            fields = targetListFieldsMap.get(targetTypeName);
        }
        return fields;
    }
    
    /**
     *  Given a targettype string value,
     *  returns the target fields related to it.
     */ 
    public static List<String> getTargetFieldsBySourceTarget(String sourceTypeName) {
        return getTargetFieldsBySourceTarget(sourceTypeName, false);
    }
    
    /**
     *  Given a targettype string value,
     *  returns the target fields related to it.
     */ 
    public static List<String> getTargetFieldsBySourceTarget(String sourceTypeName, Boolean allowDuplicated) {
        List<String> targetFields = new List<String>();
        System.debug('sourceFieldToTargetFieldMap ---> '+sourceFieldToTargetFieldMap);
        if(sourceFieldToTargetFieldMap.get(sourceTypeName) != null){
            // removing duplicated fields if not allowed
            for(List<String> fields : sourceFieldToTargetFieldMap.get(sourceTypeName).values()) {
                targetFields.addAll(fields);
            }
            if(!allowDuplicated){
                targetFields = new List<String>(new Set<String>(targetFields));   
            }
        }
        System.debug('targetFields --->'+targetFields);
        return targetFields;
    }
    
    /**
     *  Given sourcetype string and sourcefield string,
     *  returns the mapped field in the target object
     */ 
    public static List<String> getTargetField(String sourceTypeName, String sourceFieldName) {
        List<String> targetField;
        Map<String,List<String>> sourceTargetFieldMatchMap = sourceFieldToTargetFieldMap.get(sourceTypeName);
        if(sourceTargetFieldMatchMap != null) {
            targetField = sourceTargetFieldMatchMap.get(sourceFieldName);
        }
        return targetField;
    }
    
    /**
     *  Given targettype string and targetfield string,
     *  returns the mapped field in the target object
     */ 
    public static List<String> getSourceField(String targetTypeName, String targetFieldName) {
        List<String> sourceField;
        Map<String,List<String>> targetTargetFieldMatchMap = targetFieldToSourceFieldMap.get(targetTypeName);
        if(targetTargetFieldMatchMap != null) {
            sourceField = targetTargetFieldMatchMap.get(targetFieldName);
        }
        return sourceField;
    }
    
    public static List<Map<String,Object>> createMuleObjects(List<Id> idList, String muleTypeName) {
        String sfTypeName = mule2SFMap.get(muleTypeName);
        List<Map<String,Object>> muleObjects = new List<Map<String,Object>>();
        System.debug('muleTypeName ---> '+muleTypeName);
        // retrive the concerning records
        UNITY_Mule2SalesforceMappingUtils.HierarchyFieldsObject hierarchyFieldsObject = UNITY_Mule2SalesforceMappingUtils.getHierarchyFields(muleTypeName);
        
        System.debug('hierarchyFieldsObject ---> '+hierarchyFieldsObject);
        Map<String, Schema.ChildRelationship> childRelationshipMap = new Map<String, Schema.ChildRelationship>();
        for (Schema.ChildRelationship childRelationship : Schema.getGlobalDescribe().get(hierarchyFieldsObject.objectName).getDescribe().getChildRelationships()) {
            childRelationshipMap.put(childRelationship.getChildSObject().getDescribe().getName(),childRelationship);
        }
        
        String queryString = 'SELECT ';
        queryString += UNITY_Utils.getQueryFields(hierarchyFieldsObject.fields);
        for(UNITY_Mule2SalesforceMappingUtils.HierarchyFieldsObject childHierarchy : hierarchyFieldsObject.children) {
            if(childRelationshipMap.get(childHierarchy.objectName) !=null && 
               childHierarchy.fields != null && !childHierarchy.fields.isEmpty()) {
                   queryString +=',('; 
                   queryString += 'SELECT '+UNITY_Utils.getQueryFields(childHierarchy.fields);
                   queryString += ' FROM '+childRelationshipMap.get(childHierarchy.objectName).getRelationshipName();
                   if(muleTypeName == 'Invoice' && childHierarchy.objectName == 'UNITY_Invoice_Line_Item__c'){
                       queryString += ' WHERE UNITY_Line_Status__c != \'Cancelled\' ';
                   }
                   queryString +=')';   
            }
        }
        queryString += ' FROM '+hierarchyFieldsObject.objectName+' WHERE Id IN: idList';
    
        System.debug('queryString --->'+queryString);
        // create the related muleobjects
        for(SObject obj : Database.query(queryString)) {
            //CLAY - if muleTypeName is case then look for the status we need out of the 
            //case map from the case Id to service channel status map
            if(muleTypeName == 'Case' && UNITY_UpdateCaseStatus.caseIdToScStatusMap != null){
                if(UNITY_UpdateCaseStatus.caseIdToScStatusMap.containsKey((String)obj.get('Id'))) {

                    obj.put('UNITY_Service_Channel_Status__c', UNITY_UpdateCaseStatus.caseIdToScStatusMap.get((String)obj.get('Id')));
                }
            }
            // populate the parent record
            system.debug('(muleTypeName,obj) ---> '); //('+muleTypeName+','+obj+')'
            system.debug(JSON.serializePretty(obj));

            system.debug('CLAY:');            
            Map<String,Object> muleObject = UNITY_Mule2SalesforceMappingUtils.populateMuleObject(muleTypeName,obj);
            
            
            
            // create new dictionary with tags for object and children objects
            Map<String,Object> muleObjectContainer = new Map<String,Object>();
            muleObjectContainer.put(tagsMuleMap.get(generateCompoundKeyPickLst(muleTypeName,sfTypeName)), muleObject);   
            muleObjects.add(muleObjectContainer);
            
            // extra tags
            if(siblingTagsMuleMap.get(muleTypeName) != null){
                for(String tag : siblingTagsMuleMap.get(muleTypeName)) {
                    if(siblingsFieldMap.get(generateCompoundKeyPickLst(muleTypeName,tag)) != null) {
                        Map<String,String> extraTagMap = new Map<String,String>();
                        for(String field : siblingsFieldMap.get(generateCompoundKeyPickLst(muleTypeName,tag))) {
                            extraTagMap.put(field, (String)muleObject.get(field));
                        }
                        
                        if(!extraTagMap.values().isEmpty()){
                            muleObjectContainer.put(tag, extraTagMap);  
                        }
                                    
                        System.debug(' >>> extraTagMap :'+extraTagMap);
                    }
                }
            }
            
            // populate the children records
            for(UNITY_Mule2SalesforceMappingUtils.HierarchyFieldsObject childHierarchy : hierarchyFieldsObject.children) {
                if(childRelationshipMap.get(childHierarchy.objectName) !=null && 
                    childHierarchy.fields != null && !childHierarchy.fields.isEmpty()) {
                        String relationshipField = childRelationshipMap.get(childHierarchy.objectName).getRelationshipName();
                        List<SObject> childrenSObjects = obj.getSObjects(relationshipField);
                        if(childrenSObjects != null && !childrenSObjects.isEmpty()){
                            system.debug('sf2MuleMap ---> '+sf2MuleMap);
                            system.debug('childrenSObjects --->'+childrenSObjects);
                            String childSObjectTypeName = childrenSObjects.getSObjectType().getDescribe().getName();
                            
                            String muleChildTypeName = sf2MuleMap.get(childSObjectTypeName);
                            system.debug('(muleChildTypeName,childrenSObjects) ---> ('+muleChildTypeName+','+childrenSObjects+')');
                            
                            List<Map<String,Object>> childrenMuleObjects = UNITY_Mule2SalesforceMappingUtils.populateMuleObjects(muleChildTypeName,childrenSObjects);   
                            
                            // add new tag as key , value as children mule objects
                            muleObjectContainer.put(tagsMuleMap.get(generateCompoundKeyPickLst(muleChildTypeName,childSObjectTypeName)), childrenMuleObjects);
                        }
               }
            }
        }
        return muleObjects;
        //return UNITY_Mule2SalesforceMappingUtils.populateMuleObject(muleTypeName,sobjects);
    }
    
    public static Boolean populateSObject(String sourceType, Map<String,String> values, SObject currentObject) {
        Boolean populatedForSomeFields = false;
        for(String key : values.keySet()) {
            List<String> fields = getTargetField(sourceType,key);
            System.debug('sourceFieldToTargetFieldMap --->>>>'+sourceFieldToTargetFieldMap);
            System.debug('fields --->>>>'+key+sourceType+fields);
            if(fields != NULL && !fields.isEmpty()) {
                for(String field : fields) {
                    String value;
                    //check if the field is a picklist
                    Map<String,String> picklistValuesMap = pickListMap.get(generateCompoundKeyPickLst(sourceType,key));
                    if(picklistValuesMap != null) {
                        value = picklistValuesMap.get(values.get(key));
                    } else{
                        value = values.get(key);
                    }
                    populatedForSomeFields = populatedForSomeFields || value !=null;
                    currentObject.put(field,value);   
                }   
            }
        }
        return populatedForSomeFields;
    }
    
    public static Map<String,Object> populateMuleObject(String muleTypeName, SObject obj) {
        return populateMuleObjects(muleTypeName,new List<SObject>{obj}).get(0);
    }
    
    public static List<Map<String,Object>> populateMuleObjects(String muleTypeName, List<SObject> objs) {
        List<Map<String,Object>> muleMapList = new List<Map<String,Object>>();
        if(!objs.isEmpty()) {
            String targetName = objs.get(0).getSObjectType().getDescribe().getName();
            Map<String, Schema.SObjectField> sObjectFieldMap = objs.get(0).getSObjectType().getDescribe().fields.getMap();
            for(SObject obj : objs) {
                System.debug('CLAY: populateMuleObjects in the Mule2SalesforceMappingUtils class');
                System.debug('Here is the muleTypeName: ' + muleTypeName);
                System.debug('obj --->'+JSON.serializePretty(obj));
                Map<String,Object> muleMap = new Map<String,Object>();
                for(String targetField : UNITY_Mule2SalesforceMappingUtils.getTargetFieldsBySourceTarget(muleTypeName, true)) {
                    List<String> sourceFields = getSourceField(targetName,targetField);
                    //System.debug('sourceFieldToTargetFieldMap --->'+sourceFieldToTargetFieldMap);
                    //System.debug('targetName:targetField:sourceFields ---> '+targetName+':'+targetField+':'+sourceFields);
                    if(sourceFields != NULL && !sourceFields.isEmpty()) {
                        for(String sourceField : sourceFields) {
                            if(sourceFieldToTargetFieldMap.get(muleTypeName).get(sourceField) != null) {
                                //check if the field is a picklist
                                Map<String,String> picklistValuesMap = pickListMap.get(generateCompoundKeyPickLst(targetName,targetField));
                                Object value = retrieveValue(obj,targetField);
                                Schema.DisplayType fieldType;
                                if(sObjectFieldMap.get(targetField) != null) {
                                    fieldType = sObjectFieldMap.get(targetField).getDescribe().getType();
                                }
                                if( value == null) {
                                    if(sObjectFieldMap.get(targetField) != null) {
                                        fieldType = sObjectFieldMap.get(targetField).getDescribe().getType();
                                    }
                                    if(fieldType == Schema.DisplayType.CURRENCY || fieldType == Schema.DisplayType.INTEGER ||
                                       fieldType == Schema.DisplayType.DOUBLE) 
                                    {
                                       value = 0;
                                    } else {
                                       value = '';
                                    }
                                } else if(fieldType == Schema.DisplayType.DATETIME || fieldType == Schema.DisplayType.DATE) {
                                    value = String.valueOf(value);
                                }
                                
                                System.debug('value --->'+value);
                                if(picklistValuesMap != null) {
                                    value = picklistValuesMap.get((String)value); 
                                }
                                muleMap.put(sourceField,value);   
                            }   
                        }
                    }
                }
                if(!muleMap.keySet().isEmpty()) {
                    muleMapList.add(muleMap);   
                }
            }    
        }      
        return muleMapList;
    }
        
    private static void buildMultipleMaps() {
        //CLAY - this is always running for everycallout? Any criteria we can add to this?
        sourceFieldToTargetFieldMap = new Map<String, Map<String,List<String>>>();
        sourceListFieldsMap = new Map<String, List<String>>();
        targetFieldToSourceFieldMap = new Map<String, Map<String,List<String>>>();
        targetListFieldsMap = new Map<String, List<String>>();
        pickListMap = new Map<String, Map<String,String>>();
        hierarchyMap = new Map<String, Set<String>>();
        mule2SFMap = new Map<String, String>();
        sf2MuleMap = new Map<String, String>();
        tagsMuleMap = new Map<String, String>();
        siblingTagsMuleMap = new Map<String, List<String>>();
        siblingsFieldMap = new Map<String, List<String>>();
        
        for(UNITY_MuleFieldMapping__c    fieldItem : UNITY_MuleFieldMapping__c.getAll().values()) {
            
            if(fieldItem.IsActive__c) {
                
                //building field list fields map
                if(targetListFieldsMap.get(fieldItem.TargetType__c ) == null) {
                    targetListFieldsMap.put(fieldItem.TargetType__c , new List<String>());
                }
                List<String> currentTargetFieldList = targetListFieldsMap.get(fieldItem.TargetType__c );
                
                currentTargetFieldList.add(fieldItem.TargetField__c);
                
                //building target map target field to source field
                if(targetFieldToSourceFieldMap.get(fieldItem.TargetType__c) == null) {
                    targetFieldToSourceFieldMap.put(fieldItem.targetType__c, new Map<String, List<String>>());
                }
                
                Map<String,List<String>> currentTargetSourceFieldsMap = targetFieldToSourceFieldMap.get(fieldItem.TargetType__c);
                if(currentTargetSourceFieldsMap.get(fieldItem.TargetField__c) == null) {
                    currentTargetSourceFieldsMap.put(fieldItem.TargetField__c  , new List<String>());
                }
                currentTargetSourceFieldsMap.get(fieldItem.TargetField__c).add(fieldItem.SourceField__c);
                
                //building source list fields map
                if(sourceListFieldsMap.get(fieldItem.SourceType__c ) == null) {
                    sourceListFieldsMap.put(fieldItem.SourceType__c , new List<String>());
                }
                List<String> currentSourceFieldList = sourceListFieldsMap.get(fieldItem.SourceType__c );
                
                currentSourceFieldList.add(fieldItem.SourceField__c);
                
                //building source map source field to target field
                if(sourceFieldToTargetFieldMap.get(fieldItem.SourceType__c) == null) {
                    sourceFieldToTargetFieldMap.put(fieldItem.SourceType__c, new Map<String,List<String>>());
                }
                
                Map<String,List<String>> currentSourceTargetFieldsMap = sourceFieldToTargetFieldMap.get(fieldItem.SourceType__c);
                if(currentSourceTargetFieldsMap.get(fieldItem.SourceField__c) == null) {
                    currentSourceTargetFieldsMap.put(fieldItem.SourceField__c  , new List<String>());
                }
                currentSourceTargetFieldsMap.get(fieldItem.SourceField__c).add(fieldItem.TargetField__c);
            
                // populate siblingTagsMuleMap and siblingsFieldMap
                if(fieldItem.Sibling_Tags__c != null) {
                    if(siblingTagsMuleMap.get(fieldItem.SourceType__c) == null) {
                        siblingTagsMuleMap.put(fieldItem.SourceType__c, new List<String>());
                        siblingsFieldMap.put(generateCompoundKeyPickLst(fieldItem.SourceType__c,
                                                                        fieldItem.Sibling_Tags__c), new List<String>());
                    }
                    siblingTagsMuleMap.get(fieldItem.SourceType__c).add(fieldItem.Sibling_Tags__c);
                    siblingsFieldMap.get(generateCompoundKeyPickLst(fieldItem.SourceType__c,
                                                                        fieldItem.Sibling_Tags__c)).add(fieldItem.SourceField__c);
                }
                
                //System.debug(' >>> siblingTagsMuleMap :'+siblingTagsMuleMap);
                //System.debug(' >>> siblingsFieldMap :'+siblingsFieldMap);
                
                // populate the mapping mule2sf and the reverse map
                mule2SFMap.put(fieldItem.SourceType__c,fieldItem.TargetType__c);
                sf2MuleMap.put(fieldItem.TargetType__c,fieldItem.SourceType__c);
            }
            
            
        } 
        
        /*
         *
         * sourceFieldToTargetFieldMap = new Map<String, Map<String,List<String>>>();
        sourceListFieldsMap = new Map<String, List<String>>();
        targetFieldToSourceFieldMap = new Map<String, Map<String,List<String>>>();
        targetListFieldsMap = new Map<String, List<String>>(); 
         * 
         */
        //System.debug(' >>> sourceFieldToTargetFieldMap :'+sourceFieldToTargetFieldMap);
        //System.debug(' >>> sourceListFieldsMap :'+sourceListFieldsMap);
        //System.debug(' >>> targetFieldToSourceFieldMap :'+targetFieldToSourceFieldMap);
        //System.debug(' >>> targetListFieldsMap :'+targetListFieldsMap);
        // populate the mapping keeping bidirectional access to target or source picklist values
        for(UNITY_MulePicklistMapping__c pickItem : UNITY_MulePicklistMapping__c.getAll().values()) {
            
            //for source picklist
            String key = generateCompoundKeyPickLst(pickItem.SourceType__c,pickItem.SourceField__c);
            if(pickListMap.get(key) == null) {
                pickListMap.put(key, new Map<String,String>());
            }
            pickListMap.get(key).put(pickItem.SourceValue__c,pickItem.TargetValue__c);
            
            //for target picklist
            key = generateCompoundKeyPickLst(pickItem.TargetType__c,pickItem.TargetField__c);
            if(pickListMap.get(key) == null) {
                pickListMap.put(key, new Map<String,String>());
            }
            pickListMap.get(key).put(pickItem.TargetValue__c,pickItem.SourceValue__c);
        }
        
        // populate the hierarchy of mule or salesforce objects
        for(UNITY_MuleHierarchyMapping__c hierarchyItem : UNITY_MuleHierarchyMapping__c.getAll().values()) {
            
            if(hierarchyMap.get(hierarchyItem.Parent__c) == null) {
               hierarchyMap.put(hierarchyItem.Parent__c, new Set<String>());
            }
            hierarchyMap.get(hierarchyItem.Parent__c).add(hierarchyItem.Child__c);
            tagsMuleMap.put(generateCompoundKeyPickLst(hierarchyItem.Name,hierarchyItem.Parent__c), hierarchyItem.Tag__c);
        }
    
    }
    
    private static String generateCompoundKeyPickLst(String atype, String field) {
        return atype+field;
    }
    
    // navigate to the top parent to retrieve its value, ex: Account__r.Contact__r.Name
    private static Object retrieveValue(SObject obj, String fieldName) {
        SObject parentObj = obj;
        Object value;
        List<String> parentsObj = fieldName.split('\\.');
        while(parentObj != null && !parentsObj.isEmpty()) {
            String topElem = parentsObj.remove(0);
            // this is the fieldValue
            if(parentsObj.size() == 0){
                value = parentObj.get(topElem);
            }else {
                // go deep to the next parent object
                parentObj = parentObj.getSObject(topElem);
            }
        }
        return value;
    }

    public static HierarchyFieldsObject getHierarchyFields(String muleTypeName) {
        System.debug('hierarchyMap ---> '+hierarchyMap);
        HierarchyFieldsObject hierarchyFieldsObject = new HierarchyFieldsObject();
        // asign the corresponding sf object
        hierarchyFieldsObject.objectName = mule2SFMap.get(muleTypeName);
        hierarchyFieldsObject.fields = getTargetFieldsBySourceTarget(muleTypeName);
        getHierarchyFieldsRecursive(hierarchyFieldsObject);

        return hierarchyFieldsObject;
    }
    
    private static void getHierarchyFieldsRecursive(HierarchyFieldsObject parentHierarchyObject) {
        Set<String> childrenObjects = hierarchyMap.get(parentHierarchyObject.objectName);
        if(childrenObjects != null) {
            for(String childObject : hierarchyMap.get(parentHierarchyObject.objectName)) {
                HierarchyFieldsObject childHierarchyFields = new HierarchyFieldsObject();
                childHierarchyFields.objectName = childObject;
                childHierarchyFields.fields = getTargetFields(childHierarchyFields.objectName);
                parentHierarchyObject.children.add(childHierarchyFields);
                getHierarchyFieldsRecursive(childHierarchyFields);
            }   
        }
    }
    
    public class HierarchyFieldsObject{
        public String objectName;
        public List<String> siblingTags = new List<String>();
        public List<String> fields = new List<String>();
        public List<HierarchyFieldsObject> children = new List<HierarchyFieldsObject>();
    }
}