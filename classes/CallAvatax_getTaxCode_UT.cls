/** This is the unit test class for the getTaxCode method in the CallAvatax class
 * @programmer: Izay Ramos
 * @date: 12/18/2015
 * @version: 1.0
 */
@isTest(SeeAllData=true)
public class CallAvatax_getTaxCode_UT {
    public static TestMethod void test1(){
        //fetch the record types for tax code associations
        String exRTId = [SELECT Id FROM RecordType WHERE SObjectType = 'Tax_Code_Associations__c' AND Name = 'Exception' LIMIT 1].Id;
        String sRTId = [SELECT Id FROM RecordType WHERE SObjectType = 'Tax_Code_Associations__c' AND Name = 'Standard' LIMIT 1].Id;
        List<Tax_Code_Associations__c> tca = new List<Tax_Code_Associations__c>();
        //Tax rule based on segment (State)
        Tax_Code_Associations__c tc1 = new Tax_Code_Associations__c(
        	Segment__c = 'TX',
            Order_Type__c = 'Service-DDM',
            Line_Type__c = 'Parts',
            Activity_Type__c = 'Parts - Service and Remodel',
            Tax_Code__c = 'seg-rule1',
            RecordTypeId = sRTId
        );
        tca.add(tc1);
        Tax_Code_Associations__c tc2 = new Tax_Code_Associations__c(
        	Segment__c = 'TX',
            Order_Type__c = 'Service-DDM',
            Activity_Type__c = 'Parts - Construction',
            Tax_Code__c = 'seg-rule2'
        );
        tca.add(tc2);
        //Rules based on order type
        Tax_Code_Associations__c tc3 = new Tax_Code_Associations__c(
        	Order_Type__c = 'Service-DDM',
            Line_Type__c = 'Labor',
            Activity_Type__c = 'Standard Labor',
            Tax_Code__c = 'ot-rule1'
        );
        tca.add(tc3);
        Tax_Code_Associations__c tc4 = new Tax_Code_Associations__c(
        	Order_Type__c = 'Service-DDM',
            Activity_Type__c = 'Overtime Labor',
            Tax_Code__c = 'ot-rule2'
        );
        tca.add(tc4);
        //Rules based on line type
        Tax_Code_Associations__c tc5 = new Tax_Code_Associations__c(
            Line_Type__c = 'Expenses',
            Activity_Type__c = 'Use Tax',
            Tax_Code__c = 'lt-rule1'
        );
        tca.add(tc5);
        Tax_Code_Associations__c tc6 = new Tax_Code_Associations__c(
            Line_Type__c = 'Expenses',
            Activity_Type__c = 'Warranty',
            Tax_Code__c = 'lt-rule2'
        );
        tca.add(tc6);
        //Rules based on activity type
        Tax_Code_Associations__c tc7 = new Tax_Code_Associations__c(
            Activity_Type__c = 'Travel - Standard Labor',
            Tax_Code__c = 'at-rule1'
        );
        tca.add(tc7);
        Tax_Code_Associations__c tc8 = new Tax_Code_Associations__c(
            Activity_Type__c = 'Travel - Over Time Labor',
            Tax_Code__c = 'at-rule2'
        );
        tca.add(tc8);
        //Insert the tax code rules
        insert tca;

        //Create Account
        Account acct = TestDataProvider.getAccounts(1,'Customer Account', 'Customer')[0];
        acct.MH_SL_CustID__c = '123456';
        acct.Ready_to_Convert__c = true;
        acct.Account_Status__c = 'Active';
        insert acct;
        //Create service group
        SVMXC__Service_Group__c sgroup = new SVMXC__Service_Group__c(
            Name = 'Test Service Group',
            SVMXC__Active__c = true,
            Super_Center__c = 'Miner-Houston',
            Segment__c = 'Houston',
            SVMXC__State__c = 'TX'
        );
        insert sgroup;
        //System.debug('===================== sgroup.id: ' + sgroup.Id);
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
        wo.SVMXC__Order_Type__c = 'Service-DDM';
        wo.SVMXC__Site__c = location.id;
        wo.SVMXC__Problem_Description__c = 'prob desc';
        wo.Location__c = location.Id;
        wo.Business_Unit__c = 'Miner Corp';
        wo.SVMXC__Service_Group__c = sgroup.Id;
        insert wo;
        
        //Create detail lines for the work order
        List<SVMXC__Service_Order_Line__c> lines = new List<SVMXC__Service_Order_Line__c>();
        SVMXC__Service_Order_Line__c line1 = new SVMXC__Service_Order_Line__c(
            SVMXC__Line_Type__c = 'Travel',
            SVMXC__Line_Status__c = 'Open',
            SVMXC__Service_Order__c = wo.Id,
            SVMXC__Activity_Type__c = 'Travel - Standard Labor'
        );
        SVMXC__Service_Order_Line__c line2 = new SVMXC__Service_Order_Line__c(
            SVMXC__Line_Type__c = 'Labor',
            SVMXC__Line_Status__c = 'Open',
            SVMXC__Service_Order__c = wo.Id,
            SVMXC__Activity_Type__c = 'Standard Labor'
        );
        SVMXC__Service_Order_Line__c line3 = new SVMXC__Service_Order_Line__c(
            SVMXC__Line_Type__c = 'Travel',
            SVMXC__Line_Status__c = 'Open',
            SVMXC__Service_Order__c = wo.Id,
            SVMXC__Activity_Type__c = 'Travel - Overtime Labor'
        );
        SVMXC__Service_Order_Line__c line4 = new SVMXC__Service_Order_Line__c(
            SVMXC__Line_Type__c = 'Labor',
            SVMXC__Line_Status__c = 'Open',
            SVMXC__Service_Order__c = wo.Id,
            SVMXC__Activity_Type__c = 'Overtime Labor'
        );
        SVMXC__Service_Order_Line__c line7 = new SVMXC__Service_Order_Line__c(
            SVMXC__Line_Type__c = 'Expenses',
            SVMXC__Line_Status__c = 'Open',
            SVMXC__Service_Order__c = wo.Id,
            SVMXC__Activity_Type__c = 'Use Tax'
        );
        lines.add(line1);lines.add(line2);lines.add(line3);lines.add(line4);lines.add(line7);
        //Create Product
        Map<String,String> prodMap = TestDataProvider.getProductAndPriceBookEntry(1);
        String prodId = '';
        for(String key :prodMap.keySet()){
            prodId = key;
            break;
        }
        SVMXC__Service_Order_Line__c line5 = new SVMXC__Service_Order_Line__c(
            SVMXC__Line_Type__c = 'Parts',
            SVMXC__Line_Status__c = 'Open',
            SVMXC__Service_Order__c = wo.Id,
            SVMXC__Product__c = prodId,
            SVMXC__Activity_Type__c = 'Parts - Service and Remodel'
        );
        SVMXC__Service_Order_Line__c line6 = new SVMXC__Service_Order_Line__c(
            SVMXC__Line_Type__c = 'Parts',
            SVMXC__Line_Status__c = 'Open',
            SVMXC__Service_Order__c = wo.Id,
            SVMXC__Product__c = prodId,
            SVMXC__Activity_Type__c = 'Parts - New Construction'
        );
        lines.add(line5);lines.add(line6);
        insert lines;
        //Now test the CallAvatax.getTaxCode method with different variations
        CallAvatax.getTaxCode(wo.Id);
    }
    //Test Tax Code Exceptions
    public static TestMethod void test2(){
        //fetch the record types for tax code associations
        String exRTId = [SELECT Id FROM RecordType WHERE SObjectType = 'Tax_Code_Associations__c' AND Name = 'Exception' LIMIT 1].Id;
        String sRTId = [SELECT Id FROM RecordType WHERE SObjectType = 'Tax_Code_Associations__c' AND Name = 'Standard' LIMIT 1].Id;
        List<Tax_Code_Associations__c> tca = new List<Tax_Code_Associations__c>();
        //Tax rule based on segment (State)
        Tax_Code_Associations__c tc1 = new Tax_Code_Associations__c(
        	Segment__c = 'TX',
            Order_Type__c = 'Service-DDM',
            Included_Line_Types__c = 'Parts;Vendor Services',
            Excluded_Line_Types__c = 'Labor',
            Included_Activity_Types__c = 'Parts - New Construction; Parts - Service and Remodel',
            Excluded_Activity_Types__c = 'Standard Labor; Overtime Labor',
            RecordTypeId = exRTId
        );
        tca.add(tc1);
        insert tca;
        List<Tax_Code_Exception__c> exceptions = new List<Tax_Code_Exception__c>();
        Tax_Code_Exception__c ex1 = new Tax_Code_Exception__c(
        	Tax_Code_Association__c = tc1.Id,
            Activity_Type__c = 'Parts - New Construction',
            Tax_Code__c = 'exempt'
        );
        insert ex1;

        //Create Account
        Account acct = TestDataProvider.getAccounts(1,'Customer Account', 'Customer')[0];
        acct.MH_SL_CustID__c = '123456';
        acct.Ready_to_Convert__c = true;
        acct.Account_Status__c = 'Active';
        insert acct;
        //Create service group
        SVMXC__Service_Group__c sgroup = new SVMXC__Service_Group__c(
            Name = 'Test Service Group',
            SVMXC__Active__c = true,
            Super_Center__c = 'Miner-Houston',
            Segment__c = 'Houston',
            SVMXC__State__c = 'TX'
        );
        insert sgroup;
        //System.debug('===================== sgroup.id: ' + sgroup.Id);
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
        wo.SVMXC__Order_Type__c = 'Service-DDM';
        wo.SVMXC__Site__c = location.id;
        wo.SVMXC__Problem_Description__c = 'prob desc';
        wo.Location__c = location.Id;
        wo.Business_Unit__c = 'Miner Corp';
        wo.SVMXC__Service_Group__c = sgroup.Id;
        insert wo;
        
        //Create detail lines for the work order
        List<SVMXC__Service_Order_Line__c> lines = new List<SVMXC__Service_Order_Line__c>();
        //Create Product
        Map<String,String> prodMap = TestDataProvider.getProductAndPriceBookEntry(1);
        String prodId = '';
        for(String key :prodMap.keySet()){
            prodId = key;
            break;
        }
        SVMXC__Service_Order_Line__c line5 = new SVMXC__Service_Order_Line__c(
            SVMXC__Line_Type__c = 'Parts',
            SVMXC__Line_Status__c = 'Open',
            SVMXC__Service_Order__c = wo.Id,
            SVMXC__Product__c = prodId,
            SVMXC__Activity_Type__c = 'Parts - Service and Remodel'
        );
        SVMXC__Service_Order_Line__c line6 = new SVMXC__Service_Order_Line__c(
            SVMXC__Line_Type__c = 'Parts',
            SVMXC__Line_Status__c = 'Open',
            SVMXC__Service_Order__c = wo.Id,
            SVMXC__Product__c = prodId,
            SVMXC__Activity_Type__c = 'Parts - New Construction'
        );
        lines.add(line5);lines.add(line6);
        insert lines;
        //Now test the CallAvatax.getTaxCode method with different variations
        CallAvatax.getTaxCode(wo.Id);
        //Update the exception rule to cover for blank values
        tc1.Order_Type__c = null;
        tc1.Included_Line_Types__c = null;
        tc1.Excluded_Line_Types__c = null;
        tc1.Included_Activity_Types__c = null;
        tc1.Excluded_Activity_Types__c = null;
        update tc1;
        CallAvatax.getTaxCode(wo.Id);
        //Update the exception rule to cover for not match
        tc1.Order_Type__c = null;
        tc1.Included_Line_Types__c = 'Labor';
        tc1.Excluded_Line_Types__c = 'Parts;Vendor Services';
        tc1.Included_Activity_Types__c = 'Standard Labor; Overtime Labor';
        tc1.Excluded_Activity_Types__c = 'Parts - New Construction; Parts - Service and Remodel';
        update tc1;
        CallAvatax.getTaxCode(wo.Id);
    }
}