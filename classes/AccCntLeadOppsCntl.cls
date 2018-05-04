public class AccCntLeadOppsCntl {
    
     public List<String> results {get;set;}
     public String selectedObject { get; set; }
     public String selectedField { get; set; }
     public Integer numberOfFieds {get;set;}
     
     public AccCntLeadOppsCntl(){
         results = new List<String>();
         numberOfFieds= 0;
     }
    
    //Getter method: getObjectOptions
    //return value: Select Option Array
    //Populate drop down list from custom metadata type 
    public SelectOption[] getObjectOptions() {
        //read from custom metadata list of sObject name to add to the list
        List_of_sObject__mdt [] sobjList = [SELECT sObjectType__c FROM List_of_sObject__mdt];
        List<String> listOfObj = new List<String>();
         for(List_of_sObject__mdt mdt :sobjList){
           listOfObj.add(mdt.sObjectType__c);
        }
        SelectOption[] results = new SelectOption[] { new SelectOption('','-- none --') };
        
        //Populate array for select option
        for(SObjectType sType: Schema.getGlobalDescribe().values()) {
            DescribeSObjectResult res = sType.getDescribe();
            String objName = res.getName();
            
            if (listOfObj.contains(objName))
               results.add(new SelectOption(res.getName(), res.getLabel()));
        }
        return results;
    }
    
    //Getter method: getsObjectFields
    //return value: List of string
    //Return list of the fields for selected object from drop down 
    public List<String> getsObjectFields() {
    //set default value
       results  = new List<String>();
       numberOfFieds = 0;
       
      if (selectedObject != null){  
        for(SObjectField sField: Schema.getGlobalDescribe().get(selectedObject).getDescribe().fields.getMap().values()) {
            DescribeFieldResult res = sField.getDescribe();
            results.add(res.getLabel());
         }
       }
       
       if ( results.size() >0){
           results.sort();
           numberOfFieds = results.size();
       }
           
        return results;
    }

}