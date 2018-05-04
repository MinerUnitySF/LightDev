@isTest
public class UNITY_InvoicePDFControllerTest{

    public static testMethod void runTest(){
        
        id priceBookId = Test.getStandardPricebookId();
        
        Account acc = new Account(Name = 'Test', Type= 'Site/Location', BillingCity = 'City', BillingStateCode = 'CA', BillingPostalCode = '12345', BillingCountry = 'US', BillingStreet = 'Street', Account_Email__c = 'test2@test.com');
        insert acc;
        
        Contact con = new Contact(FirstName = 'Test', LastName = 'Test', Email='test@test.com', AccountId = acc.Id);
        insert con;
        
        Case c = new Case(AccountId = acc.Id, ContactId = con.Id);
        insert c;
    
        RecordType customerRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'UNITY_Customer' AND SObjectType = 'Account'];

        Account customer = new Account(UNITY_TimeZoneSidKey__c = 'Europe/Prague', RecordTypeId = customerRt.Id, Name='Test2', BillingCity='City', BillingStateCode='CA', BillingStreet='Test Street', BillingPostalCode='12345', Account_Email__c = 'test2@test.com');
        insert customer;
    
        Key_Value_Store__c kvs = new Key_Value_Store__c(Name = 'Avatax URL', Value__c = 'www.someTestURL.com');
        insert kvs;
    
        UNITY_Invoice__c invoice = new UNITY_Invoice__c(UNITY_Customer__c = customer.Id, UNITY_Case__c = c.Id);
        insert invoice;
        
        Product2 product = new Product2(Name = 'Test');
        product.UNITY_Status__c = 'Inactive';
        product.Description = 'testtesttesttesttesttesttesttest';
        insert product;
        
        Product2 product2 = new Product2(Name = 'Test2');
        product2.UNITY_Status__c = 'Inactive';
        product2.Description = 'testtesttesttesttesttesttesttest';
        insert product2;
        
        Product2 product3 = new Product2(Name = 'Test3');
        product3.UNITY_Status__c = 'Inactive';
        product3.Description = 'testtesttesttesttesttesttesttest';
        insert product3;
        
        PricebookEntry pe = new PricebookEntry(Pricebook2Id = priceBookId, Product2Id = product.Id, UnitPrice = 10, IsActive = true);
        insert pe;
        
        PricebookEntry pe2 = new PricebookEntry(Pricebook2Id = priceBookId, Product2Id = product2.Id, UnitPrice = 10, IsActive = true);
        insert pe2;
        
        PricebookEntry pe3 = new PricebookEntry(Pricebook2Id = priceBookId, Product2Id = product3.Id, UnitPrice = 10, IsActive = true);
        insert pe3;
        
        UNITY_Invoice_Line_Item__c ili1 = new UNITY_Invoice_Line_Item__c(Product__c = product.Id, UNITY_Invoice__c = invoice.Id, UNITY_Quantity__c = 1);
        insert ili1;
        
        UNITY_Invoice_Line_Item__c ili2 = new UNITY_Invoice_Line_Item__c(Product__c = product2.Id, UNITY_Invoice__c = invoice.Id, UNITY_Quantity__c = 2);
        insert ili2;
        
        UNITY_Invoice_Line_Item__c ili3 = new UNITY_Invoice_Line_Item__c(Product__c = product3.Id, UNITY_Invoice__c = invoice.Id, UNITY_Quantity__c = 3);
        insert ili3;
        
        Test.startTest();
        UNITY_InvoicePDFController controller = new UNITY_InvoicePDFController();
        controller.invoiceId = invoice.Id;
        
        Set<String> invIds = new Set<String>();
        invIds.add(invoice.Id);
        UNITY_AttachmentHelper_Miner.createInvoiceAttachment(invIds);
        
        system.assertEquals(15, controller.pageWrappers.get(0).invoiceLineItemWrappers.size());
        system.assertEquals(true, controller.pageWrappers.get(0).invoiceLineItemWrappers.get(0).productName.contains('Test'));
        system.assertEquals(true, controller.pageWrappers.get(0).invoiceLineItemWrappers.get(1).productName.contains('Test'));
        system.assertEquals(true, controller.pageWrappers.get(0).invoiceLineItemWrappers.get(2).productName.contains('Test'));
        system.assertEquals('', controller.pageWrappers.get(0).invoiceLineItemWrappers.get(3).productName);
    	Test.stopTest();
    }

}