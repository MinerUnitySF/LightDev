@isTest(seeAllData=true)
public with sharing class EditWOandCreateInvoiceTest {

    private static testmethod void test1(){
        
        String rtid = [Select Id From RecordType  Where SobjectType = 'SVMXC__Service_Order_Line__c' and DeveloperName = 'UsageConsumption'].id;
        
        Account ac = TestDataProvider.getAccounts(1,'Customer Account','Customer')[0];
        insert ac;
        
        Account ac1 = TestDataProvider.getAccounts(1,'Vendor Account','Vendor')[0];
        insert ac1;
        
        SVMXC__Installed_Product__c IP1 = new SVMXC__Installed_Product__c();
        IP1.Name = 'ip1';
        IP1.SVMXC__Company__c = ac.id;
        insert IP1;
        
        SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
        
        wo.SVMXC__Company__c = ac.id;
        wo.SVMXC__Order_Status__c = 'Open';
        wo.SVMXC__Order_Type__c = 'Parts Orders';
        wo.SVMXC__Component__c = IP1.id;
        insert wo;
        
        Map<String,String> prodMap = TestDataProvider.getProductAndPriceBookEntry(1);
        String pId = '';
        for(String key :prodMap.keySet()){
            pId = key;
			break;
        }
        
        SVMXC__Service_Order_Line__c wod = new SVMXC__Service_Order_Line__c();
        wod.Vendor__c = ac1.id;
        wod.SVMXC__Service_Order__c = wo.id;
        wod.SVMXC__Line_Type__c = 'Parts';
        wod.SVMXC__Activity_Type__c = 'Parts - Service and Remodel';
        wod.recordTypeId = rtid;
        wod.Sort_Order__c = 1;
        wod.SVMXC__Product__c = pId;
        wod.SVMXC__Actual_Quantity2__c = 1;
        wod.SVMXC__Actual_Price2__c = 100;
        wod.Vendor_Cost_Per_Unit__c = 100;
        wod.SVMXC__Is_Billable__c = true;
        insert wod;
        
        SVMXC__Service_Order_Line__c wod1 = new SVMXC__Service_Order_Line__c();
        wod1.Vendor__c = ac1.id;
        wod1.SVMXC__Service_Order__c = wo.id;
        wod1.SVMXC__Line_Type__c = 'Parts';
        wod1.SVMXC__Activity_Type__c = 'Parts - Service and Remodel';
        wod1.recordTypeId = rtid;
        wod1.SVMXC__Product__c = pId;
        wod1.SVMXC__Actual_Quantity2__c = 1;
        wod1.SVMXC__Actual_Price2__c = 100;
        wod1.Vendor_Cost_Per_Unit__c = 100;
        wod1.SVMXC__Activity_Type__c = 'Standard Labor';
        wod1.SVMXC__Is_Billable__c = true;
        insert wod1;
        
        PageReference pr = Page.EditWOandCreateInvoice;
        pr.getParameters().put('id', String.valueOf(wo.Id));
        
        Test.setCurrentPage(pr);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(wo);
        EditWOandCreateInvoice controller = new EditWOandCreateInvoice(sc);
        
        test.startTest();
        
        controller.add10MoreLines();
        
        controller.workOrderLines[0].enableCheckbox();
        controller.workOrderLines[0].changePart();
        controller.workOrderLines[0].togglePart();
        
        controller.quickSave();
        
        controller.completeLines();
        
        controller.workOrderLines[0].line.recordTypeId = rtid;
        controller.workOrderLines[0].line.SVMXC__Product__c = pId;
        controller.workOrderLines[0].line.SVMXC__Actual_Quantity2__c = 1;
        controller.workOrderLines[0].line.SVMXC__Actual_Price2__c = 100;
        controller.workOrderLines[0].line.Vendor_Cost_Per_Unit__c = 100;
        controller.workOrderLines[0].line.SVMXC__Activity_Type__c = 'Standard Labor';
        controller.workOrderLines[0].line.SVMXC__Is_Billable__c = true;
        controller.workOrderLines[0].invoice = true;
        
        Decimal subtotal = controller.workOrderLines[0].subTotal;
        controller.callAvatax();
        controller.saveAndClose();
        controller.updateAndCreateInvoice();
        ac.MH_SL_CustID__c = '1234567';
        update ac;
        controller.updateAndCreateInvoice();
        test.stopTest();
        
    }
    
    private static testmethod void test2(){
        
        //Create Account
        Account acct = TestDataProvider.getAccounts(1,'Prospect Accounts', 'Customer')[0];
        acct.MH_SL_CustID__c = '1234567';
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
        
        SVMXC__Service_Order_Line__c wod = new SVMXC__Service_Order_Line__c();
        wod.SVMXC__Line_Type__c = 'Travel';
        wod.SVMXC__Line_Status__c = 'Open';
        wod.SVMXC__Service_Order__c = wo.Id;
        wod.SVMXC__Activity_Type__c = 'Standard Labor';
        wod.Quoted__c = true;
        wod.Quoted_Unit_Cost__c = 10;
        wod.Quoted_Unit_Price__c = 15;
        wod.Quoted_Quantity__c = 2;
        wod.SVMXC__Is_Billable__c = true;
        insert wod;
        
        SVMXC__Service_Order_Line__c wod1 = new SVMXC__Service_Order_Line__c();
        wod1.SVMXC__Line_Type__c = 'Labor';
        wod1.SVMXC__Line_Status__c = 'Open';
        wod1.SVMXC__Service_Order__c = wo.Id;
        wod1.SVMXC__Activity_Type__c = 'Standard Labor';
        wod1.Quoted__c = true;
        wod1.Quoted_Unit_Cost__c = 10;
        wod1.Quoted_Unit_Price__c = 15;
        wod1.Quoted_Quantity__c = 2;
        wod1.SVMXC__Is_Billable__c = true;
        insert wod1;
        
        PageReference pr = Page.EditWOandCreateInvoice;
        pr.getParameters().put('id', String.valueOf(wo.Id));
        
        Test.setCurrentPage(pr);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(wo);
        EditWOandCreateInvoice controller = new EditWOandCreateInvoice(sc);
        
        test.startTest();
        
        controller.add10MoreLines();
        
        controller.workOrderLines[0].enableCheckbox();
        controller.workOrderLines[0].changePart();
        controller.workOrderLines[0].togglePart();
        controller.workOrderLines[0].quotedChanged();
        
        controller.quickSave();
        
        controller.completeLines();
        
        Decimal subtotal = controller.workOrderLines[0].subTotal;
        controller.callAvatax();
        controller.requestEditQuote();
        controller.saveAndClose();
        controller.updateAndCreateInvoice();
        test.stopTest();
    }
	private static testmethod void test3(){
        
        //Create Account
        Account acct = TestDataProvider.getAccounts(1,'Prospect Accounts', 'Customer')[0];
        acct.MH_SL_CustID__c = '1234567';
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
        wo.Work_Order_Type__c = 'Warranty';
        wo.Quoted_Total__c = 1000;
        insert wo;
        
        SVMXC__Service_Order_Line__c wod = new SVMXC__Service_Order_Line__c();
        wod.SVMXC__Line_Type__c = 'Travel';
        wod.SVMXC__Line_Status__c = 'Open';
        wod.SVMXC__Service_Order__c = wo.Id;
        wod.SVMXC__Activity_Type__c = 'Warranty';
        wod.SVMXC__Actual_Quantity2__c = 1.75;
        wod.Vendor_Cost_Per_Unit__c = 62;
        wod.SVMXC__Is_Billable__c = false;
        insert wod;
        
        SVMXC__Service_Order_Line__c wod1 = new SVMXC__Service_Order_Line__c();
        wod1.SVMXC__Line_Type__c = 'Labor';
        wod1.SVMXC__Line_Status__c = 'Open';
        wod1.SVMXC__Service_Order__c = wo.Id;
        wod1.SVMXC__Activity_Type__c = 'Warranty';
        wod1.SVMXC__Actual_Quantity2__c = 1.75;
        wod1.Vendor_Cost_Per_Unit__c = 62;
        wod1.SVMXC__Is_Billable__c = false;
        insert wod1;
        
        PageReference pr = Page.EditWOandCreateInvoice;
        pr.getParameters().put('id', String.valueOf(wo.Id));
        
        Test.setCurrentPage(pr);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(wo);
        EditWOandCreateInvoice controller = new EditWOandCreateInvoice(sc);
        
        test.startTest();
        
        controller.add10MoreLines();
        
        controller.workOrderLines[0].enableCheckbox();
        controller.workOrderLines[0].changePart();
        controller.workOrderLines[0].togglePart();
        controller.workOrderLines[0].billableChanged();
        
        controller.quickSave();
        
        controller.completeLines();
        
        Decimal subtotal = controller.workOrderLines[0].subTotal;
        controller.callAvatax();
        controller.saveAndClose();
        controller.updateAndCreateInvoice();
        test.stopTest();
    }
}