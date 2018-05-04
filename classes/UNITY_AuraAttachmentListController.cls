public class UNITY_AuraAttachmentListController {

    @AuraEnabled
    public static UNITYAttachmentWrapper getAttachmentWrapper(Id recordId) {
        UNITYAttachmentWrapper attachmentWrapper = new UNITYAttachmentWrapper();
        attachmentWrapper.attachmentList = new List<UNITY_Attachment__c>();
        attachmentWrapper.isCase = false;
        
        system.debug('@@@getAttachments recordId:'+recordId);

        if (isCaseObject(recordId))       {
        	attachmentWrapper.attachmentList = [Select Id, Name, UNITY_Type__c, Work_Order__r.WorkOrderNumber, Work_Order__r.Id,CreatedDate, CreatedById From UNITY_Attachment__c WHERE Work_Order__r.CaseId = :recordId];
			attachmentWrapper.isCase = true;            
        }
        else 
            attachmentWrapper.attachmentList= [Select Id, Name, UNITY_Type__c, Work_Order__r.WorkOrderNumber, Work_Order__r.Id, CreatedDate, CreatedById From UNITY_Attachment__c WHERE Work_Order__c = :recordId];
        
        system.debug('@@@getAttachments attachmentWrapper:'+attachmentWrapper);
        return attachmentWrapper;
    }
    
    private static boolean isCaseObject(Id recordId){
		//determine if this a Case or WO Id
        Map<String,String> keys = new Map<String,String>();
        Map<String,Schema.SobjectType> describe = Schema.getGlobalDescribe();
        for(String s:describe.keyset())
        	keys.put(describe.get(s).getDescribe().getKeyPrefix(),s);
        
		if (keys.get(String.valueOf(recordId).substring(0,3)) == 'Case')
            return true;
        else
            return false;
    }
    
    public class UNITYAttachmentWrapper
    {
        @AuraEnabled
        public List<UNITY_Attachment__c> attachmentList {get;set;}
        @AuraEnabled
        public Boolean isCase {get;set;}
    }
}