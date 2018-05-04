trigger InvoiceDetailToWorkOrderDetail on MH_Invoice_Details__c (after insert) {
    Map<Id,Id> woLineTpoInvLineMap = new Map<Id,Id>();
    for(MH_Invoice_Details__c line :Trigger.new){
        if(String.isNotBlank(line.Work_Detail__c)){
            woLineTpoInvLineMap.put(line.Work_Detail__c,line.Id);
        }
    }
    if(woLineTpoInvLineMap.keySet().size() > 0){
        List<SVMXC__Service_Order_Line__c> woLines = [SELECT Id,Invoice_Detail__c,Invoiced__c FROM SVMXC__Service_Order_Line__c WHERE Id IN :woLineTpoInvLineMap.keySet()];
        if(woLines.size() > 0){
            for(SVMXC__Service_Order_Line__c wol :woLines){
                if(woLineTpoInvLineMap.containsKey(wol.Id)){
                    wol.Invoice_Detail__c = woLineTpoInvLineMap.get(wol.Id);
                    wol.Invoiced__c = true;
                }
            }
            update woLines;
        }
    }
}