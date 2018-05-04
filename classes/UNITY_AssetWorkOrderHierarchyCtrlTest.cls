@isTest
public class UNITY_AssetWorkOrderHierarchyCtrlTest {
    
    /*
     * Name : data_A
     * Data : 
     * 
     */
    static Map<String,Object> data_A() {
        
        Map<String,Object> toReturn = new Map<String,Object>();
        
        Case onCase;
        Account customer;
        FSO__Skill__c onSkill;
        Asset onAsset;
        Contact onContact;
        List<WorkOrder> workOrders = new List<WorkOrder>();
        List<WorkOrderLineItem> workOrderLineItems = new List<WorkOrderLineItem>();
                
        // DATA FIELDS MOCK UP
        Map<String,Object> workOrderFields             = UNITY_TestDataFactory.MOCKUP_WORK_ORDER_FIELDS;
        Map<String,Object> vendorPreferenceFields      = UNITY_TestDataFactory.MOCKUP_VENDOR_TRADE_FIELDS;
        Map<String,Object> vendorPreferenceTradeFields = UNITY_TestDataFactory.MOCKUP_VENDOR_PREFERENCE_TRADE_FIELDS;
        Map<String,Object> vendorTradeFields           = UNITY_TestDataFactory.MOCKUP_VENDOR_TRADE_FIELDS;
        Map<String,Object> vendorLocationFields        = UNITY_TestDataFactory.MOCKUP_VENDOR_LOCATION_FIELDS;
        Map<String,Object> accountFields               = UNITY_TestDataFactory.MOCKUP_ACCOUNT_FIELDS;    
        Map<String,Object> skillFields                 = UNITY_TestDataFactory.MOCKUP_FSO_SKILL_FIELDS;  
        Map<String,Object> workOrderLineItemFields     = UNITY_TestDataFactory.MOCKUP_WORK_ORDER_LINE_ITEM_FIELDS;
        Map<String,Object> caseFields                  = UNITY_TestDataFactory.MOCKUP_CASE_FIELDS;
        
        // CREARE CUSTOMER 
        accountFields.put('ShippingPostalCode', UNITY_Utils.generateRandomPin()+'-'+UNITY_Utils.generateRandomPin());
        accountFields.put('RecordTypeId', UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE);
        accountFields.put('Name', 'C-'+UNITY_Utils.generateRandomPin());
        customer = (Account)UNITY_TestDataFactory.createObject(1, Account.getSObjectType(),accountFields ).get(0);
        insert customer;
        toReturn.put('customer',customer);
        
        onContact = UNITY_TestDataFactory.createContacts(1,customer.Id).get(0);
        toReturn.put('contact',onContact);
        
        // CREARE CUSTOMER 
        onSkill = UNITY_TestDataFactory.createSkills(1, false).get(0);
        insert onSkill;
        toReturn.put('skill',onSkill);
        
        // CREATE SERVICE CONTRACT 
        
        UNITY_Service_Contract__c serviceContract1 = new UNITY_Service_Contract__c();
        
        serviceContract1.UNITY_Account__c = customer.Id;
        serviceContract1.UNITY_Trip_Charge__c = 10;
        serviceContract1.UNITY_Trip_Charge_Type__c = 'Hourly Rate';
        serviceContract1.UNITY_Default_Labor_Rate__c = 75;
        serviceContract1.UNITY_Invoicing_Increments__c = 'Next ¼ hr';
        serviceContract1.UNITY_IS_Active__c = true;
        serviceContract1.RecordTypeId = UNITY_Constants.SC_SERVICE_REQUEST_RECORDTYPE;
        serviceContract1.UNITY_ServiceReport_Template__c = 'my template';
        
        insert serviceContract1;
        
        // CREATE CASE 
        caseFields.put('Customer__c' , customer.id);
        caseFields.put('AccountId'   , customer.id);
        caseFields.put('RecordTypeId', UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
        caseFields.put('UNITY_Trade__c',onSkill.id); 
        caseFields.put('Status','Verified');
        onCase = (Case) UNITY_TestDataFactory.createObject(1, Case.getSObjectType(), caseFields).get(0); 
        insert onCase;
        toReturn.put('case',onCase);
        
        // CREATE WO
        workOrderFields.put('RecordTypeId', UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE);
        workOrderFields.put('AccountId'   , customer.id);
        workOrderFields.put('CaseId'      ,onCase.id);
        workOrderFields.put('UNITY_Customer__c', customer.id);
        workOrderFields.put('UNITY_Trade__c'   , onSkill.id);
        workOrderFields.put('UNITY_Customer_Service_Contract__c',serviceContract1.Id);
        
        for(integer index = 0 ; index<2 ; index ++ ){
            workOrderFields.put('Subject'     , 'WO-Test-'+index);
            workOrders.addAll(UNITY_TestDataFactory.createWorkOrders(1,workOrderFields));
        }
        insert workOrders;
        toReturn.put('workOrders',workOrders);
        
        // CREATE ASSET
        onAsset = new Asset();
        onAsset.Name = 'test asset ';
        onAsset.AccountId = customer.id;
        onAsset.ContactId = onContact.id;
        insert onAsset;
        toReturn.put('asset',onAsset);
        
        // CREATE WORK ORDER LINE ITEMS 
        for(WorkOrder onWO :workOrders){
            workOrderLineItemFields.put('WorkOrderId' , onWO.id);
            workOrderLineItemFields.put('AssetId' , onAsset.id );
            workOrderLineItemFields.put('Description' , 'WOLI for '+onWO.WorkOrderNumber );
            workOrderLineItemFields.put('RecordTypeId' ,UNITY_Constants.WOLI_WORK_ORDER_LINE_ITEM_RECORDTYPE);
            workOrderLineItems.add((WorkOrderLineItem)UNITY_TestDataFactory.createObject(1, WorkOrderLineItem.getSObjectType(), workOrderLineItemFields).get(0));
        }
        insert workOrderLineItems;
        toReturn.put('workOrderItems',workOrderLineItems);

        return toReturn;
    }
    
    static testMethod void controllerTest() {
        
        Map<String,Object> data = data_A();
        Asset onAsset = (Asset)data.get('asset');
        List<WorkOrder> workOrders = (List<WorkOrder>)data.get('workOrders');
        Test.startTest();
            PageReference pageRef = Page.UNITY_AssetWorkOrderHierarchy;
            pageRef.getParameters().put('Id',onAsset.id);
            Test.setCurrentPage(pageRef);
            UNITY_AssetWorkOrderHierarchyController ctrl = new UNITY_AssetWorkOrderHierarchyController(new ApexPages.StandardController(onAsset) ); 
            system.assertEquals(2, ctrl.workOrderMap.size(), 'Should be two WO filtered.');
            ctrl.searchWO = workOrders.get(0).id;
            ctrl.searchWO();
            system.assertEquals(1, ctrl.workOrderMap.size(), 'Should be one WO filtered.');
        Test.stopTest();
        
    }
}