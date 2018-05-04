@isTest
public class UNITY_VendorsAtLocationTest {
    
   
    static void dataA() {
        
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
    
    /*
    *   @programer:    Samuel Astol
    *   @date:         12/15/2015             
    *   @description:  retrieve the vendors at the location from the Customer account and from WO context, test the creation of vendors assignment if it required from WO context
    * 
    *   @note:         Data required 
    *                  # FSO__Skill__c  
    *                  # Vendor Accounts  -> Vendor Trade 
    *                  # Customer Account -> Cases    -> Work Orders -> Vandor Assignments  
    *                                     -> Vendor Preferences to Vendor Accounts
    *                                     -> Vendor Preferences by Trade 
    */
    static testMethod void vendorSpecificTest(){
        UNITY_Constants.MAX_TRIGGER_EXECUTION = 2;
        dataA();
            
        // get account customer
        Account  onCustomer = [SELECT id, Name, ShippingCountryCode, ShippingPostalCode  FROM Account WHERE recordTypeId = :UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE LIMIT 1];
        
        // get customer location key 
        String locationKey = UNITY_Utils.getLocationKey(onCustomer.ShippingCountryCode, onCustomer.ShippingPostalCode);
        
        // get vendors which covers the customer location key 
        list<UNITY_Vendor_Covered_Location__c> locationV = [SELECT id, Name, Vendor__c FROM UNITY_Vendor_Covered_Location__c  WHERE (Location_Key__c = :locationKey) AND (Vendor__r.UNITY_Do_Not_Use__c  = false)];
        
        set<id> vendorIds = new set<id>();

        for(UNITY_Vendor_Covered_Location__c vl :locationV){
            vendorIds.add(vl.Vendor__c);
        }
        
        list<UNITY_Vendor_Preference__c >  customerP = [SELECT id, Name, Vendor__c, Customer__c FROM UNITY_Vendor_Preference__c WHERE (Customer__c = :onCustomer.id) AND (Type__c ='DO NOT USE')];
        
        for(UNITY_Vendor_Preference__c vp :customerP){
            vendorIds.remove(vp.Vendor__c);
        }
        
        list<UNITY_Vendor_Trade__c> tradeV = [SELECT  id, Name, Vendor__c, Trade__c,
                                                      Vendor__r.UNITY_Vendor_Type_SS__c,
                                                      Vendor__r.UNITY_Vendor_Type_Project__c,
                                                      Vendor__r.UNITY_Vendor_Type_PM__c,
                                                      Vendor__r.UNITY_Vendor_Type_SR__c
                                              FROM UNITY_Vendor_Trade__c  WHERE Vendor__c IN :vendorIds];
        
        Map<String,Integer> requestTypeTrade_vendorCount =  new Map<String,Integer>();
        List<id> skills =  new List<id>();
        Set<id>  skills_control =  new Set<id>();   
        
        for(UNITY_Vendor_Trade__c vt :tradeV){
            
            if(requestTypeTrade_vendorCount.get('SS'+vt.Trade__c) == null){
                requestTypeTrade_vendorCount.put('SS'+vt.Trade__c, 0);
            }
            if(requestTypeTrade_vendorCount.get('PM'+vt.Trade__c) == null){
                requestTypeTrade_vendorCount.put('PM'+vt.Trade__c, 0);
            }
            if(requestTypeTrade_vendorCount.get('Project'+vt.Trade__c) == null){
                requestTypeTrade_vendorCount.put('Project'+vt.Trade__c, 0);
            }
            if(requestTypeTrade_vendorCount.get('SR'+vt.Trade__c) == null){
                requestTypeTrade_vendorCount.put('SR'+vt.Trade__c, 0);
            }
            
            if(vt.Vendor__r.UNITY_Vendor_Type_SS__c){
                requestTypeTrade_vendorCount.put('SS'+vt.Trade__c     , requestTypeTrade_vendorCount.get('SS'+vt.Trade__c)+ 1);
            }
            if(vt.Vendor__r.UNITY_Vendor_Type_PM__c){
               requestTypeTrade_vendorCount.put('PM'+vt.Trade__c      , requestTypeTrade_vendorCount.get('PM'+vt.Trade__c)+ 1);
            }
            if(vt.Vendor__r.UNITY_Vendor_Type_Project__c){
                requestTypeTrade_vendorCount.put('Project'+vt.Trade__c, requestTypeTrade_vendorCount.get('Project'+vt.Trade__c)+ 1);
            }
            if(vt.Vendor__r.UNITY_Vendor_Type_SR__c){
                requestTypeTrade_vendorCount.put('SR'+vt.Trade__c     , requestTypeTrade_vendorCount.get('SR'+vt.Trade__c)+ 1);
            }
            if(!skills_control.contains(vt.Trade__c)){
                skills_control.add(vt.Trade__c);
                skills.add(vt.Trade__c);
            }
        }
        
        Test.startTest();
            
            integer numberOfSkill = skills.size();
        
            integer indexSkill = ((numberOfSkill - 1 )>0) ? (numberOfSkill - 1) :  0 ;
        
            Map< id, list<UNITY_wrapperVendorByTrade>> account_vendors = UNITY_Vendor_Utils.getVendorsSpecific(new list<id>{onCustomer.id}, Account.getsObjectType(), null , false, false);
            
        
            list<UNITY_wrapperVendorByTrade> vendors_glass = UNITY_Vendor_Utils.wrapperVendorByTradeFilter(account_vendors.get(onCustomer.id), 'SR', skills.get(indexSkill),null,null);
        
                 System.assertEquals(requestTypeTrade_vendorCount.get('SR'+skills.get(indexSkill))  , vendors_glass.size()   , 'Should be '+requestTypeTrade_vendorCount.get('SR'+skills.get(indexSkill))+' vendors for '+skills.get(indexSkill)+' trade and SR request type.');
        
            vendors_glass = UNITY_Vendor_Utils.wrapperVendorByTradeFilter(account_vendors.get(onCustomer.id), 'SS', skills.get(indexSkill),null,null);
        
                 System.assertEquals(requestTypeTrade_vendorCount.get('SS'+skills.get(indexSkill))  , vendors_glass.size()   , 'Should be '+requestTypeTrade_vendorCount.get('SS'+skills.get(indexSkill)) +' vendors for '+skills.get(indexSkill)+' trade and SS request type.');
        
            indexSkill = ((numberOfSkill - 2 )>0) ? (numberOfSkill - 2) :  0 ;  
                                                                                                                             
            vendors_glass = UNITY_Vendor_Utils.wrapperVendorByTradeFilter(account_vendors.get(onCustomer.id), 'SS', skills.get(indexSkill),null,null);
        
                 System.assertEquals(requestTypeTrade_vendorCount.get('SS'+skills.get(indexSkill))   , vendors_glass.size()   , 'Should be '+requestTypeTrade_vendorCount.get('SS'+skills.get(indexSkill))+' vendors for '+skills.get(indexSkill)+' trade and SS request type.');
        
            vendors_glass = UNITY_Vendor_Utils.wrapperVendorByTradeFilter(account_vendors.get(onCustomer.id), 'SR', skills.get(indexSkill),null,null);
        
                 System.assertEquals(requestTypeTrade_vendorCount.get('SR'+skills.get(indexSkill))  , vendors_glass.size()   , 'Should be '+requestTypeTrade_vendorCount.get('SR'+skills.get(indexSkill)) +' vendors for '+skills.get(indexSkill)+' trade and SR request type.');
        
        
             Map<String,Object> workOrderFields = UNITY_TestDataFactory.MOCKUP_WORK_ORDER_FIELDS;
             Map<String,Object> caseFields = UNITY_TestDataFactory.MOCKUP_CASE_FIELDS;
             list<Case> cases = new list<Case>();
        
             caseFields.put('Customer__c', onCustomer.id);
             caseFields.put('AccountId', onCustomer.id);
             caseFields.put('RecordTypeId', UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
             
             for(id skillId :skills){
                
                caseFields.put('UNITY_Trade__c',skillId); 
                cases.add((Case) UNITY_TestDataFactory.createObject(1, Case.getSObjectType(), caseFields).get(0));
             }
             insert cases;
        
             workOrderFields.put('RecordTypeId', UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE);
             workOrderFields.put('AccountId', onCustomer.id);
             workOrderFields.put('Subject', 'WO-Test');
             workOrderFields.put('UNITY_Customer__c', onCustomer.id);
        
             List<WorkOrder> workOrders = new List<WorkOrder>();
             for(Case onCase :cases){
                 workOrderFields.put('UNITY_Trade__c',onCase.UNITY_Trade__c); 
                 workOrderFields.put('CaseId',onCase.id);
                 workOrders.addAll(UNITY_TestDataFactory.createWorkOrders(1,workOrderFields));
             }
        
             insert workOrders;
        
             list<id> woIds = new list<id>();
             Map<id,id> woToTrade = new Map<id,id>();
        
             for(WorkOrder wo :workOrders){
                woIds.add(wo.id);
                woToTrade.put(wo.id, wo.UNITY_Trade__c);
             }
        
             Map< id, list<UNITY_wrapperVendorByTrade>> wo_vendors = UNITY_Vendor_Utils.getVendorsSpecific(woIds, WorkOrder.getSObjectType(), null, false,  false);
             
                System.assertEquals(woIds.size()  , wo_vendors.size()   , '');
             
             for(id woId :wo_vendors.keySet()){
                System.assertEquals(requestTypeTrade_vendorCount.get('SR'+woToTrade.get(woId)), wo_vendors.get(woId).size() , '');
             }
        
             wo_vendors = UNITY_Vendor_Utils.getVendorsSpecific(woIds, WorkOrder.getSObjectType(), null, true,  true);
                
             //System.assertEquals(woIds.size()  , wo_vendors.size()   , '');
             /*
             for(id woId :wo_vendors.keySet()){
                System.assertEquals(((requestTypeTrade_vendorCount.get('SR'+woToTrade.get(woId))>=3)?3:requestTypeTrade_vendorCount.get('SR'+woToTrade.get(woId))), wo_vendors.get(woId).size() , '');
             }*/
             wo_vendors = UNITY_Vendor_Utils.getVendorsSpecific(woIds, WorkOrder.getSObjectType(), null, false,  false);
        
             wo_vendors = UNITY_Vendor_Utils.getVendorsSpecific(woIds, WorkOrder.getSObjectType(), null, true,  true);
        
             UNITY_Vendor_Utils.createVendorCandidates( wo_vendors.get(workOrders.get(0).id), workOrders.get(0));
        
             wo_vendors.get(workOrders.get(0).id).get(0).isCandidateOffHours = true;
             wo_vendors.get(workOrders.get(0).id).get(0).isCandidateBelowMargin = true;
             wo_vendors.get(workOrders.get(0).id).get(0).isRejected = true;
             wo_vendors.get(workOrders.get(0).id).get(0).isOON = true;
             UNITY_Vendor_Utils.getVendorAssignmentWarning(wo_vendors.get(workOrders.get(0).id).get(0),true);
        Test.stopTest();
        
        UNITY_Vendor_Utils.getVendorsSpecific(locationKey);
    }
    
    /*
    *   @programer:    Samuel Astol
    *   @date:         12/15/2015             
    *   @description:  Assign Miner account as Vendor Assigned to WO and verify that the suggested technician is populated 
    * 
    *   @note:         Data required 
    *                  # FSO__Skill__c  
    *                  # Miner Account    -> Contacts -> Technician Users.
    *                                     -> Vendor Trade
    *                  # Customer Account -> Cases    -> Work Orders -> Vandor Assignments  
    *                                     -> Vendor Preferences to Miner Account
    *                                     -> Vendor Preferences by Trade 
    * 
    */ 
    static testMethod void suggestedTechnicianTest () {
        UNITY_Constants.MAX_TRIGGER_EXECUTION = 3;
        // get default value fields per object to use as mokup data 
        Map<String,Object> accountFields          = UNITY_TestDataFactory.MOCKUP_ACCOUNT_FIELDS;
        Map<String,Object> userFields             = UNITY_TestDataFactory.MOCKUP_USER_FIELDS;
        Map<String,Object> vendorAssignmentFields = UNITY_TestDataFactory.MOCKUP_VENDOR_ASSIGNMENT_FIELDS;
        Map<String,Object> workOrderFields        = UNITY_TestDataFactory.MOCKUP_WORK_ORDER_FIELDS;
        
        workOrderFields.put('RecordTypeId' , UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE);
        accountFields.put('RecordTypeId' , UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE);
        
        Account customer = (Account)UNITY_TestDataFactory.createObject(1, Account.getSObjectType(), accountFields).get(0);
        customer.Type = 'Customer';
        insert customer;
        
        // set new values for Miner Account
        accountFields.put('RecordTypeId' , UNITY_Constants.ACCOUNT_MINER_RECORDTYPE);
        accountFields.put('Type' , 'Vendor');
        accountFields.put('UNITY_Miner_Regional_Office__c' , true);
        accountFields.put('UNITY_TimeZoneSidKey__c' , 'America/Chicago');
        Account miner = (Account)UNITY_TestDataFactory.createObject(1, Account.getSObjectType(), accountFields).get(0);
        insert miner;
        
        Contact onContact = UNITY_TestDataFactory.createContacts(1,miner.Id).get(0);
        
        userFields.put('ContactId', onContact.id);
        userFields.put('UNITY_Auto_Dispatch__c', true);
        String tecname = 'test.vendor.tech'+String.valueOf(TestDataProvider.getRandomInt(11111,99999));
        userFields.put('Username', tecname+'@minercorp.com.test');
        userFields.put('CommunityNickname', tecname+'.minercorp.com.test');
        
        User onUser = (User)UNITY_TestDataFactory.createUsersTechnician(1, userFields).get(0);
        insert onUser;
        
        List<FSO__Skill__c> skills = UNITY_TestDataFactory.createSkills(3);
        
        UNITY_Vendor_Trade__c vendorTrade = new UNITY_Vendor_Trade__c(Vendor__c = miner.Id,  Trade__c = skills.get(0).Id);
        insert vendorTrade;
        
        Case onCase = UNITY_TestDataFactory.createCases(1, customer.id, customer.id).get(0);
        workOrderFields.put('CaseId'     , onCase.id);
        workOrderFields.put('AccountId'  , customer.id);
        workOrderFields.put('UNITY_Customer__c', customer.id);
        workOrderFields.put('UNITY_Trade__c'   , skills.get(0).Id);
        workOrderFields.put('UNITY_Work_Window_Begin__c' , DateTime.now());
        workOrderFields.put('UNITY_Work_Window_End__c'   , DateTime.now().addDays(5));
        WorkOrder workOrder = UNITY_TestDataFactory.createWorkOrders(4,workOrderFields).get(0);
        insert workOrder;
       
        vendorAssignmentFields.put('Customer__c', customer.id);
        vendorAssignmentFields.put('Trade__c'   , skills.get(0).Id);
        vendorAssignmentFields.put('Vendor__c'  , miner.Id);
        vendorAssignmentFields.put('Status__c'  , 'Candidate');
        vendorAssignmentFields.put('Work_Order__c', workOrder.Id);
        UNITY_Vendor_Assignment__c  vp = (UNITY_Vendor_Assignment__c )UNITY_TestDataFactory.createObject(1,UNITY_Vendor_Assignment__c.getSObjectType(),vendorAssignmentFields).get(0);
        insert vp;
        
        Test.startTest();
        
            workOrder.UNITY_Assigned_Vendor__c = miner.id;
            workOrder.UNITY_Vendor_Status__c   = UNITY_Constants.WO_VENDOR_STATUS_ASSIGNED;
            update workOrder;
        
            WorkOrder workOrderCloned = workOrder.clone();
            workOrderCloned.StartDate = DateTime.now().addHours(5);
            workOrderCloned.UNITY_Vendor_Status__c = 'Accepted';
            workOrderCloned.Status = 'New';
            insert workOrderCloned; 
        
            UNITY_Vendor_Utils.populateSuggestedTechnician(new List<WorkOrder>{workOrder,workOrderCloned});
        
            /*
            update workOrder;
        
            workOrder = [SELECT id, WorkOrderNumber, 
                             UNITY_Trade__c,
                             CaseId,
                             AccountId,
                             UNITY_Work_Window_Begin__c, 
                             UNITY_Suggested_Technician__c,
                             UNITY_Work_Window_End__c,
                             UNITY_Assigned_Vendor__c,
                             UNITY_Assigned_Vendor__r.UNITY_Miner_Regional_Office__c, 
                             UNITY_Suggested_Work_Date__c 
                         FROM WorkOrder WHERE id = :workOrder.Id];

        
            //System.assertEquals(onUser.Id, workOrder.UNITY_Suggested_Technician__c , 'Should be assigned the user '+onUser.Id);
        
            system.debug('########^^^^> '+workOrder);
            system.debug('########^^^^> '+workOrder.UNITY_Work_Window_Begin__c.date());
            system.debug('########^^^^> '+workOrder.UNITY_Work_Window_End__c.date());
            system.debug('########^^^^> '+workOrder.UNITY_Suggested_Technician__c);
            system.debug('########^^^^> '+workOrder.UNITY_Suggested_Work_Date__c);
            system.debug('########^^^^> '+workOrder.UNITY_Assigned_Vendor__r.UNITY_Miner_Regional_Office__c);
            */
        Test.stopTest();
    }

}