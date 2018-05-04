@isTest(SeeAllData = true)
private class CreateInvoiceandinvoiceDetails_UT {

    static testMethod void myUnitTest() {
            
        Account ac = TestDataProvider.getAccounts(1,'Customer Account','Customer')[0];
        insert ac;

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
        
        Account ac1 = TestDataProvider.getAccounts(1,'Vendor Account','Vendor')[0];
        insert ac1;
        
        SVMXC__Service_Order_Line__c wod = new SVMXC__Service_Order_Line__c();
        wod.Vendor__c = ac1.id;
        wod.SVMXC__Service_Order__c = wo.id;
        wod.SVMXC__Line_Type__c = 'Parts';
        wod.SVMXC__Activity_Type__c = 'Parts - Service and Remodel';
        wod.SVMXC__Line_Status__c = 'Completed';
        insert wod;
        
        SVMXC__Service_Order_Line__c wod1 = new SVMXC__Service_Order_Line__c();
        wod1.Vendor__c = ac1.id;
        wod1.SVMXC__Service_Order__c = wo.id;
        wod1.SVMXC__Line_Type__c = 'Parts';
        wod1.SVMXC__Activity_Type__c = 'Parts - Service and Remodel';
        insert wod1;
        
        PageReference pageRef = Page.CreateInvoiceandInvoiceDetails;
        pageRef.getParameters().put('id',wo.id);
        
        Test.setCurrentPageReference(pageRef);
        CreateInvoiceandInvoiceDetails br = new CreateInvoiceandInvoiceDetails();
        br.wodw_list[0].checked = true;
        br.saveAndClose();
    }
}