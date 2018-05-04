/**This the unit test for the AttachmentHelper class
** @programer: Izay Ramos-Irizarry
** @version: 2.0
** @date: 6/17/2015
*/
@isTest
private class WOAndSafetyChecklistAttachment_UT {
    //Test setup methood
    @testSetup 
    static void setup() {
        //Set accounts
        List<Account> accounts = TestDataProvider.getAccounts(2,'Customer','Customer');
        insert accounts;
        //Set contacts
        List<Contact> contacts = TestDataProvider.getContacts(1, accounts[0].Id);
        contacts.addAll(TestDataProvider.getContacts(1, accounts[1].Id));
        insert contacts;
        //Set vendors
        List<Account> vendors = TestDataProvider.getAccounts(1, 'Vendor Account', 'Vendor');
        insert vendors;
        //Set lovcations
        List<SVMXC__Site__c> locations = TestDataProvider.getLocations(1, 'Standard Location', 'Miner Corp', accounts[0].Id);
        insert locations;
        //Set installed products
        List<SVMXC__Installed_Product__c> installedProds = TestDataProvider.getInstalledProducts(2, 'Installed Product', locations[0].Id, accounts[0].Id);
        insert installedProds;
        //Set service teams
        List<SVMXC__Service_Group__c> serviceTeams = TestDataProvider.getServiceTeams(1, 'Miner Corp', 'Miner Corp');
        insert serviceTeams;
        //Set key store values
        TestDataProvider.setKeyValueStore();
    }
    
    static testMethod void test1() {
        //List of attachments
        List<Attachment> atts = new List<Attachment>();
        List<Account> accounts = [SELECT Id,Name FROM Account]; //fetch account
        List<Contact> contacts = [SELECT Id,Name,Email FROM Contact];//fetch contacts
        List<SVMXC__Installed_Product__c> ip = [SELECT Id,Name,SVMXC__Product__c,SVMXC__Site__c,SVMXC__Company__c FROM SVMXC__Installed_Product__c];//fetch installed prod
        //Create case
        Case cs = new Case(
            Status ='New', 
            Priority = 'Medium',
            Origin = 'Email',
            ContactId = contacts[0].Id,
            AccountId = accounts[0].Id,
            UNITY_Customer__c = accounts[0].Id
        ); 
        insert cs;
        //Create work order
        SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c(SVMXC__Company__c = accounts[0].Id);
        wo.SVMXC__Order_Status__c = 'New';
        wo.SVMXC__Order_Type__c='Field Service';
        wo.SVMXC__Street__c = '16260 Monterey St.';
        wo.SVMXC__City__c = 'Morgan Hill';
        wo.SVMXC__State__c = 'California';
        wo.SVMXC__Zip__c = '95037';
        wo.SVMXC__Country__c = 'USA';
        wo.Email_Service_Report__c = 'test.contact_0@domain.com';
        wo.SVMXC__Site__c = ip[0].SVMXC__Site__c;
        wo.SVMXC__Priority__c = 'Medium';
        wo.SVMXC__Case__c = cs.Id;
        wo.SVMXC__Component__c = ip[0].id;
        wo.SVMXC__Scheduled_Date_Time__c = DateTime.now();
        insert wo;
        //Create detail lines
        SVMXC__Service_Order_Line__c wdl = new SVMXC__Service_Order_Line__c(
            SVMXC__Service_Order__c = wo.id,
            SVMXC__Product__c = ip[0].SVMXC__Product__c,
            SVMXC__Line_Type__c = 'Parts',
            SVMXC__Activity_Type__c = 'Parts - New Construction',
            SVMXC__Estimated_Quantity2__c = 2,
            SVMXC__Estimated_Price2__c = 2,
            SVMXC__Actual_Quantity2__c  = 2,
            Service_Report_Line__c = 'Queued'
        );
        insert wdl;
        //Create job note
        Work_Performed__c jnote = new Work_Performed__c(
            Report_Status__c = 'Queued',
            Work_Order_c__c = wo.Id
        );
        insert jnote;
        
        Test.startTest();
        //Create attachment
        Attachment attach=new Attachment();     
        attach.Name = 'Create_Service_Report.pdf';
        Blob bodyBlob = Blob.valueOf('Unit Test Attachment Body');
        attach.body = bodyBlob;
        attach.parentId = wo.id;
        insert attach;
        atts.add(attach);
        List<Attachment> attachments = [SELECT Id, Name FROM Attachment WHERE Parent.Id = :wo.Id];
        System.assertEquals(1, attachments.size());
        //Create attachment 2
        Attachment attach2 = new Attachment();      
        attach2.Name = 'Create_Outlook_Safety.pdf';
        Blob bodyBlob2 = Blob.valueOf('Unit Test Attachment Body');
        attach2.body = bodyBlob2;
        attach2.parentId = wo.id;
        insert attach2;
        
        atts.add(attach2);
        
        SVMXC__Service_Order__c wo2 = new SVMXC__Service_Order__c(SVMXC__Company__c = accounts[1].Id);
        wo2.SVMXC__Order_Status__c = 'New';
        wo2.SVMXC__Order_Type__c='Field Service';
        wo2.SVMXC__Street__c = '16260 Monterey St.';
        wo2.SVMXC__City__c = 'Morgan Hill';
        wo2.SVMXC__State__c = 'California';
        wo2.SVMXC__Zip__c = '95037';
        wo2.SVMXC__Country__c = 'USA';
        wo2.Email_Service_Report__c = 'test.contact@domain.com';
        wo2.SVMXC__Site__c = ip[1].SVMXC__Site__c;
        wo2.SVMXC__Priority__c = 'Medium';
        wo2.SVMXC__Case__c = cs.Id;
        wo2.SVMXC__Component__c = ip[1].id;
        wo2.SVMXC__Scheduled_Date_Time__c = DateTime.now();
        insert wo2;
        
        //Create attachment 3
        Attachment attach3 = new Attachment();      
        attach3.Name = 'Create_Service_Report.pdf';
        Blob bodyBlob3 = Blob.valueOf('Unit Test Attachment Body');
        attach3.Body = bodyBlob3;
        attach3.ParentId = wo2.id;
        insert attach3;
        
        atts.add(attach3);
        
        update atts;
        
        Test.stopTest();
    }
    
}