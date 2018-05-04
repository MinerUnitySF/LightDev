@isTest
public class Web2LeadEmailHandler_UT{

    public static testMethod void EmailAttachmentTester(){
        String emailBody = 'FirstName:Test1\n\r'+
        'LastName:user\n\r'+
        'Company:test123\n\r'+
        'Email:izramos@minercorp.com\n\r'+
        'Phone:2105555532\n\r'+
        'Description:Hopefully this works\n\r'+
        'Web2Lead_Type__c:Contact Us\n\r'+
        'PostalCode:78232\n\r-END-';
       
        // Create a new email, envelope object and Attachment
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        
        email.subject = 'Web To Lead Test';
        email.plainTextBody = emailBody;
        envelope.fromAddress = 'izramos@minercorp.com';
        //Messaging.InboundEmail.BinaryAttachment[] binaryAttachments = new Messaging.InboundEmail.BinaryAttachment[2];
        Messaging.InboundEmail.BinaryAttachment binaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
        binaryAttachment.Filename = 'test.pdf';
        binaryAttachment.body = blob.valueOf('my attachment text');
        binaryattachment.mimeTypeSubType = 'text/plain';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { binaryattachment };
        
        Web2LeadEmailHandler w2leh = new Web2LeadEmailHandler();
        
        Messaging.InboundEmailResult result = w2leh.handleInboundEmail(email,envelope);
        System.debug(result);
        System.assertEquals( result.success  ,true);
    
    }
}