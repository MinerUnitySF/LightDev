global class UNITY_ScheduleInsertWOLItiJunction implements Schedulable
{
    global void execute(SchedulableContext sc)    {
        
        UNITYPM_PopulateJunctionObjFromWOLI jobUpsert = new UNITYPM_PopulateJunctionObjFromWOLI ();
        Integer batchSize = 100;
        database.executebatch(jobUpsert,1);
    }
   
}