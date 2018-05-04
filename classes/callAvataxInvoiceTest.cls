@isTest(SeeAllData=true)
public with sharing class callAvataxInvoiceTest {
    
    private static testmethod void test1(){
        
        //Create Account;
        Account acct = TestDataProvider.getAccounts(1, 'Customer Account', 'Customer')[0];
        insert acct;
        //Create location
        SVMXC__Site__c l = new SVMXC__Site__c(
            Name = 'TestLocation_0',
            SVMXC__Street__c = '000 Main Street',
            SVMXC__City__c = 'San Antonio',
            SVMXC__State__c = 'TX',
            SVMXC__Zip__c = '78232',
            Call_Type__c = 'SPSC',
            SVMXC__Account__c = acct.Id
        );
        insert l;
        //Create Contact
        Contact contact = new Contact(
            FirstName = 'Test', 
            LastName = 'Contact_0', 
            Email = 'test.contact_0@domain.com',
            AccountId = acct.Id
        );
        insert contact; 
        Product2 prod = new Product2(
            Name = 'TestProduct_IP',
            ProductCode = 'Test-123456',
            Make1__c = 'TestMake',
            Model__c = 'TestModel',
            Broad__c = 'Door',
            Group__c = 'High Speed',
            Type__c = 'Electrical',
            Family = 'Equipment',
            SVMXC__Product_Line__c = 'Equipment',
            IsActive = true,
            Description = 'Installed Product Test Product',
            SVMXC__Product_Cost__c = 0.00,
            SVMXC__Inherit_Parent_Warranty__c = true,
            UNITY_Status__c = 'Active',
            UNITY_Product_Cost__c = 0,
            UNITY_Unit_Of_Measure__c = 'Each'
        );
        insert prod;
        //create IP
        SVMXC__Installed_Product__c ip1 = new SVMXC__Installed_Product__c(
            Name = 'TestLocation_IP_',
            Serial_Number__c = '123456_',
            SVMXC__Asset_Tag__c = 'ABC',
            SVMXC__Status__c = 'Active',
            Broad_IP__c = 'Door',
            Group_IP__c = 'High Speed',
            Ownership_Type__c = 'Owned',
            SVMXC__Product__c = prod.Id,
            SVMXC__Site__c = l.Id,
            SVMXC__Company__c = acct.Id
        );
        insert ip1;
        ip1 = [SELECT Id,Name,Serial_Number__c,SVMXC__Site__c,SVMXC__Company__c,SVMXC__Product__c FROM SVMXC__Installed_Product__c WHERE Id = :ip1.Id LIMIT 1];    
        //Create a service team
        SVMXC__Service_Group__c st = new SVMXC__Service_Group__c(
            Name = 'TestServiceTeam_',
            Super_Center__c = 'Miner-Central Texas',
            Segment__c = 'San Antonio',
            SVMXC__Active__c = true,
            SVMXC__Group_Type__c = 'Internal',
            SVMXC__Description__c = 'Test Service Team for Miner-Central Texas',
            Company_Code__c = 'code'
        );
        insert st;
        //Create service group member
        SVMXC__Service_Group_Members__c member = new SVMXC__Service_Group_Members__c(
            SVMXC__Service_Group__c = st.Id,
            SVMXC__Salesforce_User__c = UserInfo.getUserId(),
            SVMXC__Fixed_Cost__c = 25,
            SVMXC__Active__c = true,
            SVMXC__Email__c = 'test@domain.com',
            SVMXC__Role__c = 'Technician',
            Name = 'Test Tech'
        ); 
        insert member;
        //Create Work Order
        SVMXC__Service_Order__c workOrder = new SVMXC__Service_Order__c (
            SVMXC__Company__c = acct.Id , 
            SVMXC__Order_Status__c = 'Open',
            SVMXC__Priority__c ='Medium',
            SVMXC__Order_Type__c='Field Service',
            SVMXC__Service_Group__c = st.Id,
            Location__c = l.Id,
            SVMXC__Component__C = ip1.Id,
            SVMXC__Group_Member__c = member.Id,
            Business_Unit__c = 'Miner Corp'
        );
        insert workOrder;
         //create WO Lines - Estimate
        RecordType rtwdLine = [SELECT Id FROM RecordType WHERE SobjectType = 'SVMXC__Service_Order_Line__c' AND Name = 'Estimate' Limit 1];
        SVMXC__Service_Order_Line__c wdLine = new SVMXC__Service_Order_Line__c(
            SVMXC__Service_Order__c = workOrder.Id,
            SVMXC__Product__c = ip1.SVMXC__Product__c,
            SVMXC__Line_Type__c = 'Parts',
            SVMXC__Estimated_Quantity2__c = 2,
            SVMXC__Estimated_Price2__c = 2,
            SVMXC__Actual_Quantity2__c  = 2,
            RecordTypeId = rtwdLine.id,
            SVMXC__Activity_Type__c = 'Parts - Service and Remodel'
        );
        insert wdLine;

        MH_Invoice__c inv = new MH_Invoice__c();
        inv.Work_Order__c = workOrder.Id;
        inv.Location__c = l.Id;
        inv.Account__c = acct.Id;
        insert inv;
        
        MH_Invoice_Details__c invli = new MH_Invoice_Details__c();
        invli.Invoice__c = inv.Id;
        invli.Work_Detail__c = wdLine.Id;
        invli.Work_Order__c = workOrder.Id;
        invli.Activity_Type__c = wdLine.SVMXC__Activity_Type__c;
        insert invli;
        
        Test.startTest();
        
        Test.setMock(WebServiceMock.class, new AvataxCalloutMock());
        ApexPages.CurrentPage().getParameters().put('id', inv.Id);
        CallAvataxInvoice cv = new CallAvataxInvoice();
        cv.call();
        cv.save();
        cv.cancel();
        
        Test.stopTest();
        
    }
    public static TestMethod void test2(){
        //Create Account;
        Account acct = TestDataProvider.getAccounts(1, 'Customer Account', 'Customer')[0];
        insert acct;
        //Create location
        SVMXC__Site__c l = new SVMXC__Site__c(
            Name = 'TestLocation_0',
            SVMXC__Street__c = '000 Main Street',
            SVMXC__City__c = 'San Antonio',
            SVMXC__State__c = 'TX',
            SVMXC__Zip__c = '78232',
            Call_Type__c = 'SPSC',
            SVMXC__Account__c = acct.Id
        );
        insert l;
        //Create Contact
        Contact contact = new Contact(
            FirstName = 'Test', 
            LastName = 'Contact_0', 
            Email = 'test.contact_0@domain.com',
            AccountId = acct.Id
        );
        insert contact; 
        Product2 prod = new Product2(
            Name = 'TestProduct_IP',
            ProductCode = 'Test-123456',
            Make1__c = 'TestMake',
            Model__c = 'TestModel',
            Broad__c = 'Door',
            Group__c = 'High Speed',
            Type__c = 'Electrical',
            Family = 'Equipment',
            SVMXC__Product_Line__c = 'Equipment',
            IsActive = true,
            Description = 'Installed Product Test Product',
            SVMXC__Product_Cost__c = 0.00,
            SVMXC__Inherit_Parent_Warranty__c = true,
            UNITY_Status__c = 'Active',
            UNITY_Product_Cost__c = 0,
            UNITY_Unit_Of_Measure__c = 'Each'
        );
        insert prod;
        //create IP
        SVMXC__Installed_Product__c ip1 = new SVMXC__Installed_Product__c(
            Name = 'TestLocation_IP_',
            Serial_Number__c = '123456_',
            SVMXC__Asset_Tag__c = 'ABC',
            SVMXC__Status__c = 'Active',
            Broad_IP__c = 'Door',
            Group_IP__c = 'High Speed',
            Ownership_Type__c = 'Owned',
            SVMXC__Product__c = prod.Id,
            SVMXC__Site__c = l.Id,
            SVMXC__Company__c = acct.Id
        );
        insert ip1;
        ip1 = [SELECT Id,Name,Serial_Number__c,SVMXC__Site__c,SVMXC__Company__c,SVMXC__Product__c FROM SVMXC__Installed_Product__c WHERE Id = :ip1.Id LIMIT 1];    
        //Create a service team
        SVMXC__Service_Group__c st = new SVMXC__Service_Group__c(
            Name = 'TestServiceTeam_',
            Super_Center__c = 'Miner-Central Texas',
            Segment__c = 'San Antonio',
            SVMXC__Active__c = true,
            SVMXC__Group_Type__c = 'Internal',
            SVMXC__Description__c = 'Test Service Team for Miner-Central Texas',
            Company_Code__c = 'code'
        );
        insert st;
        //Create Work Order
        SVMXC__Service_Order__c workOrder = new SVMXC__Service_Order__c (
            SVMXC__Company__c = acct.Id , 
            SVMXC__Order_Status__c = 'Open',
            SVMXC__Priority__c ='Medium',
            SVMXC__Order_Type__c='Field Service',
            SVMXC__Service_Group__c = st.Id,
            Location__c = l.Id,
            SVMXC__Component__C = ip1.Id
        );
        insert workOrder;
         //create WO Lines - Estimate
        RecordType rtwdLine = [SELECT Id FROM RecordType WHERE SobjectType = 'SVMXC__Service_Order_Line__c' AND Name = 'Estimate' Limit 1];
        SVMXC__Service_Order_Line__c wdLine = new SVMXC__Service_Order_Line__c(
            SVMXC__Service_Order__c = workOrder.Id,
            SVMXC__Product__c = ip1.SVMXC__Product__c,
            SVMXC__Line_Type__c = 'Parts',
            SVMXC__Estimated_Quantity2__c = 2,
            SVMXC__Estimated_Price2__c = 2,
            SVMXC__Actual_Quantity2__c  = 2,
            RecordTypeId = rtwdLine.id,
            SVMXC__Activity_Type__c = 'Parts - Service and Remodel',
            Tax_Code__c = 'testcode'
        );
        insert wdLine;
        
        MH_Invoice__c inv = new MH_Invoice__c();
        inv.Work_Order__c = workOrder.Id;
        inv.Location__c = l.Id;
        inv.Account__c = acct.Id;
        insert inv;
        
        MH_Invoice_Details__c invli = new MH_Invoice_Details__c();
        invli.Invoice__c = inv.Id;
        invli.Work_Detail__c = wdLine.Id;
        invli.Work_Order__c = workOrder.Id;
        invli.Activity_Type__c = wdLine.SVMXC__Activity_Type__c;
        insert invli;
        
        Test.startTest();
        
        Test.setMock(WebServiceMock.class, new AvataxCalloutMock_Error());
        ApexPages.CurrentPage().getParameters().put('id', inv.Id);
        ApexPages.CurrentPage().getParameters().put('retUrl', '/'+inv.Id);
        CallAvataxInvoice cv = new CallAvataxinvoice();
        cv.call();
        cv.tcode = 'testtaxcode';
        cv.save();
        cv.cancel();
        
        Test.stopTest();
    }
}