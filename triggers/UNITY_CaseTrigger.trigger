/*------------------------------------------------------------
Name:           UNITY_CaseTrigger 
Author:         SFDC UNITY Team
Company:        Miner
Description:    This trigger call the UNITY processes on cases 
=====================================================
Changelog
=====================================================
Developer:      Izay Ramos
Description:    Added call to set business unit on case before any unity code executes
Date:           1/20/2016
=====================================================
------------------------------------------------------------*/
trigger UNITY_CaseTrigger on Case (before insert, after insert, before update, after update) {
    //Izay: Added to populate business unit before any unity process runs
    if(Trigger.isInsert && Trigger.isBefore){
        UNITY_CaseTriggerHandler_Miner.setCaseBusinessUnitFromUserBusinessUnit(Trigger.new);
    }
    if(Trigger.isUpdate && Trigger.isBefore){
        //Clay: Added to handle work order agent matching to case.
        //send the case to the casetriggerhandlerminer
        UNITY_CaseTriggerHandler_Miner.updateAgentonWOs(Trigger.newMap, Trigger.oldMap);

    }



    
    UNITY_TriggerFactory.createAndExecuteHandler(UNITY_CaseHandler.class);
    /*if(Trigger.isInsert){
        if(Trigger.isBefore){
            UNITY_CaseUtilities.onBeforeInsert(Trigger.New);
        }
    }else if(Trigger.isUpdate){
        if(Trigger.isBefore){
            UNITY_CaseUtilities.onBeforeUpdate(Trigger.oldMap,Trigger.New, Trigger.newMap);
        }
    }*/

    
}