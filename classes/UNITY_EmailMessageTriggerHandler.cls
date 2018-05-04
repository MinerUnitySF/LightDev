/*
 *   @programer:    Rodrigo Birriel
 *   @description:  email message trigger handler.
 *   @date:         01/05/2016      
 *
 *
 *   @Updates: Raunacq - Code added to accept Proposal/Invoice Accept and Reject from email      
 */


public class UNITY_EmailMessageTriggerHandler extends UNITY_BaseHandler {

    public static final String acceptWord               = 'ACCEPT';
    public static final String rejectWord               = 'REJECT';
    private static final String subjectWORegEx          = '.*Work Order Assigned (WO-\\d{5,}) PIN (\\d{4}).*';
    private static final String subjectQuoteRegEx       = '.*Quote Proposed (QT-\\d{4,}) PIN (\\d{4}).*'; // Proposal Email temaplate subject
    private static final String subjectInvoiceRegEx     = '.*Invoice Proposed (INV-\\d{4,}) PIN (\\d{4}).*'; // Invoice Email temaplate subject
    private static final String bodyCommonRegEx         = '(?i)(?m).*(ACCEPT|REJECT)';
    private static final String bodyQuoteRegEx          = '(?i)(?m).*(ACCEPT|REJECT\\.\\nThe reason is:\\n*(.{0,255}))';

    public override void bulkBefore() {
        acceptOrRejectWorkOrderAssignmentFlow((List<EmailMessage>) Trigger.new);

    }
    
    /*
     * Process the incoming messages filtering for the ones which are incoming as true
     * extracting the concerning WO, PIN and case from 
     * each message.
     */  
    private void acceptOrRejectWorkOrderAssignmentFlow(List<EmailMessage> messages) {
        System.debug('entering messages'+messages);
        // filter by status
        List<EmailMessage> filteredMessages = filteringMessagesByStatus(messages);
        // extracting subject and body stuff
        acceptOrRejectWorkOrderAssigment(extractStuffsInvolved(filteredMessages,subjectWORegEx,bodyCommonRegEx));
        // extracting subject and body stuff
        acceptOrRejectQuoteAssigment(extractStuffsInvolved(filteredMessages,subjectQuoteRegEx,bodyQuoteRegEx));
        // extracting subject and body stuff
        //acceptOrRejectInvoiceAssigment(extractStuffsInvolved(filteredMessages,subjectInvoiceRegEx,bodyCommonRegEx));
    }
    
    /*
     * Accept or reject if the current work order status is Assigned AND Work Order 
     * belongs to the case(associated automatically based on thread ID) and work Order PIN match.
     */  
    private void acceptOrRejectWorkOrderAssigment(Map<String,HitResult> hitResultsMap) {
        List<WorkOrder> workOrders = new List<WorkOrder>();
        for(WorkOrder workOrder : [SELECT Id,WorkOrderNumber, CaseId,UNITY_Vendor_PIN__c FROM WorkOrder 
                                           WHERE WorkOrderNumber IN :hitResultsMap.keySet() 
                                           AND UNITY_Vendor_Status__c =: UNITY_Constants.WO_VENDOR_STATUS_ASSIGNED]) {
            HitResult hitResult = hitResultsMap.get(workOrder.WorkOrderNumber);
            System.debug('workOrder: '+workOrder);                                   
            if(hitResult != null && hitResult.caseId == workOrder.CaseId  && 
                hitResult.pin == workOrder.UNITY_Vendor_PIN__c){
                workOrder.UNITY_Vendor_Status__c = (hitResult.accepted?UNITY_Constants.WO_VENDOR_STATUS_ACCEPTED:UNITY_Constants.WO_VENDOR_STATUS_REJECTED); 
                workOrders.add(workOrder);                                      
            }
        }
        
        // at the end save work order status (accepted|rejected)
        if(!workOrders.isEmpty()) {
            update workOrders;   
        }
    }

    //RCQ - In progress - Start 
    //Quote
    
    private void acceptOrRejectQuoteAssigment(Map<String,HitResult> hitResultsMapQuote) {
        System.debug('>> hitResultsMapQuote: '+ hitResultsMapQuote);
        System.debug('#####Izay PROPOSAL_MASTER_PROPOSAL_RECORDTYPE: '+ UNITY_Constants.PROPOSAL_MASTER_PROPOSAL_RECORDTYPE);
        System.debug('#####Izay QT_STATUS_SENT_TO_CUSTOMER: '+ UNITY_Constants.QT_STATUS_SENT_TO_CUSTOMER);
        Map<Id,UNITY_Proposal__c> masterQuoteIdSubQuoteMap = new Map<Id,UNITY_Proposal__c>();
        List<UNITY_Proposal__c> proposals = new List<UNITY_Proposal__c>();
        for(UNITY_Proposal__c proposal : [SELECT Id,Name, UNITY_Case__c,UNITY_Master_PIN__c,UNITY_Master_Quote__c 
                                          FROM UNITY_Proposal__c 
                                          WHERE Name IN :hitResultsMapQuote.keySet() AND
                                          		RecordTypeId =: UNITY_Constants.PROPOSAL_MASTER_PROPOSAL_RECORDTYPE AND
                                           	 	UNITY_Proposal_Status__c =: UNITY_Constants.QT_STATUS_SENT_TO_CUSTOMER]) {
            HitResult hitResult = hitResultsMapQuote.get(proposal.Name);
            System.debug('Proposal: '+proposal);                                   
            if(hitResult != null && hitResult.caseId == proposal.UNITY_Case__c && 
                hitResult.pin == proposal.UNITY_Master_PIN__c){
                proposal.UNITY_Status__c = (hitResult.accepted?UNITY_Constants.QT_CUSTOMER_STATUS_ACCEPT:UNITY_Constants.QT_CUSTOMER_STATUS_REJECT); 
                proposal.UNITY_Proposal_Status__c = (hitResult.accepted?UNITY_Constants.QT_STATUS_CUSTOMER_APPROVED:UNITY_Constants.QT_STATUS_CUSTOMER_REJECTED);
                if(!hitResult.accepted) {
                    proposal.UNITY_Comments__c = hitResult.reason==null||hitResult.reason == '-- '?'No Reject Reason provided, please contact customer for more details.':hitResult.reason;
                }
                System.debug('Proposal updated:'+proposal);
                proposals.add(proposal);                                      
            }
        }
        
        // at the end save Quote/Proposal customer status (accepted|rejected)
        if(!proposals.isEmpty()) {
            update proposals;   
        }
    }

    
    // Invoice
    /*
    private void acceptOrRejectInvoiceAssigment(Map<String,HitResult> hitResultsMapInvoice) {
        List<UNITY_Invoice__c> invoices = new List<UNITY_Invoice__c>();
        for(UNITY_Invoice__c invoice : [SELECT Id,Name, UNITY_Case__c FROM UNITY_Invoice__c 
                                           WHERE Name IN :hitResultsMapInvoice.keySet() 
                                           AND UNITY_Status__c =: UNITY_Constants.INV_CUSTOMER_STATUS_ACCEPT]) {
            HitResult hitResult = hitResultsMapInvoice.get(invoice.Name);
            System.debug('invoice: '+invoice);                                   
            if(hitResult != null && hitResult.caseId == invoice.UNITY_Case__c ){
                invoice.UNITY_Status__c = (hitResult.accepted?UNITY_Constants.INV_CUSTOMER_STATUS_ACCEPT:UNITY_Constants.INV_CUSTOMER_STATUS_REJECT); 
                invoice.UNITY_Invoice_Status__c = UNITY_Constants.INV_SENT_TO_CUSTOMER;
                invoice.UNITY_Comments__c = hitResult.reason;
                invoices.add(invoice);                                      
            }
        }
        
        // at the end save work order status (accepted|rejected)
        if(!invoices.isEmpty()) {
            update invoices;   
        }
    }
	*/
    // RCQ  - In Progress
    
    
    /*
     * Allow the ones who are incoming.
     */
    private List<EmailMessage> filteringMessagesByStatus(List<EmailMessage> messages) {
        List<EmailMessage> filteredMessages = new List<EmailMessage>();
        // allow the ones who are incoming and with ReplyToEmailMessageId not null
        for(EmailMessage message : messages) {
            if(message.Incoming) {
                filteredMessages.add(message);
            }
        }
        System.debug('entering filteringMessagesByStatus'+filteredMessages);
        return filteredMessages;
    }
    
    /*
     * Extract the matches from the subject and the body from email messages, 
     * returning a list of wo stuffs.
     */
    private Map<String,HitResult> extractStuffsInvolved(List<EmailMessage> messages, String subjectRegex, String bodyRegex) {
        Map<String,HitResult> hitResultsMap = new Map<String,HitResult>();
        Pattern subjectPattern = Pattern.compile(subjectRegex);
        Pattern bodyPattern = Pattern.compile(bodyRegex);
        
        System.debug('>> messages '+messages+' <<');
        system.debug('subjectRegex: '+subjectRegex);
        system.debug('bodyRegex: '+bodyRegex);
        for(EmailMessage message : messages) {
            if(message.Subject != null && message.TextBody != null) {
                Matcher subjectMatcher = subjectPattern.matcher(message.Subject);
                Matcher bodyMatcher = bodyPattern.matcher(message.TextBody.left(300));
                System.debug('>> matching subject'+(subjectMatcher.matches()?'yes':'no')+' <<');
                //System.debug('>> matching body'+(bodyMatcher.find()?'yes':'no')+' <<');
                if(subjectMatcher.matches() && bodyMatcher.find()){
                    
                    HitResult hitResult = new HitResult();
                    System.debug('> subjectMatcher.group(1) '+subjectMatcher.group(1));
                    System.debug('> subjectMatcher.group(2) '+subjectMatcher.group(2));
                    System.debug('> bodyMatcher.group(1) '+bodyMatcher.group(1));
                    hitResult.recordName = subjectMatcher.group(1);
                    hitResult.pin= subjectMatcher.group(2);
                    hitResult.caseId = message.ParentId;
                    hitResult.accepted = bodyMatcher.group(1).toUpperCase() == acceptWord;
                    hitResult.reason = bodyMatcher.groupCount()==2?bodyMatcher.group(2):NULL;
                    hitResultsMap.put(hitResult.recordName,hitResult);  
                }  
            }
        }
        System.debug('entering hitResultsMap'+hitResultsMap);
        return hitResultsMap;
    }
    
    class HitResult {
        public String recordName;
        public String pin;
        public String caseId;
        public Boolean accepted;
        public String reason;
    }
    
}