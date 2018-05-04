global class UNITY_VendorScoreCalculationVA_Schedule implements Schedulable{
    global void execute(SchedulableContext SC) {
        // calls excecuteBatch to intiate the process
        // calculate vendor score based on vendor assignment score factors
        Database.executeBatch(new UNITY_VendorAssignmentScoreBatch(),200);
    }       
}