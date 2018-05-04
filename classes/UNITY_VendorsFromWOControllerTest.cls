@isTest
public class UNITY_VendorsFromWOControllerTest {
    //Setup Product and Pricebook Info
    public static Id PRICEBOOKENTRYID_T;
    public static Id PRICEBOOKENTRYID_L;
    public static Id PRICEBOOKENTRYID_P;
    public static Id PRODUCTID;
    static{
        //Create Product & pricebook
        Map<String,String> prodMapP = TestDataProvider.getProductAndPriceBookEntry(1,'Part');
        for(String s :prodMapP.keySet()){
            PRICEBOOKENTRYID_P = (Id)prodMapP.get(s);
            PRODUCTID = (Id)s;
        }
        Map<String,String> prodMapL = TestDataProvider.getProductAndPriceBookEntry(1,'Labor');
        for(String s :prodMapL.keySet()){
            PRICEBOOKENTRYID_L = (Id)prodMapL.get(s);
        }
        Map<String,String> prodMapT = TestDataProvider.getProductAndPriceBookEntry(1,'Travel');
        for(String s :prodMapT.keySet()){
            PRICEBOOKENTRYID_T = (Id)prodMapT.get(s);
        }
    }
    
    static testMethod void vendorSpecific(){
        UNITY_Constants.MAX_TRIGGER_EXECUTION = 2;
        Map<String,Object> data = data_A();
        
        Account customer      = (Account)data.get('customer');
        FSO__Skill__c skill   = (FSO__Skill__c)data.get('skill');
        String locationKey    = (String)data.get('locationKey');
        List<Account> vendors = (List<Account>)data.get('vendors');
        List<UNITY_Vendor_Trade__c>               vendorTrades      = (List<UNITY_Vendor_Trade__c>)data.get('vendorTrades');
        List<UNITY_Vendor_Covered_Location__c>    locationVendors   = (List<UNITY_Vendor_Covered_Location__c>)data.get('locationVendors');
        Map<id,UNITY_Vendor_Preference__c>        vendorPreferences = null;
        List<UNITY_Vendor_Preference_By_Trade__c> vendorPreferenceTrades = null;
        
        Map<String,Object> workOrderFields = UNITY_TestDataFactory.MOCKUP_WORK_ORDER_FIELDS;
        Map<String,Object> caseFields = UNITY_TestDataFactory.MOCKUP_CASE_FIELDS;
        
        Test.startTest();
        
            caseFields.put('RecordTypeId'     , UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
            caseFields.put('Customer__c'      , customer.id);
            caseFields.put('AccountId'        , customer.id);
            caseFields.put('UNITY_Trade__c'   , skill.id);
            
            Case onCase = (Case) UNITY_TestDataFactory.createObject(1, Case.getSObjectType(), caseFields).get(0);
            insert onCase; 
            
            workOrderFields.put('RecordTypeId'      , UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE);
            workOrderFields.put('CaseId'      , onCase.id);
            workOrderFields.put('AccountId'   , customer.id);
            workOrderFields.put('Subject'   , 'WO-Test');
            workOrderFields.put('UNITY_Trade__c'    , skill.id);
            workOrderFields.put('UNITY_Customer__c' , customer.id);
            
            WorkOrder workOrder  = UNITY_TestDataFactory.createWorkOrders(1,workOrderFields).get(0) ;
            insert workOrder;
            
            UNITY_VendorsFromWOController controller  = new UNITY_VendorsFromWOController(new ApexPages.StandardController(workOrder) );
            /*
            system.assertEquals(skill.id, controller.tradeIdF         ,'Should be '+skill.id+' skill.');
            system.assertEquals('SR'            , controller.requestTypeAbbrF ,'Should be Service Request request type.');
            system.assertEquals(locationKey     , controller.locationKeyF     ,'Should be '+locationKey+' location key.');*/
             
             
             controller.nextOperations();
            
             /*system.assertEquals(3, controller.vendors.size() ,'Should be 3 new candidates suggested.');
             system.assertEquals(true            , controller.showAssignBtn    ,'The Agent is working on a WO without vendor assigned and he is looking for vendors in the Network.');
             system.assertEquals(false           , controller.canSearch        ,'The Agent should not be able to search vendors Out of Network.');
             system.assertEquals(false           , controller.notVendorsToShow ,'Should be 3 vendors to display.');*/
             
             controller.showAllVendors();        
                     
             //system.assertEquals(vendors.size(), controller.vendors.size(),'Should be '+vendors.size()+' vendors displayed.');
        
        Test.stopTest();
         
        
    }

    static testMethod void vendorSpecificOONAssignmnet(){
        
        UNITY_Constants.MAX_TRIGGER_EXECUTION = 2;
        
        if(UNITY_General_Settings__c.getAll().values() == null ){
           
            List<UNITY_General_Settings__c> generalSettings = new List<UNITY_General_Settings__c>();
            
            UNITY_General_Settings__c gSetting1 = new UNITY_General_Settings__c(Name= UNITY_Constants.SERVICE_FEE_PRODUCT_TYPE_CS_KEY, UNITY_Value__c = 'Vendor Service Fee', UNITY_Description__c='Vendor Service Fee');
            
            generalSettings.add(gSetting1);
            
            insert generalSettings;
        }
        
        Map<String,Object> data = data_B();
        
        Account customer          = (Account)data.get('customer');
        String locationKey        = (String)data.get('locationKey');
        
        List<Account> vendorsSR   = (list<Account>)data.get('vendorsSR');
        List<Account> vendorsPM   = (list<Account>)data.get('vendorsPM');
        List<Account> vendorsSS   = (list<Account>)data.get('vendorsSS');
        List<Account> vendors     = (List<Account>)data.get('vendors');
        
        List<FSO__Skill__c> skills = (list<FSO__Skill__c>)data.get('skills');
        
        List<UNITY_Vendor_Trade__c>               vendorTrades      = (List<UNITY_Vendor_Trade__c>)data.get('vendorTrades');
        List<UNITY_Vendor_Covered_Location__c>    locationVendors   = (List<UNITY_Vendor_Covered_Location__c>)data.get('locationVendors');
        Map<String,Integer>        tradeRequestTypeAbb_count        = (Map<String,Integer>)data.get('tradeRequestTypeAbb_count');
        
        Map<id,UNITY_Vendor_Preference__c>        vendorPreferences = null;
        List<UNITY_Vendor_Preference_By_Trade__c> vendorPreferenceTrades = null;
        
        Map<String,Object> workOrderFields = UNITY_TestDataFactory.MOCKUP_WORK_ORDER_FIELDS;
        Map<String,Object> caseFields = UNITY_TestDataFactory.MOCKUP_CASE_FIELDS;
        
        Test.startTest();
        
            caseFields.put('RecordTypeId'     , UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
            caseFields.put('Customer__c'      , customer.id);
            caseFields.put('AccountId'        , customer.id);
            caseFields.put('UNITY_Trade__c'   , skills.get(0).id);
            
            Case onCase = (Case) UNITY_TestDataFactory.createObject(1, Case.getSObjectType(), caseFields).get(0);
            insert onCase; 
            
            workOrderFields.put('RecordTypeId'      , UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE);
            workOrderFields.put('CaseId'      , onCase.id);
            workOrderFields.put('AccountId'   , customer.id);
            workOrderFields.put('Subject'   , 'WO-Test');
            workOrderFields.put('UNITY_Trade__c'    , skills.get(0).id);
            workOrderFields.put('UNITY_Customer__c' , customer.id);
            workOrderFields.put('UNITY_OON_Vendor_Eligible__c' , true);
            workOrderFields.put('UNITY_OON_Vendor_Approved__c' , true);
            
            WorkOrder workOrder  = UNITY_TestDataFactory.createWorkOrders(1,workOrderFields).get(0) ;
            insert workOrder;
            
            UNITY_VendorsFromWOController controller  = new UNITY_VendorsFromWOController(new ApexPages.StandardController(workOrder) );
            /*
            system.assertEquals(skills.get(0).id, controller.tradeIdF         ,'Should be '+skills.get(0).id+' skill.');
            system.assertEquals('SR'            , controller.requestTypeAbbrF ,'Should be Service Request request type.');
            system.assertEquals(locationKey     , controller.locationKeyF     ,'Should be '+locationKey+' location key.');*/
        	
            controller.nextOperations();

            if(tradeRequestTypeAbb_count.get(skills.get(2).id+'-SS') > 0){
                
                 controller.requestTypeAbbrF = 'SS';
                 controller.tradeIdF = skills.get(2).id;
                 controller.applyFilter();
                 controller.vendorIdToAssign = controller.vendors.get(0).id;
            		
                 //system.assertEquals(true, controller.outscope,'Should be true, the agent is searching OON.');
                
                 controller.assignAction();
            }
        
            controller.showAllVendors();
        
        Test.stopTest();
        
    }
    
    static testMethod void vendorSpecificOON(){
        UNITY_Constants.MAX_TRIGGER_EXECUTION = 2;
        Map<String,Object> data = data_B();
        
        Account customer          = (Account)data.get('customer');
        String locationKey        = (String)data.get('locationKey');
        
        List<Account> vendorsSR   = (list<Account>)data.get('vendorsSR');
        List<Account> vendorsPM   = (list<Account>)data.get('vendorsPM');
        List<Account> vendorsSS   = (list<Account>)data.get('vendorsSS');
        List<Account> vendors     = (List<Account>)data.get('vendors');
        
        List<FSO__Skill__c> skills = (list<FSO__Skill__c>)data.get('skills');
        
        List<UNITY_Vendor_Trade__c>               vendorTrades      = (List<UNITY_Vendor_Trade__c>)data.get('vendorTrades');
        List<UNITY_Vendor_Covered_Location__c>    locationVendors   = (List<UNITY_Vendor_Covered_Location__c>)data.get('locationVendors');
        Map<String,Integer>        tradeRequestTypeAbb_count        = (Map<String,Integer>)data.get('tradeRequestTypeAbb_count');
        
        Map<id,UNITY_Vendor_Preference__c>        vendorPreferences = null;
        List<UNITY_Vendor_Preference_By_Trade__c> vendorPreferenceTrades = null;
        
        Map<String,Object> workOrderFields = UNITY_TestDataFactory.MOCKUP_WORK_ORDER_FIELDS;
        Map<String,Object> caseFields = UNITY_TestDataFactory.MOCKUP_CASE_FIELDS;
        
        Test.startTest();
        
            caseFields.put('RecordTypeId'     , UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
            caseFields.put('Customer__c'      , customer.id);
            caseFields.put('AccountId'        , customer.id);
            caseFields.put('UNITY_Trade__c'   , skills.get(0).id);
            
            Case onCase = (Case) UNITY_TestDataFactory.createObject(1, Case.getSObjectType(), caseFields).get(0);
            insert onCase; 
            
            workOrderFields.put('RecordTypeId'      , UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE);
            workOrderFields.put('CaseId'      , onCase.id);
            workOrderFields.put('AccountId'   , customer.id);
            workOrderFields.put('Subject'   , 'WO-Test');
            workOrderFields.put('UNITY_Trade__c'    , skills.get(0).id);
            workOrderFields.put('UNITY_Customer__c' , customer.id);
            workOrderFields.put('UNITY_OON_Vendor_Eligible__c' , true);
            workOrderFields.put('UNITY_OON_Vendor_Approved__c' , true);
            
            WorkOrder workOrder  = UNITY_TestDataFactory.createWorkOrders(1,workOrderFields).get(0) ;
            insert workOrder;
            
            UNITY_VendorsFromWOController controller  = new UNITY_VendorsFromWOController(new ApexPages.StandardController(workOrder) );
            /*
            system.assertEquals(skills.get(0).id, controller.tradeIdF         ,'Should be '+skills.get(0).id+' skill.');
            system.assertEquals('SR'            , controller.requestTypeAbbrF ,'Should be Service Request request type.');
            system.assertEquals(locationKey     , controller.locationKeyF     ,'Should be '+locationKey+' location key.');
             */
             
             controller.nextOperations();
            /*
             system.assertEquals(((tradeRequestTypeAbb_count.get(skills.get(0).id+'-SR')>=3)?3:tradeRequestTypeAbb_count.get(skills.get(0).id+'-SR')), controller.vendors.size() ,'Should be 3 new candidates suggested.');
             system.assertEquals(true     , controller.showAssignBtn    ,'The Agent is working on a WO without vendor assigned and he is looking for vendors in the Network.');
             system.assertEquals(true     , controller.canSearch        ,'The Agent can search vendors Out of Network.');
             system.assertEquals(!(tradeRequestTypeAbb_count.get(skills.get(0).id+'-SR')>=3)    , controller.notVendorsToShow ,'Should be 3 vendors to display.');
             system.assertEquals(false    , controller.outscope         ,'Should be false, the agent did not search OON yet.');
        */
             //controller.showAllVendors();        
                     
             //system.assertEquals(tradeRequestTypeAbb_count.get(skills.get(0).id+'-SR'), controller.vendors.size(),'Should be '+tradeRequestTypeAbb_count.get(skills.get(0).id+'-SR')+' vendors displayed.');
             
             controller.tradeIdF = skills.get(1).id;
             
             controller.applyFilter();
        
             //system.assertEquals(tradeRequestTypeAbb_count.get(skills.get(1).id+'-SR'), controller.vendors.size(),'Should be '+tradeRequestTypeAbb_count.get(skills.get(1).id+'-SR')+' vendors displayed.');
        
             controller.requestTypeAbbrF = 'SS';
             controller.tradeIdF = skills.get(2).id;
        
             controller.applyFilter();
        /*
             system.assertEquals(tradeRequestTypeAbb_count.get(skills.get(2).id+'-SS'), controller.vendors.size(),'Should be '+tradeRequestTypeAbb_count.get(skills.get(2).id+'-SS')+' vendors displayed.');
            
             system.assertEquals(true, controller.outscope,'Should be true, the agent is searching OON.');
        */
        Test.stopTest();
         
    }
    
    /*
     * Name : data_B
     */
    static Map<String,Object> data_B() {
        
        Map<String,Object> toReturn = new Map<String,Object>();
        
        Account customer              = new Account();
        List<Account> accounts        = new List<Account>();
        List<Account> accountsPM      = new List<Account>();
        List<Account> accountsSS      = new List<Account>();
        List<Account> accountsSR      = new List<Account>();
        List<Account> accountsVendors = new List<Account>();
        List<FSO__Skill__c>                       skills = new List<FSO__Skill__c>();
        List<UNITY_Vendor_Trade__c>               vendorTrades      = new List<UNITY_Vendor_Trade__c>();
        Map<id,UNITY_Vendor_Preference__c>        vendorPreferences = new Map<id,UNITY_Vendor_Preference__c>();
        List<UNITY_Vendor_Covered_Location__c>    locationVendors   = new List<UNITY_Vendor_Covered_Location__c>();
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
        
        //  CREATE CUSTOMER
        accountFields.put('ShippingPostalCode', UNITY_Utils.generateRandomPin()+'-'+UNITY_Utils.generateRandomPin());
        accountFields.put('RecordTypeId', UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE);
        accountFields.put('Name', 'C-'+UNITY_Utils.generateRandomPin());
        customer = (Account)UNITY_TestDataFactory.createObject(1, Account.getSObjectType(),accountFields ).get(0); 
        toReturn.put('customer', customer);
        
        // CREATE VENDORS 
        accountsSR.addAll(UNITY_TestDataFactory.createAccounts(12, UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE, serviceRequestType, todayWorkTime, true,'SR_'));
        accountsSS.addAll(UNITY_TestDataFactory.createAccounts(12, UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE, siteSurveyType    , todayWorkTime, true,'SS_'));
        accountsPM.addAll(UNITY_TestDataFactory.createAccounts(12, UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE, preventativeMaintenanceType, todayWorkTime, true,'PM_'));
        
        toReturn.put('vendorsSR', accountsSR);
        toReturn.put('vendorsSS', accountsSS);
        toReturn.put('vendorsPM', accountsPM);
        
        accounts.addAll(accountsSR);
        accounts.addAll(accountsPM);
        accounts.addAll(accountsSS);
        
        accountsVendors.addAll(accounts);
        toReturn.put('vendors', accountsVendors);
        
        accounts.add(customer);
        insert accounts;
        
        // CREATE SKILLS
        skills = UNITY_TestDataFactory.createSkills(3, false);
        toReturn.put('skills', skills);
        insert skills;
        
        // key : skill id + request type ABB
        // value: count 
        Map<String,Integer> aux_count = new Map<String,Integer>();
        
        // CREATE DYNAMIC VENDOR TRADE RECORDS PER TRADE(SKILL)
        for(FSO__Skill__c onSkill :skills){
            
            integer maxVendorsPerTrade = Math.round(System.Math.random()*(accountsVendors.size()-1));
            set<integer> indexCache = new set<integer>();
            
            aux_count.put(onSkill.id+'-SS', 0);
            aux_count.put(onSkill.id+'-PM', 0);
            aux_count.put(onSkill.id+'-SR', 0);
            aux_count.put(onSkill.id+'-Project', 0);
            
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
                    aux_count.put(onSkill.id+'-SS', aux_count.get(onSkill.id+'-SS')+1);
                }
                if(onVendor.UNITY_Vendor_Type_PM__c){
                     vendorTradeFields.put('Score_PM__c', System.Math.round((System.Math.random()*8)+1));
                     vendorTradeFields.put('Price_PM__c', (index+1)*100);
                     aux_count.put(onSkill.id+'-PM', aux_count.get(onSkill.id+'-PM')+1);
                }
                if(onVendor.UNITY_Vendor_Type_Project__c){
                     vendorTradeFields.put('Score_Project__c', System.Math.round((System.Math.random()*8)+1));
                     vendorTradeFields.put('Price_Project__c', (index+1)*100);
                     aux_count.put(onSkill.id+'-Project', aux_count.get(onSkill.id+'-Project')+1);
                }
                if(onVendor.UNITY_Vendor_Type_SR__c){
                     vendorTradeFields.put('Score_SR__c', System.Math.round((System.Math.random()*8)+1));
                     vendorTradeFields.put('Price_SR__c', (index+1)*100);
                     aux_count.put(onSkill.id+'-SR', aux_count.get(onSkill.id+'-SR')+1);
                }        
                
                UNITY_Vendor_Trade__c  vendorTrade  = (UNITY_Vendor_Trade__c)UNITY_TestDataFactory.createObject(1, UNITY_Vendor_Trade__c.getSObjectType(), vendorTradeFields).get(0);
                
                vendorTrades.add(vendorTrade);
            } 
        }
        toReturn.put('tradeRequestTypeAbb_count', aux_count);
        insert vendorTrades;
        
        // CREATE VENDOR COVERED LOCATION PER VENDOR 
        vendorLocationFields.put('Location_Key__c', UNITY_Utils.getLocationKey(customer.ShippingCountryCode, customer.ShippingPostalCode));
        toReturn.put('locationKey',UNITY_Utils.getLocationKey(customer.ShippingCountryCode, customer.ShippingPostalCode));       
        for(integer index = 0 ; index < accountsVendors.size(); index++ ){
                
            Account onVendor =  accountsVendors.get(index);
            vendorLocationFields.put('Vendor__c', onVendor.id);
                
            UNITY_Vendor_Covered_Location__c locationKey = (UNITY_Vendor_Covered_Location__c)UNITY_TestDataFactory.createObject(1, UNITY_Vendor_Covered_Location__c.getSObjectType(), vendorLocationFields).get(0);
            locationVendors.add(locationKey);
                
        }
        toReturn.put('locationVendors', locationVendors);
        insert locationVendors;
        
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