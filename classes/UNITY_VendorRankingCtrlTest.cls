@isTest
public class UNITY_VendorRankingCtrlTest {
	
    static testMethod void setRanking(){
        
        Map<String,Object> data = data_A();
        Account customer      = (Account)data.get('customer');
        FSO__Skill__c skill   = (FSO__Skill__c)data.get('skill');
        String locationKey    = (String)data.get('locationKey');
        List<Account> vendors = (List<Account>)data.get('vendors');
        List<UNITY_Vendor_Trade__c>               vendorTrades      = (List<UNITY_Vendor_Trade__c>)data.get('vendorTrades');
        List<UNITY_Vendor_Covered_Location__c>    locationVendors   = (List<UNITY_Vendor_Covered_Location__c>)data.get('locationVendors');
        
        Test.startTest();
        	
        	PageReference pageRef = Page.UNITY_VendorRanking;
       	    pageRef.getParameters().put('customerId', customer.id);
            pageRef.getParameters().put('vendorId'  , vendors.get(0).id);
            pageRef.getParameters().put('tradeId'   , skill.id);
        
            Test.setCurrentPage(pageRef); 
        
        	UNITY_VendorRankingCtrl ctrl = new UNITY_VendorRankingCtrl();
            ctrl.getTypes();
            ctrl.save();
        	
            pageRef.getParameters().put('vendorId'  , vendors.get(1).id);
            Test.setCurrentPage(pageRef); 
        
            ctrl = new UNITY_VendorRankingCtrl();
            ctrl.goUp();
        	ctrl.goDown();
            ctrl.save();
        	
            pageRef.getParameters().put('vendorId'  , vendors.get(1).id);
            Test.setCurrentPage(pageRef); 
        
            ctrl = new UNITY_VendorRankingCtrl();
            ctrl.vendorRankingToDelete = vendors.get(0).id;
            ctrl.deletePreference();
        
        Test.stopTest();
    }
    
    /*
     * Name : data_A
     */
    static Map<String,Object> data_A() {
        
        // MAP TO RETURN 
        Map<String,Object> toReturn = new Map<String,Object>();
        
        Account customer  = new Account();
        List<Account> vendors = new List<Account>();
        List<Account> accounts = new List<Account>();
        List<UNITY_Vendor_Trade__c>               vendorTrades           = new List<UNITY_Vendor_Trade__c>();
        List<UNITY_Vendor_Covered_Location__c>    locationVendors        = new List<UNITY_Vendor_Covered_Location__c>();
        Map<id,UNITY_Vendor_Preference__c>        vendorPreferences      = new Map<id,UNITY_Vendor_Preference__c>();
        List<UNITY_Vendor_Preference_By_Trade__c> vendorPreferenceTrades = new List<UNITY_Vendor_Preference_By_Trade__c>();
        
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
                                                                        
        // CREATE CUSTOMER                                                             
        accountFields.put('ShippingPostalCode', UNITY_Utils.generateRandomPin()+'-'+UNITY_Utils.generateRandomPin());
        accountFields.put('RecordTypeId', UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE);
        accountFields.put('Name', 'C-'+UNITY_Utils.generateRandomPin());
        customer = (Account)UNITY_TestDataFactory.createObject(1, Account.getSObjectType(),accountFields ).get(0);
        customer.Type = 'Site/Location';
        toReturn.put('customer', customer);
        
        // CREATE VENDORS 
        vendors.addAll(UNITY_TestDataFactory.createAccounts(12, UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE, serviceRequestType, todayWorkTime, true,'SR_'));
        toReturn.put('vendors', vendors);
        
        accounts.addAll(vendors);
        accounts.add(customer);
        
        insert accounts;
        
        // CREATE SKILL
        FSO__Skill__c skill = UNITY_TestDataFactory.createSkills(1, false).get(0);
        insert skill;
        toReturn.put('skill', skill);
       
        // CREATE VENDOR TRADE PER VENDOR
        for(integer index = 0 ; index < vendors.size(); index++ ){
                
            Account onVendor =  vendors.get(index);
                
            vendorTradeFields.put('Trade__c' , skill.id);
            vendorTradeFields.put('Vendor__c', onVendor.id);
                
            vendorTradeFields.put('Score_SR__c', System.Math.round((System.Math.random()*8)+1));
            vendorTradeFields.put('Price_SR__c', 10);
                
            UNITY_Vendor_Trade__c  vendorTrade  = (UNITY_Vendor_Trade__c)UNITY_TestDataFactory.createObject(1, UNITY_Vendor_Trade__c.getSObjectType(), vendorTradeFields).get(0);
            vendorTrades.add(vendorTrade);
        }
        insert vendorTrades;
        toReturn.put('vendorTrades', vendorTrades);
        
        
        vendorLocationFields.put('Location_Key__c', UNITY_Utils.getLocationKey(customer.ShippingCountryCode, customer.ShippingPostalCode));
        toReturn.put('locationKey',UNITY_Utils.getLocationKey(customer.ShippingCountryCode, customer.ShippingPostalCode));
        
        
        // CREATE VENDOR LOCARIONS 
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