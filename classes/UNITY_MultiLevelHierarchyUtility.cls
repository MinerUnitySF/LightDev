public with sharing class UNITY_MultiLevelHierarchyUtility {

    public static Map<String,String> relationshipLookupsMap = new Map<String,String>();
    public static Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();  
    public static String TEMPLATE_CONFIG_EXT_ID_FIELDNAME = 'UNITY_Template_Config_Ext_ID__c';
    
    // used just for pricebook
    
    // Map<recordId, PriceBookId> 
    public static Map<Id, Id> priceBookMap {get;set;}
    // Map<PriceBookId+ProductId. PriceBookEntryId>
    public static Map<String, PricebookEntry> priceBookEntryMap {get;set;}
    public static Id standardPriceBookId {get;set;}
    
    static {
        Map<String, UNITY_TemplateConfigRelationshipLookups__c> relationshipLookupsCS = UNITY_TemplateConfigRelationshipLookups__c.getAll();
        for (UNITY_TemplateConfigRelationshipLookups__c relationshipLookup: relationshipLookupsCS.values()){
            String relationship = relationshipLookup.UNITY_Child_Object__c + '->' + relationshipLookup.UNITY_Parent_Object__c;
            String lookupField = relationshipLookup.UNITY_Parent_Lookup_Field__c;
            relationshipLookupsMap.put(relationship,lookupField);
        } 
        standardPriceBookId = UNITY_Constants.getStandardPriceBookId();
        
    }

    public static Map<Id,HierarchyNode> getHierarchies(List<UNITY_Template_Configuration__c> topLevelTemplateConfigs) {
        Map<Id,HierarchyNode> nodes = new Map<Id,HierarchyNode>();
        Set<Id> parentTemplateConfigIds = new Set<Id>();
     
        for (UNITY_Template_Configuration__c templateConfig : topLevelTemplateConfigs) {
            nodes.put(templateConfig.Id, new HierarchyNode(templateConfig));
            parentTemplateConfigIds.add(templateConfig.Id);
        }
     
        while (parentTemplateConfigIds.size() > 0) {
            Map<Id,UNITY_Template_Configuration__c> subordinateTemplateConfigs =
                new Map<Id,UNITY_Template_Configuration__c>([
                    SELECT Id, UNITY_Template_Parent__c , Name, UNITY_Applicable_Template__c, UNITY_Product_Type__c, UNITY_Product_Activity_Type__c, UNITY_Node_Type__c, UNITY_Node_Value__c, UNITY_Part_Lookup__c, UNITY_Target_Object__c, UNITY_Target_Object_Record_Type__c
                    FROM UNITY_Template_Configuration__c
                    WHERE UNITY_Template_Parent__c IN :parentTemplateConfigIds
                ]);
     
            parentTemplateConfigIds = subordinateTemplateConfigs.keySet();
     
            for (UNITY_Template_Configuration__c templateConfig : subordinateTemplateConfigs.values()) {
                HierarchyNode new_node = new HierarchyNode(templateConfig);
                nodes.put(templateConfig.id, new_node);
                HierarchyNode ref_node = nodes.get(templateConfig.UNITY_Template_Parent__c);
                ref_node.children.add(new_node);
            }
        }
        return nodes;
    }

    //Utility method for debugging. DO NOT USE!
    public static void printAllChildrenNames(List<UNITY_Template_Configuration__c> topLevelTemplateConfigs, Map<Id,HierarchyNode> nodes) {
        for (UNITY_Template_Configuration__c templateConfig : topLevelTemplateConfigs) {
            HierarchyNode ref_node = nodes.get(templateConfig.id);
            Set<Id> child_templateConfig_ids = traverseChildren(ref_node.children, nodes);
            List<String> names = new List<String>();
     
            for (Id ref_id : child_templateConfig_ids) {
                names.add(nodes.get(ref_id).node.name);
            }
            System.debug('ALL CHILDREN = ' + String.join(names, ', '));
        }
    }

    public static sObject[] createRelatedSObjects(Map<Id,HierarchyNode> nodes, String parentObjectType, Id parentId){
        sObject[] sObjectsToBeCreated = new List<sObject>();
        
        for (HierarchyNode currentNode : nodes.values()){
            sObjectsToBeCreated = traverseChildren(currentNode,parentObjectType, parentId, null);                   
        }
        
        return sObjectsToBeCreated;
    }
    
    public static sObject[] traverseChildren(HierarchyNode currentNode, String parentObjectType, Id parentId, sObject referenceObject){
        sObject[] newObjects = new List<sObject>();

        UNITY_Template_Configuration__c tempConfig = currentNode.node;
        List<UNITY_Template_Configuration_Line_Item__c> TCLIs = tempConfig.UNITY_Template_Configuration_Line_Items__r;
        
        String applicableTemplate =  tempConfig.UNITY_Applicable_Template__c;
        String nodeType = tempConfig.UNITY_Node_Type__c;
        String nodeValue = tempConfig.UNITY_Node_Value__c;
        String productType = tempConfig.UNITY_Product_Type__c;
        String productActivityType = tempConfig.UNITY_Product_Activity_Type__c;
        Id partLookup = tempConfig.UNITY_Part_Lookup__c;
        String targetObjectName = tempConfig.UNITY_Target_Object__c;
        String targetObjectRecordType = tempConfig.UNITY_Target_Object_Record_Type__c;
        Schema.SObjectType targetObjectType = gd.get(targetObjectName);
        sObject targetObject = targetObjectType.newSObject();
        String parentLookupField = relationshipLookupsMap.get(targetObjectName+'->'+parentObjectType);
        
        System.debug('#parentObjectType '+parentObjectType);
        System.debug('#targetObjectName '+targetObjectName);
        System.debug('#parentLookupField '+parentLookupField);
        if (parentId!=null){
            targetObject.put(parentLookupField, parentId);
        }else{
            Schema.SObjectField oField= targetObjectType.getDescribe().fields.getMap().get(parentLookupField);
            Schema.DescribeFieldResult dfr = oField.getDescribe();
            targetObject.putSObject(dfr.getRelationshipName(), referenceObject);
        } 
        if (TCLIs.size()>0){
            for (UNITY_Template_Configuration_Line_Item__c TCLI : TCLIs){
                Schema.sObjectType objectDef = gd.get(targetObjectName).getDescribe().getSObjectType();
                Map<String, Schema.SobjectField> ObjectFieldsMap = objectDef.getDescribe().fields.getMap();
                String fieldType = ObjectFieldsMap.get(TCLI.UNITY_Target_Object_Field__c).getDescribe().getType().name().ToLowerCase();
                System.debug('#fieldType '+fieldType);
                    
                if(fieldType == 'currency' || fieldType == 'double' || fieldType == 'percent' || fieldType == 'decimal' )
                {
                    targetObject.put(TCLI.UNITY_Target_Object_Field__c, decimal.valueOf(TCLI.UNITY_Target_Object_Field_Value__c.trim())); 
                }
                else if(fieldType == 'boolean')
                {
                    targetObject.put(TCLI.UNITY_Target_Object_Field__c, Boolean.valueOf(TCLI.UNITY_Target_Object_Field_Value__c)); 
                }                   
                else if(fieldType == 'date')
                {
                    targetObject.put(TCLI.UNITY_Target_Object_Field__c, date.valueOf(TCLI.UNITY_Target_Object_Field_Value__c)); 
                }                
                else
                {
                    targetObject.put(TCLI.UNITY_Target_Object_Field__c, TCLI.UNITY_Target_Object_Field_Value__c);
                }
            }
        }
        if (targetObjectName=='WorkOrder'){
            targetObject.put('Subject','Test Work Order from Hierarchy');
        }
        else if (targetObjectName=='UNITY_Proposal_Line_Item__c'){
            targetObject.put('UNITY_Quantity__c',Decimal.valueof(nodeValue));
            targetObject.put('UNITY_Product__c',partLookup);
            targetObject.put('UNITY_Type__c', productType);
            targetObject.put('UNITY_Activity_Type__c', productActivityType);
        }
        else if (targetObjectName=='Order'){
            targetObject.put('Pricebook2Id',standardPriceBookId);
            targetObject.put('Status','Draft');
            targetObject.put('EffectiveDate', Date.today());
        }
        else if (targetObjectName=='OrderItem'){
            targetObject.put('Quantity',Decimal.valueof(nodeValue));
            
            Id priceBookId = priceBookMap.get(parentId);
            if (priceBookId == null){
                priceBookId = standardPriceBookId;
            }
            Id productId = partLookup;
            
            System.debug('#priceBookEntryMap '+priceBookEntryMap);
            
            PricebookEntry pbE = priceBookEntryMap.get((string)priceBookId+(string)productId);
            targetObject.put('PricebookEntryId',pbE.Id);
            targetObject.put('UnitPrice',pbE.UnitPrice);
            targetObject.put('UNITY_Type__c', productType);
            targetObject.put('UNITY_Activity_Type__c', productActivityType);
        }
        else if (targetObjectName=='Asset'){
            targetObject.put('Product2Id',partLookup);
        }       
        newObjects.add(targetObject);   
        
        targetObject.put(TEMPLATE_CONFIG_EXT_ID_FIELDNAME,String.valueof(Datetime.now().getTime()));
        for (HierarchyNode childNode : currentNode.children) {
            sObject targetReferenceObject = targetObjectType.newSObject();
            //targetReferenceObject.put(TEMPLATE_CONFIG_EXT_ID_FIELDNAME,String.valueof(Datetime.now().getTime()));
            targetReferenceObject.put(TEMPLATE_CONFIG_EXT_ID_FIELDNAME,targetObject.get(TEMPLATE_CONFIG_EXT_ID_FIELDNAME));
            System.debug(newObjects);
            newObjects.addAll(traverseChildren(childNode,targetObjectName, null,targetReferenceObject));
        }
        return newObjects;
    }
     
    public static Set<Id> traverseChildren(List<HierarchyNode> children, Map<Id,HierarchyNode> nodes) {
        Set<Id> templateConfigIds = new Set<Id>();
        for (HierarchyNode ref_node : children) {
            templateConfigIds.add(ref_node.node.id);
            templateConfigIds.addAll(traverseChildren(ref_node.children, nodes));
        }
        return templateConfigIds;
    }


    // Add children nodes
    private static void addChildren(List<UNITY_Template_Configuration__c> templateConfigs, Map<Id,HierarchyNode> nodes, Set<Id> parentTemplateConfigIds) {
        for (UNITY_Template_Configuration__c templateConfig : templateConfigs) {
            HierarchyNode ref_node = nodes.get(templateConfig.UNITY_Template_Parent__c);
            HierarchyNode new_node = new HierarchyNode(templateConfig, ref_node);
            if (ref_node != null) {
                ref_node.children.add(new_node);
            }else{
                //nodes.put(templateConfig.id, new_node);
            }
            nodes.put(templateConfig.id, new_node);
            if (parentTemplateConfigIds != null) {
                parentTemplateConfigIds.add(templateConfig.id);
            }
        }
    }
     
    public static Map<Id,HierarchyNode> getHierarchiesOptimized(List<UNITY_Template_Configuration__c> topLevelTemplateConfigs) {
        Set<Id> parentTemplateConfigIds = new Set<Id>();
        Map<Id,HierarchyNode> nodes = new Map<Id,HierarchyNode>();
        for (UNITY_Template_Configuration__c templateConfig : topLevelTemplateConfigs) {
            nodes.put(templateConfig.Id, new HierarchyNode(templateConfig));
            parentTemplateConfigIds.add(templateConfig.Id);
        }
        return getHierarchiesOptimized(parentTemplateConfigIds, nodes);
    }
 
    // Queries 3 Levels (not including the top level) at a time, doesn't return the top level node in the map.
    public static Map<Id,HierarchyNode> getHierarchiesOptimized(Set<Id> topTemplateConfigIds) {
        
        Map<Id,HierarchyNode> result;
        
        Map<Id,HierarchyNode> nodes = new Map<Id,HierarchyNode>();
        Set<Id> parentTemplateConfigIds = topTemplateConfigIds;
     
        while (parentTemplateConfigIds.size() > 0) {
            Map<Id,UNITY_Template_Configuration__c> subordinateTemplateConfigs =
            new Map<Id,UNITY_Template_Configuration__c>([
                SELECT Id, Name, UNITY_Applicable_Template__c, UNITY_Product_Type__c, UNITY_Product_Activity_Type__c, UNITY_Node_Type__c, UNITY_Node_Value__c, UNITY_Part_Lookup__c, UNITY_Target_Object__c, UNITY_Target_Object_Record_Type__c,
                       UNITY_Template_Parent__c,
                       UNITY_Template_Parent__r.UNITY_Template_Parent__c,
                       UNITY_Template_Parent__r.UNITY_Template_Parent__r.UNITY_Template_Parent__c,
                       (Select Id, UNITY_Target_Object_Field__c, UNITY_Target_Object_Field_Value__c from UNITY_Template_Configuration_Line_Items__r)
                FROM   UNITY_Template_Configuration__c
                WHERE (UNITY_Template_Parent__c IN :parentTemplateConfigIds) OR
                      (UNITY_Template_Parent__r.UNITY_Template_Parent__c IN :parentTemplateConfigIds) OR
                      (UNITY_Template_Parent__r.UNITY_Template_Parent__r.UNITY_Template_Parent__c IN :parentTemplateConfigIds)]);
     
            List<UNITY_Template_Configuration__c> level1TemplateConfigs = new List<UNITY_Template_Configuration__c>();
            List<UNITY_Template_Configuration__c> level2TemplateConfigs = new List<UNITY_Template_Configuration__c>();
            List<UNITY_Template_Configuration__c> level3TemplateConfigs = new List<UNITY_Template_Configuration__c>();
     
            // Split UNITY_Template_Configuration__cs in levels
            for (UNITY_Template_Configuration__c templateConfig : subordinateTemplateConfigs.values()) {
                if (templateConfig.UNITY_Template_Parent__c != null) {
                    if (parentTemplateConfigIds.contains(templateConfig.UNITY_Template_Parent__c)) {
                        level1TemplateConfigs.add(templateConfig);
                    }
                    else if (templateConfig.UNITY_Template_Parent__r.UNITY_Template_Parent__c != null) {
                        if (parentTemplateConfigIds.contains(templateConfig.UNITY_Template_Parent__r.UNITY_Template_Parent__c)) {
                            level2TemplateConfigs.add(templateConfig);
                        }
                        else if (templateConfig.UNITY_Template_Parent__r.UNITY_Template_Parent__r.UNITY_Template_Parent__c != null) {
                            if (parentTemplateConfigIds.contains(templateConfig.UNITY_Template_Parent__r.UNITY_Template_Parent__r.UNITY_Template_Parent__c)) {
                                level3TemplateConfigs.add(templateConfig);
                            }
                        }
                    }
                }
            }
     
            Set<Id> next_parentTemplateConfigIds = new Set<Id>();
     
            // Add children on all levels found, one level at a time
        
            addChildren(level1TemplateConfigs, nodes, null);
            
            if (result == null){
                result = nodes.clone();
            }
            
            System.debug('#nodes1 '+nodes);
            
            addChildren(level2TemplateConfigs, nodes, null);
            
            System.debug('#nodes2 '+nodes);
            addChildren(level3TemplateConfigs, nodes, next_parentTemplateConfigIds);
            
            System.debug('#nodes3 '+nodes);
               
            // Use lowest level of UNITY_Template_Configuration__c ids for next SOQL query
            parentTemplateConfigIds = next_parentTemplateConfigIds;
        }
        return nodes;
    }


    // Queries 3 Levels (not including the top level) at a time, returns top level node as well.
    public static Map<Id,HierarchyNode> getHierarchiesOptimized(Set<Id> topTemplateConfigIds, Map<Id,HierarchyNode> nodes) {
        Set<Id> parentTemplateConfigIds = topTemplateConfigIds;
     
        while (parentTemplateConfigIds.size() > 0) {
            Map<Id,UNITY_Template_Configuration__c> subordinateTemplateConfigs =
            new Map<Id,UNITY_Template_Configuration__c>([
                SELECT Id, Name, UNITY_Applicable_Template__c, UNITY_Product_Type__c, UNITY_Product_Activity_Type__c, UNITY_Node_Type__c, UNITY_Node_Value__c, UNITY_Part_Lookup__c, UNITY_Target_Object__c, UNITY_Target_Object_Record_Type__c,
                       UNITY_Template_Parent__c,
                       UNITY_Template_Parent__r.UNITY_Template_Parent__c,
                       UNITY_Template_Parent__r.UNITY_Template_Parent__r.UNITY_Template_Parent__c
                FROM   UNITY_Template_Configuration__c
                WHERE (UNITY_Template_Parent__c IN :parentTemplateConfigIds) OR
                      (UNITY_Template_Parent__r.UNITY_Template_Parent__c IN :parentTemplateConfigIds) OR
                      (UNITY_Template_Parent__r.UNITY_Template_Parent__r.UNITY_Template_Parent__c IN :parentTemplateConfigIds)]);
     
            List<UNITY_Template_Configuration__c> level1TemplateConfigs = new List<UNITY_Template_Configuration__c>();
            List<UNITY_Template_Configuration__c> level2TemplateConfigs = new List<UNITY_Template_Configuration__c>();
            List<UNITY_Template_Configuration__c> level3TemplateConfigs = new List<UNITY_Template_Configuration__c>();
     
            // Split UNITY_Template_Configuration__cs in levels
            for (UNITY_Template_Configuration__c templateConfig : subordinateTemplateConfigs.values()) {
                if (templateConfig.UNITY_Template_Parent__c != null) {
                    if (parentTemplateConfigIds.contains(templateConfig.UNITY_Template_Parent__c)) {
                        level1TemplateConfigs.add(templateConfig);
                    }
                    else if (templateConfig.UNITY_Template_Parent__r.UNITY_Template_Parent__c != null) {
                        if (parentTemplateConfigIds.contains(templateConfig.UNITY_Template_Parent__r.UNITY_Template_Parent__c)) {
                            level2TemplateConfigs.add(templateConfig);
                        }
                        else if (templateConfig.UNITY_Template_Parent__r.UNITY_Template_Parent__r.UNITY_Template_Parent__c != null) {
                            if (parentTemplateConfigIds.contains(templateConfig.UNITY_Template_Parent__r.UNITY_Template_Parent__r.UNITY_Template_Parent__c)) {
                                level3TemplateConfigs.add(templateConfig);
                            }
                        }
                    }
                }
            }
     
            Set<Id> next_parentTemplateConfigIds = new Set<Id>();
     
            // Add children on all levels found, one level at a time
        
            addChildren(level1TemplateConfigs, nodes, null);
            addChildren(level2TemplateConfigs, nodes, null);
            addChildren(level3TemplateConfigs, nodes, next_parentTemplateConfigIds);

            // Use lowest level of UNITY_Template_Configuration__c ids for next SOQL query
            parentTemplateConfigIds = next_parentTemplateConfigIds;
        }
        return nodes;
    }

    // Class that is used as nodes in the UNITY_Template_Configuration__c hierarchy tree built by this class
    public class HierarchyNode {
        public HierarchyNode parent;
        public UNITY_Template_Configuration__c node;
        public List<HierarchyNode> children;
     
        HierarchyNode(UNITY_Template_Configuration__c templateConfig, HierarchyNode parent) {
            this.parent = parent;
            this.node = templateConfig;
            this.children = new List<HierarchyNode>();
        }
     
        HierarchyNode(UNITY_Template_Configuration__c templateConfig) {
            this.parent = null;
            this.node = templateConfig;
            this.children = new List<HierarchyNode>();
        }
    }
}