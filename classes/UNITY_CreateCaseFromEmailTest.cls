@isTest
private class UNITY_CreateCaseFromEmailTest {

    static testMethod void TestCreateCaseFromTemplateEmail() {
        //create custom setting data
        List<UNITY_CaseFromEmailFields__c> fieldMap = new List<UNITY_CaseFromEmailFields__c>();
        fieldMap.add(new UNITY_CaseFromEmailFields__c(Template_Name__c = 'UnitTest-UNITY_CreateCaseFromEmail', 
                                                Field_Name__c = 'Priority', Additional_Description__c = 'This is a test',
                                                Search_Attribute__c = 'Priority', 
                                                Template_Key__c = 'someaddress@email.com',
                                                Name = 'Priority-UNITY_CreateCaseFromEmail'));
        fieldMap.add(new UNITY_CaseFromEmailFields__c(Template_Name__c = 'UnitTest-UNITY_CreateCaseFromEmail', 
                                                Field_Name__c = 'UNITY_NTE_Threshold__c',
                                                Search_Attribute__c = 'Not to Exceed Amt', 
                                                Template_Key__c = 'someaddress@email.com',
                                                Name = 'NTE-UNITY_CreateCaseFromEmail'));
        fieldMap.add(new UNITY_CaseFromEmailFields__c(Template_Name__c = 'UnitTest-UNITY_CreateCaseFromEmail', 
                                                Field_Name__c = 'UNITY_Service_Channel_Create_Date_Time__c',
                                                Search_Attribute__c = 'CreatedDate', 
                                                Template_Key__c = 'someaddress@email.com',
                                                Name = 'CreatedDate-UNITY_CreateCaseFromEmail'));
        fieldMap.add(new UNITY_CaseFromEmailFields__c(Template_Name__c = 'UnitTest-UNITY_CreateCaseFromEmail', 
                                                Field_Name__c = 'UNITY_SL_Invoice_Date__c',
                                                Search_Attribute__c = 'Invoice Date', 
                                                Template_Key__c = 'someaddress@email.com',
                                                Name = 'InvDate-UNITY_CreateCaseFromEmail'));
        fieldMap.add(new UNITY_CaseFromEmailFields__c(Template_Name__c = 'UnitTest-UNITY_CreateCaseFromEmail', 
                                                Field_Name__c = 'IsEscalated',
                                                Search_Attribute__c = 'IsEscalated', 
                                                Template_Key__c = 'someaddress@email.com',
                                                Name = 'IsEscalated-UNITY_CreateCaseFromEmail'));
        fieldMap.add(new UNITY_CaseFromEmailFields__c(Template_Name__c = 'UnitTest-UNITY_CreateCaseFromEmail', 
                                                Field_Name__c = 'AccountId',
                                                Search_Attribute__c = 'Service Address', 
                                                Template_Key__c = 'someaddress@email.com',
                                                Name = 'Address-UNITY_CreateCaseFromEmail'));
        insert fieldMap;
        
        UNITY_CaseFromEmailFieldValues__c fieldValueMap = new UNITY_CaseFromEmailFieldValues__c(Template_Name__c = 'UnitTest-UNITY_CreateCaseFromEmail', 
                                                                                    Field_Name__c = 'Priority',
                                                                                    Source_Value__c = 'Emergency', 
                                                                                    Template_Key__c = 'someaddress@email.com',
                                                                                    Final_Value__c = '4 Hour Response',
                                                                                    Name = 'UnitTest-UNITY_CreateCaseFromEmail');
        insert fieldValueMap;
        
        Account testAccount = new Account(Name = 'Test Acc for UNITY_CreateCaseFromEmail', ShippingStreet = '123 Test Ln', ShippingCity = 'SF', ShippingState = 'CA', ShippingPostalCode = '94104',
                                            BillingStreet = '123 Test Ln', BillingCity = 'SF', BillingState = 'CA', BillingPostalCode = '94104');
        insert testAccount;
        
        UNITY_Service_Contract__c testContract = new UNITY_Service_Contract__c(UNITY_Account__c = testAccount.Id, UNITY_IS_Active__c = TRUE);
        insert testContract;
        
        // create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        // setup the data for the email
        email.subject = 'UnitTest-UNITY_CreateCaseFromEmail';
        email.fromAddress = 'someaddress@email.com';
        email.toAddresses = new String[] {'toAddress@email.com'};
        email.plainTextBody = 'email body\nPriority: High\nNot to Exceed Amt: 200.00\nCreatedDate: ' + System.now() + 
                                '\nUNITY_SL_Invoice_Date__c: ' + Date.today() + '\nIsEscalated: false\nService Address: 123 Test Ln, SF, CA 94104';
        // add an Binary attachment
        Messaging.InboundEmail.BinaryAttachment binAttachment = new Messaging.InboundEmail.BinaryAttachment();
        binAttachment.body = blob.valueOf('my attachment binary');
        binAttachment.fileName = 'textfileone.txt';
        binAttachment.mimeTypeSubType = 'text/plain';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { binAttachment };
        // add an Text atatchment
        Messaging.InboundEmail.TextAttachment txtAttachment = new Messaging.InboundEmail.TextAttachment();
        txtAttachment.body = 'my attachment text';
        txtAttachment.fileName = 'textfiletwo.txt';
        txtAttachment.mimeTypeSubType = 'text/plain';
        email.textAttachments = new Messaging.inboundEmail.TextAttachment[] { txtAttachment };
        // call the email service class and test it with the data in the testMethod
        UNITY_CreateCaseFromEmail testInbound = new UNITY_CreateCaseFromEmail();
        testInbound.handleInboundEmail(email, env);
    }
    
    static testMethod void TestCreateCaseFromGenericEmail() {
        //create custom setting data
        List<UNITY_CaseFromEmailFields__c> fieldMap = new List<UNITY_CaseFromEmailFields__c>();
        fieldMap.add(new UNITY_CaseFromEmailFields__c(Template_Name__c = 'Generic', 
                                                Field_Name__c = 'Origin',
                                                Search_Attribute__c = 'Origin',
                                                Template_Key__c = 'email.com',
                                                Name = 'Generic-UNITY_CreateCaseFromEmail'));
        
        insert fieldMap;
        
        List<UNITY_EmailDomainMap__c> domainMap = new List<UNITY_EmailDomainMap__c>();
        domainMap.add(new UNITY_EmailDomainMap__c(Business_Unit__c = 'MNS', Case_Origin__c = 'Email-MNS', To_Email_Domain__c = 'email.com', Name = 'TestCreateCaseFromGenericEmail'));
        insert domainMap;
        
        // create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        // setup the data for the email
        email.subject = 'UnitTest-UNITY_CreateCaseFromEmail';
        email.fromAddress = 'someaddress@email.com';
        email.toAddresses = new String[] {'toAddress@email.com'};
        email.plainTextBody = 'email body\nOrigin: Email\n';
        
        // call the email service class and test it with the data in the testMethod
        UNITY_CreateCaseFromEmail testInbound = new UNITY_CreateCaseFromEmail();
        testInbound.handleInboundEmail(email, env);
    }
}