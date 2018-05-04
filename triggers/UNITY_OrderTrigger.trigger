trigger UNITY_OrderTrigger on Order (before insert,after insert, before update, after update) {

    UNITY_TriggerFactory.createAndExecuteHandler(UNITY_OrderTriggerHandler.class);
    //This line was added by Izay to support work order status change from order status 
    UNITY_TriggerFactory.createAndExecuteHandler(UNITY_OrderTriggerHandler_Miner.class);
}