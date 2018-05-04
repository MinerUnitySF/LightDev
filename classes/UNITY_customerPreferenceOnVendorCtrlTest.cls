@isTest
public class UNITY_customerPreferenceOnVendorCtrlTest {
    
    @testSetup 
    static void init() {
            
        Account customer              = new Account();
        List<Account> accounts        = new List<Account>();
        List<Account> accountsPM      = new List<Account>();
        List<Account> accountsSS      = new List<Account>();
        List<Account> accountsSR      = new List<Account>();
        List<Account> accountsVendors= new List<Account>();
        
        List<FSO__Skill__c> skills = new List<FSO__Skill__c>();
        List<UNITY_Vendor_Preference__c> preferences = new List<UNITY_Vendor_Preference__c>();
        List<UNITY_Vendor_Trade__c>               vendorTrades      = new List<UNITY_Vendor_Trade__c>();
        List<UNITY_Vendor_Covered_Location__c>    locationVendors   = new List<UNITY_Vendor_Covered_Location__c>();
        Map<id,UNITY_Vendor_Preference__c>        vendorPreferences = new Map<id,UNITY_Vendor_Preference__c>();
        List<UNITY_Vendor_Preference_By_Trade__c> vendorPreferenceTrades = new List<UNITY_Vendor_Preference_By_Trade__c>();
        
        
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
        customer = (Account)UNITY_TestDataFactory.createObject(1, Account.getSObjectType(),accountFields ).get(0); 
        
        accountsSR.addAll(UNITY_TestDataFactory.createAccounts(12, UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE, serviceRequestType, todayWorkTime, true,'SR_'));
        accountsSS.addAll(UNITY_TestDataFactory.createAccounts(12, UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE, siteSurveyType    , todayWorkTime, true,'SS_'));
        accountsPM.addAll(UNITY_TestDataFactory.createAccounts(12, UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE, preventativeMaintenanceType, todayWorkTime, true,'PM_'));
        
        accounts.addAll(accountsSR);
        accounts.addAll(accountsPM);
        accounts.addAll(accountsSS);
        
        accountsVendors.addAll(accounts);
        
        accounts.add(customer);
        insert accounts;
        
        
        for(Account var :accountsSR){
            UNITY_Vendor_Preference__c onPreference= new UNITY_Vendor_Preference__c();
            onPreference.Vendor__c   = var.id;
            onPreference.Customer__c = customer.id;
            onPreference.Type__c = 'Preferred';
            onPreference.Ranking__c  = System.Math.round((System.Math.random()*8)) ;
            preferences.add(onPreference);
        }
        insert preferences;
        
        skills = UNITY_TestDataFactory.createSkills(3, false);
        insert skills;
       
        
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
        
    }
    
    static testMethod void setPreferenceTest(){
        
        Account onCustomer = [SELECT id,ShippingCountryCode,ShippingPostalCode FROM Account WHERE  RecordtypeId = :UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE  LIMIT 1 ];
        Account onVendorSS   = [SELECT id FROM Account WHERE  (RecordtypeId = :UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE) AND (UNITY_Vendor_Type_SS__c = true) LIMIT 1 ];
        Account onVendorSR   = [SELECT id FROM Account WHERE  (RecordtypeId = :UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE) AND (UNITY_Vendor_Type_SR__c = true) LIMIT 1 ]; 
        
        // get all the skills 
        list<FSO__Skill__c> skills= [SELECT id, name  FROM FSO__Skill__c ];
         
        // get the location key from the Customer 
        String locationKey = UNITY_Utils.getLocationKey(onCustomer.ShippingCountryCode, onCustomer.ShippingPostalCode);
         
        // get all the vendors al the location 
        list<UNITY_Vendor_Covered_Location__c> locations = [SELECT id, Vendor__c FROM UNITY_Vendor_Covered_Location__c where Location_Key__c = :locationKey];
        
        // capture the vendor ids 
        list<id> vendorsIds = new list<id>();
        for(UNITY_Vendor_Covered_Location__c var :locations) vendorsIds.add(var.Vendor__c) ;
        
        Test.startTest();
        
            PageReference pageRef = Page.UNITY_customerPreferenceOnVendor;
            Test.setCurrentPage(pageRef);
        
            UNITY_customerPreferenceOnVendorCtrl controller = new UNITY_customerPreferenceOnVendorCtrl();
        
            ApexPages.currentPage().getParameters().put('customerId', onCustomer.id);
            ApexPages.currentPage().getParameters().put('vendorId'  , onVendorSR.id);
        
            controller = new UNITY_customerPreferenceOnVendorCtrl();
            controller.getData();
        
            system.assertEquals(12, controller.preferences.size(), 'Should be 12 preferred vendors.');
            
            UNITY_customerPreferenceOnVendorCtrl.VendorPreference aux_v = null;
            
            for(UNITY_customerPreferenceOnVendorCtrl.VendorPreference var : controller.preferences){
                if(var.id == onVendorSR.id){
                    aux_v = var;
                }
            }
            
            system.assert(aux_v != null);
            system.assert(aux_v.preferenceId != null);
            
            aux_v.preferenceType = 'Do Not Use';
            
                
            UNITY_customerPreferenceOnVendorCtrl.upsertVendorPreference(new list<UNITY_customerPreferenceOnVendorCtrl.VendorPreference>{aux_v} , onCustomer.id, onVendorSR.id);
            
            UNITY_Vendor_Preference__c vp = [SELECT id, Type__c  FROM UNITY_Vendor_Preference__c WHERE id = :aux_v.preferenceId ];    
            
            system.assertEquals('Do Not Use',vp.Type__c, 'The vendor should not be preferred.');
            
            ApexPages.currentPage().getParameters().put('customerId', onCustomer.id);
            ApexPages.currentPage().getParameters().put('vendorId'  , onVendorSS.id);
        
            controller = new UNITY_customerPreferenceOnVendorCtrl();
            controller.getData();
            
            aux_v = null;
        
            for(UNITY_customerPreferenceOnVendorCtrl.VendorPreference var : controller.preferences){
                if(var.id == onVendorSS.id){
                    aux_v = var;
                }
            }
            
            system.assert(aux_v != null);
            system.assert(aux_v.preferenceId == null);
        
            UNITY_customerPreferenceOnVendorCtrl.upsertVendorPreference(new list<UNITY_customerPreferenceOnVendorCtrl.VendorPreference>{aux_v} , onCustomer.id, onVendorSS.id);
            
            vp = [SELECT id, Type__c  FROM UNITY_Vendor_Preference__c WHERE Customer__c  = :onCustomer.id AND  Vendor__c = :aux_v.id];    
            
            system.assertEquals('Preferred',vp.Type__c, 'The vendor should not be preferred.');
           
        
        Test.stopTest();
        
    }
    
    static testMethod void setTradePreferenceTest(){
        
        Account onCustomer = [SELECT id,ShippingCountryCode,ShippingPostalCode FROM Account WHERE  RecordtypeId = :UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE  LIMIT 1 ];
        Account onVendorSR   = [SELECT id FROM Account WHERE  (RecordtypeId = :UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE) AND (UNITY_Vendor_Type_SR__c = true) LIMIT 1 ];
        
        // get all the skills 
        list<FSO__Skill__c> skills = [SELECT id, name  FROM FSO__Skill__c ];
        
        list<UNITY_Vendor_Trade__c> vts = [SELECT id ,Vendor__c, Trade__c  FROM UNITY_Vendor_Trade__c WHERE Vendor__c = :onVendorSR.id ];
        
        UNITY_Vendor_Preference__c vp = [SELECT id FROM  UNITY_Vendor_Preference__c WHERE  (Customer__c = :onCustomer.id) AND (Vendor__c = :onVendorSR.id) LIMIT 1 ];
        
        Test.startTest();
        
            PageReference pageRef = Page.UNITY_customerPreferenceOnVendor;
            Test.setCurrentPage(pageRef);
        
            UNITY_customerPreferenceOnVendorCtrl controller = new UNITY_customerPreferenceOnVendorCtrl();
        
            ApexPages.currentPage().getParameters().put('customerId', onCustomer.id);
            ApexPages.currentPage().getParameters().put('vendorId'  , onVendorSR.id);
        
            controller = new UNITY_customerPreferenceOnVendorCtrl();
            controller.getData();
            
            system.assertEquals(vts.size(), controller.TradeCovered.size());
            
            List<Id> skillIds =  new List<Id>();
            for(UNITY_Vendor_Trade__c var :vts){
                skillIds.add(var.Trade__c  );
            }
            
            UNITY_customerPreferenceOnVendorCtrl.createTradesPreference(skillIds, onCustomer.id, onVendorSR.id, vp.id);
            
            controller = new UNITY_customerPreferenceOnVendorCtrl();
            controller.getData();
        
            list<UNITY_Vendor_Preference_By_Trade__c> vpt = [SELECT id FROM UNITY_Vendor_Preference_By_Trade__c WHERE  (Customer__c = :onCustomer.id) AND (Vendor__c = :onVendorSR.id) AND (Trade__c IN :skillIds)];
            
            system.assertEquals(vts.size(), vpt.size());
            
            UNITY_customerPreferenceOnVendorCtrl.deletePreferencesOnVendor( onCustomer.id, onVendorSR.id, vp.id );
            
            vpt = [SELECT id FROM UNITY_Vendor_Preference_By_Trade__c WHERE  (Customer__c = :onCustomer.id) AND (Vendor__c = :onVendorSR.id) AND (Trade__c IN :skillIds)];
            
            system.assertEquals(0, vpt.size());
        
        Test.stopTest();
        
    }
    
    
}