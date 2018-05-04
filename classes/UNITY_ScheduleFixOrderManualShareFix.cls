global class UNITY_ScheduleFixOrderManualShareFix implements Schedulable
{
    global void execute(SchedulableContext sc)    {
        
        UNITY_FixOrderManualSharing fixOrderShare = new UNITY_FixOrderManualSharing ();
        Integer batchSize = 30;
        database.executebatch(fixOrderShare,30);
    }
   
}