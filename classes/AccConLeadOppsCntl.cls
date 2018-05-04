public class AccConLeadOppsCntl {
    
     public List<String> results {get;set;}
     public String selectedObject { get; set; }
     public String selectedField { get; set; }
        
     public AccConLeadOppsCntl(){
         results = new List<String>();
     }
       
    public SelectOption[] getObjectOptions() {
        SelectOption[] results = new SelectOption[] { new SelectOption('','-- none --') };
        for(SObjectType sType: Schema.getGlobalDescribe().values()) {
            DescribeSObjectResult res = sType.getDescribe();
            String objName = res.getName();
            if (objName == 'Account' || objName == 'Lead' || objName == 'Contact' || objName == 'Opportunity' )
            results.add(new SelectOption(res.getName(), res.getLabel()));
        }
        return results;
    }
    
    public List<String> getsObjectFields() {
       results  = new List<String>();
      if (selectedObject != null){  
        for(SObjectField sField: Schema.getGlobalDescribe().get(selectedObject).getDescribe().fields.getMap().values()) {
            DescribeFieldResult res = sField.getDescribe();
            results.add(res.getLabel());
        }
       }
        return results;
    }

}