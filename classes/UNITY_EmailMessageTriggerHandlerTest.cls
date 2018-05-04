@isTest
public class UNITY_EmailMessageTriggerHandlerTest {
    
    static List<WorkOrder> workOrders;
    static Case acase;
    static Account accountCustomer;
    
    public static void setUp() {
        UNITY_Constants.MAX_TRIGGER_EXECUTION = 2;
        accountCustomer = UNITY_TestDataFactory.createAccounts(1,'Site/Location',UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE).get(0);
        Account accountVendor = UNITY_TestDataFactory.createAccounts(1,'Customer',UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE).get(0);
        List<Contact> contacts = UNITY_TestDataFactory.createContacts(2,accountCustomer.Id);
        List<Case> cases = UNITY_TestDataFactory.createCases(2,accountCustomer.Id,accountVendor.Id,contacts.get(0).Id,UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
        List<UNITY_Service_Contract__c> serviceContracts = UNITY_TestDataFactory.createServiceContracts(1, accountCustomer.Id);
        workOrders = UNITY_TestDataFactory.createWorkOrders(2,cases.get(0).Id,accountCustomer.Id,serviceContracts.get(0).Id,UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE);
        acase = cases.get(0);
    }
    
    static testMethod void acceptOrRejectWorkOrderAssigmentSuccess() { 
        setUp();
        WorkOrder workOrder = workOrders.get(0);
        workOrder.UNITY_Vendor_PIN__c = '1234';
        workOrder.UNITY_Vendor_Status__c = UNITY_Constants.WO_VENDOR_STATUS_ASSIGNED;
        update workOrder;
        
        EmailMessage dummyEmailMessage = new EmailMessage();
        dummyEmailMessage.Subject='Dummy Email Message';
        dummyEmailMessage.TextBody='';
        dummyEmailMessage.ParentId = acase.Id;
        insert dummyEmailMessage;
        
        Test.startTest();
        
        // work order status accepted
        EmailMessage emailMessage = new EmailMessage();
        emailMessage.Subject='Work Order Assigned '+ workOrder.WorkOrderNumber+' PIN '+workOrder.UNITY_Vendor_PIN__c;
        emailMessage.TextBody= UNITY_EmailMessageTriggerHandler.acceptWord;
        emailMessage.ParentId = acase.Id;
        emailMessage.Incoming = true;
        emailMessage.ReplyToEmailMessageId = dummyEmailMessage.Id;
        
        insert emailMessage;
        
        /*System.assert(![SELECT Id FROM WorkOrder WHERE WorkOrderNumber =: workOrder.WorkOrderNumber AND 
                      UNITY_Vendor_Status__c =: UNITY_Constants.WO_STATUS_ACCEPTED].isEmpty());*/
        workOrder = workOrders.get(1);
        update workOrder;
        
        // work order status rejected
        emailMessage = new EmailMessage();
        emailMessage.Subject='adsfasf Work Order Assigned '+ workOrder.WorkOrderNumber+' PIN '+workOrder.UNITY_Vendor_PIN__c;
        emailMessage.TextBody= UNITY_EmailMessageTriggerHandler.rejectWord;
        emailMessage.ParentId = acase.Id;
        emailMessage.Incoming = true;
        emailMessage.ReplyToEmailMessageId = dummyEmailMessage.Id;
        
        insert emailMessage;
        
        /*System.assert(![SELECT Id FROM WorkOrder WHERE WorkOrderNumber =: workOrder.WorkOrderNumber AND 
                      UNITY_Vendor_Status__c =: UNITY_Constants.WO_STATUS_REJECTED].isEmpty());*/
        
        Test.stopTest();
    }
    
    static testMethod void acceptProposalAssigmentSuccess() {
        setUp();
        List<UNITY_Proposal__c> proposals = UNITY_TestDataFactory.createQuote(1, acase.Id, workOrders.get(0).Id,accountCustomer.Id,UserInfo.getUserId());

        UNITY_Proposal__c proposal = proposals.get(0);
        proposal.RecordTypeId = UNITY_Constants.PROPOSAL_MASTER_PROPOSAL_RECORDTYPE;
        proposal.UNITY_Proposal_Status__c = UNITY_Constants.QT_STATUS_QUOTE_FINALIZED;
        proposal.UNITY_Master_PIN__c = UNITY_Utils.generateRandomPin();
        update proposal;
        system.debug('proposal from db'+[SELECT Id,Name,UNITY_Status__c,UNITY_Proposal_Status__c FROM UNITY_Proposal__c]);
        Test.startTest();
        System.debug('proposal:'+proposal);
        
        // work order status accepted
        EmailMessage emailMessage = new EmailMessage();
        emailMessage.Subject='Quote Proposed '+ proposal.Name+' PIN '+proposal.UNITY_Master_PIN__c;
        emailMessage.TextBody= UNITY_EmailMessageTriggerHandler.acceptWord;
        emailMessage.ParentId = acase.Id;
        emailMessage.Incoming = true;
        
        insert emailMessage;
        system.debug('proposal after insert emailMessage'+[SELECT Id,Name,UNITY_Status__c,UNITY_Proposal_Status__c FROM UNITY_Proposal__c]);
       /* System.assert(![SELECT Id FROM UNITY_Proposal__c WHERE Name =: proposal.Name AND 
                      UNITY_Status__c =: UNITY_Constants.QT_CUSTOMER_STATUS_ACCEPT].isEmpty());*/
        
        Test.stopTest();
    }
    
    static testMethod void rejectProposalAssigmentSuccess() {
        setUp();
        List<UNITY_Proposal__c> proposals = UNITY_TestDataFactory.createQuote(1, acase.Id, workOrders.get(0).Id,accountCustomer.Id,UserInfo.getUserId());

        UNITY_Proposal__c proposal = proposals.get(0);
        proposal.UNITY_Proposal_Status__c = UNITY_Constants.QT_STATUS_SENT_TO_CUSTOMER;
        update proposal;
        system.debug('proposal from db'+[SELECT Id,Name,UNITY_Status__c,UNITY_Proposal_Status__c FROM UNITY_Proposal__c]);
        Test.startTest();
        System.debug('proposal:'+proposal);
        
        // work order status accepted
        EmailMessage emailMessage = new EmailMessage();
        emailMessage.Subject='Quote Proposed '+ proposal.Name+' PIN '+proposal.UNITY_Customer_PIN__c;
        emailMessage.TextBody= UNITY_EmailMessageTriggerHandler.rejectWord+'.\nThe reason is: i do not care.';
        emailMessage.ParentId = acase.Id;
        emailMessage.Incoming = true;
        
        insert emailMessage;
        system.debug('proposal after insert emailMessage'+[SELECT Id,Name,UNITY_Status__c,UNITY_Proposal_Status__c FROM UNITY_Proposal__c]);
        /*System.assert(![SELECT Id FROM UNITY_Proposal__c WHERE Name =: proposal.Name AND 
                      UNITY_Status__c =: UNITY_Constants.QT_CUSTOMER_STATUS_REJECT].isEmpty());*/
        
        Test.stopTest();
    }
}