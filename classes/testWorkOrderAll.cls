/**This class serves as unit test for the WorkOrderAll trigger and WorkOrderTriggerUtil class
***@Developer: Izay Ramos-Irizarry
***@Date:      4/9/2015
***@Version:   1.0
*/
@isTest(SeeAllData=true)
private class testWorkOrderAll {

    static testMethod void test1() {
        //Create Account
        Account acct = TestDataProvider.getAccounts(1,'Prospect Accounts', 'Customer')[0];
        //acct.name = 'Test Account';
        insert acct;
        //Create Product
        Map<String,String> prodMap = TestDataProvider.getProductAndPriceBookEntry(1);
        String prodId = '';
        for(String key :prodMap.keySet()){
            prodId = key;
			break;
        }
        //Create Installed Product
        SVMXC__Installed_Product__c ip = new SVMXC__Installed_Product__c();
        ip.Name = 'Installed Product';
        ip.SVMXC__Status__c = 'Active';
        ip.SVMXC__Product__c = prodId;
        ip.SVMXC__Serial_Lot_Number__c = '123456';
        insert ip;
        //Create service group
        SVMXC__Service_Group__c sgroup = new SVMXC__Service_Group__c(
            Name = 'Test Service Group',
            SVMXC__Active__c = true,
            Super_Center__c = 'Miner-Central Texas',
            Segment__c = 'San Antonio'
        );
        insert sgroup;
        //Create service group
        SVMXC__Service_Group__c sgroup2 = new SVMXC__Service_Group__c(
            Name = 'Test Service Group',
            SVMXC__Active__c = true,
            Super_Center__c = 'Miner-Houston'
        );
        insert sgroup2;
        //Create service group member
        SVMXC__Service_Group_Members__c member = new SVMXC__Service_Group_Members__c(
            SVMXC__Service_Group__c = sgroup.Id,
            SVMXC__Salesforce_User__c = UserInfo.getUserId(),
            SVMXC__Fixed_Cost__c = 25
        ); 
        //insert member;
        //Create location
        SVMXC__Site__c  location = TestDataProvider.getLocations(1,'Location Site','SPSC',acct.Id)[0];
        insert location;
        //Start the test
        Test.startTest();
        //create Work Order
        SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
        wo.SVMXC__Company__c = acct.Id;
        wo.SVMXC__Order_Status__c = 'Open';
        wo.SVMXC__Order_Type__c = 'Depot Repair';
        wo.SVMXC__Component__c = ip.id;
        wo.Meter_Reading__c = 123;
        wo.SVMXC__Site__c = location.id;
        wo.SVMXC__Problem_Description__c = 'desc';
        wo.Location__c = location.Id;
        wo.Business_Unit__c = 'Miner Corp';
        wo.SVMXC__Service_Group__c = sgroup.Id;
        insert wo;
        
        WorkOrderTriggerUtil.isFirstTriggerRun_Before = true;
        WorkOrderTriggerUtil.isFirstTriggerRun_After = true;
        wo.Meter_Reading__c = 987;
        wo.Technician_Arrived__c = true;
        wo.SVMXC__Order_Status__c = 'Work Finished';
        update wo;
        
        WorkOrderTriggerUtil.isFirstTriggerRun_Before = true;
        WorkOrderTriggerUtil.isFirstTriggerRun_After = true;
        wo.SVMXC__Group_Member__c = null;
        wo.SVMXC__Service_Group__c = sgroup2.Id;
        wo.SVMXC__Order_Status__c = 'Invoice Completed';
        update wo;
        
        WorkOrderTriggerUtil.isFirstTriggerRun_Before = true;
        WorkOrderTriggerUtil.isFirstTriggerRun_After = true;
        //wo.SVMXC__Group_Member__c = member.Id;
        wo.SVMXC__Order_Status__c = 'Credit Approval';
        update wo;

        test.stopTest();
    }
    
    public static TestMethod void test2(){
        //Create Account
        Account acct = TestDataProvider.getAccounts(1,'Prospect Accounts', 'Customer')[0];
        //acct.name = 'Test Account';
        insert acct;
        //Create Product
        Map<String,String> prodMap = TestDataProvider.getProductAndPriceBookEntry(1);
        String prodId = '';
        for(String key :prodMap.keySet()){
            prodId = key;
			break;
        }
        //Create Installed Product
        SVMXC__Installed_Product__c ip = new SVMXC__Installed_Product__c();
        ip.Name = 'Installed Product';
        ip.SVMXC__Status__c = 'Active';
        ip.SVMXC__Product__c = prodId;
        ip.SVMXC__Serial_Lot_Number__c = '123456';
        insert ip;
        //Create service group
        SVMXC__Service_Group__c sgroup = new SVMXC__Service_Group__c(
            Name = 'Test Service Group',
            SVMXC__Active__c = true
        );
        insert sgroup;
        //Create service group member
        SVMXC__Service_Group_Members__c member = new SVMXC__Service_Group_Members__c(
            SVMXC__Service_Group__c = sgroup.Id,
            SVMXC__Salesforce_User__c = UserInfo.getUserId(),
            SVMXC__Fixed_Cost__c = 25
        ); 
        //insert member;
        //Create location
        SVMXC__Site__c  location = TestDataProvider.getLocations(1,'Location Site','SPSC',acct.Id)[0];
        insert location;
        //Start the test
        Test.startTest();
        
        SVMXC__Service_Order__c wo3 = new SVMXC__Service_Order__c();
        wo3.SVMXC__Company__c = acct.Id;
        wo3.SVMXC__Order_Status__c = 'Open';
        wo3.SVMXC__Order_Type__c = 'Leasing/Rental';
        wo3.SVMXC__Component__c = ip.id;
        wo3.SVMXC__Site__c = location.id;
        wo3.Meter_Reading__c = 123;
        wo3.SVMXC__Problem_Description__c = 'desc';
        wo3.Location__c = location.Id;
        wo3.Business_Unit__c = 'National Maintenance Services';
        wo3.TFS_AMF_WO__c = true;
        insert wo3;
        
        List<Meter_History__c> meterHistories = [SELECT Id FROM Meter_History__c WHERE Work_Order__c = :wo3.Id LIMIT 1];
        if(meterHistories.size() > 0){
            delete meterHistories;
        }
        
        WorkOrderTriggerUtil.isFirstTriggerRun_Before = true;
        WorkOrderTriggerUtil.isFirstTriggerRun_After = true;
        wo3.Meter_Reading__c = 234;
        update wo3;
        
        WorkOrderTriggerUtil.isFirstTriggerRun_Before = true;
        WorkOrderTriggerUtil.isFirstTriggerRun_After = true;
        SVMXC__Service_Order__c wo4 = new SVMXC__Service_Order__c();
        wo4.SVMXC__Company__c = acct.Id;
        wo4.SVMXC__Order_Status__c = 'Open';
        wo4.SVMXC__Order_Type__c = 'Other';
        wo4.SVMXC__Component__c = ip.id;
        wo4.SVMXC__Site__c = location.id;
        wo4.Meter_Reading__c = 123;
        wo4.SVMXC__Problem_Description__c = 'desc';
        wo4.Location__c = location.Id;
        wo4.Business_Unit__c = 'National Maintenance Services';
        wo4.TFS_AMF_WO__c = true;
        insert wo4;
        
        Meter_History__c newMeterHistory = new Meter_History__c(
            Installed_Product__c = ip.Id,
            Meter_Reading__c = wo4.Meter_Reading__c,
            Work_Order__c = wo4.Id,
            Description__c = 'Meter Reading from Work Order',
            Reading_Date__c = Date.today()
        );
        insert newMeterHistory;
        
        WorkOrderTriggerUtil.isFirstTriggerRun_Before = true;
        WorkOrderTriggerUtil.isFirstTriggerRun_After = true;
        wo4.Meter_Reading__c = 234;
        update wo4;
        
        Test.stopTest();
    }
    
    public static TestMethod void test3(){
        String vrtid = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Vendor Account' LIMIT 1].Id;
        List<Account> accounts = new List<Account>();
        //Create Account
        Account acct = TestDataProvider.getAccounts(1,'Prospect Accounts', 'Customer')[0];
        acct.name = 'Test Account';
        accounts.add(acct);
        //Create Vendor Account
        accounts.addAll(TestDataProvider.getAccounts(2,'Vendor Account', 'Vendor'));
        //vendor.name = 'Test Vendor';
        //vendor.Type = 'Vendor';
        //vendor.RecordTypeId = vrtId;
        //accounts.add(vendor);
        //Create vendoe2
        //vendor2.name = 'Test Vendor2';
        //vendor2.Type = 'Vendor';
        //vendor2.RecordTypeId = vrtId;
        //accounts.add(vendor2);
        insert accounts;
        //Create Product
        Map<String,String> prodMap = TestDataProvider.getProductAndPriceBookEntry(1);
        String prodId = '';
        for(String key :prodMap.keySet()){
            prodId = key;
			break;
        }
        //Create Installed Product
        SVMXC__Installed_Product__c ip = new SVMXC__Installed_Product__c();
        ip.Name = 'Installed Product';
        ip.SVMXC__Status__c = 'Active';
        ip.SVMXC__Product__c = prodId;
        ip.SVMXC__Serial_Lot_Number__c = '123456';
        insert ip;
        //Create service group
        SVMXC__Service_Group__c sgroup = new SVMXC__Service_Group__c(
            Name = 'Test Service Group',
            SVMXC__Active__c = true,
            Super_Center__c = 'Miner-Central Texas'
        );
        insert sgroup;
        //Create service group member
        SVMXC__Service_Group_Members__c member = new SVMXC__Service_Group_Members__c(
            SVMXC__Service_Group__c = sgroup.Id,
            SVMXC__Salesforce_User__c = UserInfo.getUserId(),
            SVMXC__Fixed_Cost__c = 25
        ); 
        //insert member;
        //Create location
        SVMXC__Site__c  location = TestDataProvider.getLocations(1,'Location Site','SPSC',acct.Id)[0];
        insert location;
        //Get TFS Record Type
        String tfsRecTypeId = [SELECT Id FROM RecordType  WHERE SobjectType = 'SVMXC__Service_Order__c' AND DeveloperName = 'TFS'].id;
        //Start the test
        Test.startTest();
        
        SVMXC__Service_Order__c wo5 = new SVMXC__Service_Order__c();
        wo5.SVMXC__Company__c = acct.Id;
        wo5.SVMXC__Order_Status__c = 'Open';
        wo5.SVMXC__Order_Type__c = 'Equpment';
        wo5.SVMXC__Component__c = ip.id;
        wo5.SVMXC__Site__c = location.id;
        wo5.Meter_Reading__c = 123;
        wo5.SVMXC__Problem_Description__c = 'desc';
        wo5.Location__c = location.Id;
        wo5.Business_Unit__c = 'Total Fleet Solutions';
        wo5.RecordTypeId = tfsRecTypeId;
        wo5.Vendor_Name_c__c = accounts[1].Id;
        insert wo5;

        WorkOrderTriggerUtil.isFirstTriggerRun_Before = true;
        WorkOrderTriggerUtil.isFirstTriggerRun_After = true;
        wo5.Vendor_Name_c__c = accounts[2].Id;
        update wo5;
        
        WorkOrderTriggerUtil.isFirstTriggerRun_Before = true;
        WorkOrderTriggerUtil.isFirstTriggerRun_After = true;
        SVMXC__Service_Order__c wo2 = new SVMXC__Service_Order__c();
        wo2.SVMXC__Company__c = acct.Id;
        wo2.SVMXC__Order_Status__c = 'Open';
        wo2.SVMXC__Order_Type__c = 'Depot Repair';
        wo2.SVMXC__Component__c = ip.id;
        wo2.SVMXC__Site__c = location.id;
        wo2.SVMXC__Problem_Description__c = 'desc';
        wo2.Location__c = location.Id;
        wo2.Business_Unit__c = 'National Maintenance Services';
        insert wo2;
        
        Test.stopTest();
    }
}