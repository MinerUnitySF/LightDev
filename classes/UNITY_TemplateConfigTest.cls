@isTest
public class UNITY_TemplateConfigTest {
    
}
/*
    static testMethod void  templateForCase() { 
        
        String  TEST_TEMPLATE  =  'test_template';  
        String  SOBJECT_TYPE   =  'Case';  
        String  SOBJECT_RECORDTYPE  =  'Project Phase';  
        String  NODE_TYPE  =  'Subject';  
        String  NODE_VALUE =  'Subject';
        Integer MAX_CASE_RECORDS = 10;
        
        List<Account> accounts = new List<Account>();
        
        // create accounts 
        Account aliAccount = new Account();
        aliAccount.RecordTypeId  = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
        aliAccount.Name = 'Ali Customer Account';
        aliAccount.UNITY_LOC__c = 'LOC_001';
        aliAccount.UNITY_Subscriber_ID__c = 'Subscriber ID 001';
        accounts.add(aliAccount);
        
        Account alexAccount = new Account();
        alexAccount.RecordTypeId = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
        alexAccount.Name = 'Alex Customer Account';
        alexAccount.UNITY_LOC__c = 'LOC_002';
        alexAccount.UNITY_Subscriber_ID__c = 'Subscriber ID 002';
        alexAccount.BillingCity        = 'Columbus';
        alexAccount.BillingState       = 'OH';
        alexAccount.BillingPostalCode  = '43221-123';
        alexAccount.BillingCountry     = 'US';
        alexAccount.BillingStreet      = '2743 Mount Holyoke Rd';
        accounts.add(alexAccount);
        
        insert accounts;
        
        UNITY_Template_Configuration__c topParent = new UNITY_Template_Configuration__c ();
        topParent.RecordTypeId          = UNITY_Constants.TEMPLATE_CONFIG_PROJECT_RECORDTYPE;
        topParent.UNITY_Template_Parent__c = null;
        topParent.Name                  = TEST_TEMPLATE;
        insert topParent;
        
        UNITY_Template_Configuration__c caseChileT = new UNITY_Template_Configuration__c ();
        caseChileT.RecordTypeId             = UNITY_Constants.TEMPLATE_CONFIG_PROJECT_RECORDTYPE;
        caseChileT.UNITY_Template_Parent__c = topParent.id;
        caseChileT.Name                     = TEST_TEMPLATE;
        caseChileT.UNITY_Level_Number__c    = 1;
        caseChileT.UNITY_Node_Type__c       = NODE_TYPE;
        caseChileT.UNITY_Node_Value__c      = NODE_VALUE;
        caseChileT.UNITY_Target_Object__c   = SOBJECT_TYPE;
        caseChileT.UNITY_Target_Object_Record_Type__c = SOBJECT_RECORDTYPE;
        insert caseChileT;
        
        UNITY_Template_Configuration__c woChildT = new UNITY_Template_Configuration__c ();
        woChildT.RecordTypeId             = UNITY_Constants.TEMPLATE_CONFIG_PROJECT_RECORDTYPE;
        woChildT.UNITY_Template_Parent__c = caseChileT.id;
        woChildT.Name                     = TEST_TEMPLATE;
        woChildT.UNITY_Level_Number__c    = 3;
        woChildT.UNITY_Node_Type__c       = 'Subject';
        woChildT.UNITY_Node_Value__c      = NODE_VALUE;
        woChildT.UNITY_Target_Object__c   = 'WorkOrder ';
        woChildT.UNITY_Target_Object_Record_Type__c = UNITY_Constants.WO_SERVICE_REQUEST;
        insert woChildT;
        
        UNITY_Template_Configuration__c taskChileT = new UNITY_Template_Configuration__c ();
        taskChileT.RecordTypeId             = UNITY_Constants.TEMPLATE_CONFIG_PROJECT_RECORDTYPE;
        taskChileT.UNITY_Template_Parent__c = caseChileT.id;
        taskChileT.Name                     = TEST_TEMPLATE;
        taskChileT.UNITY_Level_Number__c    = 3;
        taskChileT.UNITY_Node_Type__c       = 'Subject';
        taskChileT.UNITY_Node_Value__c      = 'Call';
        taskChileT.UNITY_Target_Object__c   = 'Task';
        taskChileT.UNITY_Target_Object_Record_Type__c = UNITY_Constants.TASK_UNITY_TASK;
        insert taskChileT;
        
        
        list<Case>  cases = new list<Case>();
            
        for(integer i = 0 ; i < MAX_CASE_RECORDS ; i++){
            
            Case  newCase = new Case();
            newCase.RecordTypeId = UNITY_Constants.CASE_PROJECT_MANAGEMENT_RECORDTYPE;
            newCase.Subject =  'test-'+i;
            newCase.UNITY_PM_Template__c = topParent.id;
            newCase.AccountId         = aliAccount.id;
            newCase.UNITY_End_User__c = alexAccount.id;
            newCase.UNITY_Customer__c = aliAccount.id;
            cases.add(newCase);
            
        }
        
        Test.startTest();
            
           
            insert cases;
            list<Case> casesCreatedByTemplate = new list<Case>([SELECT id, ParentId FROM Case WHERE RecordType.Name = :SOBJECT_RECORDTYPE  ]);
            
            Set<id>  caseIds = new Set<id>();
            
            System.assertEquals(MAX_CASE_RECORDS, casesCreatedByTemplate.size(), 'Should be created '+MAX_CASE_RECORDS+' Cases.' );
        
            for(Case onCase :cases){
                caseIds.add(onCase.id);
            }
        
            for(Case onCase :casesCreatedByTemplate){
                if(caseIds.contains(onCase.ParentId)){
                    caseIds.remove(onCase.ParentId);
                }
            }
        
            System.assertEquals(0, caseIds.size(), 'Should be 1 Case created by Template Config created per Project Managment Case.' );
        
        Test.stopTest();
        
        
        
    }
    
    static testMethod void  templateForOrders() { 
        
        String  SOBJECT_TYPE   = 'OrderItem';
        String  SOBJECT_RECORDTYPE = '';
        String  TEST_TEMPLATE  =  'test_template'; 
        Integer MAX_CASE_RECORDS = 10;
        
        id  standardBookId = Test.getStandardPricebookId();
        
        Product2 car = new Product2();
        car.Name = 'test_prod';
        car.IsActive = true ;
        car.Description  = 'test_prod test_prod';
        insert car;
        
        PricebookEntry pbEntry = new PricebookEntry();
        pbEntry.Pricebook2Id = standardBookId;
        pbEntry.Product2Id   = car.id;
        pbEntry.IsActive     = true;
        pbEntry.UnitPrice    = 34;
        pbEntry.UseStandardPrice = false;
        insert pbEntry;
        
        // create accounts 
        Account aliAccount = new Account();
        aliAccount.RecordTypeId  = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
        aliAccount.Name = 'Ali Customer Account';
        aliAccount.UNITY_LOC__c = 'LOC_001';
        aliAccount.UNITY_Subscriber_ID__c = 'Subscriber ID 001';
        insert aliAccount;
        
        UNITY_Template_Configuration__c topParent = new UNITY_Template_Configuration__c ();
        topParent.RecordTypeId             = UNITY_Constants.TEMPLATE_CONFIG_PURCHASE_ORDER_RECORDTYPE;
        topParent.UNITY_Template_Parent__c = null;
        topParent.Name                     = TEST_TEMPLATE;
        insert topParent;
        
        UNITY_Template_Configuration__c orderItemChileT = new UNITY_Template_Configuration__c ();
        orderItemChileT.RecordTypeId             = UNITY_Constants.TEMPLATE_CONFIG_PURCHASE_ORDER_RECORDTYPE;
        orderItemChileT.UNITY_Template_Parent__c = topParent.id;
        orderItemChileT.Name                     = TEST_TEMPLATE;
        orderItemChileT.UNITY_Level_Number__c    = 2;
        //orderItemChileT.UNITY_Node_Type__c       = NODE_TYPE;
        //orderItemChileT.UNITY_Node_Value__c      = NODE_VALUE;
        orderItemChileT.UNITY_Target_Object__c   = SOBJECT_TYPE;
        //orderItemChileT.UNITY_Target_Object_Record_Type__c = SOBJECT_RECORDTYPE;
        orderItemChileT.UNITY_Part_Lookup__c     = car.id;
        insert orderItemChileT;
        
        orderItemChileT = new UNITY_Template_Configuration__c ();
        orderItemChileT.RecordTypeId             = UNITY_Constants.TEMPLATE_CONFIG_PURCHASE_ORDER_RECORDTYPE;
        orderItemChileT.UNITY_Template_Parent__c = topParent.id;
        orderItemChileT.Name                     = TEST_TEMPLATE;
        orderItemChileT.UNITY_Level_Number__c    = 2;
        //orderItemChileT.UNITY_Node_Type__c     = NODE_TYPE;
        //orderItemChileT.UNITY_Node_Value__c     = NODE_VALUE;
        orderItemChileT.UNITY_Target_Object__c   = SOBJECT_TYPE;
        orderItemChileT.UNITY_Part_Lookup__c     = car.id;
        //orderItemChileT.UNITY_Target_Object_Record_Type__c = SOBJECT_RECORDTYPE;
        insert orderItemChileT;
        
        Test.startTest();
            Order onOrder = new Order();
            
            onOrder.RecordTypeId = UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE;
            onOrder.AccountId    = aliAccount.id;
            onOrder.UNITY_PO_Template__c = topParent.id;
            onOrder.EffectiveDate  = Date.today(); 
            onOrder.Status = 'Draft';
            onOrder.Pricebook2Id = standardBookId;
            
            insert onOrder;
        Test.stopTest();
        
    }
    
    static testMethod void  templateForProposal() { 
    
    }
    
    
}

*/