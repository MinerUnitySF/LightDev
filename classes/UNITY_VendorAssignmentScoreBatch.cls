global class UNITY_VendorAssignmentScoreBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    String query      ='SELECT {FIELDS} FROM UNITY_Vendor_Assignment__c WHERE {WHERE}';
    String fields     =' Id, ' 
                      +' Trade__c,'
                      +' Status__c,'
                      +' Vendor__c,'
                      +' Request_Type__c,'
                      +' UNITY_Priority__c,'
                      +' UNITY_Score_Factor_1__c,'
                      +' UNITY_Score_Factor_2__c';
    //String conditions =' (Last_Assigned__c >= THIS_MONTH AND Vendor__c = \'001R0000011QYrE\')';
    //String conditions = ' (Vendor__c = \'001R0000011QYrE\')';
    String conditions = '';
    
    
    private Map<String,UNITY_ScoreHandler.VendorTradeHandler> vendorIdTradeId_vendorTradeHelper = new Map<String,UNITY_ScoreHandler.VendorTradeHandler>();
    private static Map<string,UNITY_Job_Settings__c> jobSettings = UNITY_Job_Settings__c.getAll();

    DateTime tBegin, tEnd;

    global UNITY_VendorAssignmentScoreBatch() {
        String sDelayInDays, sPeriodInDays;
        Integer nDelayInDays, nPeriodInDays;

        if (jobSettings.get(UNITY_Constants.VendorScoreCalculation_DelayInDays_VA_KEY) != NULL)
            sDelayInDays = jobSettings.get(UNITY_Constants.VendorScoreCalculation_DelayInDays_VA_KEY).Value__c;
        if (sDelayInDays == null) 
            sDelayInDays = UNITY_Constants.VendorScoreCalculation_DelayInDays_DEFAULT;

        if (jobSettings.get(UNITY_Constants.VendorScoreCalculation_PeriodInDays_VA_KEY) != NULL)
            sPeriodInDays = jobSettings.get(UNITY_Constants.VendorScoreCalculation_PeriodInDays_VA_KEY).Value__c;
        if (sPeriodInDays == null) 
            sPeriodInDays = UNITY_Constants.VendorScoreCalculation_PeriodInDays_DEFAULT;

        nDelayInDays = Integer.valueOf(sDelayInDays);
        nPeriodInDays = Integer.valueOf(sPeriodInDays);

        Date today = DateTime.now().date();
        tEnd = today.addDays(- nDelayInDays); 
        tBegin = tEnd.addDays(- nPeriodInDays);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String sBegin = tBegin.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
        String sEnd = tEnd.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
        String sLogMsg = 'Job Started - Calculating VA Factors - From ' + sBegin + ' to ' + sEnd;
        UNITY_Utils.insertJobLog(UNITY_Constants.JOB_LOG_SEVERITY.INFO, 'VendorScoreCalcuation-VA Factors', 'Started', sLogMsg);

        if (conditions != '')
            conditions ='((Last_Assigned__c >= ' + sBegin + ' AND Last_Assigned__c < ' + sEnd + ') AND '  + conditions + ')';
        else
            conditions ='(Last_Assigned__c >= ' + sBegin + ' AND Last_Assigned__c < ' + sEnd + ')';
        
        // add fields and conditions 
        query =  query.replace('{FIELDS}',fields).replace('{WHERE}',conditions);
        
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {

        UNITY_Utils.insertJobLog(UNITY_Constants.JOB_LOG_SEVERITY.INFO, 'VendorScoreCalcuation-VA Factors', 'In progress', 'Calculation In Progress...');

        Set<String> accountId_tradeId = UNITY_ScoreHandler.execute( UNITY_Vendor_Assignment__c.getSObjectType() , scope, this.vendorIdTradeId_vendorTradeHelper);
        List<UNITY_Vendor_Trade__c> aux_vt =  new List<UNITY_Vendor_Trade__c>();

        for(String key :accountId_tradeId){
            if(this.vendorIdTradeId_vendorTradeHelper.get(key)!=null){
                this.vendorIdTradeId_vendorTradeHelper.get(key).calculate();
                aux_vt.add(this.vendorIdTradeId_vendorTradeHelper.get(key).vendorTrade);
            }
        }
        update aux_vt;
    }
    
    global void finish(Database.BatchableContext BC) {
        UNITY_Utils.insertJobLog(UNITY_Constants.JOB_LOG_SEVERITY.INFO, 'VendorScoreCalcuation-VA Factors', 'Completed', 'Calculation Completed');
    }
    
}