/**This trigger updates the lead status and contacted time stamp when a task related to a lead is completed
** @programer: Izay Ramos-Irizarry
** @version: 1.0
** @date: 8/26/2015
*/
trigger TaskUpdateLeadStatus  on Task (after insert, after update) {
    
    Set<Id> lids = new Set<Id>();//Hold lead ids
    //For each task...
    for(Task t :Trigger.new){
        if(String.isNotBlank(t.WhoId)){
            //Get the object type for the task WhoId
            Schema.SObjectType sobjectType = t.WhoId.getSObjectType();
            String sobjectName = sobjectType.getDescribe().getName();
            //If the WhoId is a Lead
            if(sobjectName == 'Lead' && t.Status == 'Completed'){
                lids.add(t.WhoId);//Add to lids list
            }//End if leads
        }
    }//End for task
    //If there are lids...
    if(lids.size() > 0){
    	//Query the lead records
        List<Lead> leads = [SELECT Id,Status,Date_Time_Contacted__c FROM Lead WHERE Id IN :lids];
        //For each lead...
        for(Lead l :leads){
            //if the lead status is New or lead status is Assigned
            if(l.Status == 'New' || l.Status == 'Assigned'){
                l.Status = 'Contacted';	//Set lead status
                l.Date_Time_Contacted__c = DateTime.now(); //Set Date Time Contacted time stamp
            }//End if new or assigned
        }//End for leads
        //Try catch block
        try{
            update leads;//Update the leads
        }catch(Exception e){
            System.debug(e.getMessage());
        }//End try catch
        
    }//End if lids
    
}