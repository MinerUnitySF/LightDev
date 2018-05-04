/*------------------------------------------------------------
Name:           UNITY_UpdateCaseStatusTest
Author:         Krishna Kamineni (Perficient)
Company:        Miner
Description:    This updateStatus() method updates status field by assign least status of its workorders
History:
03/21/2016      Krishna Kamineni Initial version.
------------------------------------------------------------*/
@isTest
public class UNITY_UpdateCaseStatusTest{
    static TestMethod void updateStatusTest(){
        /*Case c1 =new Case(Status='New',Origin='Phone');
        insert c1;
        WorkOrder wo1 =new WorkOrder(Status ='New',CaseId =c1.Id);
        WorkOrder wo2 =new WorkOrder(Status ='Assigned',CaseId =c1.Id);
        List<WorkOrder>workOrders =new List<WorkOrder>();
        workOrders.add(wo1);
        workOrders.add(wo2);
        insert workOrders;
        Account accountCustomer = UNITY_TestDataFactory.createAccounts(1,'Site/Location',UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE).get(0);
        Account accountVendor = UNITY_TestDataFactory.createAccounts(1,'Customer',UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE).get(0);
        List<Contact> contacts = UNITY_TestDataFactory.createContacts(2,accountCustomer.Id);
        List<Case> cases = UNITY_TestDataFactory.createCases(2,accountCustomer.Id,accountVendor.Id,contacts.get(0).Id,UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
        cases[0].Status ='Verified';
        update cases;
        List<WorkOrder> workOrders = UNITY_TestDataFactory.createWorkOrders(2,cases.get(0).Id,accountCustomer.Id,UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE);
        workOrders.get(0).Status ='Assigned';
        update workOrders;
        */

        /*
        List<Case> caseRecords =[SELECT Status
                                 FROM Case
                                 WHERE Id ='50018000004TwT1'];
        List<WorkOrder>workOrders =[SELECT Status
                                    From WorkOrder
                                    WHERE CaseId =:caseRecords.get(0).Id];
        workOrders[0].Status ='Pending Acceptance';
        update workOrders;
        if(!caseRecords.isEmpty()){                    
            System.AssertEquals('Verified',caseRecords[0].Status);
        }
        */

        Map<String,Object> data = test_data();
        
        Account customer      = (Account)data.get('customer');
        FSO__Skill__c skill   = (FSO__Skill__c)data.get('skill');
        String locationKey    = (String)data.get('locationKey');
        List<Account> vendors = (List<Account>)data.get('vendors');
        List<UNITY_Vendor_Trade__c>               vendorTrades      = (List<UNITY_Vendor_Trade__c>)data.get('vendorTrades');
        List<UNITY_Vendor_Covered_Location__c>    locationVendors   = (List<UNITY_Vendor_Covered_Location__c>)data.get('locationVendors');
        Map<id,UNITY_Vendor_Preference__c>        vendorPreferences = null;
        List<UNITY_Vendor_Preference_By_Trade__c> vendorPreferenceTrades = null;
        
        Account selectedVendor = vendors[0];

        Map<String,Object> workOrderFields = UNITY_TestDataFactory.MOCKUP_WORK_ORDER_FIELDS;
        Map<String,Object> caseFields = UNITY_TestDataFactory.MOCKUP_WORK_ORDER_FIELDS;
            
        caseFields.put('RecordTypeId'     , UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
        caseFields.put('Customer__c'      , customer.id);
        caseFields.put('AccountId'        , customer.id);
        caseFields.put('UNITY_Trade__c'   , skill.id);
        caseFields.put('Status'           , 'Verified');
        
        Case onCase = (Case) UNITY_TestDataFactory.createObject(1, Case.getSObjectType(), caseFields).get(0);
        insert onCase; 

        DateTime tNow = DateTime.Now();
        
        workOrderFields.put('RecordTypeId'      , UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE);
        workOrderFields.put('CaseId'      , onCase.id);
        workOrderFields.put('AccountId'   , customer.id);
        workOrderFields.put('Subject'   , 'WO-Test');
        workOrderFields.put('UNITY_Trade__c'    , skill.id);
        workOrderFields.put('UNITY_Customer__c' , customer.id);
        workOrderFields.put('UNITY_Assigned_Vendor__c' , selectedVendor.id);
        workOrderFields.put('UNITY_Accepted_Vendor__c' , selectedVendor.id);
        workOrderFields.put('UNITY_Vendor_Status__c' , 'Accepted');
        workOrderFields.put('Status' , 'New');
        workOrderFields.put('UNITY_Vendor_Last_Assigned__c' , tNow.addHours(1));
        workOrderFields.put('UNITY_Vendor_Accept_Date__c' , tNow.addHours(2));
        workOrderFields.put('StartDate' , tNow.addHours(3));
        workOrderFields.put('SFPS_FS_Overall_Start__c' , tNow.addHours(3));
        workOrderFields.put('FSO__Start_Travel_Date__c' , tNow.addHours(3));        
        workOrderFields.put('SFPS_FS_FirstTravel__c' , tNow.addHours(3));
        workOrderFields.put('FSO__Check_In_Date__c' , tNow.addHours(4));
        workOrderFields.put('SFPS_FS_FirstCheckIn__c' , tNow.addHours(4));
        workOrderFields.put('FSO__Completed_Date__c' , tNow.addHours(5));
        workOrderFields.put('SFPS_FS_LastCheckOut__c' , tNow.addHours(5));

        WorkOrder workOrder  = UNITY_TestDataFactory.createWorkOrders(1,workOrderFields).get(0) ;
        insert workOrder;

        Test.startTest();

        workOrder.Status = 'Completed';
        update workOrder;

        /* 
        //Uncomment after custom setting is loaded
        Case caseX =[SELECT Id, Status
                                    From Case
                                    WHERE Id =:onCase.Id];

        //System.AssertEquals('Service Complete',caseX.Status);
        */

        Test.stopTest();
    }        

    static Map<String,Object> test_data() {
        
        Map<String,Object> toReturn = new Map<String,Object>();
        
        Account customer  = new Account();
        List<Account> vendors = new List<Account>();
        List<Account> accounts = new List<Account>();
        
        Map<String,boolean> serviceRequestType          = new   Map<String,boolean>{'UNITY_Vendor_Type_SR__c'=>true}; 
            
        Map<String,Object> workOrderFields             = UNITY_TestDataFactory.MOCKUP_WORK_ORDER_FIELDS;
        Map<String,Object> vendorPreferenceFields      = UNITY_TestDataFactory.MOCKUP_VENDOR_TRADE_FIELDS;
        Map<String,Object> vendorPreferenceTradeFields = UNITY_TestDataFactory.MOCKUP_VENDOR_PREFERENCE_TRADE_FIELDS;
        Map<String,Object> vendorTradeFields           = UNITY_TestDataFactory.MOCKUP_VENDOR_TRADE_FIELDS;
        Map<String,Object> vendorLocationFields        = UNITY_TestDataFactory.MOCKUP_VENDOR_LOCATION_FIELDS;
        Map<String,Object> accountFields               = UNITY_TestDataFactory.MOCKUP_ACCOUNT_FIELDS;    
        Map<String,Object> skillFields                 = UNITY_TestDataFactory.MOCKUP_FSO_SKILL_FIELDS;    
        
        Integer dayOfTheWeek = UNITY_Utils.getDayOfTheWeek();
        Map<String,String> todayWorkTime = new Map<String,String>{  UNITY_Constants.ACCOUNT_OPERATION_HOURS.get(dayOfTheWeek)[0]=>'00:00',
                                                                    UNITY_Constants.ACCOUNT_OPERATION_HOURS.get(dayOfTheWeek)[1]=>'23:59'};
                                                                        
        accountFields.put('ShippingPostalCode', UNITY_Utils.generateRandomPin()+'-'+UNITY_Utils.generateRandomPin());
        accountFields.put('RecordTypeId', UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE);
        accountFields.put('Name', 'C-'+UNITY_Utils.generateRandomPin());
        accountFields.put('UNITY_TimeZoneSidKey__c','America/New_York');

        customer = (Account)UNITY_TestDataFactory.createObject(1, Account.getSObjectType(),accountFields ).get(0); 
        toReturn.put('customer', customer);
        
        vendors.addAll(UNITY_TestDataFactory.createAccounts(12, UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE, serviceRequestType, todayWorkTime, true,'SR_'));
        toReturn.put('vendors', vendors);
        
        accounts.addAll(vendors);
        accounts.add(customer);
        
        insert accounts;
        
        FSO__Skill__c skill = UNITY_TestDataFactory.createSkills(1, false).get(0);
        insert skill;
        
        toReturn.put('skill', skill);
       
        List<UNITY_Vendor_Trade__c>               vendorTrades      = new List<UNITY_Vendor_Trade__c>();
                
        insert vendorTrades;
        toReturn.put('vendorTrades', vendorTrades);

        return toReturn;
    }


    static Map<String,Object> data_A() {
        
        Map<String,Object> toReturn = new Map<String,Object>();
        
        Account customer  = new Account();
        List<Account> vendors = new List<Account>();
        List<Account> accounts = new List<Account>();
        
        Map<String,boolean> serviceRequestType          = new   Map<String,boolean>{'UNITY_Vendor_Type_SR__c'=>true}; 
            
        Map<String,Object> workOrderFields             = UNITY_TestDataFactory.MOCKUP_WORK_ORDER_FIELDS;
        Map<String,Object> vendorPreferenceFields      = UNITY_TestDataFactory.MOCKUP_VENDOR_TRADE_FIELDS;
        Map<String,Object> vendorPreferenceTradeFields = UNITY_TestDataFactory.MOCKUP_VENDOR_PREFERENCE_TRADE_FIELDS;
        Map<String,Object> vendorTradeFields           = UNITY_TestDataFactory.MOCKUP_VENDOR_TRADE_FIELDS;
        Map<String,Object> vendorLocationFields        = UNITY_TestDataFactory.MOCKUP_VENDOR_LOCATION_FIELDS;
        Map<String,Object> accountFields               = UNITY_TestDataFactory.MOCKUP_ACCOUNT_FIELDS;    
        Map<String,Object> skillFields                 = UNITY_TestDataFactory.MOCKUP_FSO_SKILL_FIELDS;    
        
        Integer dayOfTheWeek = UNITY_Utils.getDayOfTheWeek();
        Map<String,String> todayWorkTime = new Map<String,String>{  UNITY_Constants.ACCOUNT_OPERATION_HOURS.get(dayOfTheWeek)[0]=>'00:00',
                                                                    UNITY_Constants.ACCOUNT_OPERATION_HOURS.get(dayOfTheWeek)[1]=>'23:59'};
                                                                        
        accountFields.put('ShippingPostalCode', UNITY_Utils.generateRandomPin()+'-'+UNITY_Utils.generateRandomPin());
        accountFields.put('RecordTypeId', UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE);
        accountFields.put('Name', 'C-'+UNITY_Utils.generateRandomPin());
        customer = (Account)UNITY_TestDataFactory.createObject(1, Account.getSObjectType(),accountFields ).get(0); 
        toReturn.put('customer', customer);
        
        vendors.addAll(UNITY_TestDataFactory.createAccounts(12, UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE, serviceRequestType, todayWorkTime, true,'SR_'));
        toReturn.put('vendors', vendors);
        
        accounts.addAll(vendors);
        accounts.add(customer);
        
        insert accounts;
        
        FSO__Skill__c skill = UNITY_TestDataFactory.createSkills(1, false).get(0);
        insert skill;
        
        toReturn.put('skill', skill);
       
        List<UNITY_Vendor_Trade__c>               vendorTrades      = new List<UNITY_Vendor_Trade__c>();
        List<UNITY_Vendor_Covered_Location__c>    locationVendors   = new List<UNITY_Vendor_Covered_Location__c>();
        Map<id,UNITY_Vendor_Preference__c>        vendorPreferences = new Map<id,UNITY_Vendor_Preference__c>();
        List<UNITY_Vendor_Preference_By_Trade__c> vendorPreferenceTrades = new List<UNITY_Vendor_Preference_By_Trade__c>();
        
        for(integer index = 0 ; index < vendors.size(); index++ ){
                
            Account onVendor =  vendors.get(index);
                
            vendorTradeFields.put('Trade__c' , skill.id);
            vendorTradeFields.put('Vendor__c', onVendor.id);
                
            vendorTradeFields.put('Score_SR__c', System.Math.round((System.Math.random()*8)+1));
            vendorTradeFields.put('Price_SR__c', (index+1)*100);
                
            UNITY_Vendor_Trade__c  vendorTrade  = (UNITY_Vendor_Trade__c)UNITY_TestDataFactory.createObject(1, UNITY_Vendor_Trade__c.getSObjectType(), vendorTradeFields).get(0);
            vendorTrades.add(vendorTrade);
        }
        
        insert vendorTrades;
        toReturn.put('vendorTrades', vendorTrades);
        
        vendorLocationFields.put('Location_Key__c', UNITY_Utils.getLocationKey(customer.ShippingCountryCode, customer.ShippingPostalCode));
        toReturn.put('locationKey',UNITY_Utils.getLocationKey(customer.ShippingCountryCode, customer.ShippingPostalCode));
        
        for(integer index = 0 ; index < vendors.size(); index++ ){
                
            Account onVendor =  vendors.get(index);
            vendorLocationFields.put('Vendor__c', onVendor.id);
                
            UNITY_Vendor_Covered_Location__c locationKey = (UNITY_Vendor_Covered_Location__c)UNITY_TestDataFactory.createObject(1, UNITY_Vendor_Covered_Location__c.getSObjectType(), vendorLocationFields).get(0);
            locationVendors.add(locationKey);
                
        }
        
        insert locationVendors;
        toReturn.put('locationVendors', locationVendors);
        
        return toReturn;
    }
    
}