@isTest
public class UNITY_VendorAssignmentTriggerHandlerTest {

    static testMethod void checkVendorAssigmentCreationSuccess() {
        Account accountCustomer = UNITY_TestDataFactory.createAccounts(1,'Site/Location',UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE).get(0);
        Account accountVendor = UNITY_TestDataFactory.createAccounts(1,'Customer',UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE).get(0);
        List<Contact> contacts = UNITY_TestDataFactory.createContacts(2,accountCustomer.Id);
        List<Case> cases = UNITY_TestDataFactory.createCases(2,accountCustomer.Id,accountVendor.Id,contacts.get(0).Id,UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
        List<WorkOrder> workOrders = UNITY_TestDataFactory.createWorkOrders(2,cases.get(0).Id,accountCustomer.Id,UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE);
        
        Test.startTest();
        UNITY_TestDataFactory.createVendorAssignments(10,accountVendor.Id,workOrders.get(0).Id);
        Test.stopTest();
        
        for(UNITY_Vendor_Assignment__c assignment : [SELECT Id, PIN__c FROM UNITY_Vendor_Assignment__c]) {
            System.assert(assignment.PIN__c != NULL && assignment.PIN__c.length() == 4,'The PIN__c field value should be a four digit string,'+assignment.PIN__c);
        }
    }
    
    static testMethod void varifyPullInfoFromVendor() {
        UNITY_Constants.MAX_TRIGGER_EXECUTION = 2;
        Account customer              = new Account();
        List<Account> accounts        = new List<Account>();
        List<Account> accountsPM      = new List<Account>();
        List<Account> accountsSS      = new List<Account>();
        List<Account> accountsSR      = new List<Account>();
        List<Account> accountsVendors= new List<Account>();
        List<FSO__Skill__c> skills = new List<FSO__Skill__c>();
        
        
        Map<String,boolean> serviceRequestType          = new   Map<String,boolean>{'UNITY_Vendor_Type_SR__c'=>true}; 
        Map<String,boolean> projectType                 = new   Map<String,boolean>{'UNITY_Vendor_Type_Project__c'=>true};
        Map<String,boolean> preventativeMaintenanceType = new   Map<String,boolean>{'UNITY_Vendor_Type_PM__c'=>true};
        Map<String,boolean> siteSurveyType              = new   Map<String,boolean>{'UNITY_Vendor_Type_SS__c'=>true};
            
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
        accountFields.put('Account_Email__c', 'customer@email.com');
        customer = (Account)UNITY_TestDataFactory.createObject(1, Account.getSObjectType(),accountFields ).get(0); 
        customer.Type = 'Customer';
        
        accountsSR.addAll(UNITY_TestDataFactory.createAccounts(12, UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE, serviceRequestType, todayWorkTime, true,'SR_'));
        accountsSS.addAll(UNITY_TestDataFactory.createAccounts(12, UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE, siteSurveyType    , todayWorkTime, true,'SS_'));
        accountsPM.addAll(UNITY_TestDataFactory.createAccounts(12, UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE, preventativeMaintenanceType, todayWorkTime, true,'PM_'));
        
        accounts.addAll(accountsSR);
        accounts.addAll(accountsPM);
        accounts.addAll(accountsSS);
        
        accountsVendors.addAll(accounts);
        
        accounts.add(customer);
        insert accounts;
        
        skills = UNITY_TestDataFactory.createSkills(3, false);
        insert skills;
       
        List<UNITY_Vendor_Trade__c>               vendorTrades      = new List<UNITY_Vendor_Trade__c>();
        List<UNITY_Vendor_Covered_Location__c>    locationVendors   = new List<UNITY_Vendor_Covered_Location__c>();
        Map<id,UNITY_Vendor_Preference__c>        vendorPreferences = new Map<id,UNITY_Vendor_Preference__c>();
        List<UNITY_Vendor_Preference_By_Trade__c> vendorPreferenceTrades = new List<UNITY_Vendor_Preference_By_Trade__c>();
        
        // create dynamic vendors trade records per trade 
        for(FSO__Skill__c onSkill :skills){
            
            integer maxVendorsPerTrade = Math.round(System.Math.random()*(accountsVendors.size()-1));
            set<integer> indexCache = new set<integer>();
            
            for(integer index = 0 ; index < maxVendorsPerTrade; index++ ){
                
                integer i = Math.round(System.Math.random()*(accountsVendors.size()-1)); 
                while(indexCache.contains(i)){
                    i = Math.round(System.Math.random()*(accountsVendors.size()-1)); 
                }
                indexCache.add(i);

                Account onVendor =  accountsVendors.get(i);
                
                vendorTradeFields.put('Trade__c' , onSkill.id);
                vendorTradeFields.put('Vendor__c', onVendor.id);
                
                if(onVendor.UNITY_Vendor_Type_SS__c){
                    vendorTradeFields.put('Score_SS__c', System.Math.round((System.Math.random()*8)+1));
                    vendorTradeFields.put('Price_SS__c', (index+1)*100);
                }
                if(onVendor.UNITY_Vendor_Type_PM__c){
                     vendorTradeFields.put('Score_PM__c', System.Math.round((System.Math.random()*8)+1));
                     vendorTradeFields.put('Price_PM__c', (index+1)*100);
                }
                if(onVendor.UNITY_Vendor_Type_Project__c){
                     vendorTradeFields.put('Score_PM__c', System.Math.round((System.Math.random()*8)+1));
                     vendorTradeFields.put('Price_PM__c', (index+1)*100);
                }
                if(onVendor.UNITY_Vendor_Type_SR__c){
                     vendorTradeFields.put('Score_SR__c', System.Math.round((System.Math.random()*8)+1));
                     vendorTradeFields.put('Price_SR__c', (index+1)*100);
                }           
                UNITY_Vendor_Trade__c  vendorTrade  = (UNITY_Vendor_Trade__c)UNITY_TestDataFactory.createObject(1, UNITY_Vendor_Trade__c.getSObjectType(), vendorTradeFields).get(0);
                vendorTrades.add(vendorTrade);
            }
        }
        
        
        insert vendorTrades;
        
        vendorLocationFields.put('Location_Key__c', UNITY_Utils.getLocationKey(customer.ShippingCountryCode, customer.ShippingPostalCode));
            
        for(integer index = 0 ; index < accountsVendors.size(); index++ ){
                
            Account onVendor =  accountsVendors.get(index);
            vendorLocationFields.put('Vendor__c', onVendor.id);
                
            UNITY_Vendor_Covered_Location__c locationKey = (UNITY_Vendor_Covered_Location__c)UNITY_TestDataFactory.createObject(1, UNITY_Vendor_Covered_Location__c.getSObjectType(), vendorLocationFields).get(0);
            locationVendors.add(locationKey);
                
        }
        
        insert locationVendors;
        
        Test.startTest();
             
             // get one customer
             Account onCustomer = [SELECT id, name, Account_Email__c, ShippingPostalCode, ShippingCountryCode  FROM Account WHERE RecordTypeId = :UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE LIMIT 1];
             
             Map<String,Object> caseFields = UNITY_TestDataFactory.MOCKUP_CASE_FIELDS;
        
             caseFields.put('RecordTypeId', UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
             caseFields.put('Customer__c', onCustomer.id);
             caseFields.put('UNITY_Trade__c', skills.get(0).id);
            
             Case onCase = (Case) UNITY_TestDataFactory.createObject(1, Case.getSObjectType(), caseFields).get(0);
             insert onCase; 
            
             workOrderFields.put('RecordTypeId', UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE);
             workOrderFields.put('CaseId', onCase.id);
             workOrderFields.put('AccountId', onCustomer.id);
             workOrderFields.put('Subject', 'WO-Test');
             workOrderFields.put('UNITY_Trade__c' , skills.get(0).id);
             workOrderFields.put('UNITY_Customer__c', onCustomer.id);
             workOrderFields.put('UNITY_Auto_Dispatch__c' , true);
            
             WorkOrder workOrder  = UNITY_TestDataFactory.createWorkOrders(1,workOrderFields).get(0) ;
             insert workOrder;    
        
             Map<id, UNITY_Vendor_Assignment__c> vendorAssignments = new Map<id , UNITY_Vendor_Assignment__c>([SELECT id,Vendor__c, UNITY_Vendor_Email__c  FROM UNITY_Vendor_Assignment__c ]);
        
             Map<id,String> account_email = new Map<id,String>();
             for(UNITY_Vendor_Assignment__c va :vendorAssignments.values()){
                 account_email.put(va.Vendor__c, va.UNITY_Vendor_Email__c );
             }
             Map<id, Account> accountCandidates = new Map<id, Account>([SELECT id, Account_Email__c  FROM Account WHERE id IN :account_email.keySet()]);
             for(Account va :accountCandidates.values()){
                 System.assertEquals(va.Account_Email__c, account_email.get(va.Id), 'The emails should be the same.');
             }
  
        Test.stopTest();
        
    }
    
    
    
}