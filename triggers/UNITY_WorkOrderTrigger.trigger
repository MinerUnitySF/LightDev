/*------------------------------------------------------------
Name:           UNITY_WorkOrderTrigger 
Author:         Dan nakonieczny
Company:        Miner
Description:    This trigger updates parent(Case) status by calling updateStatus() method updates status field by assign least status of its workorders
History:
03/21/2016      Krishna Kamineni Added if statement.
=====================================================
Changelog
=====================================================
Developer:      Izay Ramos
Description:    Added call to intercompany transfer sharing process
Date:           1/20/2016
=====================================================
------------------------------------------------------------*/
trigger UNITY_WorkOrderTrigger on WorkOrder (after insert, after update, after delete, before insert, before update) {
    system.debug(LoggingLevel.INFO, '****** UNITY_WorkOrderTrigger');
    UNITY_TriggerFactory.createAndExecuteHandler(UNITY_WorkOrderTriggerHandler.class);

    /*
    Hao - 5/3 Move Update Case Status to UNITY_WorkOrderTriggerHandler
    if(Trigger.isInsert){
        if(Trigger.isAfter){
            UNITY_UpdateCaseStatus.onAfterInsert(Trigger.New);
        }
    }
    else if(Trigger.isUpdate){
        if(Trigger.isAfter){
            UNITY_UpdateCaseStatus.onAfterUpdate(Trigger.New,Trigger.oldMap);
        }
    }
    */
    
    UNITY_TriggerFactory.createAndExecuteHandler(UNITY_WorkOrderTriggerHandler_Miner.class);

    //Izay: Added to call the intercompany transfer process sharing after all UNITY code runs.
    if(Trigger.isBefore && Trigger.isUpdate && MSPFS_WorkOrderHandler.handleIntercompanyTransferOnce()){
        MSPFS_WorkOrderHandler.handleIntercompanyTransferSharing(Trigger.new,Trigger.oldMap);
    }else if(Trigger.isAfter && Trigger.isInsert && MSPFS_WorkOrderHandler.handleIntercompanyTransferOnce()){
        MSPFS_WorkOrderHandler.handleIntercompanyTransferSharing(Trigger.new,null);
    }
    
}