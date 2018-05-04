@isTest
public class UNITY_Mule2Salesforce_MappingUtilsTest {

    public static String objectType1    = 'Customer';
    public static String objectType2    = 'Account1';
    public static String objectType3    = 'Vendor';
    public static String objectType4    = 'Invoice';
    
    public static String targetType1    = 'Account';
    public static String targetType2    = 'UNITY_Invoice__c';
    
    public static String field1         = 'Add1';
    public static String field2         = 'BillingAddress';
    public static String field3         = 'Add2';
    public static String field4         = 'ShippingAddress';
    public static String field5         = 'Name';
    public static String field6         = 'Name';
    public static String field7         = 'Status';
    public static String field8         = 'Account_Status__c';
    public static String field9         = 'VendId';
    public static String field10        = 'Id';
    
    public static String sourceField1   = field1;
    public static String targetField1   = field2;
    
    public static String sourceField2   = field3;
    public static String targetField2   = field4;
    
    public static String sourceField3   = field5;
    public static String targetField3   = field6;
    
    public static String sourceField4   = field7;
    public static String targetField4   = field8;
    
    public static String sourceField5   = field9;
    public static String targetField5   = field10;
        
    public static String sourceValue1   = 'sourceValue1';
    public static String targetValue1   = 'targetValue1';
    
    public static String sourceValue2   = 'A';
    public static String targetValue2   = 'Active';
    
    public static String sourceValue3   = 'I';
    public static String targetValue3   = 'Inactive';
    
    public static String siblingTag     = 'siblingTag1';
    
    static testMethod void testFineValuesSuccess() {
        
        setUp();
        
        Test.startTest();
        List<String> sourceFields = UNITY_Mule2SalesforceMappingUtils.getSourceFields(objectType1);
        List<String> sourceFields2 = UNITY_Mule2SalesforceMappingUtils.getSourceField(objectType1, field1);
        List<String> targetField = UNITY_Mule2SalesforceMappingUtils.getTargetField(objectType1, field1);
        List<String> targerFields = UNITY_Mule2SalesforceMappingUtils.getTargetFields(objectType1);
        System.assert(!UNITY_Mule2SalesforceMappingUtils.getTargetFieldsBySourceTarget(objectType1).isEmpty());
        System.assert(!UNITY_Mule2SalesforceMappingUtils.getTargetFieldsBySourceTarget(objectType1,true).isEmpty());
        
        Test.stopTest();
        
        System.assert(!sourceFields.isEmpty(),'The list should not be empty ' + sourceFields.size());
        System.assert(targetField.get(0) == field2,'The targetField value should be ' + field2);
        System.assert(!sourceFields.isEmpty(),'The list should not be empty ' + sourceFields.size());
        
    }
    
    static testMethod void createSObjectAndMuleObjectTestSuccess() {
        Account accountVendor = UNITY_TestDataFactory.createAccounts(1,'Customer',UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE).get(0);
        List<Map<String,Object>> muleObjectList = UNITY_Mule2SalesforceMappingUtils.createMuleObjects(new List<Id>{accountVendor.Id}, UNITY_MuleSiteSettingUtils.VENDOR);
        System.assert(!muleObjectList.isEmpty());
        Map<String,String> newMap = new Map<String,String>();
        newMap.put(sourceField4, sourceValue3);
        System.assert(UNITY_Mule2SalesforceMappingUtils.populateSObject(UNITY_MuleSiteSettingUtils.VENDOR, newMap, accountVendor));
    }
    
    public static void setUp() {
        
        if(UNITY_MuleFieldMapping__c.getAll().values().isEmpty()) {
            // insert fields mapping
            List<UNITY_MuleFieldMapping__c> fieldStoreSettingList = new List<UNITY_MuleFieldMapping__c>();
            UNITY_MuleFieldMapping__c fieldStoreSetting1 = new UNITY_MuleFieldMapping__c();
            fieldStoreSetting1.Name = 'sourceTargetMap1';
            fieldStoreSetting1.SourceType__c = objectType1;
            fieldStoreSetting1.SourceField__c = sourceField1;
            fieldStoreSetting1.TargetType__c = objectType1;
            fieldStoreSetting1.TargetField__c = targetField1;
            fieldStoreSettingList.add(fieldStoreSetting1);
            
            UNITY_MuleFieldMapping__c fieldStoreSetting2 = new UNITY_MuleFieldMapping__c();
            fieldStoreSetting2.Name = 'sourceTargetMap2';
            fieldStoreSetting2.SourceType__c = objectType1;
            fieldStoreSetting2.SourceField__c = sourceField2;
            fieldStoreSetting2.TargetType__c = objectType1;
            fieldStoreSetting2.TargetField__c = targetField2;
            fieldStoreSettingList.add(fieldStoreSetting2);
            
            //vendor setting
            
            UNITY_MuleFieldMapping__c fieldStoreSetting3 = new UNITY_MuleFieldMapping__c();
            fieldStoreSetting3.Name = 'Vendor sourceField5';
            fieldStoreSetting3.SourceType__c = objectType2;
            fieldStoreSetting3.SourceField__c = field7;
            fieldStoreSetting3.TargetType__c = targetType1;
            fieldStoreSetting3.TargetField__c = targetField3;
            fieldStoreSettingList.add(fieldStoreSetting3);
            
            UNITY_MuleFieldMapping__c fieldStoreSetting4 = new UNITY_MuleFieldMapping__c();
            fieldStoreSetting4.Name = 'Vendor sourceField7';
            fieldStoreSetting4.SourceType__c = objectType3;
            fieldStoreSetting4.SourceField__c = sourceField4;
            fieldStoreSetting4.TargetType__c = targetType1;
            fieldStoreSetting4.TargetField__c = targetField4;
            fieldStoreSetting4.Sibling_Tags__c = siblingTag;
            fieldStoreSettingList.add(fieldStoreSetting4);
            
            UNITY_MuleFieldMapping__c fieldStoreSetting5 = new UNITY_MuleFieldMapping__c();
            fieldStoreSetting5.Name = 'Vendor sourceField9';
            fieldStoreSetting5.SourceType__c = objectType2;
            fieldStoreSetting5.SourceField__c = sourceField5;
            fieldStoreSetting5.TargetType__c = objectType2;
            fieldStoreSetting5.TargetField__c = targetField5;
            fieldStoreSettingList.add(fieldStoreSetting5);
            
            UNITY_MuleFieldMapping__c fieldStoreSetting6 = new UNITY_MuleFieldMapping__c();
            fieldStoreSetting6.Name = 'Invoice Name';
            fieldStoreSetting6.SourceType__c = objectType4;
            fieldStoreSetting6.SourceField__c = sourceField5;
            fieldStoreSetting6.TargetType__c = targetType2;
            fieldStoreSetting6.TargetField__c = targetField5;
            fieldStoreSettingList.add(fieldStoreSetting6);
            
            insert fieldStoreSettingList;
            system.debug(' fieldStoreSettingList ----> '+fieldStoreSettingList);
            
            // insert picklist mapping
            List<UNITY_MulePicklistMapping__c> picklistMappings = new List<UNITY_MulePicklistMapping__c>();
            UNITY_MulePicklistMapping__c picklistMapping1 = new UNITY_MulePicklistMapping__c();
            picklistMapping1.Name = 'Name1';
            picklistMapping1.SourceType__c = objectType3;
            picklistMapping1.SourceField__c = sourceField4;
            picklistMapping1.SourceValue__c  = sourceValue2;
            picklistMapping1.TargetType__c = targetType1;
            picklistMapping1.TargetField__c = targetField4;
            picklistMapping1.TargetValue__c  = targetValue2;
            picklistMappings.add(picklistMapping1);
            
            UNITY_MulePicklistMapping__c picklistMapping2 = new UNITY_MulePicklistMapping__c();
            picklistMapping2.Name = 'Name2';
            picklistMapping2.SourceType__c = objectType3;
            picklistMapping2.SourceField__c = sourceField4;
            picklistMapping2.SourceValue__c  = sourceValue3;
            picklistMapping2.TargetType__c = targetType1;
            picklistMapping2.TargetField__c = targetField4;
            picklistMapping2.TargetValue__c  = targetValue3;
            picklistMappings.add(picklistMapping2);
            
            insert picklistMappings;
            
            // insert hierarchy mapping
            UNITY_MuleHierarchyMapping__c hierarchyMapping = new UNITY_MuleHierarchyMapping__c();
            hierarchyMapping.Name = objectType3;
            hierarchyMapping.Parent__c = targetType1;
            hierarchyMapping.Child__c = 'Contact';
            hierarchyMapping.Tag__c = 'Tag1';
            hierarchyMapping.Sibling_Tags__c = siblingTag;
            
            insert hierarchyMapping;
            
            // insert mule template
            UNITY_Mule_Template__c template1 = new UNITY_Mule_Template__c();
            template1.Name = objectType4; 
            template1.Template__c = '<tag ID="1">text</tag>';
            
            insert template1;
                
        }
        
    }
    
}