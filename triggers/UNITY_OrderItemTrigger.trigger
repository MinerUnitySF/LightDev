trigger UNITY_OrderItemTrigger on OrderItem (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {

    UNITY_TriggerFactory.createAndExecuteHandler(UNITY_OrderItemHandler.class);
    //Izay: Added line to call the Miner trigger handler
    UNITY_TriggerFactory.createAndExecuteHandler(UNITY_OrderItemTriggerHandler_Miner.class);
    
}