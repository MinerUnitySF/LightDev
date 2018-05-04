@isTest
public class UNITY_WOHighlightPanelControllerTest {
    
    
    static testMethod void testWOHighlightPanelController_Completed(){
        
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
        workOrderFields.put('Status' , 'Completed');
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

        UNITY_WOHighlightPanelController controller  = new UNITY_WOHighlightPanelController(new ApexPages.StandardController(workOrder) );
        
        system.assertEquals(controller.dtzLocalTime.displayname ,'Eastern Standard Time');
        system.assertEquals(controller.dtzWOCreated.displayname ,'Eastern Standard Time');
        system.assertEquals(controller.dtzWOScheduled.displayname ,'Eastern Standard Time');
        system.assertEquals(controller.dtzWOCheckedIn.displayname ,'Eastern Standard Time');
        system.assertEquals(controller.dtzWOWorkWindowBegin.displayname ,'Eastern Standard Time');
        system.assertEquals(controller.dtzWOWorkWindowEnd.displayname ,'Eastern Standard Time');

        Test.stopTest();
    }
    

    static testMethod void testWOHighlightPanelController_New(){
        
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
        caseFields.put('Status'   , 'Verified');
        
        Case onCase = (Case) UNITY_TestDataFactory.createObject(1, Case.getSObjectType(), caseFields).get(0);
        insert onCase; 

        DateTime tNow = DateTime.Now();
        
        workOrderFields.put('RecordTypeId'      , UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE);
        workOrderFields.put('CaseId'      , onCase.id);
        workOrderFields.put('AccountId'   , customer.id);
        workOrderFields.put('Subject'   , 'WO-Test');
        workOrderFields.put('UNITY_Trade__c'    , skill.id);
        workOrderFields.put('UNITY_Customer__c' , customer.id);
        workOrderFields.put('Status' , 'New');

        WorkOrder workOrder  = UNITY_TestDataFactory.createWorkOrders(1,workOrderFields).get(0) ;
        insert workOrder;
        
        Test.startTest();

        UNITY_WOHighlightPanelController controller  = new UNITY_WOHighlightPanelController(new ApexPages.StandardController(workOrder) );
        system.assertEquals(controller.dtzLocalTime.displayname ,'Eastern Standard Time');

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