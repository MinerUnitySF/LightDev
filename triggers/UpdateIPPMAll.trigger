trigger UpdateIPPMAll on SVMXC__Service_Order__c (after insert, after update) {
    if(Trigger.new.size()>0){  // watch for batch size
        UpdateIPPM.updateIPPMDate(Trigger.new);
    }
}