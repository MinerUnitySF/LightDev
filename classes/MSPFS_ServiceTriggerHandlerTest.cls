@isTest
public class MSPFS_ServiceTriggerHandlerTest {
        private static String custRTId = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
        private static String vendRTId = UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE;
        private static String buRTId = UNITY_Constants.ACCOUNT_MINER_RECORDTYPE;
        private static String woRTId = UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE;

        private static Account cust;
        private static Account vend;
        private static Account bu;
        private static WorkOrder wo;
        private static CKSW_BASE__Service__c svc;
        private static CKSW_BASE__Location__c baseLoc;
        private static CKSW_BASE__Resource__c baseResource;
    
        //Setup test data
        @testSetup
        public static void init(){
            TestDataProvider.unityTestSetup();
        }    
    
        public static void setupAcctWOAndService(){
        //Get the accounts
        List<Account> accounts = [SELECT Id,RecordTypeId,Account_Email__c FROM Account];
        
        for(Account a :accounts){
            if(a.RecordTypeId == custRTId)
                cust = a;
            if(a.RecordTypeId == vendRTId)
                vend = a;
            if(a.RecordTypeId == buRTId)
                bu = a;
        }
        //Get the case
        Case testCase = [SELECT Id FROM Case LIMIT 1];            
            
        //Create a location
        baseLoc = new CKSW_BASE__Location__c();
        baseLoc.Name = 'Nashville';
        baseLoc.MSPFS_Business_Unit_Account__c = bu.Id;
        insert baseLoc;
        
        //Create a default resource
        baseResource = new CKSW_BASE__Resource__c();
        baseResource.Name = 'Technician Default';
        baseResource.MSPFS_Burden_Rate__c = 50.00;
        baseResource.CKSW_BASE__Location__c = baseLoc.Id;            
        baseResource.MSPFS_BU_Default_Resource__c = true;
        insert baseResource;        

        //Set custom setting to automatically create service record
        FSL_INTG__Sync_Settings__c cSetting = FSL_INTG__Sync_Settings__c.getOrgDefaults();
        cSetting.FSL_INTG__Service_Work_Order_Sync__c = true;
        cSetting.FSL_INTG__Absence_Request_Auto_Approve__c = true;
        cSetting.FSL_INTG__Request_Sync__c = true;
        cSetting.FSL_INTG__Service_Required_Skill_Sync__c = true;
        cSetting.FSL_INTG__Skill_Sync__c = true;
        cSetting.FSL_INTG__Update_WOLI_Owner__c = true;
        cSetting.FSL_INTG__Update_WO_Expected_Duration__c = true;
        upsert cSetting;
            
        //Create a Work Order
        wo = new WorkOrder();
        wo.AccountId = cust.Id;
        wo.UNITY_Accepted_Vendor__c = vend.Id;
        wo.UNITY_Business_Unit_Account__c = bu.Id;
        wo.UNITY_Business_Unit__c = 'NSBS';
        wo.UNITY_Customer__c = cust.Id;
        wo.UNITY_Skill_Broad__c = 'Glass';
        wo.UNITY_Skill_Group__c = 'Glass Installation/Repair';
        wo.UNITY_Skill_Type__c = 'Glass, Board up, Mirrors & Displays';
        wo.Priority = '24 Hour Response';
        wo.Status = 'New';
        wo.RecordTypeId = woRTId;
        wo.CaseId = testCase.Id;
        wo.Description = 'Test Test Test';
        wo.UNITY_Work_Description__c = 'Test Test Test';
        wo.UNITY_Work_Window_Begin__c = DateTime.now();
        wo.UNITY_Work_Window_End__c = DateTime.now().addMinutes(60);
        insert wo;     
    }
    
    private static testMethod void testCascadeTechAssignment(){
        //Setup Account, Work Order and Service
        setupAcctWOAndService();
        
        Test.startTest();
        
        //Set the Tech ETA on the Work Order to initially populate Start, Finish and Resource
        //wo.StartDate = DateTime.now().addMinutes(1);
        //update wo;
        
        //Define a new resource    
        User newUser = TestDataProvider.getUser('Technician', 'New', 'UNITY_FSL Technician');
        insert newUser;
        
        CKSW_BASE__Resource__c newResource = new CKSW_BASE__Resource__c();
        newResource.Name = 'Technician New';
        newResource.MSPFS_Burden_Rate__c = 40.00;
        newResource.CKSW_BASE__Location__c = baseLoc.Id;            
        newResource.MSPFS_BU_Default_Resource__c = false;
        newResource.CKSW_BASE__User__c = newUser.Id;
        insert newResource;
        
        //Query the service automatically created with the work order and replace the current resource assigned
        CKSW_BASE__Service__c serv = [SELECT Id, CKSW_BASE__Resource__c FROM CKSW_BASE__Service__c WHERE FSL_INTG__Work_Order__c = :wo.Id LIMIT 1];
        System.assert(serv != null);
        
        serv.CKSW_BASE__Resource__c = newResource.Id; 
        serv.CKSW_Base__Start__c =  DateTime.now();
        serv.CKSW_Base__Finish__c =  DateTime.now().addHours(1); 
        MSPFS_ServiceTriggerHandler.cascadeTechnicianOnce = true;
        update serv;
        
        //Verify that the Primary Technician was assigned with the new Resource in the WorkOrder
        WorkOrder updatedWO = [SELECT UNITY_Primary_Technician__c FROM WorkOrder WHERE Id = :wo.Id LIMIT 1];
        System.assert(updatedWO != null);
        System.assert(newUser.Id == updatedWO.UNITY_Primary_Technician__c);
                    
        Test.stopTest();

    }
    
    private static testMethod void testSetDefaultOnServiceRecord(){
        //Setup Account, Work Order and Service
        setupAcctWOAndService();
        
        Test.startTest();
        MSPFS_ServiceTriggerHandler.setDefaultOnce = true;        
        //Update Tech ETA time in the Work Order
        wo.StartDate = DateTime.now().addMinutes(1);
        update wo;
        
        //Query the Service record automatically created 
        CKSW_BASE__Service__c serv = [SELECT Id, CKSW_BASE__Resource__c
                                      FROM CKSW_BASE__Service__c WHERE FSL_INTG__Work_Order__c = :wo.Id];
        System.Assert(serv != null);
        
        //Verify that the assigned resource to the service is the default resource to the bu        
        System.assert(baseResource.Id == serv.CKSW_BASE__Resource__c);
        
        Test.stopTest();
    }    
    
    
}