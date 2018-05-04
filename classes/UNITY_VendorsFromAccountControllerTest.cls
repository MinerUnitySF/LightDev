@isTest
public class UNITY_VendorsFromAccountControllerTest {
    
    @testSetup 
    static void init() {
            
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
        
    }
        
    static testMethod void vendorSpecificTest(){
        
        // get one customer
        Account onCustomer = [SELECT id, name, ShippingPostalCode, ShippingCountryCode  FROM Account WHERE RecordTypeId = :UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE LIMIT 1];
        
        // get all the skills 
        list<FSO__Skill__c> skills= [SELECT id, name  FROM FSO__Skill__c ];
         
        // get the location key from the Customer 
        String locationKey = UNITY_Utils.getLocationKey(onCustomer.ShippingCountryCode, onCustomer.ShippingPostalCode);
         
        // get all the vendors al the location 
        list<UNITY_Vendor_Covered_Location__c > locations = [SELECT id, Vendor__c FROM UNITY_Vendor_Covered_Location__c where Location_Key__c = :locationKey];
        
        // capture the vendor ids 
        list<id> vendorsIds = new list<id>();
        for(UNITY_Vendor_Covered_Location__c var :locations) vendorsIds.add(var.Vendor__c) ;
        
        // query the vendors
        Map<id,Account> vendors = new Map<id,Account>([SELECT   id, 
                                                                name,  
                                                                UNITY_Vendor_Type_SR__c,
                                                                UNITY_Vendor_Type_Project__c,
                                                                UNITY_Vendor_Type_PM__c,
                                                                UNITY_Vendor_Type_SS__c,
                                                                (SELECT id,Trade__c FROM Vendor_Trades__r) 
                                                       FROM Account WHERE id IN :vendorsIds AND UNITY_Do_Not_Use__c = false]);
        
         Map<String,Map<String,Integer>> skill_rt_count =  new  Map<String,Map<String,Integer>>();
         for(Account vendor :vendors.values()){
            for(UNITY_Vendor_Trade__c trade :vendor.Vendor_Trades__r){
                if(vendor.UNITY_Vendor_Type_SR__c){
                    if(skill_rt_count.get('SR') == null)skill_rt_count.put('SR',new Map<String,Integer>());
                    if(skill_rt_count.get('SR').get(trade.Trade__c ) == null) skill_rt_count.get('SR').put(trade.Trade__c ,1);
                        else skill_rt_count.get('SR').put(trade.Trade__c ,skill_rt_count.get('SR').get(trade.Trade__c )+1);
                }
                if(vendor.UNITY_Vendor_Type_Project__c){
                    if(skill_rt_count.get('Project') == null)skill_rt_count.put('Project',new Map<String,Integer>());
                    if(skill_rt_count.get('Project').get(trade.Trade__c ) == null) skill_rt_count.get('Project').put(trade.Trade__c ,1);
                        else skill_rt_count.get('Project').put(trade.Trade__c ,skill_rt_count.get('Project').get(trade.Trade__c )+1);
                }
                if(vendor.UNITY_Vendor_Type_PM__c){
                    if(skill_rt_count.get('PM') == null)skill_rt_count.put('PM',new Map<String,Integer>());
                    if(skill_rt_count.get('PM').get(trade.Trade__c ) == null) skill_rt_count.get('PM').put(trade.Trade__c ,1); 
                       else skill_rt_count.get('PM').put(trade.Trade__c ,skill_rt_count.get('PM').get(trade.Trade__c )+1);
                }
                if(vendor.UNITY_Vendor_Type_SS__c){
                    if(skill_rt_count.get('SS') == null)skill_rt_count.put('SS',new Map<String,Integer>());
                    if(skill_rt_count.get('SS').get(trade.Trade__c ) == null) skill_rt_count.get('SS').put(trade.Trade__c ,1);
                        else skill_rt_count.get('SS').put(trade.Trade__c ,skill_rt_count.get('SS').get(trade.Trade__c )+1);
                }
            }    
         }
                
         UNITY_VendorsFromAccountController controller  = new UNITY_VendorsFromAccountController(new ApexPages.StandardController(onCustomer) );
        
         system.assertEquals('SR'            , controller.recordTypeFilter ,'Should be Service Request request type.');
         system.debug('##### test size '+controller.vendors.size());
         for(UNITY_wrapperVendorByTrade var :controller.vendors){
             system.debug('##### 111111 test '+var.name);
             system.debug('##### test '+var.tradeName);
             system.debug('##### test '+var.status);
             system.debug('##### test '+var.isRT('SR'));
             
         }
        
         integer compareWith = ((skill_rt_count.get('SR').get(controller.tradeFilter) == null)?0:skill_rt_count.get('SR').get(controller.tradeFilter));
         system.assertEquals(compareWith, controller.vendors.size(),'Should be '+skill_rt_count.get('SR').get(controller.tradeFilter)+' vendors displayed.');
         
         controller.recordTypeFilter = 'SS';
         
         controller.filterByRecordType();
         
         compareWith = ((skill_rt_count.get('SS').get(controller.tradeFilter) == null)?0:skill_rt_count.get('SS').get(controller.tradeFilter));
         system.assertEquals(compareWith, controller.vendors.size(),'Should be '+skill_rt_count.get('SR').get(controller.tradeFilter)+' vendors displayed.');
        
         controller.tradeFilter = skills.get(1).id;
        
         controller.filterByTrade();
         
         compareWith = ((skill_rt_count.get('SS').get(skills.get(1).id) == null)?0:skill_rt_count.get('SS').get(skills.get(1).id));
         system.assertEquals(compareWith, 
                              controller.vendors.size(),'Should be '+((skill_rt_count.get('SS').get(skills.get(1).id)==null)?0:skill_rt_count.get('SS').get(skills.get(1).id))+' vendors displayed.');
         
    }
}