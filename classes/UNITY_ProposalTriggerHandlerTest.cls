@isTest
public class UNITY_ProposalTriggerHandlerTest {
    
    @TestVisible static private List<UNITY_Proposal__c> proposals;
    
    @TestVisible static testMethod void testProposalShareReadSuccess(){
        
        Account accountCustomer = UNITY_TestDataFactory.createAccounts(1,'Site/Location',UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE).get(0);
        Account accountVendor = UNITY_TestDataFactory.createAccounts(1,'Customer',UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE).get(0);
        List<UNITY_Service_Contract__c> serviceContractsVendor = UNITY_TestDataFactory.createServiceContracts(2,accountVendor.id);
        List<UNITY_Service_Contract__c> serviceContractsCustomer = UNITY_TestDataFactory.createServiceContracts(2,accountCustomer.Id);
        List<Contact> contacts = UNITY_TestDataFactory.createContacts(2,accountCustomer.Id);
        List<Case> cases = UNITY_TestDataFactory.createCases(2,accountCustomer.Id,accountVendor.Id,contacts.get(0).Id,UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
        List<UNITY_Service_Contract__c> serviceContracts = UNITY_TestDataFactory.createServiceContracts(1, accountCustomer.Id);
        List<WorkOrder> workOrders = UNITY_TestDataFactory.createWorkOrders(2,cases.get(0).Id,accountCustomer.Id,serviceContracts.get(0).Id,UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE);
        
        List<User> technicians = UNITY_TestDataFactory.createUsersTechnician(1, contacts.get(0).Id);
        
        Test.startTest();
        proposals = UNITY_TestDataFactory.createQuote(10,cases.get(0).Id,workOrders.get(0).Id,accountCustomer.Id,UserInfo.getUserId());
        
        Test.stopTest(); 
        
        system.debug(' >>> cases :'+[SELECT Id,ContactId FROM Case]);
        
         System.debug(' >>> manual sharing :'+[SELECT Id, UserOrGroupId, AccessLevel, RowCause 
                       FROM UNITY_Proposal__Share 
                       WHERE ParentId IN :UNITY_Utils.joiningByIdList(proposals)]);
        
        // TODO potential issue
        System.assert([SELECT Id, UserOrGroupId, AccessLevel, RowCause 
                       FROM UNITY_Proposal__Share 
                       WHERE ParentId IN :UNITY_Utils.joiningByIdList(proposals) AND 
                             UserOrGroupId IN :UNITY_Utils.joiningByIdList(technicians)].isEmpty());
        
    }
    
    static testMethod void createFirsSubQuoteOnCase() {
        Account accountCustomer = UNITY_TestDataFactory.createAccounts(1,'Site/Location',UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE).get(0);
        Account accountVendor = UNITY_TestDataFactory.createAccounts(1,'Customer',UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE).get(0);
        List<Contact> contacts = UNITY_TestDataFactory.createContacts(2,accountCustomer.Id);
        List<Case> cases = UNITY_TestDataFactory.createCases(2,accountCustomer.Id,accountVendor.Id,contacts.get(0).Id,UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
        List<UNITY_Service_Contract__c> serviceContracts = UNITY_TestDataFactory.createServiceContracts(1, accountCustomer.Id);
        List<WorkOrder> workOrders = UNITY_TestDataFactory.createWorkOrders(2,cases.get(0).Id,accountCustomer.Id,serviceContracts.get(0).Id,UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE);
        
        Test.startTest();
        proposals = UNITY_TestDataFactory.createQuote(10,cases.get(0).Id,workOrders.get(0).Id,accountCustomer.Id,UserInfo.getUserId());
        
        for(UNITY_Proposal__c subQuotes : proposals) {
            subQuotes.UNITY_Proposal_Status__c = UNITY_Constants.QT_STATUS_AGENT_REVIEW_COMPLETE;
            system.assert(subQuotes.UNITY_Master_Quote__c != NULL);
        }
        
        update proposals;
        
        // pending customer review
        for(UNITY_Proposal__c subQuotes : proposals) {
            subQuotes.UNITY_Proposal_Status__c = UNITY_Constants.QT_STATUS_PENDING_CUSTOMER_REVIEW;
            system.assert(subQuotes.UNITY_Master_Quote__c != NULL);
        }
        
        update proposals;
        
        // approve customer
        UNITY_Proposal__c masterQuote1 = new UNITY_Proposal__c(Id=proposals.get(0).UNITY_Master_Quote__c);
        masterQuote1.UNITY_Proposal_Status__c = UNITY_Constants.QT_STATUS_CUSTOMER_APPROVED;
        masterQuote1.UNITY_Has_Pending_Approval_Sub_Quotes__c = false;
        update masterQuote1;
        
        Test.stopTest(); 
        
        for(UNITY_Proposal__c masterQuote : [SELECT Id,UNITY_Has_Pending_Approval_Sub_Quotes__c,
                                             (
                                              SELECT Id FROM Quotes__r 
                                              WHERE UNITY_Proposal_Status__c =: UNITY_Constants.QT_STATUS_CUSTOMER_APPROVED
                                             )
                                             FROM UNITY_Proposal__c
                                             WHERE
                                             RecordTypeId =: UNITY_Constants.PROPOSAL_MASTER_PROPOSAL_RECORDTYPE AND
                                             Id =: proposals.get(0).UNITY_Master_Quote__c
                                             ]) 
        {
             //System.assert(masterQuote.UNITY_Has_Pending_Approval_Sub_Quotes__c); 
        }
    }
    
    static testMethod void testQuoteDates(){		
        Account accountCustomer = UNITY_TestDataFactory.createAccounts(1,'Site/Location',UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE).get(0);
        Account accountVendor = UNITY_TestDataFactory.createAccounts(1,'Customer',UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE).get(0);
        List<Contact> contacts = UNITY_TestDataFactory.createContacts(1,accountCustomer.Id);
        List<Case> cases = UNITY_TestDataFactory.createCases(1,accountCustomer.Id,accountVendor.Id,contacts.get(0).Id,UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
        List<UNITY_Service_Contract__c> serviceContracts = UNITY_TestDataFactory.createServiceContracts(1, accountCustomer.Id);
        List<WorkOrder> workOrders = UNITY_TestDataFactory.createWorkOrders(1,cases.get(0).Id,accountCustomer.Id,serviceContracts.get(0).Id,UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE);
        
        Test.startTest();
        proposals = UNITY_TestDataFactory.createQuote(1,cases.get(0).Id,workOrders.get(0).Id,accountCustomer.Id,UserInfo.getUserId());
        system.assert(proposals[0].UNITY_Master_Quote__c != NULL);
        
        proposals[0].UNITY_Proposal_Status__c = UNITY_Constants.QT_STATUS_AGENT_REVIEW_COMPLETE;
        update proposals[0];
        
        UNITY_Constants.executionsPerTrigger.put('UNITY_ProposalTriggerHandler',1);
        
		UNITY_Proposal__c masterQuote = [SELECT Id, Quote_Submitted_Date__c, Quote_Approved_Date__c,UNITY_Proposal_Status__c FROM UNITY_Proposal__c 
                                          WHERE Id = :proposals[0].UNITY_Master_Quote__c 
                                          AND RecordTypeId =: UNITY_Constants.PROPOSAL_MASTER_PROPOSAL_RECORDTYPE];
        
        //Submit To Customer
        masterQuote.UNITY_Proposal_Status__c = UNITY_Constants.QT_STATUS_SENT_TO_CUSTOMER;
        update masterQuote;

        masterQuote = [SELECT Id, Quote_Submitted_Date__c FROM UNITY_Proposal__c 
                                          WHERE Id = :proposals[0].UNITY_Master_Quote__c 
                                          AND RecordTypeId =: UNITY_Constants.PROPOSAL_MASTER_PROPOSAL_RECORDTYPE];
        
         
        
        system.assert(masterQuote.Quote_Submitted_Date__c != null);
        
        //Customer approves quote
        masterQuote.UNITY_Proposal_Status__c = UNITY_Constants.QT_STATUS_CUSTOMER_APPROVED;
        update masterQuote;
        
        masterQuote = [SELECT Quote_Approved_Date__c FROM UNITY_Proposal__c WHERE Id = :proposals.get(0).UNITY_Master_Quote__c];
        system.assert(masterQuote.Quote_Approved_Date__c != null);
        Test.stopTest();
    }
}