/*
 *   @programer:    Rodrigo Birriel
 *   @date:         05/30/2016      
 */
global class UNITY_WorkOrderVendorScoreBatch implements Database.Batchable<sObject>, Database.Stateful{

    String query      ='SELECT {FIELDS} FROM WorkOrder WHERE {WHERE}';
    
    String fields     =' Id, ' 
                      +' Status,'
                      +' RecordTypeId,'
                      +' UNITY_Trade__c,'
                      +' RecordType.Name,'
                      +' SFPS_FS_LastCheckOut__c,'
                      +' UNITY_Score_Factor_1__c,'
                      +' UNITY_Score_Factor_2__c,'
                      +' UNITY_Score_Factor_3__c,'
                      +' UNITY_Score_Factor_4__c,'
                      +' UNITY_Score_Factor_5__c,'
                      +' UNITY_Assigned_Vendor__c';

    //String conditions =' (SFPS_FS_OverallStatus__c = \'Completed\') AND (UNITY_Assigned_Vendor__c <> null) AND (UNITY_Trade__c <> null) ';
    String conditions =' (SFPS_FS_OverallStatus__c = \'Completed\') ';

    private Map<String,UNITY_ScoreHandler.VendorTradeHandler> vendorIdTradeId_vendorTradeHelper = new Map<String,UNITY_ScoreHandler.VendorTradeHandler>();
    private static Map<string,UNITY_Job_Settings__c> jobSettings = UNITY_Job_Settings__c.getAll();

    DateTime tBegin, tEnd;

    // Batch Constructor
    global UNITY_WorkOrderVendorScoreBatch() {
      String sDelayInDays, sPeriodInDays;
      Integer nDelayInDays, nPeriodInDays;

      if (jobSettings.get(UNITY_Constants.VendorScoreCalculation_DelayInDays_WO_KEY) != NULL)
        sDelayInDays = jobSettings.get(UNITY_Constants.VendorScoreCalculation_DelayInDays_WO_KEY).Value__c;
      if (sDelayInDays == null) 
        sDelayInDays = UNITY_Constants.VendorScoreCalculation_DelayInDays_DEFAULT;

      if (jobSettings.get(UNITY_Constants.VendorScoreCalculation_PeriodInDays_WO_KEY) != NULL)
        sPeriodInDays = jobSettings.get(UNITY_Constants.VendorScoreCalculation_PeriodInDays_WO_KEY).Value__c;
      if (sPeriodInDays == null) 
        sPeriodInDays = UNITY_Constants.VendorScoreCalculation_PeriodInDays_DEFAULT;

      nDelayInDays = Integer.valueOf(sDelayInDays);
      nPeriodInDays = Integer.valueOf(sPeriodInDays);

      Date today = DateTime.now().date();
      tEnd = today.addDays(- nDelayInDays); 
      tBegin = tEnd.addDays(- nPeriodInDays);
    }
    
    // Start Method
    global Database.QueryLocator start(Database.BatchableContext BC){      
        String sBegin = tBegin.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
        String sEnd = tEnd.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
        String sLogMsg = 'Job Started - Calculating WO Factors - From ' + sBegin + ' to ' + sEnd;
        UNITY_Utils.insertJobLog(UNITY_Constants.JOB_LOG_SEVERITY.INFO, 'VendorScoreCalcuation-WO Factors', 'Started', sLogMsg);

        if (conditions != '')
          conditions ='((SFPS_FS_LastCheckOut__c >= ' + sBegin + ' AND SFPS_FS_LastCheckOut__c < ' + sEnd + ') AND '  + conditions + ')';
        else
          conditions ='(SFPS_FS_LastCheckOut__c >= ' + sBegin + ' AND SFPS_FS_LastCheckOut__c < ' + sEnd + ')';
        
        // add fields and conditions 
        query =  query.replace('{FIELDS}',fields).replace('{WHERE}',conditions);
        
        return Database.getQueryLocator(query);
    }
    
    // Execute Logic
    global void execute(Database.BatchableContext BC, List<sObject>scope){
        UNITY_Utils.insertJobLog(UNITY_Constants.JOB_LOG_SEVERITY.INFO, 'VendorScoreCalcuation-WO Factors', 'In progress', 'Calculation In Progress...');

        Set<String> accountId_tradeId = UNITY_ScoreHandler.execute( WorkOrder.getSObjectType() , scope, this.vendorIdTradeId_vendorTradeHelper);
        
        List<UNITY_Vendor_Trade__c> aux_vt =  new List<UNITY_Vendor_Trade__c>();
        for(String key :accountId_tradeId){
          if(this.vendorIdTradeId_vendorTradeHelper.get(key)!=null){
            this.vendorIdTradeId_vendorTradeHelper.get(key).calculate();
            aux_vt.add(this.vendorIdTradeId_vendorTradeHelper.get(key).vendorTrade);
          }
        }
        update aux_vt;
        
    }
    
    global void finish(Database.BatchableContext BC){
/*
        List<UNITY_Vendor_Trade__c> aux_vt =  new List<UNITY_Vendor_Trade__c>();

        for(UNITY_ScoreHandler.VendorTradeHandler VTHandler :this.vendorIdTradeId_vendorTradeHelper.values()){
            VTHandler.calculate();
            aux_vt.add(VTHandler.vendorTrade);
        }

        update aux_vt;*/
        UNITY_Utils.insertJobLog(UNITY_Constants.JOB_LOG_SEVERITY.INFO, 'VendorScoreCalcuation-WO Factors', 'Completed', 'Calculation Completed');

    }
}