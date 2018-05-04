/*
 *   @programer:    Rodrigo Birriel
 *   @description:  invoice trigger handler.
 *   @date:         01/14/2016            
 */
public class UNITY_InvoiceTriggerHandler extends UNITY_BaseHandler {

    private Map<Id,UNITY_Service_Contract__c> customerSCMap = new Map<Id,UNITY_Service_Contract__c>();
    
    public override void bulkAfter(){
        
        if(Trigger.isUpdate) {
           	updateManualSharing();    
           
          	createInvoiceLinteItemFromServiceCharge(Trigger.New, Trigger.OldMap);
            
           	pushInvoiceCompletedToSL((List<UNITY_Invoice__c>) Trigger.Old,(List<UNITY_Invoice__c>) Trigger.New);
        }
        
        if(Trigger.isInsert){
            createInvoiceLinteItemFromServiceCharge(Trigger.New, null);
        }
    }

    public override void bulkBefore(){
		System.debug(LoggingLevel.INFO,'<AK - UNITY_InvoiceTriggerHandler.bulkBefore> : inside buldBefore : ');
		System.debug(LoggingLevel.INFO,'<AK - UNITY_InvoiceTriggerHandler.bulkBefore> : trigger.isUpdate : '+trigger.isUpdate);

        if (trigger.isUpdate){
            setRelatedCustomerSC();
        }
    }

    public override void beforeUpdate(SObject oldSo, SObject so) { 
        
        UNITY_Invoice__c newInvoice = (UNITY_Invoice__c) so;
        UNITY_Invoice__c oldInvoice = (UNITY_Invoice__c) oldSo;

       	System.debug(LoggingLevel.INFO,'<AK - UNITY_InvoiceTriggerHandler.beforeUpdate> : newInvoice.UNITY_Total_Vendor_Supplied_Dis_Price__c : '+newInvoice.UNITY_Total_Vendor_Supplied_Dis_Price__c);
       	System.debug(LoggingLevel.INFO,'<AK - UNITY_InvoiceTriggerHandler.beforeUpdate> : oldInvoice.UNITY_Total_Vendor_Supplied_Dis_Price__c : '+oldInvoice.UNITY_Total_Vendor_Supplied_Dis_Price__c);
        
        if((newInvoice.UNITY_Total_Vendor_Supplied_Dis_Price__c != oldInvoice.UNITY_Total_Vendor_Supplied_Dis_Price__c) || 
           (newInvoice.UNITY_Total_Vendor_Supplied_Dis_Price__c != null && newInvoice.UNITY_Total_Vendor_Supplied_Dis_Price__c > 0 && 
            newInvoice.UNITY_Service_Charge__c == null)){
            UNITY_Service_Contract__c customerSC = customerSCMap.get(newInvoice.UNITY_Customer_Service_Contract__c);
       		System.debug(LoggingLevel.INFO,'<AK - UNITY_InvoiceTriggerHandler.beforeUpdate> : customerSC : '+customerSC);
            if (customerSC != null && customerSC.UNITY_Is_Pass_Through__c){
                for (UNITY_Service_Contract_Line_Item__c scli: customerSC.UNITY_Service_Contract_Line_Items__r){
			       	System.debug(LoggingLevel.INFO,'<AK - UNITY_InvoiceTriggerHandler.beforeUpdate> : scli.UNITY_Threshold_Start__c : '+scli.UNITY_Threshold_Start__c);
			       	System.debug(LoggingLevel.INFO,'<AK - UNITY_InvoiceTriggerHandler.beforeUpdate> : scli.UNITY_Threshold_End__c : '+scli.UNITY_Threshold_End__c);
			       	System.debug(LoggingLevel.INFO,'<AK - UNITY_InvoiceTriggerHandler.beforeUpdate> : scli.UNITY_Service_Charge_Percentage__c : '+scli.UNITY_Service_Charge_Percentage__c);
			       	System.debug(LoggingLevel.INFO,'<AK - UNITY_InvoiceTriggerHandler.beforeUpdate> : scli.UNITY_Service_Charge_Amount__c : '+scli.UNITY_Service_Charge_Amount__c);

                    if(newInvoice.UNITY_Total_Vendor_Supplied_Dis_Price__c >= scli.UNITY_Threshold_Start__c && (scli.UNITY_Threshold_End__c == null || newInvoice.UNITY_Total_Vendor_Supplied_Dis_Price__c <= scli.UNITY_Threshold_End__c)){
                        Decimal serviceChargePercentage = 0;
                        Decimal serviceChargeAmount = 0;
                        
                        if (scli.UNITY_Service_Charge_Percentage__c!=null){
                            serviceChargePercentage = scli.UNITY_Service_Charge_Percentage__c;
                        }
                        if (scli.UNITY_Service_Charge_Amount__c!=null){
                            serviceChargeAmount = scli.UNITY_Service_Charge_Amount__c;
                        }
                        if ((newInvoice.UNITY_Total_Vendor_Supplied_Dis_Price__c * (serviceChargePercentage/100)) >= serviceChargeAmount){
                            newInvoice.UNITY_Service_Charge__c = newInvoice.UNITY_Total_Vendor_Supplied_Dis_Price__c * (serviceChargePercentage/100); 
                        }else if ((newInvoice.UNITY_Total_Vendor_Supplied_Dis_Price__c * (serviceChargePercentage/100)) < serviceChargeAmount){
                            newInvoice.UNITY_Service_Charge__c = serviceChargeAmount; 
                        }
			       		System.debug(LoggingLevel.INFO,'<AK - UNITY_InvoiceTriggerHandler.beforeUpdate> : newInvoice.UNITY_Service_Charge__c : '+newInvoice.UNITY_Service_Charge__c);
                        
                        break;
                    }
                }   
            } 
        }
        if(newInvoice.UNITY_Invoice_Status__c != oldInvoice.UNITY_Invoice_Status__c && newInvoice.UNITY_Invoice_Status__c == 'Disputed'){
            newInvoice.UNITY_Doc_Type__c = 'CM';
            newInvoice.UNITY_SL_Process_Complete__c = false;
        }
    }
     
    private void createInvoiceLinteItemFromServiceCharge(List<SObject> invoiceList, Map<Id, SObject> oldMap){
        List<UNITY_Invoice_Line_Item__c> invoiceLineItemsToInsert = new List<UNITY_Invoice_Line_Item__c>();
        List<UNITY_Invoice_Line_Item__c> invoiceLineItemsToUpdate = new List<UNITY_Invoice_Line_Item__c>();
        Product2 serviceChargeProduct;

        Set<Id> invoiceIdSet = new Set<Id>();
        Set<UNITY_Invoice__c> invoiceSetWithNewServiceCharge = new Set<UNITY_Invoice__c>();
        for(SObject obj : invoiceList){
            UNITY_Invoice__c invoice = (UNITY_Invoice__c)obj;

            if(Trigger.isUpdate){
                UNITY_Invoice__c oldInvoice = (UNITY_Invoice__c)oldMap.get(obj.Id);
                if(invoice.UNITY_Service_Charge__c != oldInvoice.UNITY_Service_Charge__c && 
                   (invoice.UNITY_Invoice_Status__c != 'Cancelled' && invoice.UNITY_Invoice_Status__c != 'Completed')){
                    invoiceIdSet.add(obj.Id);
                    invoiceSetWithNewServiceCharge.add(invoice);
                }
            }else{
                if(invoice.UNITY_Service_Charge__c != null){
                    invoiceIdSet.add(obj.Id);                    
                    invoiceSetWithNewServiceCharge.add(invoice);
                }
            }
        }

        if (invoiceIdSet.size()>0){
            //TODO - Update to use new Service Charge Type once created, more risk by searching with Name field
            List<Product2> serviceChargeProducts = [SELECT Id FROM Product2 WHERE UNITY_Product_Type__c ='Customer Service Charge' LIMIT 1]; 
            // prevent List has no rows for assignment to SObject
            if(!serviceChargeProducts.isEmpty()) {
                serviceChargeProduct = serviceChargeProducts.get(0); 
            }

            if(serviceChargeProduct != null){
                if(Trigger.isUpdate){
                    List<UNITY_Invoice_Line_Item__c > iliList = [SELECT Id, UNITY_Invoice__c, Product__r.Type__c FROM UNITY_Invoice_Line_Item__c WHERE UNITY_Invoice__c IN: invoiceIdSet AND Product__c =: serviceChargeProduct.Id];
                    Map<Id, UNITY_Invoice_Line_Item__c> invoiceIdToInvoiceLineItemMap = new Map<Id, UNITY_Invoice_Line_Item__c>();
                    for(UNITY_Invoice_Line_Item__c ili : iliList){
                        invoiceIdToInvoiceLineItemMap.put(ili.UNITY_Invoice__c, ili);
                    }
                    for(UNITY_Invoice__c invoice : invoiceSetWithNewServiceCharge){
                        if(invoiceIdToInvoiceLineItemMap.get(invoice.Id) == null){
                            UNITY_Invoice_Line_Item__c ili = new UNITY_Invoice_Line_Item__c();
                            ili.UNITY_Invoice__c = invoice.Id;
                            ili.UNITY_Total_Price__c = invoice.UNITY_Service_Charge__c;
                            //ili.UNITY_Excluded_from_Total__c = true;
                            ili.Product__c = serviceChargeProduct.Id;
                            ili.UNITY_Type__c = 'Service Fee';
                            ili.UNITY_Activity_Type__c = 'Service Charge';
                            ili.UNITY_Quantity__c = 1;
                            ili.UNITY_Adjusted_Quantity__c = 1;
                            invoiceLineItemsToInsert.add(ili);
                        } else {
                            UNITY_Invoice_Line_Item__c ili = invoiceIdToInvoiceLineItemMap.get(invoice.Id);
                            ili.UNITY_Total_Price__c = invoice.UNITY_Service_Charge__c;
                            //ili.UNITY_Excluded_from_Total__c = true;
                            invoiceLineItemsToUpdate.add(ili);
                        }
                    }
                } else {
                    for(UNITY_Invoice__c invoice : invoiceSetWithNewServiceCharge){
                        UNITY_Invoice_Line_Item__c ili = new UNITY_Invoice_Line_Item__c();
                        ili.UNITY_Invoice__c = invoice.Id;
                        ili.UNITY_Total_Price__c = invoice.UNITY_Service_Charge__c;
                        //ili.UNITY_Excluded_from_Total__c = true;
                        ili.Product__c = serviceChargeProduct.Id;
                        ili.UNITY_Type__c = 'Service Fee';
                        ili.UNITY_Activity_Type__c = 'Service Charge';
                        ili.UNITY_Quantity__c = 1;
                        ili.UNITY_Adjusted_Quantity__c = 1;
                        invoiceLineItemsToInsert.add(ili);
                    }
                }   
            }
            if(invoiceLineItemsToInsert.size() > 0){
                insert invoiceLineItemsToInsert;
            }
            if(invoiceLineItemsToUpdate.size() > 0){
                update invoiceLineItemsToUpdate;
            }
        }
    }
    
    public void setRelatedCustomerSC(){
        Set<Id> customerSCIds = new Set<Id>();
			System.debug(LoggingLevel.INFO,'<AK - UNITY_InvoiceTriggerHandler.setRelatedCustomerSC> : trigger.new : '+trigger.new);
        
        for (SObject iter: trigger.new){
			System.debug(LoggingLevel.INFO,'<AK - UNITY_InvoiceTriggerHandler.setRelatedCustomerSC> : ((UNITY_Invoice__c)iter).UNITY_Customer_Service_Contract__c : '+((UNITY_Invoice__c)iter).UNITY_Customer_Service_Contract__c);
            customerSCIds.add(((UNITY_Invoice__c)iter).UNITY_Customer_Service_Contract__c);
        }           
		System.debug(LoggingLevel.INFO,'<AK - UNITY_InvoiceTriggerHandler.setRelatedCustomerSC> : customerSCIds : '+customerSCIds);
			
        customerSCMap = new Map<Id,UNITY_Service_Contract__c>([select id, UNITY_Is_Pass_Through__c, (Select id,  UNITY_Threshold_Start__c, UNITY_Threshold_End__c, UNITY_Service_Charge_Percentage__c, UNITY_Service_Charge_Amount__c from UNITY_Service_Contract_Line_Items__r where RecordTypeId=:UNITY_Constants.SCLI_SERVICE_CHARGE_RECORDTYPE) from UNITY_Service_Contract__c where UNITY_IS_Active__c = true and  UNITY_Service_Contract__c.RecordTypeId =:UNITY_Constants.SC_SERVICE_REQUEST_RECORDTYPE and UNITY_Is_Pass_Through__c = true and Id in :customerSCIds]);
		System.debug(LoggingLevel.INFO,'<AK - UNITY_InvoiceTriggerHandler.setRelatedCustomerSC> : customerSCMap : '+customerSCMap);

    }
    
    // Update manual sharing with Contact.User
    private void updateManualSharing() {
        List<SObject> sobjects = new List<SObject>();
        List<SObject> sobjectsToDelete = new List<SObject>();
        List<Id> parentIds = new List<Id>();
        
        //retrieve the users associated to the contacts
        Map<Id,Id> contactIdUserIdMap = new Map<Id,Id>();
        List<Id> contactIds = new List<Id>();
        for(UNITY_Invoice__c invoice : (List<UNITY_Invoice__c>)Trigger.new) {
            UNITY_Invoice__c oldInvoice = (UNITY_Invoice__c)Trigger.oldMap.get(invoice.Id);
            if(invoice.UNITY_Shared_to_Contact__c != oldInvoice.UNITY_Shared_to_Contact__c)
                contactIds.add(invoice.UNITY_Shared_to_Contact__c);
        }
        
        if(!contactIds.isEmpty()){
            for(User user : [SELECT Id, ContactId FROM User 
                             WHERE ContactId IN:contactIds]) {
                if(user.ContactId != NULL) {                        
                    contactIdUserIdMap.put(user.ContactId, user.Id);   
                }    
            }
    
            system.debug('>>> contactIdUserIdMap'+contactIdUserIdMap);
            for(UNITY_Invoice__c invoiceNew : (List<UNITY_Invoice__c>)Trigger.new) {
                UNITY_Invoice__c invoiceOld = (UNITY_Invoice__c)Trigger.oldMap.get(invoiceNew.Id);
                if(invoiceNew.UNITY_Shared_to_Contact__c != invoiceOld.UNITY_Shared_to_Contact__c) {
                    if(invoiceNew.UNITY_Shared_to_Contact__c != null) {
                        sobjects.add(invoiceNew);
                        parentIds.add(contactIdUserIdMap.get(invoiceNew.UNITY_Shared_to_Contact__c));
                    }
                    if(invoiceOld.UNITY_Shared_to_Contact__c != null) {
                        sobjectsToDelete.add(invoiceOld);   
                    }
                } 
            }
		            
           // update the share object when the field UNITY_Shared_to_Contact__c change,
           // deleting the invalid share objects.
           UNITY_SharingUtil.manualShareDelete(sobjectsToDelete,UNITY_Invoice__Share.SObjectType);
            
           System.debug('creating manual sharing'+sobjects+parentIds);
           UNITY_SharingUtil.manualShareCreateReadWriteBulk(sobjects,parentIds,UNITY_Invoice__Share.SObjectType);
        }

    }
    
    // Push Invoice and all associated POs to SL
    private void pushInvoiceCompletedToSL(List<UNITY_Invoice__c> oldInvoices, List<UNITY_Invoice__c> invoices) {
        List<Id> invoicesFinalized = new List<Id>();
        List<Id> invoicesDisputed = new List<Id>();
        UNITY_Invoice__c oldInvoice,invoice;
        for(Integer i=0; i<invoices.size(); i++){
            oldInvoice = oldInvoices.get(i);
            invoice = invoices.get(i);
            if(oldInvoice.UNITY_Invoice_Status__c != UNITY_Constants.INV_FINALIZED && 
               invoice.UNITY_Invoice_Status__c == UNITY_Constants.INV_FINALIZED) {
                   invoicesFinalized.add(invoice.Id);
               }else
            if(oldInvoice.UNITY_Invoice_Status__c != invoice.UNITY_Invoice_Status__c && invoice.UNITY_Invoice_Status__c == 'Disputed'){
                invoicesDisputed.add(invoice.Id);
            }
        }
        if(!invoicesFinalized.isEmpty()){
            InvoiceValidation validate = new InvoiceValidation();
            validate = validateInvoices(invoicesFinalized);
            if(validate.valid && !System.isFuture() && !System.isBatch()){
                UNITY_MuleCalloutOperation.invokeCallOut(invoicesFinalized, UNITY_MuleSiteSettingUtils.INVOICE);
                // retrieve the po associated to the invoices to be pushed too.
                // /* Added to account for POs on the new invoice */
                Map<string,UNITY_General_Settings__c> generalSettings = UNITY_General_Settings__c.getAll();
                Set<String> delimitedInvoiceableStatuses = new Set<String>();
                UNITY_General_Settings__c generalSetting = generalSettings.get(UNITY_Constants.PO_INVOICEABLE_STATUSES);
                String POInvoiceableStatuses;
                if (generalSetting!=null){
                    POInvoiceableStatuses = generalSetting.UNITY_Value__c;
                }
                if (POInvoiceableStatuses!=null){
                    delimitedInvoiceableStatuses = new Set<String>(POInvoiceableStatuses.split(UNITY_Constants.PO_INVOICEABLE_STATUSES_DELIMITER));
                }
                //List<Id> poAssociatedToInvoices = UNITY_Utils.joiningByIdList([SELECT Id FROM ORDER WHERE (UNITY_Invoice__c IN :invoicesFinalized OR UNITY_Updated_Invoice__c IN :invoicesFinalized) AND UNITY_SL_Vendor_Voucher_Created__c = FALSE AND Status IN :delimitedInvoiceableStatuses]);
                //UNITY_MuleCalloutOperation.invokeCallOut(poAssociatedToInvoices,UNITY_MuleSiteSettingUtils.PURCHASE_ORDER);
            }else if(!Test.isRunningTest() && !validate.valid){
                Trigger.new[0].addError(validate.message);
            }
        }
        if(!invoicesDisputed.isEmpty()){ 
            InvoiceValidation validate = new InvoiceValidation();
            validate = validateInvoices(invoicesDisputed);
            if(validate.valid){
                UNITY_MuleCalloutOperation.invokeCallOut(invoicesDisputed, UNITY_MuleSiteSettingUtils.INVOICE);
            }else if(!Test.isRunningTest()){
                Trigger.new[0].addError(validate.message);
            }
        }
    }
    
    private InvoiceValidation validateInvoices(List<Id> invids){
        InvoiceValidation valid = new InvoiceValidation();
        Map<Id,UNITY_Invoice__c> invsMap = new Map<Id,UNITY_invoice__c>([SELECT Id,Name,UNITY_Customer__c,UNITY_Customer__r.Name,UNITY_Customer__r.MH_SL_CustID__c,UNITY_GL_Company__c,UNITY_Tax_Process_Result__c,
                                                                         (SELECT Id,Name,UNITY_Type__c,UNITY_Activity_Type__c,UNITY_GL_Company__c,UNITY_GL_Revenue_Account__c,UNITY_GL_Sub_Account__c,UNITY_GL_Tax_Account__c,UNITY_Sales_Tax__c FROM Invoice_Line_Items__r)
                                                                         FROM UNITY_Invoice__c WHERE Id IN :invids]);
        
        String message = '';
        Integer errCount = 0;
        for(UNITY_Invoice__c inv :invsMap.values()){
            if(String.isBlank(inv.UNITY_Customer__r.MH_SL_CustID__c)){
                valid.valid = false;
                errCount ++;
                valid.message += errCount + ': ' + inv.UNITY_Customer__r.Name + ' doesn\'t have an SL Customer Id. ';
            }
            if(String.isBlank(inv.UNITY_GL_Company__c)){
                valid.valid = false;
                errCount ++;
                valid.message += ' ' + errCount + '. ' + inv.Name + ' doesn\'t have a GL Company set. ';
            }
            if(String.isBlank(inv.UNITY_Tax_Process_Result__c) || !inv.UNITY_Tax_Process_Result__c.contains('Success')){
                valid.valid = false;
                errCount ++;
                valid.message += ' ' + errCount + '. ' + inv.Name + ' tax calculation not completed successfully. \n';
            }
            for(UNITY_Invoice_Line_Item__c ili :inv.Invoice_line_Items__r){
                if(String.isBlank(ili.UNITY_Type__c)){
                    valid.valid = false;
                    errCount ++;
                    valid.message += ' ' + errCount + '. ' + ili.Name + ' doesn\'t have an Line Type set. ';
                }
                if(String.isBlank(ili.UNITY_Activity_Type__c)){
                    valid.valid = false;
                    errCount ++;
                    valid.message += ' ' + errCount + '. ' + ili.Name + ' doesn\'t have an Activity Type set. ';
                }
                if(String.isBlank(ili.UNITY_GL_Company__c)){
                    valid.valid = false;
                    errCount ++;
                    valid.message += ' ' + errCount + '. ' + ili.Name + ' doesn\'t have a GL Company set. ';
                }
                if(String.isBlank(String.valueOf(ili.UNITY_Sales_Tax__c))){
                    valid.valid = false;
                    errCount ++;
                    valid.message += ' ' + errCount + '. ' + ili.Name + ' tax not calculated. ';
                }
                if(String.isBlank(ili.UNITY_GL_Sub_Account__c)){
                    valid.valid = false;
                    errCount ++;
                    valid.message += ' ' + errCount + '. ' + ili.Name + ' doesn\'t have a GL Sub Account set. ';
                }
                if(String.isBlank(ili.UNITY_GL_Revenue_Account__c)){
                    valid.valid = false;
                    errCount ++;
                    valid.message += ' ' + errCount + '. ' + ili.Name + ' doesn\'t have a GL Revenue Account set. ';
                }
                if(String.isBlank(ili.UNITY_GL_Tax_Account__c)){
                    valid.valid = false;
                    errCount ++;
                    valid.message += ' ' + errCount + '. ' + ili.Name + ' doesn\'t have a GL Tax Account set. ';
                }
            }
        }
        /*
        List<Order> orders = [SELECT Id,OrderNumber,UNITY_GL_Company__c,UNITY_GL_Segment__c,UNITY_GL_Segment_Account__c,UNITY_GL_Sub_Account__c,UNITY_Vendor__c,UNITY_Vendor__r.Name,UNITY_Vendor__r.SL_Vendor_ID__c,
                              (SELECT Id,OrderItemNumber,UNITY_Activity_Type__c,UNITY_GL_Cost_Account__c,UNITY_GL_Revenue_Account__c,UNITY_GL_Sub_Account__c,UNITY_GL_Tax_Account__c,UNITY_Type__c FROM OrderItems)
                              FROM Order WHERE UNITY_Invoice__c IN :invids];
		*/
        Map<string,UNITY_General_Settings__c> generalSettings = UNITY_General_Settings__c.getAll();
        Set<String> delimitedInvoiceableStatuses = new Set<String>();
        UNITY_General_Settings__c generalSetting = generalSettings.get(UNITY_Constants.PO_INVOICEABLE_STATUSES);
        String POInvoiceableStatuses;
        if (generalSetting!=null){
            POInvoiceableStatuses = generalSetting.UNITY_Value__c;
        }
        if (POInvoiceableStatuses!=null){
            delimitedInvoiceableStatuses = new Set<String>(POInvoiceableStatuses.split(UNITY_Constants.PO_INVOICEABLE_STATUSES_DELIMITER));
        }
        List<Order> orders = [SELECT Id,OrderNumber,UNITY_GL_Company__c,UNITY_GL_Segment__c,UNITY_GL_Segment_Account__c,UNITY_GL_Sub_Account__c,UNITY_Vendor__c,UNITY_Vendor__r.Name,UNITY_Vendor__r.SL_Vendor_ID__c,
                              (
                                  SELECT Id,OrderItemNumber,UNITY_Activity_Type__c,UNITY_GL_Cost_Account__c,UNITY_GL_Revenue_Account__c,UNITY_GL_Sub_Account__c,UNITY_GL_Tax_Account__c,UNITY_Type__c FROM OrderItems
                                  WHERE PriceBookEntry.Product2.Name != 'Vendor Service Fee' AND UNITY_Type__c != 'Non Billable' AND UNITY_Not_Billable__c = FALSE 
                              )
                              FROM Order WHERE UNITY_Invoice__c IN :invids
                              AND IsDeleted = FALSE
                              AND(
                                  RecordTypeId =: UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE 
                                  OR 
                                  RecordTypeId =: UNITY_Constants.PART_SOURCING_PURCHASE_ORDER_RECORDTYPE
                              )
                              AND Status IN :delimitedInvoiceableStatuses
                              AND FSO__WorkOrder__r.Status != 'Canceled'];
        for(Order o :orders){
            if(String.isBlank(o.UNITY_GL_Company__c)){
                valid.valid = false;
                errCount ++;
                valid.message += ' ' + errCount + '. ' + o.OrderNumber + ' doesn\'t have a GL Company set. ';
            }
            if(String.isBlank(o.UNITY_GL_Segment__c)){
                valid.valid = false;
                errCount ++;
                valid.message += ' ' + errCount + '. ' + o.OrderNumber + ' doesn\'t have a GL Segment set. ';
            }
            if(String.isBlank(o.UNITY_GL_Segment_Account__c)){
                valid.valid = false;
                errCount ++;
                valid.message += ' ' + errCount + '. ' + o.OrderNumber + ' doesn\'t have a GL Segment Account set. ';
            }
            if(String.isBlank(o.UNITY_GL_Sub_Account__c)){
                valid.valid = false;
                errCount ++;
                valid.message += ' ' + errCount + '. ' + o.OrderNumber + ' doesn\'t have a GL Sub Account set. ';
            }
            if(String.isBlank(o.UNITY_Vendor__r.SL_Vendor_ID__c)){
                valid.valid = false;
                errCount ++;
                valid.message += ' ' + errCount + '. ' + o.UNITY_Vendor__r.Name + ' doesn\'t have an SL Vendor Id. ';
            }
            for(OrderItem oi :o.OrderItems){
                if(String.isBlank(oi.UNITY_Type__c)){
                    valid.valid = false;
                    errCount ++;
                    valid.message += ' ' + errCount + '. ' + oi.OrderItemNumber + ' doesn\'t have an Line Type set. ';
                }
                if(String.isBlank(oi.UNITY_Activity_Type__c)){
                    valid.valid = false;
                    errCount ++;
                    valid.message += ' ' + errCount + '. ' + oi.OrderItemNumber + ' doesn\'t have an Activity Type set. ';
                }
                if(String.isBlank(oi.UNITY_GL_Revenue_Account__c)){
                    valid.valid = false;
                    errCount ++;
                    valid.message += ' ' + errCount + '. ' + oi.OrderItemNumber + ' doesn\'t have an GL Revenue Account set. ';
                }
                if(String.isBlank(oi.UNITY_GL_Cost_Account__c)){
                    valid.valid = false;
                    errCount ++;
                    valid.message += ' ' + errCount + '. ' + oi.OrderItemNumber + ' doesn\'t have an GL Cost Account set. ';
                }
                if(String.isBlank(oi.UNITY_GL_Tax_Account__c)){
                    valid.valid = false;
                    errCount ++;
                    valid.message += ' ' + errCount + '. ' + oi.OrderItemNumber + ' doesn\'t have an GL Tax Account set. ';
                }
            }
        }
        
        return valid;
    }
    
    public class InvoiceValidation{
        public Boolean valid {get;set;}
        public String message {get;set;}
        public InvoiceValidation(){
            valid = true;
            message = '';
        }
    }
}