global class UNITY_VendorScoreCalculationWO_Schedule implements Schedulable{
    global void execute(SchedulableContext SC) {
        // calls excecuteBatch to intiate the process
        // calculate vendor score based on work order score factors
        Database.executeBatch(new UNITY_WorkOrderVendorScoreBatch(),200);
    }       
}