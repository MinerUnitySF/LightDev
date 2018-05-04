@isTest

private class UNITY_AuraWOAssignmentController_UT {
    
    private static String  VENDOR_ID      = 'vendorId';
    private static String  VENDOR_PIN     = 'vendorPin';
    private static String  VENDOR_EMAIL   = 'vendorEmail';
    private static String  IS_OON         = 'isOON';
    private static String  VENDOR_WARNING = 'vendorWarning';
    private static String  AUTO_DISPATCH  = 'autoDispatch';
    
   static testMethod void getWorkOrdersList_Test() {
        
        Map<String,Object> data = data_A();
        
        Account customer      = (Account)data.get('customer');
        FSO__Skill__c skill   = (FSO__Skill__c)data.get('skill');
        String locationKey    = (String)data.get('locationKey');
        List<Account> vendors = (List<Account>)data.get('vendors');
        List<UNITY_Vendor_Trade__c>               vendorTrades      = (List<UNITY_Vendor_Trade__c>)data.get('vendorTrades');
        List<UNITY_Vendor_Covered_Location__c>    locationVendors   = (List<UNITY_Vendor_Covered_Location__c>)data.get('locationVendors');
        Map<id,UNITY_Vendor_Preference__c>        vendorPreferences = null;
        List<UNITY_Vendor_Preference_By_Trade__c> vendorPreferenceTrades = null;
        
        Map<String,Object> workOrderFields         = UNITY_TestDataFactory.MOCKUP_WORK_ORDER_FIELDS;
        Map<String,Object> caseFields              = UNITY_TestDataFactory.MOCKUP_WORK_ORDER_FIELDS;
        Map<String,Object> vendorPreferenceFields  = UNITY_TestDataFactory.MOCKUP_VENDOR_ASSIGNMENT_FIELDS;
        
        Map<String, Object> dataFields = new  Map<String, Object>();
        dataFields.put(VENDOR_ID        , vendors.get(0).id);
        dataFields.put(VENDOR_PIN       , null);
        dataFields.put(VENDOR_EMAIL     , vendors.get(0).Account_Email__c);
        dataFields.put(IS_OON           , false);
        dataFields.put(VENDOR_WARNING   , null);
            
        Test.startTest();
        
            caseFields.put('RecordTypeId'     , UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
            caseFields.put('Status'           , 'Verified');
            caseFields.put('AccountId'        , customer.id);
            caseFields.put('Customer__c'      , customer.id);
            caseFields.put('UNITY_Trade__c'   , skill.id);
            
            Case onCase = (Case) UNITY_TestDataFactory.createObject(1, Case.getSObjectType(), caseFields).get(0);
            insert onCase; 
            
            workOrderFields.put('RecordTypeId'      , UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE);
            workOrderFields.put('CaseId'      , onCase.id);
            workOrderFields.put('AccountId'   , customer.id);
            workOrderFields.put('Subject'   , 'WO-Test');
            workOrderFields.put('UNITY_Trade__c'    , skill.id);
            workOrderFields.put('UNITY_Customer__c' , customer.id);       
            workOrderFields.put('UNITY_Vendor_PIN__c' , '12');         
            
            WorkOrder workOrder  = UNITY_TestDataFactory.createWorkOrders(1,workOrderFields).get(0) ;
            insert workOrder;
        
            vendorPreferenceFields.put('Customer__c', customer.id);
            vendorPreferenceFields.put('Trade__c'   , skill.id);
            vendorPreferenceFields.put('Vendor__c'  , vendors.get(0).id);
            vendorPreferenceFields.put('Status__c'  , UNITY_Constants.VENDOR_ASSIGNMENT_STATUS_CANDIDATE);
            vendorPreferenceFields.put('Work_Order__c' , workOrder.id);
            UNITY_Vendor_Assignment__c vendorAssignment = (UNITY_Vendor_Assignment__c)UNITY_TestDataFactory.createObject(1, UNITY_Vendor_Assignment__c.getSObjectType(), vendorPreferenceFields).get(0);
            insert vendorAssignment;
            
            vendorAssignment = [SELECT id, Customer__c, Trade__c, Vendor__c,Vendor__r.ID, Status__c, PIN__c, Work_Order__c,UNITY_Vendor_Email__c FROM UNITY_Vendor_Assignment__c WHERE id = :vendorAssignment.id ];
            dataFields.put(VENDOR_PIN , vendorAssignment.PIN__c);
            workOrder = getWO(workOrder.id);
            // Assign vendor
            workOrder.UNITY_Assigned_Vendor__c = vendors.get(0).id; 
            workOrder.UNITY_Vendor_Status__c = UNITY_Constants.WO_VENDOR_STATUS_ASSIGNED;
        
            update workOrder;
            workOrder = getWO(workOrder.id);
            
            //call aura controller           
            List<UNITY_AuraWOAssignmentController.VendorWOWrapper> vendorwo = UNITY_AuraWOAssignmentController.getWorkOrdersList(vendorAssignment.Vendor__r.ID);
            
            system.assert(vendorwo != null);
            system.assertEquals(vendorwo[0].workOrderID, workOrder.id);
           	system.assertEquals(vendorwo[0].workOrder.UNITY_Assigned_Vendor__c, workOrder.UNITY_Assigned_Vendor__c);
       		system.assertEquals(vendorwo[0].workOrder.UNITY_Trade__r.name, workOrder.UNITY_Trade__r.name);
       		system.assertEquals(vendorwo[0].workOrder.Account.Name, workOrder.Account.Name);
            system.assertEquals(vendorwo[0].workOrder.UNITY_Work_Description__c, workOrder.UNITY_Work_Description__c);
       		
            UNITY_Utils.DateTimeZone dtzCreatedDate = UNITY_Utils.getDateTime(workOrder.UNITY_Work_Window_Begin__c, null, workOrder.Account.UNITY_TimeZoneSidKey__c);
            UNITY_Utils.DateTimeZone dtzWindow_End = UNITY_Utils.getDateTime(workOrder.UNITY_Work_Window_End__c, null, workOrder.Account.UNITY_TimeZoneSidKey__c);
            String createdDate = dtzCreatedDate.format + ' ' + dtzCreatedDate.displayname;
            String window_End = dtzWindow_End.format + ' ' + dtzWindow_End.displayname; 
            system.assertEquals(vendorwo[0].createdDate, createdDate);
            system.assertEquals(vendorwo[0].window_End, window_End);
       
             UNITY_Utils.DateTimeZone dtzRetracAtDate = UNITY_Utils.getDateTime(workOrder.UNITY_WO_Retract_At__c, null, null);
             String deadlinePerformWork = dtzRetracAtDate.format + ' ' + dtzRetracAtDate.displayname;  
             system.assertEquals(vendorwo[0].deadlinePerformWork, deadlinePerformWork);
            
             system.debug('####  >>  vendorwo[0]  >> ####' + vendorwo[0].workOrder);
       
            //accept work order :
            List<String> acceptWO = New List<String>{vendorwo[0].workOrder.WorkOrderNumber + ',' + vendorwo[0].workOrder.CaseId +',' + vendorwo[0].workOrder.UNITY_Vendor_PIN__c + ',' + vendorwo[0].workOrder.UNITY_Case_Thread_Id__c + ', ' + UNITY_Constants.WO_VENDOR_STATUS_ACCEPTED +',' +  vendorwo[0].workOrder.ID};
            List<string> woList = UNITY_AuraWOAssignmentController.updateWorkOrdersStatusBySendingEmail(acceptWO);
            system.debug('####  >> acceptWO  >> ####' + acceptWO);
            system.debug('####  >> woList  >> ####' + woList);
       
            system.assert(woList.size() == 1);
       
        Test.stopTest();
    }       
   
        static WorkOrder getWO(id woId) {
             return [SELECT id, UNITY_Vendor_Email__c, UNITY_Action__c, ownerId,Account.Name,
                                     UNITY_Assigned_Vendor__c, UNITY_Agent__c ,
                                     UNITY_Accepted_Vendor__c, UNITY_Trade__r.name, UNITY_Work_Description__c,
                                     UNITY_Vendor_PIN__c,UNITY_Dispatch_Attempts__c,Account.UNITY_TimeZoneSidKey__c,
                                     UNITY_OON_Vendor_Assigned__c, UNITY_Vendor_Status__c,UNITY_WO_Retract_At__c,
                                     UNITY_Vendor_Assignment_Warning__c, UNITY_Work_Window_Begin__c, UNITY_Work_Window_End__c
                             FROM  WorkOrder 
                             WHERE id = :woId ];
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
        accountFields.put('Account_Status__c', 'Active' );
          
        customer = (Account)UNITY_TestDataFactory.createObject(1, Account.getSObjectType(),accountFields ).get(0);
        customer.Type = 'Site/Location';
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
            vendorTradeFields.put('Price_SR__c', 10);
                
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