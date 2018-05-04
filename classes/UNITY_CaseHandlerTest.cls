@isTest
public class UNITY_CaseHandlerTest {
    
    private static Map<SObjecttype, Map<String,Object>>  predefinedValues = new Map<SObjecttype, Map<String,Object>>();

    private static WorkOrder wo;
    private static Asset rootAsset;
    private static Asset childAsset;
    private static UNITY_Invoice__c invoice;
    private static Case onCase;
    

    static testMethod void closedStatusCase() {

        setupDataA();

        Test.startTest();
            //List<Case> cases = [SELECT id, Status FROM Case];
            invoice = new  UNITY_Invoice__c();
            invoice.UNITY_Invoice_Status__c = 'Invoice Finalized';
            invoice.UNITY_Case__c = onCase.Id;
            insert invoice;
            //List<UNITY_Invoice__c> invoices = UNITY_TestDataFactory.createInvoices(1, onCase.Id, onAccount.Id);
            //invoices[0].UNITY_Invoice_Status__c = 'Invoice Finalized';
            //update invoices[0];

            UNITY_Invoice_Line_Item__c woLavel      = new UNITY_Invoice_Line_Item__c(   UNITY_Asset__c            = childAsset.Id,
                                                                                        UNITY_Invoice__c          = invoice.Id,
                                                                                        UNITY_WorkOrder__c        = wo.Id,
                                                                                        UNITY_Sales_Tax__c        = 10,
                                                                                        UNITY_Total_Price__c      = 200);

            UNITY_Invoice_Line_Item__c caseLavel    = new UNITY_Invoice_Line_Item__c(   UNITY_Invoice__c          = invoice.Id ,
                                                                                        UNITY_Sales_Tax__c        = 10,
                                                                                        UNITY_Total_Price__c      = 200);

            UNITY_Invoice_Line_Item__c woAssetLavel = new UNITY_Invoice_Line_Item__c(   UNITY_Invoice__c          = invoice.Id,
                                                                                        UNITY_WorkOrder__c        = wo.Id,
                                                                                        UNITY_Sales_Tax__c        = 10,
                                                                                        UNITY_Total_Price__c      = 200);

            insert  new List<UNITY_Invoice_Line_Item__c>{woLavel,caseLavel,woAssetLavel};
            
            //for(Case onCase :cases ){
                onCase.Status = 'Closed';
                onCase.UNITY_Business_Unit__c  = 'MNS';
            //}
            update onCase;
        Test.stopTest();

    }

    static testMethod void serviceChannelStatusCase() {

        predefinedValues.put(Case.getSObjecttype(), new Map<String,Object>());

        predefinedValues.get(Case.getSObjecttype()).put('UNITY_Case_Notes__c'            , 'Test');
        predefinedValues.get(Case.getSObjecttype()).put('UNITY_Portal_Source__c'         , UNITY_Constants.CASE_PORTAL_SOURCE_SERVICE_CHANNEL);
        predefinedValues.get(Case.getSObjecttype()).put('UNITY_Service_Channel_Status__c', 'OPEN');
        
        setupDataA();

        Test.startTest();
            //List<Case> cases = [SELECT id, Status FROM Case];
            invoice = new  UNITY_Invoice__c();
            invoice.UNITY_Invoice_Status__c = 'Invoice Finalized';
            invoice.UNITY_Case__c = onCase.Id;
            insert invoice;
            //List<UNITY_Invoice__c> invoices = UNITY_TestDataFactory.createInvoices(1, onCase.Id, onAccount.Id);
            //invoices[0].UNITY_Invoice_Status__c = 'Invoice Finalized';
            //update invoices[0];

            UNITY_Invoice_Line_Item__c woLavel      = new UNITY_Invoice_Line_Item__c(   UNITY_Asset__c            = childAsset.Id,
                                                                                        UNITY_Invoice__c          = invoice.Id,
                                                                                        UNITY_WorkOrder__c        = wo.Id,
                                                                                        UNITY_Sales_Tax__c        = 10,
                                                                                        UNITY_Total_Price__c      = 200);

            UNITY_Invoice_Line_Item__c caseLavel    = new UNITY_Invoice_Line_Item__c(   UNITY_Invoice__c          = invoice.Id ,
                                                                                        UNITY_Sales_Tax__c        = 10,
                                                                                        UNITY_Total_Price__c      = 200);

            UNITY_Invoice_Line_Item__c woAssetLavel = new UNITY_Invoice_Line_Item__c(   UNITY_Invoice__c          = invoice.Id,
                                                                                        UNITY_WorkOrder__c        = wo.Id,
                                                                                        UNITY_Sales_Tax__c        = 10,
                                                                                        UNITY_Total_Price__c      = 200);

            insert  new List<UNITY_Invoice_Line_Item__c>{woLavel,caseLavel,woAssetLavel};
            //List<Case> cases = [SELECT id, Status FROM Case];
            //for(Case onCase :cases ){
                onCase.Status = 'Closed'; 
                onCase.UNITY_Case_Notes__c = 'Closed'; 
                onCase.UNITY_Service_Channel_Status__c = 'COMPLETED'; 
            //}
            update onCase;

            delete onCase;

        Test.stopTest();

    }

    static testMethod void changeQueueCase() {
        system.debug([Select QueueId from QueueSobject  where SobjectType = 'Case']);

        setupDataA();
        
        Test.startTest();
            //List<Case> cases = [SELECT id, Status FROM Case];
            invoice = new  UNITY_Invoice__c();
            invoice.UNITY_Invoice_Status__c = 'Invoice Finalized';
            invoice.UNITY_Case__c = onCase.Id;
            insert invoice;
            //List<UNITY_Invoice__c> invoices = UNITY_TestDataFactory.createInvoices(1, onCase.Id, onAccount.Id);
            //invoices[0].UNITY_Invoice_Status__c = 'Invoice Finalized';
            //update invoices[0];

            UNITY_Invoice_Line_Item__c woLavel      = new UNITY_Invoice_Line_Item__c(   UNITY_Asset__c            = childAsset.Id,
                                                                                        UNITY_Invoice__c          = invoice.Id,
                                                                                        UNITY_WorkOrder__c        = wo.Id,
                                                                                        UNITY_Sales_Tax__c        = 10,
                                                                                        UNITY_Total_Price__c      = 200);

            UNITY_Invoice_Line_Item__c caseLavel    = new UNITY_Invoice_Line_Item__c(   UNITY_Invoice__c          = invoice.Id ,
                                                                                        UNITY_Sales_Tax__c        = 10,
                                                                                        UNITY_Total_Price__c      = 200);

            UNITY_Invoice_Line_Item__c woAssetLavel = new UNITY_Invoice_Line_Item__c(   UNITY_Invoice__c          = invoice.Id,
                                                                                        UNITY_WorkOrder__c        = wo.Id,
                                                                                        UNITY_Sales_Tax__c        = 10,
                                                                                        UNITY_Total_Price__c      = 200);

            insert  new List<UNITY_Invoice_Line_Item__c>{woLavel,caseLavel,woAssetLavel};
            //List<Case> cases = [SELECT id, Status FROM Case];
            //for(Case onCase :cases ){
               // onCase.OwnerId = g1.Id; 
            //}
            update onCase;

        Test.stopTest();

    }

    static testMethod void captureParentDataCase() {

        Test.startTest();
            setupDataB();
        Test.stopTest();

    }

    static void setupDataB() {

        // CREATE SKILL
        // CREATE ACCOUNT
        // CREATE SERVICE CONTRACT
        // CREATE CASE PARENT  
        // CREATE CASE CHILD

        Integer MAX_CHILD_CASES  = 10;
        Integer MAX_PARENT_CASES = 10;


        Map<String,Object> caseFields                  = UNITY_TestDataFactory.MOCKUP_CASE_FIELDS;
        Map<String,Object> skillFields                 = UNITY_TestDataFactory.MOCKUP_FSO_SKILL_FIELDS;
        Map<String,Object> contactFields               = UNITY_TestDataFactory.MOCKUP_CONTACT_FIELDS;
        Map<String,Object> accountFields               = UNITY_TestDataFactory.MOCKUP_ACCOUNT_FIELDS;
        Map<String,Object> serviceContractFields       = UNITY_TestDataFactory.MOCKUP_SERVICE_CONTRACT_FIELDS;

        accountFields.put('recordTypeId', UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE);
        accountFields.put('Type', 'Customer');

        Account onAccount = (Account)UNITY_TestDataFactory.createObject(1, Account.getSObjectType() , accountFields).get(0);
        insert onAccount;

        accountFields.put('Type', 'Business Unit');
        accountFields.put('recordTypeId', UNITY_Constants.ACCOUNT_MINER_RECORDTYPE);
        accountFields.put('UNITY_Business_Unit__c', 'MNS');
        accountFields.put('UNITY_Service_Report_Template__c' , 'SRT');

        Account minerAccount   = (Account)UNITY_TestDataFactory.createObject(1, Account.getSObjectType() , accountFields).get(0);
        insert minerAccount;

        contactFields.put('AccountId', onAccount.id);

        Contact cont       = (Contact)UNITY_TestDataFactory.createObject(1, Contact.getSObjectType() , contactFields).get(0);
        insert cont;

        FSO__Skill__c onSkill = (FSO__Skill__c)UNITY_TestDataFactory.createObject(1, FSO__Skill__c.getSObjectType() , skillFields).get(0);
        insert onSkill;


        caseFields.put('Status'           , 'Verified');
        caseFields.put('AccountId'        , onAccount.id);
        caseFields.put('ContactId'        , cont.id);
        caseFields.put('Customer__c'      , onAccount.id);
        caseFields.put('RecordTypeId'     , UNITY_Constants.CASE_PROJECT_PHASE_RECORDTYPE);
        caseFields.put('UNITY_Trade__c'   , onSkill.id);
        caseFields.put('UNITY_Asset_Down__c'    , true);
        caseFields.put('UNITY_Asset_Up_At__c'   , Date.today().addDays(5));
        caseFields.put('UNITY_Asset_Down_At__c' , Date.today());
        caseFields.put('UNITY_Work_Window_End__c'   , Date.today().addDays(10));
        caseFields.put('UNITY_Work_Window_Begin__c' , Date.today());
        caseFields.put('UNITY_Business_Unit__c' , 'MNS');
        caseFields.put('UNITY_Business_Unit_Account__c' , minerAccount.Id);

        List<Case> parents  = (List<Case>) UNITY_TestDataFactory.createObject(MAX_PARENT_CASES, Case.getSObjectType(), caseFields);
        insert parents;

        List<Case> children = new List<Case>();
        for(Case parent :parents){
            caseFields.put('ParentId' , parent.Id);
            children.addAll((List<Case>) UNITY_TestDataFactory.createObject(MAX_CHILD_CASES, Case.getSObjectType(), caseFields));
        }
         

        insert children;   

    }

    static void setupDataA() {

        // CREATE SKILL
        // CREATE ACCOUNT
        // CREATE SERVICE CONTRACT
        // CREATE CASE
        // CREATE WORKORDER
        // CREATE ASSET

        Map<String,Object> caseFields                  = UNITY_TestDataFactory.MOCKUP_CASE_FIELDS;
        Map<String,Object> orderFields                 = UNITY_TestDataFactory.MOCKUP_ORDER_FIELDS;
        Map<String,Object> assetFields                 = new Map<String,Object>();
        Map<String,Object> skillFields                 = UNITY_TestDataFactory.MOCKUP_FSO_SKILL_FIELDS;
        Map<String,Object> contactFields               = UNITY_TestDataFactory.MOCKUP_CONTACT_FIELDS;
        Map<String,Object> accountFields               = UNITY_TestDataFactory.MOCKUP_ACCOUNT_FIELDS;
        Map<String,Object> locationFields              = UNITY_TestDataFactory.MOCKUP_LOCATION_FIELDS;
        Map<String,Object> workOrderFields             = UNITY_TestDataFactory.MOCKUP_WORK_ORDER_FIELDS;
        Map<String,Object> assetHistoryFields          = new Map<String,Object>();
        Map<String,Object> serviceContractFields       = UNITY_TestDataFactory.MOCKUP_SERVICE_CONTRACT_FIELDS;



        accountFields.put('recordTypeId', UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE);
        accountFields.put('Type', 'Customer');

        Account onAccount = (Account)UNITY_TestDataFactory.createObject(1, Account.getSObjectType() , accountFields).get(0);
        onAccount.UNITY_LOC__c = '0123';
        onAccount.UNITY_Subscriber_ID__c = '0123456789';
        insert onAccount;


        assetFields.put('Name'   , 'RootAsset');
        assetFields.put('AccountId', onAccount.Id);
        rootAsset = (Asset)UNITY_TestDataFactory.createObject(1, Asset.getSObjectType() , assetFields).get(0);
        insert rootAsset;

        assetFields.put('Name'   , 'ChildAsset');
        assetFields.put('AccountId', onAccount.Id);
        assetFields.put('ParentId' , rootAsset.Id);
        childAsset = (Asset)UNITY_TestDataFactory.createObject(1, Asset.getSObjectType() , assetFields).get(0);
        insert childAsset;


        accountFields.put('Type', 'Business Unit');
        accountFields.put('recordTypeId', UNITY_Constants.ACCOUNT_MINER_RECORDTYPE);
        accountFields.put('UNITY_Business_Unit__c', 'MNS');
        accountFields.put('UNITY_Service_Report_Template__c' , 'SRT');

        List<Account> accounts = new List<Account>();
        Account minerAccount   = (Account)UNITY_TestDataFactory.createObject(1, Account.getSObjectType() , accountFields).get(0);

        accountFields.put('recordTypeId', UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE);
        accountFields.put('Type', 'Vendor');

        Account vendor = (Account)UNITY_TestDataFactory.createObject(1, Account.getSObjectType() , accountFields).get(0);

        insert new List<Account>{minerAccount,vendor};

        contactFields.put('AccountId', onAccount.id);

        Contact cont       = (Contact)UNITY_TestDataFactory.createObject(1, Contact.getSObjectType() , contactFields).get(0);
        insert cont;

        FSO__Skill__c onSkill = (FSO__Skill__c)UNITY_TestDataFactory.createObject(1, FSO__Skill__c.getSObjectType() , skillFields).get(0);
        insert onSkill;

        caseFields.put('Status'           , 'Verified');
        caseFields.put('AccountId'        , onAccount.id);
        caseFields.put('ContactId'        , cont.id);
        caseFields.put('UNITY_Customer__c', onAccount.id);
        caseFields.put('RecordTypeId'     , UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
        caseFields.put('UNITY_Trade__c'   , onSkill.id);
        caseFields.put('UNITY_Asset_Down__c'    , true);
        caseFields.put('UNITY_Asset_Up_At__c'   , Date.today().addDays(5));
        caseFields.put('UNITY_Asset_Down_At__c' , Date.today());
        caseFields.put('UNITY_Work_Window_End__c'   , Date.today().addDays(10));
        caseFields.put('UNITY_Work_Window_Begin__c' , Date.today());
        caseFields.put('UNITY_Business_Unit__c' , 'MNS');
        caseFields.put('UNITY_Business_Unit_Account__c' , minerAccount.Id);

        if(predefinedValues.get(Case.getSObjectType())!=null)
            for(String field :predefinedValues.get(Case.getSObjectType()).keySet()){
                system.debug('>>> predefinedValues '+field+' / '+predefinedValues.get(Case.getSObjectType()).get(field));
                caseFields.put(field , predefinedValues.get(Case.getSObjectType()).get(field));
            }

        onCase = (Case) UNITY_TestDataFactory.createObject(1, Case.getSObjectType(), caseFields).get(0);
        //CLAY - trying to get the NTE to blank
        onCase.UNITY_NTE_Threshold__c = null;
        onCase.UNITY_LOC__c = '0123';
        onCase.UNITY_Subscriber_ID__c = '0123456789';
        insert onCase;

        
        serviceContractFields.put('RecordTypeId', UNITY_Constants.SC_SERVICE_REQUEST_RECORDTYPE);
        serviceContractFields.put('UNITY_Account__c', onAccount.id);
        serviceContractFields.put('UNITY_IS_Active__c', true);
        serviceContractFields.put('UNITY_End_Customer__c', onAccount.id);
        serviceContractFields.put('UNITY_Business_Unit__c', 'MNS');
        
        serviceContractFields.put('UNITY_Required_Documentation__c', 'Customer-Specific Service Report Sign');
        UNITY_Service_Contract__c c_sc  = (UNITY_Service_Contract__c)UNITY_TestDataFactory.createObject(1, UNITY_Service_Contract__c.getSObjectType(), serviceContractFields).get(0);
        //insert c_sc;

        serviceContractFields.put('UNITY_Business_Unit__c', 'MNS');
        serviceContractFields.put('UNITY_Account__c', minerAccount.id);
        serviceContractFields.put('UNITY_Required_Documentation__c', 'Customer-Specific Service Report Sign');
        UNITY_Service_Contract__c v_sc  = (UNITY_Service_Contract__c)UNITY_TestDataFactory.createObject(1, UNITY_Service_Contract__c.getSObjectType(), serviceContractFields).get(0);
        //insert v_sc;

        UNITY_Service_Contract__c v_sc2 = v_sc.clone(false, false, false, false);
        v_sc2.UNITY_Account__c = vendor.Id;
        //insert v_sc2;

        insert new List<UNITY_Service_Contract__c>{c_sc,v_sc,v_sc2};

        workOrderFields.put('CaseId'            , onCase.id);
        workOrderFields.put('Subject'           , 'WO-Test');
        workOrderFields.put('AccountId'         , onAccount.id);
        workOrderFields.put('RecordTypeId'      , UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE);
        workOrderFields.put('UNITY_Trade__c'    , onSkill.id);
        workOrderFields.put('UNITY_Agent__c'    , UserInfo.getUserId());
        workOrderFields.put('UNITY_Customer__c' , onAccount.id);
        workOrderFields.put('UNITY_Business_Unit__c' , 'MNS');
        workOrderFields.put('UNITY_Vendor_Status__c' , 'Accepted');
        workOrderFields.put('UNITY_Assigned_Vendor__c' , vendor.Id);
        workOrderFields.put('UNITY_Accepted_Vendor__c' , vendor.Id);
        workOrderFields.put('UNITY_Vendor_Contract__c' , v_sc2.id);
        workOrderFields.put('UNITY_Vendor_Dispatcher__c' , UserInfo.getUserId());
        workOrderFields.put('UNITY_Business_Unit_Account__c' , minerAccount.Id);
        workOrderFields.put('SFPS_FS_Is_Vendor_Dispatcher__c' , true);
        workOrderFields.put('UNITY_Customer_Service_Contract__c' , c_sc.id);

        wo  = (WorkOrder)UNITY_TestDataFactory.createObject(1, WorkOrder.getSObjectType(), workOrderFields).get(0);
        insert wo;

        WorkOrderLineItem woli = new WorkOrderLineItem();
        woli.AssetId = childAsset.Id;
        woli.WorkOrderId = wo.Id;
        //insert woli;

        WorkOrderLineItem woli_check_in = new WorkOrderLineItem();
        woli_check_in.Description = Date.today().addDays(1).format()+' : Tech Check-In';
        woli_check_in.WorkOrderId = wo.Id;
        woli_check_in.FSO__IsCompleted__c = true;
        //insert woli_check_in;

        WorkOrderLineItem woli_check_out = new WorkOrderLineItem();
        woli_check_out.Description = Date.today().addDays(5).format()+' : Tech Check-Out';
        woli_check_out.WorkOrderId = wo.Id;
        woli_check_out.FSO__IsCompleted__c = true;
        woli_check_out.SFPS_FS_ServiceTime__c = (1440*4);
        //insert woli_check_out;
        insert new List<WorkOrderLineItem>{woli,woli_check_in,woli_check_out};
        /*
        UNITY_Invoice__c invoice = new  UNITY_Invoice__c();
        invoice.UNITY_Invoice_Status__c = 'Invoice Finalized';
        invoice.UNITY_Case__c = onCase.Id;
        insert invoice;
        //List<UNITY_Invoice__c> invoices = UNITY_TestDataFactory.createInvoices(1, onCase.Id, onAccount.Id);
        //invoices[0].UNITY_Invoice_Status__c = 'Invoice Finalized';
        //update invoices[0];

        UNITY_Invoice_Line_Item__c woLavel      = new UNITY_Invoice_Line_Item__c(   UNITY_Asset__c            = childAsset.Id,
                                                                                    UNITY_Invoice__c          = invoice.Id,
                                                                                    UNITY_WorkOrder__c        = wo.Id,
                                                                                    UNITY_Sales_Tax__c        = 10,
                                                                                    UNITY_Total_Price__c      = 200);

        UNITY_Invoice_Line_Item__c caseLavel    = new UNITY_Invoice_Line_Item__c(   UNITY_Invoice__c          = invoice.Id ,
                                                                                    UNITY_Sales_Tax__c        = 10,
                                                                                    UNITY_Total_Price__c      = 200);

        UNITY_Invoice_Line_Item__c woAssetLavel = new UNITY_Invoice_Line_Item__c(   UNITY_Invoice__c          = invoice.Id,
                                                                                    UNITY_WorkOrder__c        = wo.Id,
                                                                                    UNITY_Sales_Tax__c        = 10,
                                                                                    UNITY_Total_Price__c      = 200);

        insert  new List<UNITY_Invoice_Line_Item__c>{woLavel,caseLavel,woAssetLavel};
        */
    }




    static testMethod void populateAccountOnCaseTest () {
        List<Account> accounts = new List<Account>();
        // create accounts 
        Account aliAccount = new Account();
        aliAccount.RecordTypeId  = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
        aliAccount.Name = 'Ali Customer Account';
        aliAccount.UNITY_LOC__c = 'LOC_001';
        aliAccount.UNITY_Subscriber_ID__c = 'Subscriber ID 001';
        aliAccount.Type ='Customer'; // Added by vaishnavi
        aliAccount.BillingCity = 'billingCity1';
        aliAccount.BillingStateCode = 'NY';
        aliAccount.BillingStreet = '123 Fake St.';
        aliAccount.BillingPostalCode = '123456';
        aliAccount.BillingCountry = 'US';
        accounts.add(aliAccount);
        
        Account alexAccount = new Account();
        alexAccount.RecordTypeId = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
        alexAccount.Name = 'Alex Customer Account';
        alexAccount.UNITY_LOC__c = 'LOC_002';
        alexAccount.UNITY_Subscriber_ID__c = 'Subscriber ID 002';
        alexAccount.Type ='Customer'; // Added by vaishnavi
        alexAccount.BillingCity = 'billingCity2';
        alexAccount.BillingStateCode = 'NY';
        alexAccount.BillingStreet = '123 Fake St.';
        alexAccount.BillingPostalCode = '123456';
        alexAccount.BillingCountry = 'US';
        accounts.add(alexAccount);
        
        insert accounts;
        
        Test.startTest();
        
        List<Case> cases = new List<Case>();
        
        Case oneCase = new Case();
        oneCase.UNITY_LOC__c = aliAccount.UNITY_LOC__c;
        oneCase.UNITY_Subscriber_ID__c = aliAccount.UNITY_Subscriber_ID__c;
        cases.add(oneCase);
        
        Case twoCase = new Case();
        twoCase.UNITY_LOC__c = alexAccount.UNITY_LOC__c;
        twoCase.UNITY_Subscriber_ID__c = alexAccount.UNITY_Subscriber_ID__c;
        cases.add(twoCase);
        
        insert cases;
        Test.stopTest();
    }
    
    static testMethod void populateVendorAccountOnCaseTest () {

        Account aliAccount = new Account();
        aliAccount.RecordTypeId  = UNITY_Constants.ACCOUNT_MINER_RECORDTYPE;
        aliAccount.Name = 'Ali Customer Account';
        aliAccount.UNITY_LOC__c = 'LOC_001';
        aliAccount.UNITY_Business_Unit__c = 'MNS';
        aliAccount.UNITY_Subscriber_ID__c = 'Subscriber ID 001';
        aliAccount.Type ='Business Unit';
        aliAccount.BillingCity = 'billingCity1';
        aliAccount.BillingStateCode = 'NY';
        aliAccount.BillingStreet = '123 Fake St.';
        aliAccount.BillingPostalCode = '123456';
        aliAccount.BillingCountry = 'US';
        aliAccount.Account_Status__c = 'Active';
        aliAccount.UNITY_Vendor_Status__c   = 'Active';
        aliAccount.UNITY_TimeZoneSidKey__c = 'America/Chicago';
        aliAccount.UNITY_Agent_Work_Day__c = 'Monday;Tuesday;Wednesday;Thursday;Friday';
        aliAccount.UNITY_Agent_Work_Hour_Start_Time__c = '08:00';
        aliAccount.UNITY_Agent_Work_Hour_End_Time__c =  '17:00';
        aliAccount.UNITY_Off_Hour_Queue__c = 'UNITY_MNS_After_Hours';
        aliAccount.UNITY_Friday_End_Time__c  = '23:59';
        aliAccount.UNITY_Friday_Start_Time__c = '00:00';
        aliAccount.UNITY_Thursday_End_Time__c = '23:59';
        aliAccount.UNITY_Thursday_Start_Time__c= '00:00';
        aliAccount.UNITY_Wednesday_End_Time__c = '23:59';
        aliAccount.UNITY_Wednesday_Start_Time__c= '00:00';
        aliAccount.UNITY_Tuesday_End_Time__c = '23:59';
        aliAccount.UNITY_Tuesday_Start_Time__c= '00:00';
        aliAccount.UNITY_Monday_End_Time__c = '23:59';
        aliAccount.UNITY_Monday_Start_Time__c= '00:00';
        aliAccount.UNITY_Sunday_End_Time__c = '23:59';
        aliAccount.UNITY_Sunday_Start_Time__c= '00:00';
        aliAccount.UNITY_Saturday_End_Time__c = '23:59';
        aliAccount.UNITY_Saturday_Start_Time__c  = '00:00';           
        insert aliAccount;
        
                
        Account alexAccount = new Account();
        alexAccount.RecordTypeId = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
        alexAccount.Name = 'Alex Customer Account';
        alexAccount.UNITY_LOC__c = 'LOC_002';
        alexAccount.UNITY_Subscriber_ID__c = 'Subscriber ID 002';
        alexAccount.Type ='Customer'; 
        alexAccount.BillingCity = 'billingCity2';
        alexAccount.BillingStateCode = 'NY';
        alexAccount.BillingStreet = '123 Fake St.';
        alexAccount.BillingPostalCode = '123456';
        alexAccount.BillingCountry = 'US';
        insert alexAccount;
        
        Contact c = new Contact();
        c.AccountId = alexAccount.id;
        c.firstName = 'Krishna';
        c.lastName = 'Kamineni';
        insert c;
        
        Case oneCase = new Case();
        oneCase.recordType = [SELECT ID FROM RecordType where DeveloperName= 'UNITY_Service_Request' and SobjectType = 'Case' Limit 1];
        oneCase.UNITY_LOC__c = alexAccount.UNITY_LOC__c;
        oneCase.UNITY_Business_Unit_Account__c = aliAccount.id;
        oneCase.UNITY_Business_Unit__c  ='MNS';
        oneCase.AccountID = alexAccount.id;
        oneCase.UNITY_Customer__c   = alexAccount.id;
        oneCase.UNITY_Subscriber_ID__c = alexAccount.UNITY_Subscriber_ID__c;    
        oneCase.ContactId = c.Id;
             
        
        insert oneCase;
        System.debug('Case Info:' + oneCase);
        //System.assertEquals([SELECT UNITY_Business_Unit_Account__c FROM Case where id =: oneCase.id].UNITY_Business_Unit_Account__c, aliAccount.id);
        Test.startTest();
        oneCase.Origin = 'Email-MNS';
        update oneCase;       
        Test.stopTest();
    }

    static testMethod void fireAssignmentRuleTest () {
        List<Account> accounts = new List<Account>();
        // create accounts 
        Account aliAccount = new Account();
        aliAccount.RecordTypeId  = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
        aliAccount.Name = 'Ali Customer Account';
        aliAccount.UNITY_LOC__c = 'LOC_001';
        aliAccount.UNITY_Subscriber_ID__c = 'Subscriber ID 001';
        aliAccount.Type ='Customer'; // Added by vaishnavi
        aliAccount.BillingCity = 'billingCity1';
        aliAccount.BillingStateCode = 'NY';
        aliAccount.BillingStreet = '123 Fake St.';
        aliAccount.BillingPostalCode = '123456';
        aliAccount.BillingCountry = 'US';
        accounts.add(aliAccount);
        
        insert accounts;
        
        List<Case> cases = new List<Case>();
        
        Case oneCase = new Case();
        oneCase.UNITY_LOC__c = aliAccount.UNITY_LOC__c;
        oneCase.UNITY_Subscriber_ID__c = aliAccount.UNITY_Subscriber_ID__c;
        cases.add(oneCase);        
        insert cases;

        Test.startTest();
        
        List<Case> casesToUpdate = new List<Case>();
        oneCase.UNITY_Fire_Assignment_Rule__c = true;
        casesToUpdate.add(oneCase);        
        Update casesToUpdate;

        Test.stopTest();

        Case caseX = [SELECT Id, UNITY_Fire_Assignment_Rule__c FROM Case WHERE Id = :oneCase.Id];
        System.assertEquals(false, caseX.UNITY_Fire_Assignment_Rule__c );
    }
}