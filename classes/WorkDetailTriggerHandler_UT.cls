@isTest(SeeAllData=true)
public class WorkDetailTriggerHandler_UT {
    public static TestMethod void test1(){
        //Create Account
        Account acct = TestDataProvider.getAccounts(1,'Prospect Accounts', 'Customer')[0];
        insert acct;
        //Create service group
        SVMXC__Service_Group__c sgroup = new SVMXC__Service_Group__c(
            Name = 'Test Service Group',
            SVMXC__Active__c = true,
            Super_Center__c = 'Miner-Houston',
            Segment__c = 'New Orleans'
        );
        insert sgroup;
        System.debug('===================== sgroup.id: ' + sgroup.Id);
        //Create service group member
        SVMXC__Service_Group_Members__c member = new SVMXC__Service_Group_Members__c(
            SVMXC__Service_Group__c = sgroup.Id,
            SVMXC__Salesforce_User__c = UserInfo.getUserId(),
            SVMXC__Fixed_Cost__c = 25,
            SVMXC__Active__c = true,
            SVMXC__Email__c = 'test@domain.com',
            SVMXC__Role__c = 'Technician',
            Name = 'Test Tech'
        ); 
        insert member;
        //Create location
        SVMXC__Site__c  location = TestDataProvider.getLocations(1,'Location Site','SPSC',acct.Id)[0];
        insert location;
        //create Work Order
        SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
        wo.SVMXC__Company__c = acct.Id;
        wo.SVMXC__Order_Status__c = 'Open';
        wo.SVMXC__Order_Type__c = 'Service-RES';
        wo.SVMXC__Site__c = location.id;
        wo.SVMXC__Problem_Description__c = 'desc';
        wo.Location__c = location.Id;
        wo.Business_Unit__c = 'Miner Corp';
        wo.SVMXC__Service_Group__c = sgroup.Id;
        insert wo;
        //Create detail lines to the work order
        List<SVMXC__Service_Order_Line__c> lines = new List<SVMXC__Service_Order_Line__c>();
        SVMXC__Service_Order_Line__c line1 = new SVMXC__Service_Order_Line__c(
            SVMXC__Line_Type__c = 'Travel',
            SVMXC__Line_Status__c = 'Open',
            SVMXC__Service_Order__c = wo.Id,
            SVMXC__Activity_Type__c = 'Standard Labor'
        );
        SVMXC__Service_Order_Line__c line2 = new SVMXC__Service_Order_Line__c(
            SVMXC__Line_Type__c = 'Labor',
            SVMXC__Line_Status__c = 'Open',
            SVMXC__Service_Order__c = wo.Id,
            SVMXC__Activity_Type__c = 'Standard Labor'
        );
        lines.add(line1);lines.add(line2);
        insert lines;
        wo = [SELECT Id,Super_Center__c,Segment__c,Certificate__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id LIMIT 1];
        System.assert(String.isNotBlank(wo.Certificate__c));
        //Create Product
        Map<String,String> prodMap = TestDataProvider.getProductAndPriceBookEntry(1);
        String prid = '';
        for(String key :prodMap.keySet()){
            prid = key;
			break;
        }
        SVMXC__Service_Order_Line__c line3 = new SVMXC__Service_Order_Line__c(
            SVMXC__Line_Type__c = 'Parts',
            SVMXC__Line_Status__c = 'Open',
            SVMXC__Service_Order__c = wo.Id,
            SVMXC__Product__c = prid,
            SVMXC__Activity_Type__c = 'Parts - Service and Remodel'
        );
        insert line3;
        wo = [SELECT Id,Super_Center__c,Segment__c,Certificate__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id LIMIT 1];
        System.assert(String.isBlank(wo.Certificate__c));
        delete line3;
        wo = [SELECT Id,Super_Center__c,Segment__c,Certificate__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id LIMIT 1];
        //System.assert(String.isNotBlank(wo.Certificate__c));
    }
    public static TestMethod void test2(){
        //Create Account
        Account acct = TestDataProvider.getAccounts(1,'Prospect Accounts', 'Customer')[0];
        insert acct;
        //Create service group
        SVMXC__Service_Group__c sgroup = new SVMXC__Service_Group__c(
            Name = 'Test Service Group',
            SVMXC__Active__c = true,
            Super_Center__c = 'Miner-Houston',
            Segment__c = 'New Orleans'
        );
        insert sgroup;
        System.debug('===================== sgroup.id: ' + sgroup.Id);
        //Create service group member
        SVMXC__Service_Group_Members__c member = new SVMXC__Service_Group_Members__c(
            SVMXC__Service_Group__c = sgroup.Id,
            SVMXC__Salesforce_User__c = UserInfo.getUserId(),
            SVMXC__Fixed_Cost__c = 25,
            SVMXC__Active__c = true,
            SVMXC__Email__c = 'test@domain.com',
            SVMXC__Role__c = 'Technician',
            Name = 'Test Tech'
        ); 
        insert member;
        //Create location
        SVMXC__Site__c  location = TestDataProvider.getLocations(1,'Location Site','SPSC',acct.Id)[0];
        insert location;
        //create Work Order
        SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
        wo.SVMXC__Company__c = acct.Id;
        wo.SVMXC__Order_Status__c = 'Open';
        wo.SVMXC__Order_Type__c = 'Service-RES';
        wo.SVMXC__Site__c = location.id;
        wo.SVMXC__Problem_Description__c = 'desc';
        wo.Location__c = location.Id;
        wo.Business_Unit__c = 'Miner Corp';
        wo.SVMXC__Service_Group__c = sgroup.Id;
        wo.Work_Order_Type__c = 'Quoted';
        wo.Quoted_Total__c = 1000;
        insert wo;
        //Create detail lines to the work order
        List<SVMXC__Service_Order_Line__c> lines = new List<SVMXC__Service_Order_Line__c>();
        SVMXC__Service_Order_Line__c line1 = new SVMXC__Service_Order_Line__c(
            SVMXC__Line_Type__c = 'Travel',
            SVMXC__Line_Status__c = 'Open',
            SVMXC__Service_Order__c = wo.Id,
            SVMXC__Activity_Type__c = 'Standard Labor',
            Quoted__c = true,
            Quoted_Unit_Cost__c = 10,
            Quoted_Unit_Price__c = 15,
            Quoted_Quantity__c = 2
        );
        SVMXC__Service_Order_Line__c line2 = new SVMXC__Service_Order_Line__c(
            SVMXC__Line_Type__c = 'Labor',
            SVMXC__Line_Status__c = 'Open',
            SVMXC__Service_Order__c = wo.Id,
            SVMXC__Activity_Type__c = 'Standard Labor',
            Quoted__c = true,
            Quoted_Unit_Cost__c = 10,
            Quoted_Unit_Price__c = 15,
            Quoted_Quantity__c = 2
        );
        SVMXC__Service_Order_Line__c line3 = new SVMXC__Service_Order_Line__c(
            SVMXC__Line_Type__c = 'Labor',
            SVMXC__Line_Status__c = 'Open',
            SVMXC__Service_Order__c = wo.Id,
            SVMXC__Activity_Type__c = 'Standard Labor',
            Line_from_iPad__c = true,
            SVMXC__Actual_Quantity2__c = 1.75,
            Vendor_Cost_Per_Unit__c = 62
        );
        lines.add(line1);lines.add(line2);lines.add(line3);
        insert lines;
        wo = [SELECT Id,Super_Center__c,Segment__c,Certificate__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id LIMIT 1];
        System.assert(String.isNotBlank(wo.Certificate__c));
        //Create Product
        Map<String,String> prodMap = TestDataProvider.getProductAndPriceBookEntry(1);
        String prid = '';
        for(String key :prodMap.keySet()){
            prid = key;
			break;
        }
        SVMXC__Service_Order_Line__c line4 = new SVMXC__Service_Order_Line__c(
            SVMXC__Line_Type__c = 'Parts',
            SVMXC__Line_Status__c = 'Open',
            SVMXC__Service_Order__c = wo.Id,
            SVMXC__Product__c = prid,
            SVMXC__Activity_Type__c = 'Parts - Service and Remodel'
        );
        insert line4;
        wo = [SELECT Id,Super_Center__c,Segment__c,Certificate__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id LIMIT 1];
        System.assert(String.isBlank(wo.Certificate__c));
        delete line3;
        wo = [SELECT Id,Super_Center__c,Segment__c,Certificate__c FROM SVMXC__Service_Order__c WHERE Id = :wo.Id LIMIT 1];
        //System.assert(String.isNotBlank(wo.Certificate__c));
    }
}