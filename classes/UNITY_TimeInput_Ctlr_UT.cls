@isTest
public class UNITY_TimeInput_Ctlr_UT {
    
    @testSetup
    public static void testSetup(){
        UNITY_MuleSiteSettingUtilsTest.setUp();
        UNITY_Mule2Salesforce_MappingUtilsTest.setUp();
        UNITY_Mulesoft_Credentials__c mCreds = new UNITY_Mulesoft_Credentials__c(
        	Name = 'Basic Authorization',
            Authorization_Header__c = 'Basic dXNlcjE6cGFzc3dvcmQx'
        );
        insert mCreds;
        UNITY_MuleHttpCalloutMockImp calloutMock = new UNITY_MuleHttpCalloutMockImp(false);
        calloutMock.supposedEndPoint = UNITY_MuleSiteSettingUtils.getEndPoint(UNITY_MuleSiteSettingUtils.VENDOR);
        Test.setMock(HttpCalloutMock.class, calloutMock);
        List<UNITY_Date_Time_Field_to_Local__c> dtFields = new List<UNITY_Date_Time_Field_to_Local__c>();
        
        UNITY_Date_Time_Field_to_Local__c fm1 = new UNITY_Date_Time_Field_to_Local__c();
        fm1.UNITY_Origin_Field__c = 'UNITY_Work_Window_Begin_Cust__c';
        fm1.UNITY_Target_Field__c = 'UNITY_Work_Window_Begin__c';
        fm1.Name = 'TestWWB_Local';
        fm1.UNITY_Object__c = 'WorkOrder';
        fm1.UNITY_Is_to_Local__c = true;
        fm1.UNITY_To_Date_Time__c = true;
        dtFields.add(fm1);
        UNITY_Date_Time_Field_to_Local__c fm2 = new UNITY_Date_Time_Field_to_Local__c();
        fm2.UNITY_Origin_Field__c = 'UNITY_Work_Window_Begin__c';
        fm2.UNITY_Target_Field__c = 'UNITY_Work_Window_Begin_Cust__c';
        fm2.Name = 'TestWWB';
        fm2.UNITY_Object__c = 'WorkOrder';
        fm2.UNITY_Is_to_Local__c = false;
        fm2.UNITY_To_Date_Time__c = false;
        dtFields.add(fm2);
        UNITY_Date_Time_Field_to_Local__c fm3 = new UNITY_Date_Time_Field_to_Local__c();
        fm3.UNITY_Origin_Field__c = 'UNITY_Tech_ETA_Date_Cust__c';
        fm3.UNITY_Target_Field__c = 'StartDate';
        fm3.Name = 'TestTechETA_Local';
        fm3.UNITY_Object__c = 'WorkOrder';
        fm3.UNITY_Is_to_Local__c = true;
        fm3.UNITY_To_Date_Time__c = true;
        dtFields.add(fm3);
        UNITY_Date_Time_Field_to_Local__c fm4 = new UNITY_Date_Time_Field_to_Local__c();
        fm4.UNITY_Origin_Field__c = 'StartDate';
        fm4.UNITY_Target_Field__c = 'UNITY_Tech_ETA_Date_Cust__c';
        fm4.Name = 'TestTechETA';
        fm4.UNITY_Object__c = 'WorkOrder';
        fm4.UNITY_Is_to_Local__c = false;
        fm4.UNITY_To_Date_Time__c = false;
        dtFields.add(fm4);
        
        insert dtFields;
    }
    
    public static TestMethod void test1(){
        List<Account> accounts = new List<Account>();
        
        Account cust = TestDataProvider.getAccounts(1,'Customer', 'Customer')[0];
        cust.Account_Status__c = 'Active';
        cust.UNITY_TimeZoneSidKey__c = 'America/New_York';
        accounts.add(cust);
        Account vend = TestDataProvider.getAccounts(1,'Vendor','Vendor')[0];
        vend.UNITY_Vendor_Status__c = 'Active'; 
        accounts.add(vend);
        Account bu = TestDataProvider.getAccounts(1,'Miner','Business Unit')[0];
        bu.UNITY_Business_Unit__c = 'NSBS';
        accounts.add(bu);
        
        insert accounts;
        
        Case c = UNITY_TestDataFactory.createCases(1,cust.Id,cust.Id)[0];
        c.Status = 'Verified';
        update c;
        
        String woRTId = UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE;
        
        Test.startTest();
        
        WorkOrder wo = new WorkOrder();
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
        wo.CaseId = c.Id;
        wo.Description = 'Test Test Test';
        wo.UNITY_Work_Description__c = 'Test Test Test';
        wo.UNITY_Work_Window_Begin__c = DateTime.now();
        insert wo;
        
        WorkOrder oldWO = wo;//Hold the work order as originally created to put in oldWOMap
        Date d = Date.today();
        String myDateString = String.valueOf(d.month()) + '/' + String.valueOf(d.day()) + '/' + String.valueOf(d.year()) + ' 8:30 AM';
        
        PageReference pageRef = Page.UNITY_WOTimeInput;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id',wo.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(wo);
        UNITY_TimeInput_Ctlr controller = new UNITY_TimeInput_Ctlr(sc);
        
        controller.controller.getRecord().put('UNITY_Work_Window_Begin_Cust__c','myDateString');
        
        pageRef = controller.saveRecord();
        Test.setCurrentPage(pageRef);
        controller.controller.getRecord().put('UNITY_Tech_ETA_Date_Cust__c','myDateString');
        pageRef = controller.saveRecord();
        
        Test.stopTest();
    }
 
    public static TestMethod void test2(){
        Account cust = TestDataProvider.getAccounts(1,'Customer', 'Customer')[0];
        cust.Account_Status__c = 'Active';
        cust.UNITY_TimeZoneSidKey__c = 'America/New_York';
        insert cust;
        
        Account vend = TestDataProvider.getAccounts(1,'Vendor','Vendor')[0];
        vend.UNITY_Vendor_Status__c = 'Active'; insert vend;
        Account bu = TestDataProvider.getAccounts(1,'Miner','Business Unit')[0];
        bu.UNITY_Business_Unit__c = 'NSBS'; insert bu;
        
        
        Case c = UNITY_TestDataFactory.createCases(1,cust.Id,cust.Id)[0];
        c.Status = 'Verified';
        update c;
        
        String woRTId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Service_Request' AND SObjectType = 'WorkOrder' LIMIT 1].Id;
        
        Test.startTest();
        WorkOrder wo = new WorkOrder();
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
        wo.CaseId = c.Id;
        wo.Description = 'Test Test Test';
        wo.UNITY_Work_Description__c = 'Test Test Test';
        Date d = Date.today();
        String myDateString = String.valueOf(d.month()) + '/' + String.valueOf(d.day()) + '/' + String.valueOf(d.year()) + ' 4:30 PM';
        wo.UNITY_Work_Window_Begin_Cust__c = mydateString;
        insert wo;
        WorkOrder oldWO = wo;//Hold the work order as originally created to put in oldWOMap
        wo.UNITY_Work_Window_Begin__c = DateTime.now();
        update wo;

        Test.stopTest();
    }
    
    public static TestMethod void test3(){
        Account cust = TestDataProvider.getAccounts(1,'Customer', 'Customer')[0];
        cust.Account_Status__c = 'Active';
        cust.UNITY_TimeZoneSidKey__c = 'America/New_York';
        insert cust;
        
        Account vend = TestDataProvider.getAccounts(1,'Vendor','Vendor')[0];
        vend.UNITY_Vendor_Status__c = 'Active'; insert vend;
        Account bu = TestDataProvider.getAccounts(1,'Miner','Business Unit')[0];
        bu.UNITY_Business_Unit__c = 'NSBS'; insert bu;
        
        Case c = UNITY_TestDataFactory.createCases(1,cust.Id,cust.Id)[0];
        c.Status = 'Verified';
        update c;
        
        String woRTId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Service_Request' AND SObjectType = 'WorkOrder' LIMIT 1].Id;
        
        Test.startTest();
        WorkOrder wo = new WorkOrder();
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
        wo.CaseId = c.Id;
        wo.Description = 'Test Test Test';
        wo.UNITY_Work_Description__c = 'Test Test Test';
        Date d = Date.today();
        String myDateString = String.valueOf(d.month()) + '/' + String.valueOf(d.day()) + '/' + String.valueOf(d.year()) + ' 4:30 PM';
        wo.UNITY_Work_Window_Begin_Cust__c = mydateString;
        insert wo;
        wo = [SELECT Id,unity_account_time_zone__c,UNITY_Work_Window_Begin__c,UNITY_Work_Window_Begin_Cust__c FROM WOrkOrder WHERE Id = :wo.Id LIMIT 1];
        
        PageReference pageRef = Page.UNITY_WOTimeInput;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id',wo.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(wo);
        UNITY_TimeInput_Ctlr controller = new UNITY_TimeInput_Ctlr(sc);
        
        controller.saveRecord();
        controller.cancelChange();
        
        Test.stopTest();
    }
    
    public static TestMethod void test4(){
        Account cust = TestDataProvider.getAccounts(1,'Customer', 'Customer')[0];
        cust.Account_Status__c = 'Active';
        cust.UNITY_TimeZoneSidKey__c = 'America/New_York';
        insert cust;
        
        Account vend = TestDataProvider.getAccounts(1,'Vendor','Vendor')[0];
        vend.UNITY_Vendor_Status__c = 'Active'; insert vend;
        Account bu = TestDataProvider.getAccounts(1,'Miner','Business Unit')[0];
        bu.UNITY_Business_Unit__c = 'NSBS'; insert bu;
        
        Case c = UNITY_TestDataFactory.createCases(1,cust.Id,cust.Id)[0];
        c.Status = 'Verified';
        update c;
        
        String woRTId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Service_Request' AND SObjectType = 'WorkOrder' LIMIT 1].Id;
        
        Test.startTest();
        WorkOrder wo = new WorkOrder();
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
        wo.CaseId = c.Id;
        wo.Description = 'Test Test Test';
        wo.UNITY_Work_Description__c = 'Test Test Test';
        Date d = Date.today();
        String myDateString = String.valueOf(d.month()) + '/' + String.valueOf(d.day()) + '/' + String.valueOf(d.year()) + ' 4:30 PM';
        wo.UNITY_Work_Window_Begin_Cust__c = mydateString;
        insert wo;

        List<WorkOrder> wos = [SELECT Id,unity_account_time_zone__c,UNITY_Work_Window_Begin__c,UNITY_Work_Window_Begin_Cust__c FROM WOrkOrder WHERE Id = :wo.Id LIMIT 1];
        
        WorkOrder oldWO = wos[0];
        oldWO = oldWO.clone(true,true,true,true);
        Map<Id,WorkOrder> wosMap = new Map<Id,WorkOrder>();
		wosMap.put(oldWO.Id,oldWO);
        
        wos[0].UNITY_Work_Window_Begin__c = DateTime.now();
        
        List<SObject> sobjs = UNITY_TimeInput_Ctlr.verifyDateTimeChanged(wos,wosMap,'WorkOrder',false);

        Test.stopTest();
    }
    
    public static TestMethod void test5(){
        Account cust = TestDataProvider.getAccounts(1,'Customer', 'Customer')[0];
        cust.Account_Status__c = 'Active';
        cust.UNITY_TimeZoneSidKey__c = 'America/New_York';
        insert cust;
        
        Account vend = TestDataProvider.getAccounts(1,'Vendor','Vendor')[0];
        vend.UNITY_Vendor_Status__c = 'Active'; insert vend;
        Account bu = TestDataProvider.getAccounts(1,'Miner','Business Unit')[0];
        bu.UNITY_Business_Unit__c = 'NSBS'; insert bu;
        
        Case c = UNITY_TestDataFactory.createCases(1,cust.Id,cust.Id)[0];
        c.Status = 'Verified';
        update c;
        
        String woRTId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Service_Request' AND SObjectType = 'WorkOrder' LIMIT 1].Id;
        
        Test.startTest();
        WorkOrder wo = new WorkOrder();
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
        wo.CaseId = c.Id;
        wo.Description = 'Test Test Test';
        wo.UNITY_Work_Description__c = 'Test Test Test';
        wo.UNITY_Work_Window_Begin__c = DateTime.now();
        insert wo;

        List<WorkOrder> wos = [SELECT Id,unity_account_time_zone__c,UNITY_Work_Window_Begin__c,UNITY_Work_Window_Begin_Cust__c FROM WOrkOrder WHERE Id = :wo.Id LIMIT 1];
        
        WorkOrder oldWO = wos[0];
        oldWO = oldWO.clone(true,true,true,true);
        Map<Id,WorkOrder> wosMap = new Map<Id,WorkOrder>();
		wosMap.put(oldWO.Id,oldWO);
        
        Date d = Date.today();
        String myDateString = String.valueOf(d.month()) + '/' + String.valueOf(d.day()) + '/' + String.valueOf(d.year()) + ' 4:30 PM';
        wos[0].UNITY_Work_Window_Begin_Cust__c = mydateString;
        
        List<SObject> sobjs = UNITY_TimeInput_Ctlr.verifyDateTimeChanged(wos,wosMap,'WorkOrder',false);

        Test.stopTest();
    }

}