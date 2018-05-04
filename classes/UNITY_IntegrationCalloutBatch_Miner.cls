global class UNITY_IntegrationCalloutBatch_Miner implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful{
    global String query {get; set;}
    global UNITY_Constants.IntegrationType OBJECT_TYPE {get; set;}
    
    /**Class Constructor
     *@param objType - UNITY_Constants.IntegrationType: The onject type as specified on the enum UNITY_Constants.IntegrationType
	*/
    public UNITY_IntegrationCalloutBatch_Miner(UNITY_Constants.IntegrationType objType){
        OBJECT_TYPE = objType;
    }
    
    //Batch start method
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
    
    //Batch execute method
    global void execute(Database.BatchableContext BC, List<SObject> scope){
        System.debug('#####Izay: In UNITY_IntegrationCalloutBatch_Miner.execute');
        String myType = '';
        if(OBJECT_TYPE == UNITY_Constants.IntegrationType.CUSTOMER){
            myType = UNITY_MuleSiteSettingUtils.CUSTOMER;
        }else if(OBJECT_TYPE == UNITY_Constants.IntegrationType.VENDOR){
            myType = UNITY_MuleSiteSettingUtils.VENDOR;
        }else if(OBJECT_TYPE == UNITY_Constants.IntegrationType.INVOICE){
            myType = UNITY_MuleSiteSettingUtils.INVOICE;
        }else if(OBJECT_TYPE == UNITY_Constants.IntegrationType.PURCHASE_ORDER){
            myType = UNITY_MuleSiteSettingUtils.PURCHASE_ORDER;
        }else if(OBJECT_TYPE == UNITY_Constants.IntegrationType.CASE1){
            myType = UNITY_MuleSiteSettingUtils.CASE1;
        }else if(OBJECT_TYPE == UNITY_Constants.IntegrationType.CASE_COMMENT){
            myType = UNITY_MuleSiteSettingUtils.CASE_COMMENT;
        }
        System.debug('#####Izay: myType = ' + myType);
        List<Id> recordIds = new List<Id>();
        for(SObject obj :scope){
            recordIds.add((Id)obj.get('Id'));
            if(OBJECT_TYPE == UNITY_Constants.IntegrationType.INVOICE || OBJECT_TYPE == UNITY_Constants.IntegrationType.PURCHASE_ORDER){
                obj.put('UNITY_SL_Processed__c',true);
            }
        }
        if(!recordIds.isEmpty()){
            System.debug('#####Izay: Calling UNITY_MuleCalloutOperation.invokeCallOut on Ids [' + recordIds + ']');
            UNITY_MuleCalloutOperation.invokeCallOut(recordIds, myType);
            if(OBJECT_TYPE == UNITY_Constants.IntegrationType.INVOICE || OBJECT_TYPE == UNITY_Constants.IntegrationType.PURCHASE_ORDER){
                Database.update(scope);
            }
        }
    }
    
    //Batch finish method
    global void finish(Database.BatchableContext BC){
    	AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed,
                          TotalJobItems, CreatedBy.Email, ExtendedStatus
                          FROM AsyncApexJob WHERE Id = :bc.getJobId()];        
        if(a.Status == 'Completed' && a.NumberOfErrors > 0 || Test.isRunningTest()){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            // Send the email to the job submitter
            String[] toAddresses = new String[] {a.CreatedBy.Email};
            mail.setToAddresses(toAddresses);
            mail.setSenderDisplayName('Integration Callout Batch: ' + OBJECT_TYPE);
            mail.setSubject('Batch Status: ' + a.Status);
            mail.setHTMLBody('<p>The batch Apex job, <strong>UNITY_IntegrationCalloutBatch_Miner</strong> completed.</p>' + 
                '<p>Number of Batches: ' + a.TotalJobItems + '</p>' + 
                '<p>Number of Errors: '+ a.NumberOfErrors + '</p>' +  
                '<p>ExtendedStatus: ' + a.ExtendedStatus);
            // Add your attachment to the email.
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }
    
}