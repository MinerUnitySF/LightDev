public class UNITY_InvoiceTriggerHandler_Miner extends UNITY_BaseHandler{
    public override void bulkBefore(){
        if(Trigger.isUpdate){
            //For each invoice being updated 
            for(SObject so :trigger.new){
                UNITY_Invoice__c inv = (UNITY_Invoice__c)so;
                UNITY_Invoice__c oldInv = (UNITY_Invoice__c)Trigger.oldMap.get(inv.Id);
                if((inv.UNITY_Invoice_Status__c == 'Invoice Finalized') && (oldInv.UNITY_Invoice_Status__c != inv.UNITY_Invoice_Status__c)){
                    inv.UNITY_Invoice_Date__c = Date.today();
                }
            }
        }
    }
    public override void bulkAfter(){
        List<UNITY_Invoice__c> invIdUpdateCase = new List<UNITY_Invoice__c>();

        if(Trigger.isUpdate){
            //Check which invoices are updated to 'Sent to Customer' to generate Invoice PDF and attach it to the case
            Set<String> invIds = new Set<String>();
            List<Id> invIdsAvatax = new List<Id>();
            List<Id> invIdsCancelTax = new List<Id>();
            Set<Id> cancelledInvIds = new Set<Id>();
            //For each invoice being updated 
            for(SObject so :trigger.new){
                UNITY_Invoice__c inv = (UNITY_Invoice__c)so;
                UNITY_Invoice__c oldInv = (UNITY_Invoice__c)Trigger.oldMap.get(inv.Id);
                System.debug('##### new status: ' + inv.UNITY_Invoice_Status__c);
                System.debug('##### new cust status: ' + inv.UNITY_Status__c);
                System.debug('##### old status: ' + oldInv.UNITY_Invoice_Status__c);
                //If invoice date changed or status, update case
                if (inv.UNITY_Invoice_Date__c != oldInv.UNITY_Invoice_Date__c || inv.UNITY_Invoice_Status__c != oldInv.UNITY_Invoice_Status__c){
                    invIdUpdateCase.add(inv);
                }                
                //If ther invoice status changes to Invoice Finalized...
                if((inv.UNITY_Invoice_Status__c == 'Invoice Finalized') && (oldInv.UNITY_Invoice_Status__c != inv.UNITY_Invoice_Status__c)){
                    invIds.add(inv.Id);
                    //if not running  postInvoiceTax && tax has not been posted
                    if(!System.isFuture() && !System.isBatch() && !inv.UNITY_Tax_Posted__c)
                        system.debug('//Clay: Adding an invoice to be sent to postInvoiceTax future  method (result will be in a different log):');
                        system.debug('//Clay: invoice: ' + inv.Id);
                        postInvoiceTax(inv.Id);
                //If the invoice status changed to Disputed...
                }else if((inv.UNITY_Invoice_Status__c == 'Disputed') && (oldInv.UNITY_Invoice_Status__c != inv.UNITY_Invoice_Status__c)){
                    //If not runnign canceltaxInvoice
                    if(!UNITY_Constants.isExecutingContext('UNITY_InvoiceTriggerHandler_Miner.cancelInvoiceTax'))
                        system.debug('//Clay: Adding an invoice to be sent to cancelInvoiceTax future  method (result will be in a different log):');
                        system.debug('//Clay: invoice: ' + inv.Id);
                        invIdsCancelTax.add(inv.Id);
                //If the invoice status changed to Disputed and tax processed is set to false...
                }else if(inv.UNITY_Invoice_Status__c == 'Disputed' && inv.UNITY_Tax_Processed__c == false){
                    //if not running cancelinvoice
                    if(!UNITY_Constants.isExecutingContext('UNITY_InvoiceTriggerHandler_Miner.cancelInvoiceTax'))
                        invIdsCancelTax.add(inv.Id);
                //If the invoice status is Invoice Creation and tax hasn't proicessed and not running callAvataxForInvoice...
                //And tax hasn't posted...
                }else if(inv.UNITY_Invoice_Status__c == 'Invoice Creation' && !inv.UNITY_Tax_Posted__c &&
                         !UNITY_Constants.isExecutingContext('UNITY_InvoiceCreationPageController.callAvataxForInvoice') &&
                         !UNITY_Constants.isExecutingContext('UNITY_CallAvatax.getTaxServiceCharge') &&
                         (inv.UNITY_Tax_Processed__c == false || (inv.UNITY_Tax_Processed__c == true && inv.UNITY_Total_Price__c != oldInv.UNITY_Total_Price__c))) {

                             invIdsAvatax.add(inv.Id);
                         }else if(inv.UNITY_Invoice_Status__c == 'Cancelled' && oldInv.UNITY_Invoice_Status__c != inv.UNITY_Invoice_Status__c){
                             cancelledInvIds.add(inv.Id);
                         }
            
            }//End for inv
            if(!invIds.isEmpty() && !System.isFuture() && !System.isBatch()){
                UNITY_AttachmentHelper_Miner.createInvoiceAttachment(invIds);
            }
            if(!invIdsAvatax.isEmpty() && !System.isFuture() && !System.isBatch()){
                setInvoiceTax(invIdsAvatax);
            }
            if(!invIdsCancelTax.isEmpty() && !System.isFuture() && !System.isBatch()){
                cancelInvoiceTax(invIdsCancelTax);
            }
            if(!cancelledInvIds.isEmpty() && !System.isFuture() && !System.isBatch()){
                resetPOsRelatedToInvoice(cancelledInvIds);
            }
        }
        if (Trigger.isInsert){
            for(SObject so :trigger.new){
                UNITY_Invoice__c inv = (UNITY_Invoice__c)so;
                invIdUpdateCase.add(inv);
            }
        }
        if (Trigger.isDelete){
            for(SObject so :trigger.old){
                UNITY_Invoice__c inv = (UNITY_Invoice__c)so;
                invIdUpdateCase.add(inv);
            }
        }
        if (!invIdUpdateCase.isEmpty() && !System.isFuture() && !System.isBatch()){
            updateCaseDaysToInvoiceField(invIdUpdateCase);
        }           
    }
    
    @future(callout=true)
    public static void setInvoiceTax(List<Id> invIdsAvatax){
        if(!invIdsAvatax.isEmpty()){
            UNITY_CallAvatax.AvataxResult taxResult = UNITY_CallAvatax.getTaxInvoice(invIdsAvatax,false);
            System.debug('#taxResult '+taxResult);
        }
    }
    
    @future(callout=true)
    public static void postInvoiceTax(String invId){
        if(String.isNotBlank(invId)){
            List<Id> invIds = new List<Id>();
            invIds.add(invId);
            UNITY_CallAvatax.AvataxResult taxResult = UNITY_CallAvatax.getTaxInvoice(invIds,true);
            system.debug('//Clay: We just tried to post tax by calling UNITY_CallAvatax.AvataxResult: ');
            system.debug('//Clay: taxResult = ' + taxResult);
        }
    }
    
    @future(callout=true)
    public static void cancelInvoiceTax(List<Id> invIds){
        if(!invIds.isEmpty()){
            UNITY_CallAvatax.AvataxResult taxResult = UNITY_CallAvatax.cancelTaxInvoice(invIds);
            system.debug('//Clay: We just tried to cancel tax by calling UNITY_CallAvatax.AvataxResult: ');
            system.debug('//Clay: taxResult = ' + taxResult);
        }
    }
    public static void resetPOsRelatedToInvoice(Set<Id> invIds){
        List<Order> orders = [SELECT Id,OrderNumber,UNITY_Invoice__c,UNITY_Updated_Invoice__c,UNITY_Invoiced__c,Status
                              FROM Order 
                              WHERE UNITY_Invoice__c IN :invIds OR UNITY_Updated_Invoice__c IN :invIds];
        for(Order o :orders){
            o.UNITY_Invoiced__c = false;
            o.UNITY_Invoice__c = null;
            o.UNITY_Updated_Invoice__c = null;
            o.Status = 'Completed';
        }
        update orders;
    }
    
    //Calculates the days between Case.UNITY_Service_Completed_Date_Time__c & most recent Invoice.UNITY_Invoice_Date__c
    private void updateCaseDaysToInvoiceField(List<UNITY_Invoice__c> invoiceList){
        
        //Get all Case Ids
        Set<Id> caseIDs = new Set<Id>();
        for (UNITY_Invoice__c inv: invoiceList){
            caseIDs.add(inv.UNITY_Case__c);
        }
        system.debug('@@@updateCaseDaysToInvoiceField caseIDs:'+caseIDs);

        //Select Service Completed Date Time
        Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, Days_to_Invoice_Completed_Cases__c, UNITY_Service_Completed_Date_Time__c FROM Case
                               WHERE Id in :caseIDs]);
        
        system.debug('@@@updateCaseDaysToInvoiceField caseMap:'+caseMap);
        
        AggregateResult[] groupedResults = [SELECT UNITY_Case__r.Id, Max(UNITY_Invoice_Date__c)
                                            FROM UNITY_Invoice__c 
                                            WHERE UNITY_Case__c IN :caseIDs 
                                            AND UNITY_Invoice_Status__c != 'Cancelled'
                                            AND UNITY_Invoice_Status__c != 'Disputed'
                                            GROUP BY UNITY_Case__r.Id];
        
        system.debug('@@@updateCaseDaysToInvoiceField groupedResults:'+groupedResults);
        
        //Put grouped result in a map
        Map<Id, AggregateResult> caseAndInvoiceMap = new Map<Id, AggregateResult>();
        for (AggregateResult result: groupedResults){
            Id caseID = (Id)result.get('Id');
            caseAndInvoiceMap.put(caseID, result);
        }
        
        List<Case> caseToUpdate = new List<Case>();
        for (Id i: caseMap.keySet()){
            Case c = caseMap.get(i);
            AggregateResult ar = caseAndInvoiceMap.get(i);
            
            if (ar != null && c.UNITY_Service_Completed_Date_Time__c != null){
                Date invoiceDate = (Date)ar.get('expr0');
                Date serviceCompleted = Date.newInstance(c.UNITY_Service_Completed_Date_Time__c.year(), c.UNITY_Service_Completed_Date_Time__c.month(), c.UNITY_Service_Completed_Date_Time__c.day());
                c.Days_to_Invoice_Completed_Cases__c = serviceCompleted.daysBetween(invoiceDate);           
                caseToUpdate.add(c);
            }
            else {
                //if there are not aggregate result or Service Completed Date/Time is null, clear the field
                c.Days_to_Invoice_Completed_Cases__c = null;
                caseToUpdate.add(c);
            }           
        }
        
        system.debug('@@@updateCaseDaysToInvoiceField update caseToUpdate:'+caseToUpdate);
        if (caseToUpdate.size() > 0)                                    
            update caseToUpdate;
    }     
}