public without sharing class UNITY_ProposalTriggerHandler extends UNITY_BaseHandler{
    

    public static id standardPriceBookId{get;set;}
    static {
        if(Test.isRunningTest()){
            standardPriceBookId = Test.getStandardPricebookId();
        }else{
            standardPriceBookId = UNITY_Constants.getStandardPriceBookId();
        }
    }

    private Map< id, id> recordIdTemplateId = new Map< id, id>();
    private List<UNITY_Proposal__c> proposalWithTemplate;
    public static Map<string,UNITY_General_Settings__c> generalSettings = UNITY_General_Settings__c.getAll();
    private static Map<Id, Case> relatedCaseMap = new Map<Id, Case>();
    private static Map<Id,UNITY_Service_Contract__c> customerSCMap = new Map<Id,UNITY_Service_Contract__c>();
    private static List<OrderItem> allVendorSupplyPOLIsForCase = new List<OrderItem>();
    private static List<OrderItem> allNonVendorSupplyPOLIsForCase = new List<OrderItem>();
    private static List<Order> allPOsForCase = new List<Order>();
    
    public UNITY_ProposalTriggerHandler(){
        
    }
        
    public override void bulkBefore(){
        
        
        if(trigger.isInsert){
            setRelatedCaseMap();
            UNITY_AutopopulateChildController.autopopulateFieldsIfApplicableBulkified(trigger.new, 'UNITY_Proposal__c');           
            setAllVendorSupplyPOLIsForCase();
            handleQuoteIncludesIncurredChargesAndQuoteItemsOnInsertFlow((List<UNITY_Proposal__c>) trigger.new);
        }
        
        if(trigger.isUpdate){
            setRelatedCaseMap();
            setRelatedCustomerSC();
            setAllVendorSupplyPOLIsForCase();
            setSubmittedAndApprovedDates();
        }
        
    }
    
    public override void bulkAfter(){
        
        if (Trigger.isUpdate || Trigger.isInsert){
            applyTemplates();
        }
        
        System.debug('->>> new quotes :'+trigger.new); 
        System.debug('->>> old quotes :'+trigger.old);
        
        if(Trigger.isUpdate){
            handleQuoteIncludesIncurredChargesAndQuoteItemsOnUpdateFlow(trigger.old,trigger.new);
            
            List<SObject> sobjects = new List<SObject>();
            List<SObject> sobjectsToDelete = new List<SObject>();
            List<Id> parentIds = new List<Id>();
            
            //retrieve the users associated to the contacts
            Map<Id,Id> contactIdUserIdMap = new Map<Id,Id>();
            for(User user : [SELECT Id, ContactId FROM User 
                             WHERE ContactId IN : UNITY_Utils.joiningByFieldList(Trigger.new,'UNITY_Shared_to_Contact__c') OR
                             ContactId IN : UNITY_Utils.joiningByFieldList(Trigger.old,'UNITY_Shared_to_Contact__c') ] ) {
                                 if(user.ContactId != NULL){
                                     contactIdUserIdMap.put(user.ContactId, user.Id);   
                                 }     
                             }
            
            system.debug('>>> contactIdUserIdMap'+contactIdUserIdMap);
            System.debug('>>> new quotes :'+trigger.new);
            System.debug('>>> old quotes :'+trigger.old);
            for(Integer index=0; index<Trigger.new.size(); index++){
                UNITY_Proposal__c proposalNew = (UNITY_Proposal__c)Trigger.new.get(index);
                UNITY_Proposal__c proposalOld = (UNITY_Proposal__c)Trigger.old.get(index);
                if(proposalNew.UNITY_Shared_to_Contact__c != proposalOld.UNITY_Shared_to_Contact__c &&
                   proposalNew.RecordTypeId == UNITY_Constants.PROPOSAL_CUSTOMER_PROPOSAL_RECORDTYPE){
                       if(proposalNew.UNITY_Shared_to_Contact__c != null) {
                           sobjects.add(proposalNew);
                           parentIds.add(contactIdUserIdMap.get(proposalNew.UNITY_Shared_to_Contact__c));
                       }
                       if(proposalOld.UNITY_Shared_to_Contact__c != null) {
                           sobjectsToDelete.add(proposalOld);   
                       }
                   }
            }
            // update the share object when the field UNITY_Shared_to_Contact__c change,
            // deleting the invalid share objects.
            UNITY_SharingUtil.manualShareDelete(sobjectsToDelete,UNITY_Proposal__Share.SObjectType);
            
            System.debug('creating manual sharing'+sobjects+parentIds);
            UNITY_SharingUtil.manualShareCreateReadWriteBulk(sobjects,parentIds,UNITY_Proposal__Share.SObjectType);
            
            //updateCaseNTE(trigger.oldMap, trigger.newMap);
            updateCaseQuoteDates(trigger.oldMap, trigger.newMap);            
        }
    }
    /**Izay: This method upodates the Case NTE once a QUote is Approved
    *@param oldQuoteMap Map<Id,SObject> : The Trigger.oldMap for the quotes 
    *@param newQuoteMap Map<Id,SObject> : The Trigger.newMap for the quotes 
    */
    public void updateCaseNTE(Set<Id> quoteIds){
        
        List<Case> casesToUpdate = new List<Case>();
        List<UNITY_Proposal__c> quotesToUpdateNTE = [SELECT Id, UNITY_Case__c, UNITY_Total_Case_Price__c FROM UNITY_Proposal__c WHERE Id IN: quoteIds];
        for(UNITY_Proposal__c quote: quotesToUpdateNTE){

            if ( quote.UNITY_Case__c==null ) continue;

            Case relatedCase = relatedCaseMap.get(quote.UNITY_Case__c); 
            if (relatedCase != null){
                relatedCase.UNITY_NTE_Threshold__c = quote.UNITY_Total_Case_Price__c;
                casesToUpdate.add( relatedCase );
            }
        }
        
        if (!casesToUpdate.isEmpty()){
            update casesToUpdate;
        }
    }
    /*
    public void updateCaseNTE(Map<Id, SObject> oldQuoteMap, Map<Id, SObject> newQuoteMap){
        
        List<Case> casesToUpdate = new List<Case>();
        
        for(SObject iter: newQuoteMap.values()){
            
            UNITY_Proposal__c newQuote = (UNITY_Proposal__c)iter;
            UNITY_Proposal__c oldQuote = (UNITY_Proposal__c)oldQuoteMap.get(iter.Id);
            
            if (newQuote.UNITY_Proposal_Status__c != oldQuote.UNITY_Proposal_Status__c && newQuote.UNITY_Proposal_Status__c == UNITY_Constants.QT_STATUS_CUSTOMER_APPROVED && newQuote.RecordTypeId == UNITY_Constants.PROPOSAL_MASTER_PROPOSAL_RECORDTYPE ){
                
                Case relatedCase = relatedCaseMap.get(newQuote.UNITY_Case__c); 
                if (relatedCase != null){
                    relatedCase.UNITY_NTE_Threshold__c = newQuote.UNITY_Total_Case_Price__c;
                    casesToUpdate.add(relatedCase);
                }
            }
        }
        
        if (!casesToUpdate.isEmpty()){
            update casesToUpdate;
        }
    }
    */  
    
    public override void beforeInsert(SObject so){
        
        UNITY_Proposal__c currentProposal = (UNITY_Proposal__c)so;
        
        setBusinessUnitAccount(currentProposal);
    }
    
    public override void beforeUpdate(SObject oldSo, SObject so){}
    
    public void applyTemplates(){
            
        for (sObject iter: trigger.new){
                
            UNITY_Proposal__c proposal = (UNITY_Proposal__c)iter;
            
            proposalWithTemplate = new List<UNITY_Proposal__c>();
            
            if( (proposal.RecordTypeId == UNITY_Constants.PROPOSAL_CUSTOMER_PROPOSAL_RECORDTYPE ) && (proposal.UNITY_Template_Configuration__c  != null) ){
                recordIdTemplateId.put(proposal.id, proposal.UNITY_Template_Configuration__c );
                proposalWithTemplate.add(proposal);
            }
        }
        
        UNITY_Utils.applyTemplates(recordIdTemplateId, proposalWithTemplate, 'UNITY_Template_Configuration__c', 'UNITY_Proposal__c');   
    }

    public void setRelatedCaseMap(){
        
        Set<Id> caseIdSet = new Set<Id>();
        
        for (SObject iter: trigger.new){
            caseIdSet.add(((UNITY_Proposal__c)iter).UNITY_Case__c);
        }
        System.debug(LoggingLevel.INFO,'<AK - ProposalTriggerHandler.setRelatedCaseMap> : caseIdSet : '+caseIdSet);
        
        List<Case> caseList = [select id, UNITY_NTE_Threshold__c, UNITY_Business_Unit_Account__c,UNITY_Customer_Service_Contract__c, Quote_Submitted_Date__c, Quote_Approved_Date__c from Case where id in:caseIdSet];
         
        System.debug(LoggingLevel.INFO,'<AK - ProposalTriggerHandler.setRelatedCaseMap> : caseList : '+caseList);

        for (Case iter: caseList){
            relatedCaseMap.put(iter.id, iter);
        }

        System.debug(LoggingLevel.INFO,'<AK - ProposalTriggerHandler.setRelatedCaseMap> : relatedCaseMap : '+relatedCaseMap);

    }
    
    public static void setAllVendorSupplyPOLIsForCase(){
        System.debug(LoggingLevel.INFO,'<AK - ProposalTriggerHandler.setAllVendorSupplyPOLIsForCase> : relatedCaseMap.keySet() : '+relatedCaseMap.keySet());

        Set<String> delimitedInvoiceableStatuses = new Set<String>();
        UNITY_General_Settings__c generalSetting = generalSettings.get(UNITY_Constants.PO_INVOICEABLE_STATUSES);
        String POInvoiceableStatuses;
        if (generalSetting!=null){
            POInvoiceableStatuses = generalSetting.UNITY_Value__c;
        }
        if (POInvoiceableStatuses!=null){
            delimitedInvoiceableStatuses = new Set<String>(POInvoiceableStatuses.split(UNITY_Constants.PO_INVOICEABLE_STATUSES_DELIMITER));
        }

        System.debug(LoggingLevel.INFO,'<AK - ProposalTriggerHandler.setAllVendorSupplyPOLIsForCase> : delimitedInvoiceableStatuses : '+delimitedInvoiceableStatuses);
      
        allVendorSupplyPOLIsForCase = [SELECT Id,orderItemNumber,UNITY_Total_Cost__c, UNITY_Total_Price__c,
                                       UNITY_Discounted_Price__c,UNITY_Sales_Tax__c,OrderId,Order.UNITY_Discount__c
                                       FROM OrderItem 
                                       WHERE OrderItem.Order.FSO__WorkOrder__r.CaseId in :relatedCaseMap.keySet()
                                       AND (OrderItem.Order.RecordTypeId =: UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE 
                                            OR 
                                            OrderItem.Order.RecordTypeId =: UNITY_Constants.PART_SOURCING_PURCHASE_ORDER_RECORDTYPE)
                                       AND OrderItem.Order.Status IN: delimitedInvoiceableStatuses 
                                       AND UNITY_Is_Vendor_Supply__c = true];
      /*
        allNonVendorSupplyPOLIsForCase = [SELECT Id,orderItemNumber,UNITY_Total_Cost__c,UNITY_Total_Price__c,UNITY_Discounted_Price__c,UNITY_Sales_Tax__c
                                          FROM OrderItem 
                                          WHERE OrderItem.Order.FSO__WorkOrder__r.CaseId in :relatedCaseMap.keySet()
                                          AND OrderItem.PriceBookEntry.Product2.Name != 'Vendor Service Fee' 
                                          AND (OrderItem.Order.Status IN: delimitedInvoiceableStatuses)]; 
    */
        allPOsForCase = [SELECT Id,OrderNumber,AccountId,EffectiveDate,UNITY_Sales_Tax__c,UNITY_Discount__c,
                         UNITY_Line_Item_DIscounted_Price__c,UNITY_Final_Price__c,UNITY_Total_Cost__c,
                  (SELECT Id,OrderId,OrderItemNumber,UNITY_Customer_Adjusted_Quantity__c,
                   UNITY_Price__c,UNITY_Type__c,UNITY_Activity_Type__c,UNITY_Discounted_Price__c,UNITY_Total_Price__c,UNITY_Product_Name__c
                   FROM OrderItems WHERE PriceBookEntry.Product2.Name != 'Vendor Service Fee' 
                  ) 
                  FROM Order WHERE FSO__WorkOrder__r.CaseId IN :relatedCaseMap.keySet()
                  AND(RecordTypeId =: UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE 
                      OR 
                      RecordTypeId =: UNITY_Constants.PART_SOURCING_PURCHASE_ORDER_RECORDTYPE)
                  AND Status IN :delimitedInvoiceableStatuses
                  AND FSO__WorkOrder__r.Status != 'Canceled'];
                                        
        System.debug(LoggingLevel.INFO,'<AK - ProposalTriggerHandler.allVendorSupplyPOLIsForCase> : delimitedInvoiceableStatuses : '+allVendorSupplyPOLIsForCase);
          
    }
    
    public void setBusinessUnitAccount(UNITY_Proposal__c proposalRecord){
        if (relatedCaseMap.get(proposalRecord.UNITY_Case__c) != null){
            proposalRecord.UNITY_Business_Unit_Account__c = relatedCaseMap.get(proposalRecord.UNITY_Case__c).UNITY_Business_Unit_Account__c;
        }else{
            proposalRecord.UNITY_Business_Unit_Account__c = null;
        }
    }
    
    public static void setRelatedCustomerSC(){
        
        Set<Id> customerSCIds = new Set<Id>();
        System.debug(LoggingLevel.INFO,'<AK - ProposalTriggerHandler.setRelatedCustomerSC> : relatedCaseMap : '+relatedCaseMap);
        
        for (Id caseId : relatedCaseMap.keySet()){
            customerSCIds.add(relatedCaseMap.get(caseId).UNITY_Customer_Service_Contract__c);
        }
        customerSCMap = new Map<Id,UNITY_Service_Contract__c>([select id, UNITY_Is_Pass_Through__c, (Select id,  UNITY_Threshold_Start__c, UNITY_Threshold_End__c, UNITY_Service_Charge_Percentage__c, UNITY_Service_Charge_Amount__c  from UNITY_Service_Contract_Line_Items__r where RecordTypeId=:UNITY_Constants.SCLI_SERVICE_CHARGE_RECORDTYPE) from UNITY_Service_Contract__c where UNITY_IS_Active__c = true and  UNITY_Service_Contract__c.RecordTypeId =:UNITY_Constants.SC_SERVICE_REQUEST_RECORDTYPE and UNITY_Is_Pass_Through__c = true and Id in :customerSCIds]);
        System.debug(LoggingLevel.INFO,'<AK - ProposalTriggerHandler.setRelatedCustomerSC> : customerSCMap : '+customerSCMap);
        
    }
    
    /*
     * The quote when change its status to Ready oo Send and its UNITY_Customer_Margin__c <= subQuote.UNITY_Quote_Margin__c
     * skip the manager approval, changing its quote status to Pending Customer Review.
     */
    private void handleQuoteSkipManagerApprovalForMarginCondition(UNITY_Proposal__c oldQuote, UNITY_Proposal__c quote) {
        if(quote.RecordTypeId == UNITY_Constants.PROPOSAL_CUSTOMER_PROPOSAL_RECORDTYPE &&
           quote.UNITY_Proposal_Status__c == UNITY_Constants.QT_STATUS_AGENT_REVIEW_COMPLETE &&
           quote.UNITY_Customer_Margin__c <= quote.UNITY_Quote_Margin__c) {
                quote.UNITY_Proposal_Status__c = UNITY_Constants.QT_STATUS_PENDING_CUSTOMER_REVIEW;
        }
    }
    
    /**
     * Quote Includes Incurred Charges and Quoted Items flow.
     * This flow is related to the cases with record type Service Request
     * Create the master quote related to the case if not exists and add the subquotes to the master one
     */ 
    public void handleQuoteIncludesIncurredChargesAndQuoteItemsOnInsertFlow(List<UNITY_Proposal__c> quotes) {
        
        if (!UNITY_Constants.isExecutingContext('masterQuoteLazyCreation')) {
            checkIfExistsMasterQuoteOnCase(quotes);
        }
        addChildrenQuoteWithMaster(quotes);
    }
    
    public void handleQuoteIncludesIncurredChargesAndQuoteItemsOnUpdateFlow(List<UNITY_Proposal__c> oldQuotes, List<UNITY_Proposal__c> quotes) {
        udpateSubQuoteStatusWithMasterQuote(oldQuotes,quotes);
        if(!System.isFuture()){
            System.debug('#####Izay: Calling updateMasterTotalFieldsAndStatusWithSubquote...');
            Set<Id> tempQuotesIds = new Set<Id>();
            for(UNITY_Proposal__c q :quotes){
                if(q.UNITY_Proposal_Status__c != 'Customer Approved'){
                    tempQuotesIds.add(q.Id);
                }
            }
            if(!tempQuotesIds.isEmpty())
                updateMasterTotalFieldsAndStatusWithSubquote( tempQuotesIds );
                //updateMasterTotalFieldsAndStatusWithSubquote(JSON.serialize(tempQuotes));
        }
        updateSubQuotesWithMasterStatus();
        updateMasterWithPendingSubQuotes(quotes);
        createPOAndPOLineItemsPerQuotes(oldQuotes,quotes);
    }
    
    /**
     * Check if exists the master quote related to the case service request, if not
     * create the master under the case, before to insert the sub quotes.
     * then the new quotes are added to the master quote related.
     */ 
    private void checkIfExistsMasterQuoteOnCase(List<UNITY_Proposal__c> quotes) {
        System.debug(LoggingLevel.INFO,'<AK> : quotes : '+quotes);
        Map<Id,UNITY_Proposal__c> caseWithChildQuotes = new Map<Id,UNITY_Proposal__c>();
        for(UNITY_Proposal__c quote : quotes) {
            if(quote.UNITY_Case__c != null) {
                caseWithChildQuotes.put(quote.UNITY_Case__c, quote);
            }
        }
        
        List<UNITY_Proposal__c> masterQuotes = new List<UNITY_Proposal__c>();
        // check if the master record is created at case level, if not create with the first sub quote
        // and assign agent and customer email to master quote.
        for(Case currentCase : [SELECT Id, (SELECT Id FROM Proposals__r 
                                            WHERE RecordTypeId =: UNITY_Constants.PROPOSAL_MASTER_PROPOSAL_RECORDTYPE) 
                                FROM Case 
                                WHERE   Id IN : UNITY_Utils.joiningByFieldList(quotes, 'UNITY_Case__c')]){
                                    if(currentCase.Proposals__r.isEmpty()) {
                                        UNITY_Proposal__c subQuote = caseWithChildQuotes.get(currentCase.Id);
                                        UNITY_Proposal__c masterQuote = new UNITY_Proposal__c();
                                        masterQuote.RecordTypeId = UNITY_Constants.PROPOSAL_MASTER_PROPOSAL_RECORDTYPE;
                                        masterQuote.UNITY_Case__c = currentCase.Id;
                                        if(subQuote!=null) {
                                            masterQuote.UNITY_Agent__c = subQuote.UNITY_Agent__c;
                                            masterQuote.UNITY_Customer_Email__c = subQuote.UNITY_Customer_Email__c;
                                            masterQuote.UNITY_Customer__c = subQuote.UNITY_Customer__c;
                                        }
                                        masterQuote.UNITY_Proposal_Status__c = 'Draft';
                                        masterQuotes.add(masterQuote);
                                    }
                                }
        
         if(!masterQuotes.isEmpty()){
            insert masterQuotes;
        }
    }
    
    
    /**
     * Add the children quote with master quote related to the case.
     */
    private void addChildrenQuoteWithMaster(List<UNITY_Proposal__c> quotes) {
        
        List<UNITY_Proposal__c> subQuotes = new List<UNITY_Proposal__c>();
        Map<Id,List<UNITY_Proposal__c>> caseWithChildQuotes = new Map<Id,List<UNITY_Proposal__c>> ();
        //keep the new sub quotes related to the case to be enqueue the master quote related.
        for(UNITY_Proposal__c quote : quotes) {
            if(quote.UNITY_Case__c != NULL && quote.RecordTypeId == UNITY_Constants.PROPOSAL_CUSTOMER_PROPOSAL_RECORDTYPE ) {
                if(caseWithChildQuotes.get(quote.UNITY_Case__c) == null) {
                    caseWithChildQuotes.put(quote.UNITY_Case__c,new List<UNITY_Proposal__c>());
                }  
                caseWithChildQuotes.get(quote.UNITY_Case__c).add(quote);
                subQuotes.add(quote);
            }
        }
        
                
        List<UNITY_Proposal__c> masterQuotes = new List<UNITY_Proposal__c>();
        
        // for each new subquote associated the UNITY_Master_Quote__c field with the masterQuote associated to the case
        for(UNITY_Proposal__c masterQuote : [SELECT Id,UNITY_Case__c FROM UNITY_Proposal__c
                                             WHERE UNITY_Case__c IN : UNITY_Utils.joiningByFieldList(subQuotes, 'UNITY_Case__c') AND
                                                   RecordTypeId =: UNITY_Constants.PROPOSAL_MASTER_PROPOSAL_RECORDTYPE]) {
            if(!caseWithChildQuotes.get(masterQuote.UNITY_Case__c).isEmpty()) {
                masterQuote.UNITY_Proposal_Status__c = 'Draft';
                masterQuotes.add(masterQuote);
                for(UNITY_Proposal__c subQuote : caseWithChildQuotes.get(masterQuote.UNITY_Case__c)) {
                    subQuote.UNITY_Master_Quote__c = masterQuote.Id;
                    masterQuote.UNITY_Business_Unit_Account__c = subQuote.UNITY_Business_Unit_Account__c;
                    masterQuote.UNITY_Business_Unit__c = subQuote.UNITY_Business_Unit__c; 
                    masterQuote.UNITY_Effective_Till_Date__c = subQuote.UNITY_Effective_Till_Date__c;
                    masterQuote.UNITY_Account__c = subQuote.UNITY_Account__c;
                    masterQuote.UNITY_Customer_Email__c = subQuote.UNITY_Customer_Email__c;
                    masterQuote.UNITY_Comments__c = subQuote.UNITY_Comments__c;
                    masterQuote.UNITY_Customer_Margin__c = subQuote.UNITY_Customer_Margin__c;
                    masterQuote.UNITY_Master_PIN__c = subQuote.UNITY_Customer_PIN__c;
                }  
            }                                           
            
        }
        
        update masterQuotes;

    }
    
    /**
     * When the master quote status changed the sub quotes associated should be updated too
     */ 
    private List<UNITY_Proposal__c> udpateSubQuoteStatusWithMasterQuote(List<UNITY_Proposal__c> oldQuotes, List<UNITY_Proposal__c> quotes) {
        Map<Id,UNITY_Proposal__c> masterQuoteWithStatusChangedMap = new Map<Id,UNITY_Proposal__c>();
        List<UNITY_Proposal__c> subquoteWithStatusChanged = new List<UNITY_Proposal__c>();
        List<UNITY_Proposal__c> subquotesNotAffected = new List<UNITY_Proposal__c>();
        UNITY_Proposal__c oldQuote,quote;
        for(Integer i=0;i<oldQuotes.size();i++) {
            oldQuote = oldQuotes.get(i);
            quote = quotes.get(i);
            if( quote.RecordTypeId == UNITY_Constants.PROPOSAL_MASTER_PROPOSAL_RECORDTYPE && 
               oldQuote.UNITY_Has_Pending_Approval_Sub_Quotes__c  != quote.UNITY_Has_Pending_Approval_Sub_Quotes__c) {
               masterQuoteWithStatusChangedMap.put(quote.Id, quote);
            } else {
                subquotesNotAffected.add(quote);
            }
        }
        System.debug(' >>> masterQuoteWithStatusChangedMap: '+masterQuoteWithStatusChangedMap);
        if(!masterQuoteWithStatusChangedMap.keySet().isEmpty()) {
            for(UNITY_Proposal__c subQuote : [SELECT Id,UNITY_Proposal_Status__c ,UNITY_Master_Quote__c, UNITY_Master_Quote__r.UNITY_Proposal_Status__c, UNITY_Comments__c
                                          FROM UNITY_Proposal__c
                                          WHERE UNITY_Master_Quote__c IN : masterQuoteWithStatusChangedMap.keySet() AND
                                          UNITY_Proposal_Status__c =: UNITY_Constants.QT_STATUS_AGENT_REVIEW_COMPLETE AND
                                          UNITY_Master_Quote__r.UNITY_Proposal_Status__c != 'Draft'] ) {
            if(subQuote.UNITY_Master_Quote__r.UNITY_Proposal_Status__c == UNITY_Constants.QT_STATUS_QUOTE_FINALIZED){
                //subQuote.UNITY_Proposal_Status__c = UNITY_Constants.QT_STATUS_PENDING_CUSTOMER_REVIEW;
                //subquoteWithStatusChanged.add(subQuote);
            } else {
                subQuote.UNITY_Proposal_Status__c = masterQuoteWithStatusChangedMap.get(subQuote.UNITY_Master_Quote__c).UNITY_Proposal_Status__c ;
                subquoteWithStatusChanged.add(subQuote);
            }                           
            // reset the master quote status to draft
            //masterQuoteWithStatusChangedMap.get(subQuote.UNITY_Master_Quote__c).UNITY_Proposal_Status__c = 'Draft';
        }
        System.debug(' >>> subquoteWithStatusChanged: '+subquoteWithStatusChanged);    
        
        update subquoteWithStatusChanged;
        }
        
        return subquotesNotAffected;
    }
      
    /*
     * Update the totals for master for subquotes related.
     * ****************************************
     * Calcualtes Service Charge on Quote *****
     * ****************************************
     */
    @Future(callout=true)
    //public static void updateMasterTotalFieldsAndStatusWithSubquote(String quotesString) {
    public static void updateMasterTotalFieldsAndStatusWithSubquote(Set<Id> quotesToUpdate) {
        UNITY_Constants.isExecutingContext('updateMasterTotalFieldsAndStatusWithSubquote');
        System.debug('#####Izay: In updateMasterTotalFieldsAndStatusWithSubquote...');
        //retrieve all sub quotes related to master types on the concerning quotes, excluding the one with status cancelled
        //to update the fields on the master quote related.
        //List<UNITY_Proposal__c> quotes = (List<UNITY_Proposal__c>)JSON.deserialize(quotesString,List<UNITY_Proposal__c>.class);
        List<UNITY_Proposal__c> quotes = [SELECT Id, UNITY_Case__c,UNITY_Master_Quote__c FROM UNITY_Proposal__c WHERE Id IN: quotesToUpdate];
        List<UNITY_Proposal__c> quotesUpdated = new List<UNITY_Proposal__c>();
        Set<Id> cids = new Set<Id>();
        for (UNITY_Proposal__c q :quotes){
            cids.add(q.UNITY_Case__c);
        }
        relatedCaseMap = new Map<Id,Case>([SELECT id, UNITY_NTE_Threshold__c, UNITY_Business_Unit_Account__c,UNITY_Customer_Service_Contract__c FROM Case WHERE Id IN:cids]);
        setRelatedCustomerSC();
        setAllVendorSupplyPOLIsForCase();
        Decimal totalCost = 0;
        Decimal totalPrice = 0;
        Decimal totalAdjustments = 0;
        Decimal totalSalesTax = 0;
        Decimal totalIncCharge = 0;
        Decimal totalIncTax = 0;
        Decimal totalIncCost = 0;
        Decimal discountedSC = 0;
        
        Decimal totalFinalPriceWithDiscounts = 0;
        
        Decimal totalVendorSuppliedFinalPrice = 0;
        Decimal totalVendSupFinalPriceWithDis = 0;
        
        Set<Id> changedSCIds = new Set<Id>();
        
        List<String> notConcerningStates = new List<String>{UNITY_Constants.QT_STATUS_CANCELLED,
            UNITY_Constants.QT_STATUS_MANAGER_REJECTED,
            UNITY_Constants.QT_STATUS_CUSTOMER_REJECTED,
            UNITY_Constants.QT_STATUS_CUSTOMER_APPROVED,
            UNITY_Constants.QT_STATUS_COMPLETED};
                for(UNITY_Proposal__c masterQuote : [SELECT Id,UNITY_Master_Quote_Total_Cost__c, UNITY_Master_Quote_Final_Price__c, UNITY_Master_Quote_Total_Price__c,
                                                     UNITY_Proposal_Status__c, UNITY_Status__c, RecordTypeId,UNITY_Case__c,UNITY_Comments__c,UNITY_Total_Adjustments__c,
                                                     UNITY_Total_Estimated_Sales_Tax__c,UNITY_Estimated_Incurred_Sales_Tax__c,UNITY_Incurred_Charges__c,
                                                     UNITY_Case__r.AccountId,UNITY_Case__r.UNITY_Customer__c,UNITY_Case__r.UNITY_Business_Unit_Account__c,
                                                     (
                                                         SELECT Id,UNITY_Total_Cost__c,UNITY_Total_Price__c , UNITY_Total_Vendor_Supplied_Final_Price__c, 
                                                         UNITY_Total_Price_with_Service_Charge__c, UNITY_Final_Price__c,UNITY_Estimated_Sales_Tax__c,
                                                         UNITY_Proposal_Status__c, UNITY_Status__c,UNITY_Total_Vendor_Supplied_Dis_Price__c,UNITY_Final_Price2__c
                                                         FROM Quotes__r 
                                                         WHERE NOT(UNITY_Proposal_Status__c IN : notConcerningStates) 
                                                     )
                                                     FROM UNITY_Proposal__c
                                                     WHERE RecordTypeId =: UNITY_Constants.PROPOSAL_MASTER_PROPOSAL_RECORDTYPE 
                                                     AND
                                                     (
                                                         Id IN: UNITY_Utils.joiningByFieldList(quotes,'UNITY_Master_Quote__c') OR
                                                         Id IN: UNITY_Utils.joiningByIdList(quotes)
                                                     )
                                                     AND UNITY_Proposal_Status__c != :UNITY_Constants.QT_CUSTOMER_STATUS_ACCEPT]) {
                                                         for(UNITY_Proposal__c subQuote : masterQuote.Quotes__r) {
                                                             Decimal cost = subQuote.UNITY_Total_Cost__c != null?subQuote.UNITY_Total_Cost__c : 0;
                                                             Decimal price = subQuote.UNITY_Total_Price__c != null?subQuote.UNITY_Total_Price__c : 0;
                                                             Decimal tax = subQuote.UNITY_Estimated_Sales_Tax__c != null ? subQuote.UNITY_Estimated_Sales_Tax__c : 0;
                                                             Decimal fprice = subQuote.UNITY_Final_Price2__c != null ? subQuote.UNITY_Final_Price2__c : 0;
                                                             
                                                             totalCost += cost;
                                                             totalPrice += price;
                                                             totalSalesTax += tax;
                                                             totalAdjustments += (price - fprice);
                                                             
                                                             totalFinalPriceWithDiscounts += subQuote.UNITY_Final_Price__c == null?0:subQuote.UNITY_Final_Price__c;
                                                             totalVendorSuppliedFinalPrice += subQuote.UNITY_Total_Vendor_Supplied_Dis_Price__c == null?0:subQuote.UNITY_Total_Vendor_Supplied_Dis_Price__c;
                                                             totalVendSupFinalPriceWithDis += subQuote.UNITY_Total_Vendor_Supplied_Final_Price__c == null?0:subQuote.UNITY_Total_Vendor_Supplied_Final_Price__c;
                                                             // update the subquote status if master is 'Customer Approved', 'Customer Rejected' or 'Rejected By Manager'
                                                             /*
                                                            if(masterQuote.UNITY_Proposal_Status__c == UNITY_Constants.QT_STATUS_MANAGER_REJECTED ||
                                                            ((masterQuote.UNITY_Proposal_Status__c == UNITY_Constants.QT_STATUS_CUSTOMER_APPROVED ||
                                                                masterQuote.UNITY_Proposal_Status__c == UNITY_Constants.QT_STATUS_CUSTOMER_REJECTED) &&
                                                                subQuote.UNITY_Proposal_Status__c == UNITY_Constants.QT_STATUS_PENDING_CUSTOMER_REVIEW)){
                                                                if(subQuote.UNITY_Proposal_Status__c == UNITY_Constants.QT_STATUS_PENDING_CUSTOMER_REVIEW && String.isNotBlank(masterQuote.UNITY_Status__c)){
                                                                    subQuote.UNITY_Status__c = masterQuote.UNITY_Status__c;
                                                                    subQuote.UNITY_Comments__c = masterQuote.UNITY_Comments__c;
                                                                }
                                                                subQuote.UNITY_Proposal_Status__c = masterQuote.UNITY_Proposal_Status__c;
                                                                quotesUpdated.add(subQuote);
                                                            }
                                                            */
                                                         }
                                                         
                                                         System.debug(LoggingLevel.INFO,'<AK - ProposalTriggerHandler.updateMasterTotalFieldsAndStatusWithSubquote> : totalVendorSuppliedFinalPrice - before : '+totalVendorSuppliedFinalPrice);
                                                         System.debug(LoggingLevel.INFO,'<AK - ProposalTriggerHandler.updateMasterTotalFieldsAndStatusWithSubquote> : allVendorSupplyPOLIsForCase : '+allVendorSupplyPOLIsForCase);
                                                         
                                                         if(allVendorSupplyPOLIsForCase!=null){
                                                             for(OrderItem iter : allVendorSupplyPOLIsForCase){
                                                                 Decimal tempLine = iter.UNITY_Discounted_Price__c == null?0:iter.UNITY_Discounted_Price__c;
                                                                 totalVendorSuppliedFinalPrice += tempLine;
                                                                 if(iter.Order.UNITY_Discount__c != null && iter.Order.UNITY_Discount__c > 0){
                                                                     tempLine = (tempLine - (tempLine*(iter.Order.UNITY_Discount__c/100)));
                                                                 }
                                                                 totalVendSupFinalPriceWithDis += tempLine;
                                                             }
                                                         }
                                                         
                                                         System.debug('#allNonVendorSupplyPOLIsForCase '+allNonVendorSupplyPOLIsForCase);
                                                         
                                                         if(allPOsForCase != null){
                                                             for(Order po : allPOsForCase){
                                                                 Decimal temp = (po.UNITY_Final_Price__c != null) ? po.UNITY_Final_Price__c : po.UNITY_Line_Item_DIscounted_Price__c;
                                                                 totalIncCharge += temp;
                                                                 totalIncTax += po.UNITY_Sales_Tax__c != null ? po.UNITY_Sales_Tax__c : 0;
                                                                 totalIncCost += po.UNITY_Total_Cost__c != null ? po.UNITY_Total_Cost__c : 0;
                                                             }
                                                         }
                                                         
                                                         System.debug(LoggingLevel.INFO,'<AK - ProposalTriggerHandler.updateMasterTotalFieldsAndStatusWithSubquote> : totalVendorSuppliedFinalPrice - after : '+totalVendorSuppliedFinalPrice);
                                                         
                                                         //masterQuote.UNITY_Incurred_Charges__c = totalVendorSuppliedFinalPrice;
                                                         System.debug('###Izay: totalCost: ' + totalCost);
                                                         System.debug('###Izay: totalPrice: ' + totalPrice);
                                                         System.debug('###Izay: totalSalesTax: ' + totalSalesTax);
                                                         System.debug('###Izay: totalAdjustments: ' + totalAdjustments);
                                                         System.debug('###Izay: totalIncCharge: ' + totalIncCharge);
                                                         System.debug('###Izay: totalIncTax: ' + totalIncTax);
                                                         System.debug('###Izay: totalIncCost: ' + totalIncCost);
                                                         
                                                         System.debug('###Izay: totalFinalPriceWithDiscounts: ' + totalFinalPriceWithDiscounts);
                                                         
                                                         System.debug(LoggingLevel.INFO,'<AK - ProposalTriggerHandler.updateMasterTotalFieldsAndStatusWithSubquote> : masterQuote : '+masterQuote);
                                                         UNITY_Service_Contract__c customerSC;
                                                         
                                                         System.debug(LoggingLevel.INFO,'<AK - ProposalTriggerHandler.updateMasterTotalFieldsAndStatusWithSubquote> : masterQuote.UNITY_Case__c : '+masterQuote.UNITY_Case__c);
                                                         System.debug(LoggingLevel.INFO,'<AK - ProposalTriggerHandler.updateMasterTotalFieldsAndStatusWithSubquote> : relatedCaseMap : '+relatedCaseMap);
                                                         
                                                         if(masterQuote.UNITY_Case__c!=null && relatedCaseMap.get(masterQuote.UNITY_Case__c)!=null){
                                                             customerSC = customerSCMap.get(relatedCaseMap.get(masterQuote.UNITY_Case__c).UNITY_Customer_Service_Contract__c);
                                                         }
                                                         System.debug(LoggingLevel.INFO,'<AK - ProposalTriggerHandler.updateMasterTotalFieldsAndStatusWithSubquote> : customerSC : '+customerSC);
                                                         
                                                         if(customerSC != null){
                                                             
                                                             for (UNITY_Service_Contract_Line_Item__c scli: customerSC.UNITY_Service_Contract_Line_Items__r){
                                                                 if(totalVendorSuppliedFinalPrice >= scli.UNITY_Threshold_Start__c && (scli.UNITY_Threshold_End__c == null || totalVendorSuppliedFinalPrice <= scli.UNITY_Threshold_End__c)){
                                                                     
                                                                     Decimal serviceChargePercentage = 0;
                                                                     Decimal serviceChargeAmount = 0;
                                                                     
                                                                     if(scli.UNITY_Service_Charge_Percentage__c!=null){
                                                                         serviceChargePercentage = scli.UNITY_Service_Charge_Percentage__c;
                                                                     }
                                                                     if(scli.UNITY_Service_Charge_Amount__c!=null){
                                                                         serviceChargeAmount = scli.UNITY_Service_Charge_Amount__c;
                                                                     }
                                                                     if((totalVendorSuppliedFinalPrice * (serviceChargePercentage/100)) >= serviceChargeAmount){
                                                                         System.debug('###Izay: Setting SC on Master: ' + masterQuote.Id);
                                                                         masterQuote.UNITY_Service_Charge__c = totalVendorSuppliedFinalPrice * (serviceChargePercentage/100); 
                                                                     }else if((totalVendorSuppliedFinalPrice * (serviceChargePercentage/100)) < serviceChargeAmount){
                                                                         System.debug('###Izay: Setting SC on Master: ' + masterQuote.Id);
                                                                         masterQuote.UNITY_Service_Charge__c = serviceChargeAmount; 
                                                                     }
                                                                     System.debug('###Izay: SC on Master: ' + masterQuote.UNITY_Service_Charge__c);
                                                                     System.debug('###Izay: totalVendorSuppliedFinalPrice: ' + totalVendorSuppliedFinalPrice);
                                                                     System.debug('###Izay: totalVendSupFinalPriceWithDis: ' + totalVendSupFinalPriceWithDis);
                                                                     Decimal scDiscPer = (totalVendSupFinalPriceWithDis/totalVendorSuppliedFinalPrice).setScale(2,System.RoundingMode.HALF_DOWN);
                                                                     
                                                                     System.debug('###Izay: scDiscPer: ' + scDiscPer);
                                                                     if(masterQuote.UNITY_Service_Charge__c != null && masterQuote.UNITY_Service_Charge__c > 0){
                                                                         discountedSC = (masterQuote.UNITY_Service_Charge__c * scDiscPer).setScale(2,System.RoundingMode.HALF_DOWN);
                                                                     }
                                                                     System.debug('###Izay: discountedSC: ' + discountedSC);
                                                                     totalAdjustments += masterQuote.UNITY_Service_Charge__c - discountedSC;
                                                                     break;
                                                                 }
                                                             }
                                                             
                                                             if(discountedSC > 0){
                                                                 UNITY_CallAvatax.AvataxResult result = 
                                                                     UNITY_CallAvatax.getServiceChargeTax(masterQuote.UNITY_Case__r.AccountId,masterQuote.UNITY_Case__r.UNITY_Business_Unit_Account__c,masterQuote.UNITY_Case__r.UNITY_Customer__c,discountedSC);
                                                                 if(result.success){
                                                                     System.debug('###Izay: ServiceChargeTax result: ' + JSON.serializePretty(result));
                                                                     System.debug('###Izay: ServiceChargeTax: ' + result.totalTax);
                                                                     masterQuote.UNITY_Service_Charge_Tax__c = result.totalTax;
                                                                 }
                                                             }
                                                         }
                                                         masterQuote.UNITY_Master_Quote_Total_Cost__c = totalCost;
                                                         masterQuote.UNITY_Master_Quote_Total_Price__c = totalPrice;
                                                         masterQuote.UNITY_Total_Adjustments__c = (totalAdjustments*-1);
                                                         masterQuote.UNITY_Total_Estimated_Sales_Tax__c = totalSalesTax;
                                                         masterQuote.UNITY_Discounted_Service_Charge__c = discountedSC;
                                                         masterQuote.UNITY_Incurred_Charges__c = totalIncCharge;
                                                         masterQuote.UNITY_Incurred_Cost__c = totalIncCost;
                                                         masterQuote.UNITY_Estimated_Incurred_Sales_Tax__c = totalIncTax;
                                                         
                                                         masterQuote.UNITY_Master_Quote_Final_Price__c = totalFinalPriceWithDiscounts;
                                                         quotesUpdated.add(masterQuote);                                  
                                                    }
        System.debug('#####Izay: quotesUpdated: ' + quotesUpdated);
        
        update quotesUpdated;
            
    }
    
    /**
     * Check quotes which are sub quotes if the status in Ready to Send then update its master quote field
     * UNITY_Has_Pending_Approval_Sub_Quotes__c to true, otherwise nothing.
     */
    private void updateMasterWithPendingSubQuotes(List<UNITY_Proposal__c> quotes) {
        
        Set<UNITY_Proposal__c> masterQuoteCandidateForFinalized = new Set<UNITY_Proposal__c>();
        Set<UNITY_Proposal__c> masterQuotes = new Set<UNITY_Proposal__c>();
        
        //retrieve the master quote which sub quotes with status Ready to Send and
        //customer margin is greater than quote margin to manager approval
        for(UNITY_Proposal__c masterQuote : [SELECT Id,UNITY_Has_Pending_Approval_Sub_Quotes__c,UNITY_Proposal_Status__c,
                                             (
                                              SELECT Id,UNITY_Customer_Margin__c,UNITY_Quote_Margin__c FROM Quotes__r 
                                              WHERE UNITY_Proposal_Status__c =: UNITY_Constants.QT_STATUS_AGENT_REVIEW_COMPLETE 
                                             )
                                             FROM UNITY_Proposal__c
                                             WHERE UNITY_Has_Pending_Approval_Sub_Quotes__c = false AND
                                             RecordTypeId =: UNITY_Constants.PROPOSAL_MASTER_PROPOSAL_RECORDTYPE AND
                                             Id IN: UNITY_Utils.joiningByFieldList(quotes,'UNITY_Master_Quote__c')
                                             ]) {
            for(UNITY_Proposal__c subQuote : masterQuote.Quotes__r) {
                if(subQuote.UNITY_Customer_Margin__c > subQuote.UNITY_Quote_Margin__c && 
                   masterQuote.UNITY_Proposal_Status__c != UNITY_Constants.QT_STATUS_QUOTE_FINALIZED && 
                   masterQuote.UNITY_Proposal_Status__c != UNITY_Constants.QT_STATUS_PENDING_MANAGER_APPROVAL && 
                   masterQuote.UNITY_Proposal_Status__c != UNITY_Constants.QT_STATUS_CUSTOMER_APPROVED && 
                   masterQuote.UNITY_Proposal_Status__c != UNITY_Constants.QT_STATUS_CUSTOMER_REJECTED){
                      masterQuote.UNITY_Has_Pending_Approval_Sub_Quotes__c = true;
                    //masterQuotes.add(masterQuote);
                //} else {
                      masterQuoteCandidateForFinalized.add(masterQuote);
                }else if(masterQuote.UNITY_Proposal_Status__c != UNITY_Constants.QT_STATUS_QUOTE_FINALIZED && 
                         masterQuote.UNITY_Proposal_Status__c != UNITY_Constants.QT_STATUS_PENDING_MANAGER_APPROVAL && 
                         masterQuote.UNITY_Proposal_Status__c != UNITY_Constants.QT_STATUS_CUSTOMER_APPROVED && 
                         masterQuote.UNITY_Proposal_Status__c != UNITY_Constants.QT_STATUS_CUSTOMER_REJECTED){
                             masterQuoteCandidateForFinalized.add(masterQuote);
                }
            }
        }
        // remove the master quote involve in a approval process
        //Izay: Commented out to move auto submit for approval  to PB
        //masterQuoteCandidateForFinalized.removeAll(masterQuotes);
        
        //update the status to finalized for the master quote candidate not affected for a margin condition
        for(UNITY_Proposal__c masterQuote : masterQuoteCandidateForFinalized) {
            masterQuote.UNITY_Proposal_Status__c = UNITY_Constants.QT_STATUS_QUOTE_FINALIZED;
        }
        
        if(!masterQuoteCandidateForFinalized.isEmpty()) {
            update new List<UNITY_Proposal__c>(masterQuoteCandidateForFinalized);   
        }
        //Izay: Commented out to move auto submit for approval  to PB
        /*
        if(!masterQuotes.isEmpty()) {
            update new List<UNITY_Proposal__c>(masterQuotes);
            system.debug('creating approval request for :'+masterQuotes);
            // create approval request for the master quotes
            for(UNITY_Proposal__c masterQuote : masterQuotes) {
                Approval.ProcessSubmitRequest masterQuoteRequest = 
                new Approval.ProcessSubmitRequest();
                masterQuoteRequest.setObjectId(masterQuote.id);
                
                // Submit the approval request for the master quote
                Approval.process(masterQuoteRequest);   
            }
        }
        */
    }
    private void updateSubQuotesWithMasterStatus(){
        if(Trigger.isUpdate){
            //////////////////////////////////////////////////////////////////
            ///////////// Check if the Master Quote was Accepted /////////////
            //////////////////////////////////////////////////////////////////
            String masterRT = UNITY_Constants.PROPOSAL_MASTER_PROPOSAL_RECORDTYPE;
            //Izay: Updated to include Sent to Customer Status
            String sent = UNITY_Constants.QT_STATUS_SENT_TO_CUSTOMER;
            String approved = UNITY_Constants.QT_STATUS_CUSTOMER_APPROVED;
            String rejected = UNITY_Constants.QT_STATUS_CUSTOMER_REJECTED;
            String managerRejected = UNITY_Constants.QT_STATUS_MANAGER_REJECTED;
            Set<Id> sentMasterQuotes = new Set<Id>();
            Set<Id> acceptedMasterQuotes = new Set<Id>();
            Set<Id> rejectedMasterQuotes = new Set<Id>();
            Set<Id> managerRejectedMasterQuotes = new Set<Id>();
            List<UNITY_Proposal__c> subQuotes = new List<UNITY_proposal__c>();
            for(SObject o :Trigger.new){
                UNITY_Proposal__c q = (UNITY_Proposal__c)o;
                UNITY_Proposal__c oldQ = (UNITY_Proposal__c)Trigger.oldMap.get(q.Id);
                if(q.RecordTypeId == masterRT && q.UNITY_Proposal_Status__c != oldQ.UNITY_Proposal_Status__c){
                    if(q.UNITY_Proposal_Status__c == sent)
                      sentMasterQuotes.add(q.Id);
                    if(q.UNITY_Proposal_Status__c == approved)
                       acceptedMasterQuotes.add(q.Id);
                    if(q.UNITY_Proposal_Status__c == rejected)
                       rejectedMasterQuotes.add(q.Id);
                    if(q.UNITY_Proposal_Status__c == managerRejected)
                       managerRejectedMasterQuotes.add(q.Id);
                }
            }
            if(!acceptedMasterQuotes.isEmpty() || !sentMasterQuotes.isEmpty() || !rejectedMasterQuotes.isEmpty() || !managerRejectedMasterQuotes.isEmpty()){
                String agentRevComp = UNITY_Constants.QT_STATUS_AGENT_REVIEW_COMPLETE;
                String pendingCust = UNITY_Constants.QT_STATUS_PENDING_CUSTOMER_REVIEW;
                String pendingManager = UNITY_Constants.QT_STATUS_PENDING_MANAGER_APPROVAL;
                subQuotes = [SELECT Id,UNITY_Proposal_Status__c,UNITY_Master_Quote__c FROM UNITY_Proposal__c 
                             WHERE (
                                 UNITY_Master_Quote__c IN :acceptedMasterQuotes 
                                 OR UNITY_Master_Quote__c IN :rejectedMasterQuotes
                                 OR UNITY_Master_Quote__c IN :managerRejectedMasterQuotes
                                 OR UNITY_Master_Quote__c IN :sentMasterQuotes
                             )
                             AND (
                                 UNITY_Proposal_Status__c = :pendingCust 
                                 OR UNITY_Proposal_Status__c = :pendingManager
                                 OR UNITY_Proposal_Status__c = :agentRevComp
                             )];
                for(UNITY_Proposal__c q :subQuotes){
                    if(sentMasterQuotes.contains(q.UNITY_Master_Quote__c) && q.UNITY_Proposal_Status__c == agentRevComp)
                        q.UNITY_Proposal_Status__c = pendingCust;
                    else if(rejectedMasterQuotes.contains(q.UNITY_Master_Quote__c) && q.UNITY_Proposal_Status__c == pendingCust)
                        q.UNITY_Proposal_Status__c = rejected;
                    else if(acceptedMasterQuotes.contains(q.UNITY_Master_Quote__c) && q.UNITY_Proposal_Status__c == pendingCust)
                        q.UNITY_Proposal_Status__c = approved;
                    else if(managerRejectedMasterQuotes.contains(q.UNITY_Master_Quote__c) && q.UNITY_Proposal_Status__c == pendingManager)
                        q.UNITY_Proposal_Status__c = managerRejected;
                }
                System.debug('#####Izay: sub quotes to update with new status = ' + JSON.serializePretty(subQuotes));
                update subQuotes;
            }
        }
    }
    /**
     * Given the quotes approved by the customer,
     * vendor is saying we need to do more work
     * so we create a new PO
     * with labor and travel (assuming quote is not needed/under NTE)
     * and if its vendor supply part
     * we add that line item as well
     */ 
    private void createPOAndPOLineItemsPerQuotes(List<UNITY_Proposal__c> oldQuotes, List<UNITY_Proposal__c> quotes) {
        System.debug('#####Izay: IN CreatePOAndPOLineItemsPerQuotes...');
        List<UNITY_Proposal__c> quotesWithCustomerAccepted = new List<UNITY_Proposal__c>();
        Set<Id> urIds = new Set<Id>();
        Set<Id> quoteIds = new Set<Id>();
        for(Integer i=0; i<quotes.size(); i++) {
            UNITY_Proposal__c quote = quotes.get(i);
            UNITY_Proposal__c oldQuote = oldQuotes.get(i);
            if(quote.RecordTypeId == UNITY_Constants.PROPOSAL_CUSTOMER_PROPOSAL_RECORDTYPE &&
               oldQuote.UNITY_Proposal_Status__c != UNITY_Constants.QT_STATUS_CUSTOMER_APPROVED &&
               quote.UNITY_Proposal_Status__c == UNITY_Constants.QT_STATUS_CUSTOMER_APPROVED) {
                   quotesWithCustomerAccepted.add(quote);
                   urIds.add(quote.UNITY_Originating_Usage_Request__c);
                   quoteIds.add(quote.UNITY_Master_Quote__c);
            }
        }
        System.debug(' >>> qquotesWithCustomerAccepted: '+quotesWithCustomerAccepted);
        System.debug(' >>> quotes: '+quotes);
        //If quote(s) were Accepted by Customer...
        if(!quotesWithCustomerAccepted.isEmpty()) {
            System.debug('#####Izay: quotesWithCustomerAccepted = ' + JSON.serializePretty(quotesWithCustomerAccepted));
            Map<String,String> result = UNITY_ProposalTriggerHandlerHelper_Miner.createPOAndPOLIsFromQuote2(quotesWithCustomerAccepted);
            
            if(result.get('success') == 'false'){
                Trigger.new[0].addError(result.get('message'));
            }else{
                System.debug('#####Izay: result from create PO from Quote = ' + result.get('message'));
                updateCaseNTE( quoteIds );
            }

            /*
            //Non Work WO recordType Id
            String NWWORTID = UNITY_Constants.WO_NON_WORK_RECORDTYPE;
            //Retrieve the work order associated
            Map<Id,WorkOrder> workOrderMap = new Map<Id,WorkOrder>([SELECT Id,UNITY_Current_PO__c,CaseId,UNITY_Assigned_Vendor__c,RecordTypeId,
                                                                    UNITY_Business_Unit__c,UNITY_Vendor_Contract__c,UNITY_Include__c,UNITY_Use_Menu_Pricing__c
                                                                    FROM WorkOrder
                                                                    WHERE Id IN: UNITY_Utils.joiningByFieldList(quotesWithCustomerAccepted,'UNITY_Work_Order__c')]);
            Map<Id,Order> originatingURMap = new Map<Id,Order>([SELECT Id,UNITY_Vendor__c,RecordTypeId FROM ORDER WHERE Id IN :urIds]);
            // retrieve the QL items related to the accepted quote
            Map<Id,List<UNITY_Proposal_Line_Item__c>> quoteWithQuoteLinesMap = new Map<Id,List<UNITY_Proposal_Line_Item__c>>();
            List<UNITY_Proposal_Line_Item__c> allQuoteLineItems = new List<UNITY_Proposal_Line_Item__c>();
            for(UNITY_Proposal_Line_Item__c quoteLineItem : [SELECT Id, UNITY_Cost__c, UNITY_Total_Cost__c, UNITY_Total_Price__c, UNITY_Quantity__c, 
                                                             UNITY_Product__c, UNITY_Is_Labor_Or_Travel_Concerned__c,UNITY_Proposal__c,
                                                             UNITY_Is_Vendor_Supply__c, UNITY_Price__c,
                                                             UNITY_Customer_Holiday_Multiplier__c, UNITY_Customer_OT_Multiplier__c,
                                                             UNITY_Vendor_Holiday_Multiplier__c, UNITY_Vendor_OT_Multiplier__c,
                                                             UNITY_Number_of_Techs__c, UNITY_Type__c, UNITY_Activity_Type__c, UNITY_PriceBook_Entry_Id__c,
                                                             UNITY_Part_Source__c, UNITY_Part_On_Hand__c, UNITY_Customer_Adjusted_Quantity__c, UNITY_Vendor_Adjusted_Quantity__c,
                                                             UNITY_Asset__c, UNITY_Make__c,UNITY_Model__c,UNITY_Description__c,UNITY_Unit_of_Measure__c
                                                             FROM UNITY_Proposal_Line_Item__c
                                                             WHERE UNITY_Proposal__c IN: UNITY_Utils.joiningByIdList(quotesWithCustomerAccepted)])
            {
                if(quoteWithQuoteLinesMap.get(quoteLineItem.UNITY_Proposal__c) == null) {
                    quoteWithQuoteLinesMap.put(quoteLineItem.UNITY_Proposal__c, new List<UNITY_Proposal_Line_Item__c>());
                }
                quoteWithQuoteLinesMap.get(quoteLineItem.UNITY_Proposal__c).add(quoteLineItem);
                allQuoteLineItems.add(quoteLineItem);
            }
            // Quote -> Work Order
            // Quote -> purchaseOrderPart
            // Quote -> purchaseOrderLaborAndTravel
            // Quote -> purchaseOrderItemsParts
            // Quote -> purchaseOrderItemsLaborAndTravel
            // 
            List<QuoteWithWO_PO_POLi> quoteWithWO_PO_POLiList = new List<QuoteWithWO_PO_POLi>();
            
            for(UNITY_Proposal__c quote : quotesWithCustomerAccepted) {
                List<UNITY_Proposal_Line_Item__c> quoteLineItems = quoteWithQuoteLinesMap.get(quote.Id);
                //Check if the WO is Non Work WO
                Boolean isNonWork = (workOrderMap.get(quote.UNITY_Work_Order__c).RecordTypeId == NWWORTID) ? true : false;
                if(quoteLineItems != null && !quoteLineItems.isEmpty()){ 
                    QuoteWithWO_PO_POLi quoteWithStuff = new QuoteWithWO_PO_POLi();
                    quoteWithStuff.quote = quote;
                        /**
                         * Given the quotes approved by the customer,
                         * vendor is saying we need to do more work
                         * so we create a new PO
                         * with labor and travel (assuming quote is not needed/under NTE)
                         * and if its vendor supply part
                         * we add that line item as well
                         
                    for(UNITY_Proposal_Line_Item__c quoteLineItem : quoteLineItems) {
                        OrderItem orderItem = new OrderItem();
                        orderItem.Quantity = quoteLineItem.UNITY_Quantity__c;
                        System.debug(' >>> quoteLineItem.UNITY_PriceBook_Entry_Id__c '+quoteLineItem.UNITY_PriceBook_Entry_Id__c);
                        System.debug(' >>> (Id)quoteLineItem.UNITY_PriceBook_Entry_Id__c '+(Id)quoteLineItem.UNITY_PriceBook_Entry_Id__c);

                        orderItem.PricebookEntryId = (Id)quoteLineItem.UNITY_PriceBook_Entry_Id__c;
                        orderItem.UNITY_Customer_Adjusted_Quantity__c = quoteLineItem.UNITY_Customer_Adjusted_Quantity__c==null?0:quoteLineItem.UNITY_Customer_Adjusted_Quantity__c;
                        orderItem.UNITY_Vendor_Adjusted_Quantity__c = quoteLineItem.UNITY_Vendor_Adjusted_Quantity__c==null?0:quoteLineItem.UNITY_Vendor_Adjusted_Quantity__c;
                        orderItem.UNITY_Cost__c = quoteLineItem.UNITY_Cost__c==null?0:quoteLineItem.UNITY_Cost__c;
                        orderItem.UNITY_Price__c = quoteLineItem.UNITY_Price__c==null?0:quoteLineItem.UNITY_Price__c;
                        orderItem.UNITY_Total_Cost__c = quoteLineItem.UNITY_Total_Cost__c==null?0:quoteLineItem.UNITY_Total_Cost__c;
                        orderItem.UNITY_Total_Price__c = quoteLineItem.UNITY_Total_Price__c==null?0:quoteLineItem.UNITY_Total_Price__c;
                        orderItem.UNITY_Number_of_Techs__c = quoteLineItem.UNITY_Number_of_Techs__c;
                        orderItem.UnitPrice = orderItem.UnitPrice==null?0:orderItem.UnitPrice;
                        orderItem.UNITY_Type__c = quoteLineItem.UNITY_Type__c;
                        orderItem.UNITY_Activity_Type__c = quoteLineItem.UNITY_Activity_Type__c;
                        orderItem.UNITY_Is_Vendor_Supply__c = quoteLineItem.UNITY_Is_Vendor_Supply__c;
                        orderItem.UNITY_Part_Source__c = quoteLineItem.UNITY_Part_Source__c;
                        orderItem.UNITY_Part_On_Hand__c = quoteLineItem.UNITY_Part_On_Hand__c;
                        orderItem.UNITY_Asset__c = quoteLineItem.UNITY_Asset__c;
                        //Izay: propagate unknown/special part info
                        orderItem.UNITY_Make__c = quoteLineItem.UNITY_Make__c;
                        orderItem.UNITY_Model__c = quoteLineItem.UNITY_Model__c;
                        orderItem.UNITY_Unit_of_Measure__c = quoteLineItem.UNITY_Unit_of_Measure__c;
                        orderItem.Description = quoteLineItem.UNITY_Description__c;
                        //Nat: propagate Multiplier fields
                        orderItem.UNITY_Customer_Holiday_Multiplier__c = quoteLineItem.UNITY_Customer_Holiday_Multiplier__c;
                        orderItem.UNITY_Customer_OT_Multiplier__c = quoteLineItem.UNITY_Customer_OT_Multiplier__c;
                        orderItem.UNITY_Vendor_Holiday_Multiplier__c = quoteLineItem.UNITY_Vendor_Holiday_Multiplier__c;
                        orderItem.UNITY_Vendor_OT_Multiplier__c = quoteLineItem.UNITY_Vendor_OT_Multiplier__c;
                         
                        if(quoteLineItem.UNITY_Is_Labor_Or_Travel_Concerned__c) {
                            quoteWithStuff.purchaseOrderItemsLaborAndTravel.add(orderItem);
                        }else{
                            Boolean isOriniatingVendor = false;
                            if(isNonWork){
                                if(originatingURMap.containsKey(quote.UNITY_Originating_Usage_Request__c)){
                                    if(String.isNotBlank(originatingURMap.get(quote.UNITY_Originating_Usage_Request__c).UNITY_Vendor__c) && String.isNotBlank(orderItem.UNITY_Part_Source__c)){
                                        if(orderItem.UNITY_Part_Source__c == originatingURMap.get(quote.UNITY_Originating_Usage_Request__c).UNITY_Vendor__c){
                                            isOriniatingVendor = true;
                                        }
                                    }
                                }
                            }
                            if(quoteLineItem.UNITY_Is_Vendor_Supply__c || workOrderMap.get(quote.UNITY_Work_Order__c).UNITY_Use_Menu_Pricing__c || workOrderMap.get(quote.UNITY_Work_Order__c).UNITY_Include__c || isOriniatingVendor) {
                                quoteWithStuff.purchaseOrderItemsIsVendorSupply.add(orderItem);
                            } else {
                                quoteWithStuff.purchaseOrderItemsIsNotVendorSupply.add(orderItem);
                                
                                //if(quote.UNITY_Work_Order__c != null && workOrderMap.get(quote.UNITY_Work_Order__c) != null &&
                                //   workOrderMap.get(quote.UNITY_Work_Order__c).UNITY_Current_PO__c != null) {
                                     
                                //add part $0 line item so the vendor knows there is a part coming
                                OrderItem clonedOrder = orderItem.clone();
                                //clonedOrder.OrderId = quoteWithStuff.purchaseOrderLaborAndTravel.id;
                                clonedOrder.UNITY_Total_Price__c = 0;
                                clonedOrder.UNITY_Price__c = 0;
                                clonedOrder.UNITY_Cost__c = 0;
                                clonedOrder.UNITY_Total_Cost__c = 0;
                                clonedOrder.UNITY_Type__c = 'Non Billable';
                                
                                quoteWithStuff.purchaseOrderItemsIsNotVendorSupplyForVendorPO.add(clonedOrder);
                                //}
                            }  
                        }
                        System.debug(' >>> purchaseOrderItemsLaborAndTravel '+quoteWithStuff.purchaseOrderItemsLaborAndTravel);
                        System.debug(' >>> purchaseOrderItemsIsVendorSupply '+quoteWithStuff.purchaseOrderItemsIsVendorSupply);
                        System.debug(' >>> purchaseOrderItemsIsNotVendorSupply '+quoteWithStuff.purchaseOrderItemsIsNotVendorSupply);
                        System.debug(' >>> purchaseOrderItemsIsNotVendorSupplyForVendorPO '+quoteWithStuff.purchaseOrderItemsIsNotVendorSupplyForVendorPO);
                    }
                    quoteWithWO_PO_POLiList.add(quoteWithStuff);
                }
            }

            System.debug(' >>> quotes :'+quotesWithCustomerAccepted);
            System.debug(' >>> workOrderMap :'+workOrderMap);
            List<Order> purchaseOrders = new List<Order>();
            for(QuoteWithWO_PO_POLi quoteWO_PO_POLi : quoteWithWO_PO_POLiList) {
                Id workOrderId = quoteWO_PO_POLi.quote.UNITY_Work_Order__c;
                if(workOrderId != null && workOrderMap.get(workOrderId) != null) {
                    WorkOrder workOrder = workOrderMap.get(workOrderId);
                    Boolean isNonWork = (workOrder.RecordTypeId == NWWORTID) ? true : false;
                    Id vendorId = String.isNotBlank(workOrder.UNITY_Assigned_Vendor__c) ? workOrder.UNITY_Assigned_Vendor__c : null;
                    if(isNonWork){
                        if(originatingURMap.containsKey(quoteWO_PO_POLi.quote.UNITY_Originating_Usage_Request__c)){
                            if(String.isNotBlank(originatingURMap.get(quoteWO_PO_POLi.quote.UNITY_Originating_Usage_Request__c).UNITY_Vendor__c)){
                                vendorId = originatingURMap.get(quoteWO_PO_POLi.quote.UNITY_Originating_Usage_Request__c).UNITY_Vendor__c;
                            }
                        }
                    }
                    if(!quoteWO_PO_POLi.purchaseOrderItemsIsNotVendorSupply.isEmpty()){
                        quoteWO_PO_POLi.purchaseOrderForPartIsNotVendorSupply.FSO__WorkOrder__c = workOrderId;
                        quoteWO_PO_POLi.purchaseOrderForPartIsNotVendorSupply.UNITY_Business_Unit__c = workOrder.UNITY_Business_Unit__c;
                        quoteWO_PO_POLi.purchaseOrderForPartIsNotVendorSupply.UNITY_Vendor_Contract__c = workOrder.UNITY_Vendor_Contract__c;
                        quoteWO_PO_POLi.purchaseOrderForPartIsNotVendorSupply.UNITY_Customer__c = quoteWO_PO_POLi.quote.UNITY_Customer__c;
                        quoteWO_PO_POLi.purchaseOrderForPartIsNotVendorSupply.AccountId = quoteWO_PO_POLi.quote.UNITY_Account__c;
                        quoteWO_PO_POLi.purchaseOrderForPartIsNotVendorSupply.UNITY_Originating_Usage_Request__c = quoteWO_PO_POLi.quote.UNITY_Originating_Usage_Request__c;
                        quoteWO_PO_POLi.purchaseOrderForPartIsNotVendorSupply.Description = quoteWO_PO_POLi.quote.UNITY_Quote_Comments__c;
                        purchaseOrders.add(quoteWO_PO_POLi.purchaseOrderForPartIsNotVendorSupply);
                    }
                    if(!quoteWO_PO_POLi.purchaseOrderItemsLaborAndTravel.isEmpty() || 
                       !quoteWO_PO_POLi.purchaseOrderItemsIsNotVendorSupplyForVendorPO.isEmpty() || 
                       !quoteWO_PO_POLi.purchaseOrderItemsIsVendorSupply.isEmpty()){
                           // labor and travel that is assigned to the same vendor / wo
                           // when we create the Labor and Travel lines after Quote..
                           // they need to have is vendor supplied = true
                           quoteWO_PO_POLi.purchaseOrderLaborAndTravel.FSO__WorkOrder__c = workOrderId;
                           quoteWO_PO_POLi.purchaseOrderLaborAndTravel.UNITY_Business_Unit__c = workOrder.UNITY_Business_Unit__c;
                           quoteWO_PO_POLi.purchaseOrderLaborAndTravel.UNITY_Vendor_Contract__c = workOrder.UNITY_Vendor_Contract__c;
                           quoteWO_PO_POLi.purchaseOrderLaborAndTravel.UNITY_Vendor__c = vendorId;
                           quoteWO_PO_POLi.purchaseOrderLaborAndTravel.UNITY_Customer__c = quoteWO_PO_POLi.quote.UNITY_Customer__c;
                           quoteWO_PO_POLi.purchaseOrderLaborAndTravel.AccountId = quoteWO_PO_POLi.quote.UNITY_Account__c;
                           quoteWO_PO_POLi.purchaseOrderLaborAndTravel.UNITY_Originating_Usage_Request__c = quoteWO_PO_POLi.quote.UNITY_Originating_Usage_Request__c;
                           quoteWO_PO_POLi.purchaseOrderLaborAndTravel.Description = quoteWO_PO_POLi.quote.UNITY_Quote_Comments__c;
                           purchaseOrders.add(quoteWO_PO_POLi.purchaseOrderLaborAndTravel);
                    }
                    /***************************************************************
                     * * HERE: TO UPDATE WO STATUS WHEN QUOTE IS CUSTOMER APPROVED *
                     * *********************************************************** 
                }
            }
            
            System.debug('purchaseOrders # : ('+purchaseOrders.size() +') - '+ purchaseOrders);
            
            // insert new purchase order for the parts that have isVendorSupply.
            if(!purchaseOrders.isEmpty()) {
                UNITY_OrderTriggerHandler_Miner.isFirstTriggerRun_Before = true;
                insert purchaseOrders;
            }
            
            // update the purchase order line item with the purchase order, excluding the part is not vendor supply
            // in a new po.
            List<OrderItem> purchaseOrderItems = new List<OrderItem>();
            for(QuoteWithWO_PO_POLi quoteWO_PO_POLi : quoteWithWO_PO_POLiList) {
                for(OrderItem purchaseOrderItemNotSupplied : quoteWO_PO_POLi.purchaseOrderItemsIsNotVendorSupply) {
                    System.debug('######## purchaseOrderItemNotSupplied.POId: ' + quoteWO_PO_POLi.purchaseOrderForPartIsNotVendorSupply.Id);
                    purchaseOrderItemNotSupplied.OrderId = quoteWO_PO_POLi.purchaseOrderForPartIsNotVendorSupply.Id;
                    purchaseOrderItems.add(purchaseOrderItemNotSupplied);
                }
                
                for(OrderItem purchaseOrderItemSuppled : quoteWO_PO_POLi.purchaseOrderItemsIsVendorSupply) {
                    System.debug('######## purchaseOrderItemSuppled.POId: ' + quoteWO_PO_POLi.purchaseOrderLaborAndTravel.Id);
                    purchaseOrderItemSuppled.OrderId = quoteWO_PO_POLi.purchaseOrderLaborAndTravel.Id;
                    purchaseOrderItems.add(purchaseOrderItemSuppled);
                }
                
                for(OrderItem purchaseOrderItemLaborAndTravel : quoteWO_PO_POLi.purchaseOrderItemsLaborAndTravel) {
                    System.debug('######## purchaseOrderItemLaborAndTravel.POId: ' + quoteWO_PO_POLi.purchaseOrderLaborAndTravel.Id);
                    purchaseOrderItemLaborAndTravel.OrderId = quoteWO_PO_POLi.purchaseOrderLaborAndTravel.Id;
                    purchaseOrderItems.add(purchaseOrderItemLaborAndTravel);
                }

                for(OrderItem purchaseOrderItemIsNotVendorSupplyForVendorPO : quoteWO_PO_POLi.purchaseOrderItemsIsNotVendorSupplyForVendorPO) {
                    System.debug('######## purchaseOrderItemIsNotVendorSupplyForVendorPO.POId: ' + quoteWO_PO_POLi.purchaseOrderLaborAndTravel.Id);
                    purchaseOrderItemIsNotVendorSupplyForVendorPO.OrderId = quoteWO_PO_POLi.purchaseOrderLaborAndTravel.Id;
                    purchaseOrderItems.add(purchaseOrderItemIsNotVendorSupplyForVendorPO);
                }                
                
            }
            
            // insert the purchase order items for 
            System.debug(' >>> purchaseOrderItems: '+JSON.serialize(purchaseOrderItems));
            UNITY_OrderItemTriggerHandler_Miner.isFirstTriggerRun_Before = true;
            insert purchaseOrderItems;
            
            List<OrderItem> purchaseOrderItemsNotSuppliedOnVendorPO = new List<OrderItem>();
            List<OrderItem> purchaseOrderItemsActualWith0Poli = new List<OrderItem>();
            List<OrderItem> POLIsToUpdate = new List<OrderItem>();
            // associate the poli on new part with the $0 poli on the vendor po,
            // updating the field UNITY_Related_Order_Product__c in one direction
            for(QuoteWithWO_PO_POLi quoteWO_PO_POLi : quoteWithWO_PO_POLiList) {
                System.debug(' >>> quoteWO_PO_POLi: '+quoteWO_PO_POLi);
                for(Integer i=0; i<quoteWO_PO_POLi.purchaseOrderItemsIsNotVendorSupply.size(); i++) {
                    System.debug(' >>> i: '+i);
                    OrderItem purchaseOrderItemNotSupplied = quoteWO_PO_POLi.purchaseOrderItemsIsNotVendorSupply.get(i);
                    OrderItem purchaseOrderItemNotSuppliedOnVendorPO = quoteWO_PO_POLi.purchaseOrderItemsIsNotVendorSupplyForVendorPO.get(i);
                    System.debug(' >>> purchaseOrderItemNotSupplied: '+purchaseOrderItemNotSupplied);
                    System.debug(' >>> purchaseOrderItemNotSuppliedOnVendorPO: '+purchaseOrderItemNotSuppliedOnVendorPO);
                    purchaseOrderItemNotSuppliedOnVendorPO.UNITY_Related_Order_Product__c = purchaseOrderItemNotSupplied.id;
                    purchaseOrderItemNotSupplied.UNITY_Related_Order_Product__c = purchaseOrderItemNotSuppliedOnVendorPO.Id;
                    purchaseOrderItemsNotSuppliedOnVendorPO.add(purchaseOrderItemNotSuppliedOnVendorPO);
                    purchaseOrderItemsActualWith0Poli.add(purchaseOrderItemNotSupplied);
                }
                System.debug(' >>> purchaseOrderItemsNotSuppliedOnVendorPO: '+purchaseOrderItemsNotSuppliedOnVendorPO);
                System.debug(' >>> purchaseOrderItemsActualWith0Poli: '+purchaseOrderItemsActualWith0Poli);
            }
            POLIsToUpdate.AddAll(purchaseOrderItemsNotSuppliedOnVendorPO);
            POLIsToUpdate.AddAll(purchaseOrderItemsActualWith0Poli);
            System.debug(' >>> POLIsToUpdate: '+POLIsToUpdate);
            
            if(!POLIsToUpdate.isEmpty()){
                update POLIsToUpdate;
                System.debug(' >>> after upadting POLIsToUpdate: '+POLIsToUpdate);

            }
            
            
      /*
            // associate the actual poli with the $0 poli
            // updating the field UNITY_Related_Order_Product__c in the reverse direction
            for(QuoteWithWO_PO_POLi quoteWO_PO_POLi : quoteWithWO_PO_POLiList) {
                for(Integer i=0; i<quoteWO_PO_POLi.purchaseOrderItemsIsNotVendorSupply.size(); i++) {
                    OrderItem purchaseOrderItemNotSupplied = quoteWO_PO_POLi.purchaseOrderItemsIsNotVendorSupply.get(i);
                    OrderItem purchaseOrderItemNotSuppliedOnVendorPO = quoteWO_PO_POLi.purchaseOrderItemsIsNotVendorSupplyForVendorPO.get(i);
                    purchaseOrderItemNotSupplied.UNITY_Related_Order_Product__c = purchaseOrderItemNotSuppliedOnVendorPO.Id;
                    purchaseOrderItemsActualWith0Poli.add(purchaseOrderItemNotSupplied);
                }
            }
            update purchaseOrderItemsActualWith0Poli;
      
            // update the UR status from In Quote Process to Quote Created
            List<Order> usageRequests = new List<Order>();
            for(Order usageRequest : [SELECT Id, Status FROM Order
                                      WHERE RecordTypeId =: UNITY_Constants.ORDER_USAGE_REQUEST_RECORDTYPE AND
                                            Status =: UNITY_Constants.ORDER_STATUS_IN_QUOTE_PROCESS AND
                                            FSO__WorkOrder__c IN : workOrderMap.keySet()]) {
                usageRequest.Status = UNITY_Constants.ORDER_STATUS_PO_CREATED;
                usageRequests.add(usageRequest);
            }
            
            update usageRequests;
            
            /*
            // updated NTE on case should be the total price on case + the Quote amount
            Map<Id,Case> caseForQuotes = new Map<Id,Case>([SELECT Id, UNITY_NTE_Threshold__c FROM Case
                                                        WHERE Id IN : UNITY_Utils.joiningByFieldList(quotesWithCustomerAccepted, 'UNITY_Case__c')]);
            
            System.debug(' >>> caseForQuotes: '+caseForQuotes);
            for(UNITY_Proposal__c quote :quotesWithCustomerAccepted) {
                if(quote.UNITY_Case__c != null && caseForQuotes.get(quote.UNITY_Case__c) != null) {
                    caseForQuotes.get(quote.UNITY_Case__c).UNITY_NTE_Threshold__c = quote.UNITY_Total_Revenue__c;
                }
            }
            
            if(!caseForQuotes.isEmpty()) {
                update caseForQuotes.values();   
            }
            */
            System.debug(' >>> User Info: '+System.UserInfo.getName());
        }
        
    }
    
    /*  Wrapper class to keep related the following things.  
    *   Quote -> Work Order
    *   Quote -> purchaseOrderPart
    *   Quote -> purchaseOrderLaborAndTravel
    *   Quote -> purchaseOrderItemsParts
    *   Quote -> purchaseOrderItemsLaborAndTravel
    */
    class QuoteWithWO_PO_POLi {
        
        public UNITY_Proposal__c  quote;
        //public Order purchaseOrderPart;
        public Order purchaseOrderLaborAndTravel;
        public Order purchaseOrderForPartIsNotVendorSupply;
        public List<OrderItem> purchaseOrderItemsLaborAndTravel = new List<OrderItem>();
        public List<OrderItem> purchaseOrderItemsIsVendorSupply = new List<OrderItem>();
        public List<OrderItem> purchaseOrderItemsIsNotVendorSupply = new List<OrderItem>();
        public List<OrderItem> purchaseOrderItemsIsNotVendorSupplyForVendorPO = new List<OrderItem>();
        
        public QuoteWithWO_PO_POLi() {
            //purchaseOrderPart = new Order(RecordTypeId=UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE);
            //purchaseOrderPart.Status = 'Submitted to Parts Team';
            //purchaseOrderPart.EffectiveDate = Date.today();
            purchaseOrderLaborAndTravel = new Order(RecordTypeId=UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE);
            purchaseOrderLaborAndTravel.pricebook2Id = standardPriceBookId;
            purchaseOrderLaborAndTravel.Status = 'Draft';
            purchaseOrderLaborAndTravel.EffectiveDate = Date.today();
            purchaseOrderForPartIsNotVendorSupply = new Order(RecordTypeId=UNITY_Constants.PART_SOURCING_PURCHASE_ORDER_RECORDTYPE);
            purchaseOrderForPartIsNotVendorSupply.pricebook2Id = standardPriceBookId;
            purchaseOrderForPartIsNotVendorSupply.Status = UNITY_Constants.ORDER_STATUS_PART_SOURCE_NEEDED;
            purchaseOrderForPartIsNotVendorSupply.EffectiveDate = Date.today();
        }
    }

    //Sets the Submitted and Approval dates for the master quote
    public void setSubmittedAndApprovedDates(){
        for (SObject val: trigger.new){
            UNITY_Proposal__c newQuote =  (UNITY_Proposal__c)val;
            UNITY_Proposal__c oldQuote =  (UNITY_Proposal__c)trigger.oldMap.get(val.id);
            
            if (newQuote.RecordTypeId == UNITY_Constants.PROPOSAL_MASTER_PROPOSAL_RECORDTYPE &&
                newQuote.UNITY_Proposal_Status__c != oldQuote.UNITY_Proposal_Status__c){ 
                
                if (newQuote.UNITY_Proposal_Status__c == UNITY_Constants.QT_STATUS_SENT_TO_CUSTOMER){
                    if (newQuote.Quote_Submitted_Date__c == null){
                        newQuote.Quote_Submitted_Date__c = DateTime.Now();
                    }
                }
                if (newQuote.UNITY_Proposal_Status__c == UNITY_Constants.QT_STATUS_CUSTOMER_APPROVED){
                    newQuote.Quote_Approved_Date__c = DateTime.Now();
                    if (newQuote.Quote_Submitted_Date__c == null)
                        newQuote.Quote_Submitted_Date__c = DateTime.Now();
                }
            }
        }
        
    }

    //Sets the Submitted and Approval dates in the Case level
    public void updateCaseQuoteDates(Map<Id, SObject> oldQuoteMap, Map<Id, SObject> newQuoteMap){
        List<Case> casesToUpdate = new List<Case>();

        //Find the Case related to Quotes that were sent, approved or cancelled
        Map<Id,Case> sentRelatedCaseMap = new Map<Id,Case>();
        Map<Id,Case> approvedRelatedCaseMap = new Map<Id,Case>();
        Map<Id,Case> cancelledRelatedCaseMap = new Map<Id,Case>();
        
        for (SObject val: newQuoteMap.values()){
            UNITY_Proposal__c newQuote =  (UNITY_Proposal__c)val;
            UNITY_Proposal__c oldQuote =  (UNITY_Proposal__c)oldQuoteMap.get(val.id);
            
            //Check if the status changed
            if (newQuote.RecordTypeId == UNITY_Constants.PROPOSAL_MASTER_PROPOSAL_RECORDTYPE &&
                newQuote.UNITY_Proposal_Status__c != oldQuote.UNITY_Proposal_Status__c){ 
                    Case c = relatedCaseMap.get(newQuote.UNITY_Case__c);
                    
                    if (newQuote.UNITY_Proposal_Status__c == UNITY_Constants.QT_STATUS_SENT_TO_CUSTOMER)
                        sentRelatedCaseMap.put(c.Id, c);
                    if (newQuote.UNITY_Proposal_Status__c == UNITY_Constants.QT_STATUS_CUSTOMER_APPROVED)
                        approvedRelatedCaseMap.put(c.Id, c);
                    if (newQuote.UNITY_Proposal_Status__c == UNITY_Constants.QT_STATUS_CUSTOMER_REJECTED)
                        cancelledRelatedCaseMap.put(c.Id, c);                       
                }
        }
        system.debug('@@@updateCaseQuoteDates sentRelatedCaseMap:'+sentRelatedCaseMap);
        system.debug('@@@updateCaseQuoteDates approvedRelatedCaseMap:'+approvedRelatedCaseMap);
        system.debug('@@@updateCaseQuoteDates cancelledRelatedCaseMap:'+cancelledRelatedCaseMap);
        
        //Get all master quotes 
        AggregateResult[] groupedResults = [SELECT UNITY_Case__r.Id, Min(Quote_Submitted_Date__c), Max(Quote_Approved_Date__c)
                                            FROM UNITY_Proposal__c 
                                            WHERE (UNITY_Case__c IN :sentRelatedCaseMap.keySet() OR UNITY_Case__c IN :approvedRelatedCaseMap.keySet() OR UNITY_Case__c IN :cancelledRelatedCaseMap.keySet()) 
                                            GROUP BY UNITY_Case__r.Id];
        system.debug('@@@updateCaseQuoteDates groupedResults:'+groupedResults);
        for (AggregateResult result: groupedResults){
            Id caseID = (Id)result.get('Id');
            DateTime submittedDate = (DateTime)result.get('expr0');
            DateTime approvedDate = (DateTime)result.get('expr1');
            
            if (sentRelatedCaseMap.containsKey(caseID)){
                Case c = sentRelatedCaseMap.get(caseID);
                if (c.Quote_Submitted_Date__c != submittedDate){
                    c.Quote_Submitted_Date__c = submittedDate;
                    casesToUpdate.add(c);
                    system.debug('@@@updateCaseQuoteDates case SENT to update:'+c);
                }
            }
            if (approvedRelatedCaseMap.containsKey(caseID)){
                Case c = approvedRelatedCaseMap.get(caseID);
                if (c.Quote_Approved_Date__c != approvedDate){
                    c.Quote_Approved_Date__c = approvedDate;
                    casesToUpdate.add(c);
                    system.debug('@@@updateCaseQuoteDates case APPROVED to update:'+c);
                }
            }
            if (cancelledRelatedCaseMap.containsKey(caseID)){
                Case c = cancelledRelatedCaseMap.get(caseID);
                c.Quote_Submitted_Date__c = submittedDate;
                c.Quote_Approved_Date__c = approvedDate;
                casesToUpdate.add(c);
                system.debug('@@@updateCaseQuoteDates case REJECTED to update:'+c);
            }
        } 
    
        if (!casesToUpdate.isEmpty()){
            Database.SaveResult[] saveResults = Database.update(casesToUpdate, false);
            system.debug('@@@updateCaseQuoteDates saveResults:'+saveResults);
        }
    }        
}