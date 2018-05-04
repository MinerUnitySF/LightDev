global class UNITYPM_UpdateCaseWorkDescriptionCtrl {
     public String workDescription {get;set;}
     public List<Case> cases {get;set;}
     private Set<Id> cIds = new Set<Id>();
     public Boolean caseUpdateDescription {get;set;}
     public String caseNoUpdateDescriptionMsg {get;set;}
    
    public UNITYPM_UpdateCaseWorkDescriptionCtrl (ApexPages.StandardController controller){
         String strIds = ApexPages.currentPage().getParameters().get('ids');
         caseUpdateDescription = true;
         caseNoUpdateDescriptionMsg ='';
         List<String> tempIDs = strIds.split('\\,');
         
         if ( tempIDs.size() > 0){
              cases = [SELECT ID, UNITY_Work_Description__c, Status, RecordType.Name FROM Case WHERE ID IN:tempIDs];
              
              for (case c :cases){
                 
                  if (c.RecordType.ID == UNITY_Constants.CASE_PROGRAM_CASE_RECORDTYPE){
                      caseUpdateDescription = false;
                      caseNoUpdateDescriptionMsg = 'Case work description CAN NOT be updated for Program Case';
                      break;
                  }
              }
            if (caseUpdateDescription == false )  
                cases = new List<case>();
           
         }
    }
    
    
    public PageReference  doUpdate(){
        List<Case> updateCases = new List <Case>();
        
        for (Case c : cases){
            c.UNITY_Work_Description__c = workDescription;
            updateCases.add(c);
        }
        
        try{
            if ( updateCases.size() >0)
                  update updateCases; 
        }
        catch (Exception ex){
            
        }
        return null;
    }
}