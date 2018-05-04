@isTest
public class UNITY_AssetAvailabilityTest {

    private static WorkOrder wo;
    private static Asset rootAsset;
    private static Asset childAsset;
    private static UNITY_Invoice__c invoice;
    private static Case onCase;

    @TestSetup
    static void init(){

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
        //insert onAccount;

        accountFields.put('Type', 'Business Unit');
        accountFields.put('recordTypeId', UNITY_Constants.ACCOUNT_MINER_RECORDTYPE);
        accountFields.put('UNITY_Business_Unit__c', 'MNS');
        accountFields.put('UNITY_Service_Report_Template__c' , 'SRT');

        Account minerAccount   = (Account)UNITY_TestDataFactory.createObject(1, Account.getSObjectType() , accountFields).get(0);
        //insert minerAccount;


        accountFields.put('recordTypeId', UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE);
        accountFields.put('Type', 'Vendor');

        Account vendor = (Account)UNITY_TestDataFactory.createObject(1, Account.getSObjectType() , accountFields).get(0);
        //insert vendor;

        insert new List<Account>{minerAccount,vendor,onAccount};

        assetFields.put('Name'   , 'RootAsset');
        assetFields.put('AccountId', onAccount.Id);
        rootAsset = (Asset)UNITY_TestDataFactory.createObject(1, Asset.getSObjectType() , assetFields).get(0);
        insert rootAsset;

        assetFields.put('Name'   , 'ChildAsset');
        assetFields.put('AccountId', onAccount.Id);
        assetFields.put('ParentId' , rootAsset.Id);
        childAsset = (Asset)UNITY_TestDataFactory.createObject(1, Asset.getSObjectType() , assetFields).get(0);
        insert childAsset;
        
        contactFields.put('AccountId', onAccount.id);

        Contact cont       = (Contact)UNITY_TestDataFactory.createObject(1, Contact.getSObjectType() , contactFields).get(0);
        insert cont;

        FSO__Skill__c onSkill = (FSO__Skill__c)UNITY_TestDataFactory.createObject(1, FSO__Skill__c.getSObjectType() , skillFields).get(0);
        insert onSkill;

        caseFields.put('Status'           , 'Verified');
        caseFields.put('AccountId'        , onAccount.id);
        caseFields.put('ContactId'        , cont.id);
        caseFields.put('Customer__c'      , onAccount.id);
        caseFields.put('RecordTypeId'     , UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
        caseFields.put('UNITY_Trade__c'   , onSkill.id);
        caseFields.put('UNITY_Asset_Down__c'    , true);
        caseFields.put('UNITY_Asset_Up_At__c'   , Date.today().addDays(5));
        caseFields.put('UNITY_Asset_Down_At__c' , Date.today());
        caseFields.put('UNITY_Work_Window_End__c'   , Date.today().addDays(10));
        caseFields.put('UNITY_Work_Window_Begin__c' , Date.today());
        caseFields.put('UNITY_Business_Unit__c' , 'MNS');
        caseFields.put('UNITY_Business_Unit_Account__c' , minerAccount.Id);

        onCase = (Case) UNITY_TestDataFactory.createObject(1, Case.getSObjectType(), caseFields).get(0);
        insert onCase;

        serviceContractFields.put('UNITY_Business_Unit__c', 'MNS');
        serviceContractFields.put('UNITY_Account__c', onAccount.id);
        serviceContractFields.put('UNITY_Required_Documentation__c', 'Customer-Specific Service Report Sign');
        UNITY_Service_Contract__c c_sc  = (UNITY_Service_Contract__c)UNITY_TestDataFactory.createObject(1, UNITY_Service_Contract__c.getSObjectType(), serviceContractFields).get(0);
        //insert c_sc;

        serviceContractFields.put('UNITY_Business_Unit__c', 'MNS');
        serviceContractFields.put('UNITY_Account__c', vendor.id);
        serviceContractFields.put('UNITY_Required_Documentation__c', 'Customer-Specific Service Report Sign');
        UNITY_Service_Contract__c v_sc  = (UNITY_Service_Contract__c)UNITY_TestDataFactory.createObject(1, UNITY_Service_Contract__c.getSObjectType(), serviceContractFields).get(0);
        //insert v_sc;
        insert new List<UNITY_Service_Contract__c>{c_sc,v_sc};


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
        workOrderFields.put('UNITY_Vendor_Contract__c' , v_sc.id);
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

        List<UNITY_Invoice_Line_Item__c> invoiceLI =  new List<UNITY_Invoice_Line_Item__c>{woLavel,caseLavel,woAssetLavel};
        insert invoiceLI;
        */

    }


    static testMethod void noAssetHistoryBefore(){
        onCase = [SELECT id, Status, UNITY_Service_Data_Processed__c  FROM Case LIMIT 1];
        childAsset = [SELECT Id FROM Asset LIMIT 1];
        wo = [SELECT Id,Status,FSO__Check_In_Date__c,FSO__Completed_Date__c,FSO__Start_Travel_Date__c,SFPS_FS_AllTasks_Completed__c FROM WorkOrder LIMIT 1];
        
        Test.startTest();

            wo.Status                        = 'Completed';
            //wo.StartDate                     = Date.today().addDays(3);
            wo.FSO__Check_In_Date__c         = Date.today().addDays(3);
            wo.FSO__Completed_Date__c        = Date.today().addDays(8);
            wo.FSO__Start_Travel_Date__c     = Date.today().addDays(3);
            wo.SFPS_FS_AllTasks_Completed__c = 'All Tasks Completed/Verified';
            update wo;


            onCase.Status = 'Closed';
            update onCase;

        Test.stopTest();

        //onCase = [SELECT id, Status, UNITY_Service_Data_Processed__c  FROM Case WHERE Id = :wo.CaseId];
        //system.assertEquals(true, onCase.UNITY_Service_Data_Processed__c);
    }

    static testMethod void withAssetHistoryBefore(){

        List<Asset> assets = [SELECT Id, AccountId FROM Asset];
        List<UNITY_Asset_History__c> assetHistories = new List<UNITY_Asset_History__c>();

        for(Asset onAsset :assets){
            assetHistories.add(new UNITY_Asset_History__c(
                                                    UNITY_Asset__c        = onAsset.Id,
                                                    UNITY_Account__c      = onAsset.AccountId,
                                                    UNITY_End_Date__c     = Date.newInstance(Date.today().year(),12, 31),
                                                    UNITY_Down_Time__c    = 1440,
                                                    UNITY_Start_Date__c   = Date.newInstance(Date.today().year(),1, 1),
                                                    UNITY_Service_Time__c = 1440));
        }
        insert assetHistories;

        onCase = [SELECT id, Status, UNITY_Service_Data_Processed__c  FROM Case LIMIT 1];
        childAsset = [SELECT Id FROM Asset LIMIT 1];
        wo = [SELECT Id,Status,FSO__Check_In_Date__c,FSO__Completed_Date__c,FSO__Start_Travel_Date__c,SFPS_FS_AllTasks_Completed__c FROM WorkOrder LIMIT 1];
        

        Test.startTest();

            wo.Status                        = 'Completed';
            //wo.StartDate                     = Date.today().addDays(1);
            wo.FSO__Check_In_Date__c         = Date.today().addDays(1);
            wo.FSO__Completed_Date__c        = Date.today().addDays(5);
            //wo.SFPS_FS_OverallStatus__c      = 'Completed';
            wo.FSO__Start_Travel_Date__c     = Date.today().addDays(1);
            wo.SFPS_FS_AllTasks_Completed__c = 'All Tasks Completed/Verified';
            update wo;


            onCase.Status = 'Closed';
            update onCase;

        Test.stopTest();

        //onCase = [SELECT id, Status, UNITY_Service_Data_Processed__c  FROM Case WHERE Id = :wo.CaseId];
        //system.assertEquals(true, onCase.UNITY_Service_Data_Processed__c);
    }

    static testMethod void withFiscalYearbaseOnEndingMonth(){

        Account customer = [SELECT Id, UNITY_Fiscal_Year_Based_On__c FROM Account LIMIT 1];
        customer.UNITY_Fiscal_Year_Based_On__c = 'Ending Month';
        update customer;

        List<Asset> assets = [SELECT Id, AccountId FROM Asset];
        List<UNITY_Asset_History__c> assetHistories = new List<UNITY_Asset_History__c>();

        for(Asset onAsset :assets){
            assetHistories.add(new UNITY_Asset_History__c(
                                                    UNITY_Asset__c        = onAsset.Id,
                                                    UNITY_Account__c      = onAsset.AccountId,
                                                    UNITY_End_Date__c     = Date.newInstance(Date.today().year(),12, 31),
                                                    UNITY_Down_Time__c    = 1440,
                                                    UNITY_Start_Date__c   = Date.newInstance(Date.today().year(),1, 1),
                                                    UNITY_Service_Time__c = 1440));
        }
        insert assetHistories;

        onCase = [SELECT id, Status, UNITY_Service_Data_Processed__c  FROM Case LIMIT 1];
        childAsset = [SELECT Id FROM Asset LIMIT 1];
        wo = [SELECT Id,Status,FSO__Check_In_Date__c,FSO__Completed_Date__c,FSO__Start_Travel_Date__c,SFPS_FS_AllTasks_Completed__c FROM WorkOrder LIMIT 1];
        

        Test.startTest();

            invoice = new  UNITY_Invoice__c();
            invoice.UNITY_Invoice_Status__c = 'Invoice Finalized';
            invoice.UNITY_Case__c = onCase.Id;
            insert invoice;


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

            List<UNITY_Invoice_Line_Item__c> invoiceLI =  new List<UNITY_Invoice_Line_Item__c>{woLavel,caseLavel,woAssetLavel};
            insert invoiceLI;

            wo.Status                        = 'Completed';
            //wo.StartDate                     = Date.today().addDays(1);
            wo.FSO__Check_In_Date__c         = Date.today().addDays(1);
            wo.FSO__Completed_Date__c        = Date.today().addDays(5);
            //wo.SFPS_FS_OverallStatus__c      = 'Completed';
            wo.FSO__Start_Travel_Date__c     = Date.today().addDays(1);
            wo.SFPS_FS_AllTasks_Completed__c = 'All Tasks Completed/Verified';
            update wo;


            onCase.Status = 'Closed';
            update onCase;

        Test.stopTest();

        //onCase = [SELECT id, Status, UNITY_Service_Data_Processed__c  FROM Case WHERE Id = :wo.CaseId];
        //system.assertEquals(true, onCase.UNITY_Service_Data_Processed__c);
    }

    static testMethod void caseAfterFY(){

        Account customer = [SELECT Id, UNITY_Fiscal_Year_Based_On__c FROM Account LIMIT 1];
        customer.UNITY_Fiscal_Year_Based_On__c = 'Ending Month';
        update customer;

        List<Asset> assets = [SELECT Id, AccountId FROM Asset];
        List<UNITY_Asset_History__c> assetHistories = new List<UNITY_Asset_History__c>();

        for(Asset onAsset :assets){
            assetHistories.add(new UNITY_Asset_History__c(
                                                    UNITY_Asset__c        = onAsset.Id,
                                                    UNITY_Account__c      = onAsset.AccountId,
                                                    UNITY_End_Date__c     = Date.newInstance(Date.today().year(),12, 31),
                                                    UNITY_Down_Time__c    = 1440,
                                                    UNITY_Start_Date__c   = Date.newInstance(Date.today().year(),1, 1),
                                                    UNITY_Service_Time__c = 1440));
        }
        insert assetHistories;

        onCase = [SELECT id, Status, UNITY_Service_Data_Processed__c  FROM Case LIMIT 1];
        childAsset = [SELECT Id FROM Asset LIMIT 1];
        wo = [SELECT Id,Status,FSO__Check_In_Date__c,FSO__Completed_Date__c,FSO__Start_Travel_Date__c,SFPS_FS_AllTasks_Completed__c FROM WorkOrder LIMIT 1];

        Test.startTest();

            invoice = new  UNITY_Invoice__c();
            invoice.UNITY_Invoice_Status__c = 'Invoice Finalized';
            invoice.UNITY_Case__c = onCase.Id;
            insert invoice;


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

            List<UNITY_Invoice_Line_Item__c> invoiceLI =  new List<UNITY_Invoice_Line_Item__c>{woLavel,caseLavel,woAssetLavel};
            insert invoiceLI;

            wo.Status                        = 'Completed';
            //wo.StartDate                     = Date.today().addDays(1);
            wo.FSO__Check_In_Date__c         = Date.today().addDays(1);
            wo.FSO__Completed_Date__c        = Date.today().addDays(5);
            //wo.SFPS_FS_OverallStatus__c      = 'Completed';
            wo.FSO__Start_Travel_Date__c     = Date.today().addDays(1);
            wo.SFPS_FS_AllTasks_Completed__c = 'All Tasks Completed/Verified';
            update wo;


            onCase.Status = 'Closed';
            onCase.UNITY_Asset_Up_At__c   = Date.today().addMonths(12);
            onCase.UNITY_Asset_Down_At__c = Date.today().addMonths(11);
            update onCase;

        Test.stopTest();

        //onCase = [SELECT id, Status, UNITY_Service_Data_Processed__c  FROM Case WHERE Id = :wo.CaseId];
        //system.assertEquals(true, onCase.UNITY_Service_Data_Processed__c);
    }

    static testMethod void caseBeforeFY(){

        Account customer = [SELECT Id, UNITY_Fiscal_Year_Based_On__c FROM Account LIMIT 1];
        customer.UNITY_Fiscal_Year_Based_On__c = 'Ending Month';
        update customer;

        List<Asset> assets = [SELECT Id, AccountId FROM Asset];
        List<UNITY_Asset_History__c> assetHistories = new List<UNITY_Asset_History__c>();

        for(Asset onAsset :assets){
            assetHistories.add(new UNITY_Asset_History__c(
                                                    UNITY_Asset__c        = onAsset.Id,
                                                    UNITY_Account__c      = onAsset.AccountId,
                                                    UNITY_End_Date__c     = Date.newInstance(Date.today().year(),12, 31),
                                                    UNITY_Down_Time__c    = 1440,
                                                    UNITY_Start_Date__c   = Date.newInstance(Date.today().year(),1, 1),
                                                    UNITY_Service_Time__c = 1440));
        }

        insert assetHistories;

        onCase = [SELECT id, Status, UNITY_Service_Data_Processed__c  FROM Case LIMIT 1];
        childAsset = [SELECT Id FROM Asset LIMIT 1];
        wo = [SELECT Id,Status,FSO__Check_In_Date__c,FSO__Completed_Date__c,FSO__Start_Travel_Date__c,SFPS_FS_AllTasks_Completed__c FROM WorkOrder LIMIT 1];
        

        Test.startTest();

            invoice = new  UNITY_Invoice__c();
            invoice.UNITY_Invoice_Status__c = 'Invoice Finalized';
            invoice.UNITY_Case__c = onCase.Id;
            insert invoice;


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

            List<UNITY_Invoice_Line_Item__c> invoiceLI =  new List<UNITY_Invoice_Line_Item__c>{woLavel,caseLavel,woAssetLavel};
            insert invoiceLI;

            wo.Status                        = 'Completed';
            //wo.StartDate                     = Date.today().addDays(1);
            wo.FSO__Check_In_Date__c         = Date.today().addDays(1);
            wo.FSO__Completed_Date__c        = Date.today().addDays(5);
            //wo.SFPS_FS_OverallStatus__c      = 'Completed';
            wo.FSO__Start_Travel_Date__c     = Date.today().addDays(1);
            wo.SFPS_FS_AllTasks_Completed__c = 'All Tasks Completed/Verified';
            update wo;


            onCase.Status = 'Closed';
            onCase.UNITY_Asset_Up_At__c   = Date.today().addMonths(-12);
            onCase.UNITY_Asset_Down_At__c = Date.today().addMonths(-11);
            update onCase;

        Test.stopTest();

        //onCase = [SELECT id, Status, UNITY_Service_Data_Processed__c  FROM Case WHERE Id = :wo.CaseId];
        //system.assertEquals(true, onCase.UNITY_Service_Data_Processed__c);
    }
}