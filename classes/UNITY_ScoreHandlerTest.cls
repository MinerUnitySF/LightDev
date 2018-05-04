@isTest
public class UNITY_ScoreHandlerTest {


    public UNITY_ScoreHandlerTest() {}

    @testSetup
    static void init() {

        Integer SKILLS_MAX    = 2;
        Integer VENDORS_MAX   = 2;
        Integer CUSTOMERS_MAX = 2;

        Map<String,Object> caseFields            = UNITY_TestDataFactory.MOCKUP_CASE_FIELDS;
        Map<String,Object> skillFields           = UNITY_TestDataFactory.MOCKUP_FSO_SKILL_FIELDS;
        Map<String,Object> assetFields           = new Map<String,Object>();
        Map<String,Object> contactFields         = UNITY_TestDataFactory.MOCKUP_CONTACT_FIELDS;
        Map<String,Object> accountFields         = UNITY_TestDataFactory.MOCKUP_ACCOUNT_FIELDS;
        Map<String,Object> workOrderFields       = UNITY_TestDataFactory.MOCKUP_WORK_ORDER_FIELDS;
        Map<String,Object> vendorTradeFields     = UNITY_TestDataFactory.MOCKUP_VENDOR_TRADE_FIELDS;
        Map<String,Object> serviceContractFields = UNITY_TestDataFactory.MOCKUP_SERVICE_CONTRACT_FIELDS;
        Map<String,Object> vendorAssignmentFields= UNITY_TestDataFactory.MOCKUP_VENDOR_ASSIGNMENT_FIELDS;

        

        List<UNITY_Job_Settings__c> cs = new List<UNITY_Job_Settings__c>();
        cs.add(new  UNITY_Job_Settings__c(Value__c = '-1', Name='VendorScoreCalculation-DelayInDays-VA'));
        cs.add(new  UNITY_Job_Settings__c(Value__c = '31', Name='VendorScoreCalculation-PeriodInDays-VA'));
        insert cs;

        // Create skills
        List<FSO__Skill__c> skills =(List<FSO__Skill__c>)UNITY_TestDataFactory.createObject(SKILLS_MAX, FSO__Skill__c.getSObjectType(), skillFields);
        insert skills;

        // Create Customers
        accountFields.put('Type'        , 'Customer');
        accountFields.put('RecordTypeId', UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE);
        List<Account> customers =(List<Account>)UNITY_TestDataFactory.createObject(CUSTOMERS_MAX, Account.getSObjectType(), accountFields);
        insert customers;

        Map<Id,Asset>                     assetsByAccountId    = new Map<Id,Asset>();
        Map<Id,Contact>                   contactsByAccountId  = new Map<Id,Contact>();
        Map<Id,UNITY_Service_Contract__c> scByAccountId        = new Map<Id,UNITY_Service_Contract__c>();

        
        serviceContractFields.put('UNITY_Business_Unit__c', 'MNS');
        serviceContractFields.put('UNITY_Signature_Template__c', 'ST');
        serviceContractFields.put('UNITY_Required_Documentation__c', 'Customer-Specific Service Report Sign');

        // Create Contacts
        for(Account acc :customers){
            contactFields.put('AccountId', acc.id);
            serviceContractFields.put('UNITY_Account__c', acc.id);
            contactsByAccountId.put(acc.Id,(Contact)UNITY_TestDataFactory.createObject(1, Contact.getSObjectType() , contactFields).get(0));
            scByAccountId.put(acc.Id,(UNITY_Service_Contract__c)UNITY_TestDataFactory.createObject(1, UNITY_Service_Contract__c.getSObjectType(), serviceContractFields).get(0));
        

            assetFields.put('Name'     , 'A-'+acc.Name);
            assetFields.put('AccountId', acc.Id);
            Asset rootAsset = (Asset)UNITY_TestDataFactory.createObject(1, Asset.getSObjectType() , assetFields).get(0);
            assetsByAccountId.put(acc.Id, rootAsset);

        }
        insert contactsByAccountId.values();
        insert assetsByAccountId.values();
        insert scByAccountId.values();

        // Create Vendors
        accountFields.put('Type'        , 'Vendor');
        accountFields.put('RecordTypeId', UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE);
        List<Account> vendors =(List<Account>)UNITY_TestDataFactory.createObject(VENDORS_MAX, Account.getSObjectType(), accountFields);
        insert vendors;

        // Create Vendor Trades
        List<UNITY_Vendor_Trade__c> vendorTrades = new List<UNITY_Vendor_Trade__c>();
        for(Account vendor :vendors){
            for(FSO__Skill__c skill :skills){
                vendorTradeFields.put('Trade__c' , skill.Id);
                vendorTradeFields.put('Vendor__c', vendor.Id);
                vendorTrades.add((UNITY_Vendor_Trade__c)UNITY_TestDataFactory.createObject(1, UNITY_Vendor_Trade__c.getSObjectType(), vendorTradeFields).get(0));
            }
        }
        insert vendorTrades;


        // BU account
        accountFields.put('Type', 'Business Unit');
        accountFields.put('recordTypeId', UNITY_Constants.ACCOUNT_MINER_RECORDTYPE);
        accountFields.put('UNITY_Business_Unit__c', 'MNS');
        accountFields.put('UNITY_Service_Report_Template__c' , 'SRT');

        Account minerAccount   = (Account)UNITY_TestDataFactory.createObject(1, Account.getSObjectType() , accountFields).get(0);
        insert minerAccount;

        // Create Cases
        caseFields.put('Status', 'Verified');
        caseFields.put('UNITY_Business_Unit_Account__c', minerAccount.Id);
        List<Case> cases = new List<Case>();
        for(Account customer :customers){
            for(FSO__Skill__c skill :skills){

                
                caseFields.put('ContactId'        , contactsByAccountId.get(customer.Id).Id);
                caseFields.put('UNITY_Customer_Service_Contract__c' , scByAccountId.get(customer.Id).Id);

                caseFields.put('AccountId'        , customer.id);
                caseFields.put('RecordTypeId'     , UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
                caseFields.put('UNITY_Trade__c'   , skill.id);
                caseFields.put('UNITY_Customer__c', customer.id);
                cases.add((Case) UNITY_TestDataFactory.createObject(1, Case.getSObjectType(), caseFields).get(0));

                caseFields.put('AccountId'        , customer.id);
                caseFields.put('RecordTypeId'     , UNITY_Constants.CASE_PROJECT_MANAGEMENT_RECORDTYPE);
                caseFields.put('UNITY_Trade__c'   , skill.id);
                caseFields.put('UNITY_Customer__c', customer.id);


                cases.add((Case) UNITY_TestDataFactory.createObject(1, Case.getSObjectType(), caseFields).get(0));

                caseFields.put('AccountId'        , customer.id);
                caseFields.put('RecordTypeId'     , UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
                caseFields.put('UNITY_Trade__c'   , skill.id);
                caseFields.put('UNITY_Customer__c', customer.id);
                cases.add((Case) UNITY_TestDataFactory.createObject(1, Case.getSObjectType(), caseFields).get(0));
            }
        }
        insert cases;

        workOrderFields.put('FSO__Check_In_Date__c'          , Date.today().addDays(-15));
        workOrderFields.put('FSO__Completed_Date__c'         , Date.today().addDays(-13));
        workOrderFields.put('FSO__Start_Travel_Date__c'      , Date.today().addDays(-15));
        workOrderFields.put('SFPS_FS_LastCheckOut__c'        , Date.today().addDays(-13));
        
        workOrderFields.put('UNITY_Business_Unit_Account__c' , minerAccount.Id);
       
        // Create Work Orders
        Account aux_vendor;
        List<WorkOrder> workOrders = new List<WorkOrder>();

        for(Integer i=0; i<cases.size();i++){

            Case onCase = cases.get(i);

            workOrderFields.put('CaseId'      , onCase.id);
            workOrderFields.put('Subject'     , 'WO-Test');
            workOrderFields.put('AccountId'   , onCase.AccountId);
            workOrderFields.put('UNITY_Agent__c'    , UserInfo.getUserId());
            workOrderFields.put('UNITY_Trade__c'    , onCase.UNITY_Trade__c);
            workOrderFields.put('UNITY_Customer__c' , onCase.AccountId);
            workOrderFields.put('UNITY_Customer_Service_Contract__c' , scByAccountId.get(onCase.AccountId).Id);
            
            if(i < (cases.size()/2)){

                aux_vendor = vendors.get(Math.round(System.Math.random()*(vendors.size()-1)));
                workOrderFields.put('UNITY_Vendor_Status__c'  , 'Accepted');
                workOrderFields.put('UNITY_Assigned_Vendor__c' , aux_vendor.Id);
                workOrderFields.put('UNITY_Accepted_Vendor__c' , aux_vendor.Id);
                
                if(i<(cases.size()/8)){
                    workOrderFields.put('Priority'  , '2 Hour Response');
                }else{
                    workOrderFields.put('Priority'  , '24 Hour Response');
                }

            }else{
                 workOrderFields.put('UNITY_Vendor_Status__c' , 'Rejected-No Response');
                 if(i<(cases.size()/4)){
                    workOrderFields.put('Priority'  , '2 Hour Response');
                }else{
                    workOrderFields.put('Priority'  , '24 Hour Response');
                }
            }
            
            if(UNITY_TestDataFactory.getMixRecordType(WorkOrder.getSObjectType(),Case.getSObjectType(), onCase.RecordTypeId)!=null)
                workOrderFields.put('RecordTypeId', UNITY_TestDataFactory.getMixRecordType(WorkOrder.getSObjectType(),Case.getSObjectType(), onCase.RecordTypeId));

            workOrders.addAll((List<WorkOrder>)UNITY_TestDataFactory.createObject(1, WorkOrder.getSObjectType(), workOrderFields));
        }
        insert workOrders;

        List<WorkOrderLineItem> wolis = createWOLIs(workOrders, assetsByAccountId.values());
        insert wolis;

        List<UNITY_Vendor_Assignment__c> vendorAssignments = new List<UNITY_Vendor_Assignment__c>();
        
        Set<Id> woId = new Set<Id>();

        for(WorkOrder wo :workOrders){ 

            woId.add(wo.Id);

            if(wo.UNITY_Vendor_Status__c == 'Accepted'){
                vendorAssignmentFields.put('Vendor__c',wo.UNITY_Assigned_Vendor__c); 
            }else{
                aux_vendor = vendors.get(Math.round(System.Math.random()*(vendors.size()-1)));
                vendorAssignmentFields.put('Vendor__c',aux_vendor.Id); 
            }

            vendorAssignmentFields.put('Trade__c',wo.UNITY_Trade__c);
            vendorAssignmentFields.put('Status__c',wo.UNITY_Vendor_Status__c);
            vendorAssignmentFields.put('Customer__c',wo.AccountId);
            vendorAssignmentFields.put('Work_Order__c',wo.Id);
            vendorAssignmentFields.put('Request_Type__c',UNITY_TestDataFactory.getRecordTypeName(WorkOrder.getSobjectType(),wo.RecordTypeId));
            vendorAssignmentFields.put('Last_Assigned__c',Datetime.now().addDays(-2));

            vendorAssignments.add((UNITY_Vendor_Assignment__c)UNITY_TestDataFactory.createObject(1, UNITY_Vendor_Assignment__c.getSObjectType(), vendorAssignmentFields).get(0));
        }
        insert vendorAssignments;

        List<WorkOrder> woList = [SELECT Status, SFPS_FS_OverallStatus__c, SFPS_FS_AllTasks_Completed__c  FROM WorkOrder WHERE (Id IN :woId) AND (UNITY_Assigned_Vendor__c!=null)];

        for(WorkOrder wo :woList){ 
            wo.Status                           = 'IVR Check Out - Agent Review Needed';
            wo.SFPS_FS_AllTasks_Completed__c    = 'All Tasks Completed/Verified';
        }
        update woList;



    }

    static testMethod void va_batch() {

        Test.startTest();

            UNITY_VendorAssignmentScoreBatch avb = new UNITY_VendorAssignmentScoreBatch();
            Database.executeBatch(avb);  

        Test.stopTest();
        
    }

    static testMethod void wo_batch() {

        Test.startTest();

            UNITY_WorkOrderVendorScoreBatch wob = new UNITY_WorkOrderVendorScoreBatch();
            Database.executeBatch(wob);

        Test.stopTest();
        
    }

    private static List<WorkOrderLineItem> createWOLIs(List<WorkOrder> workOrders, List<Asset> assets){

        List<WorkOrderLineItem> wolis = new List<WorkOrderLineItem>();

        for(WorkOrder wo :workOrders){

            for(Asset onAsset :assets){
                WorkOrderLineItem woli = new WorkOrderLineItem();
                woli.AssetId = onAsset.Id;
                woli.WorkOrderId = wo.Id;
                wolis.add(woli);

                WorkOrderLineItem woli_check_in = new WorkOrderLineItem();
                woli_check_in.Description = Date.today().addDays(1).format()+' : Tech Check-In';
                woli_check_in.WorkOrderId = wo.Id;
                woli_check_in.FSO__IsCompleted__c = true;
                wolis.add(woli_check_in);

                WorkOrderLineItem woli_check_out = new WorkOrderLineItem();
                woli_check_out.Description = Date.today().addDays(5).format()+' : Tech Check-Out';
                woli_check_out.WorkOrderId = wo.Id;
                woli_check_out.FSO__IsCompleted__c = true;
                woli_check_out.SFPS_FS_ServiceTime__c = (1440*4);
                wolis.add(woli_check_out);
            }
        } 
        return wolis;
    }
    
    static testMethod void wo_batch_schedule() {
        
        String CRON_EXP = '0 0 0 15 3 ? 2022';
        
        Test.startTest();

            String jobId = System.schedule( 'ScheduleWO',
                                            CRON_EXP,  
                                            new UNITY_VendorScoreCalculationWO_Schedule());

        Test.stopTest();
        
    }
    
    static testMethod void va_batch_schedule() {
        
        String CRON_EXP = '0 0 0 15 3 ? 2022';
        
        Test.startTest();

            String jobId = System.schedule( 'ScheduleVA',
                                            CRON_EXP,
                                            new UNITY_VendorScoreCalculationVA_Schedule());
 

        Test.stopTest();
        
    }
}