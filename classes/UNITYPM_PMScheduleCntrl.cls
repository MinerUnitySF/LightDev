public class UNITYPM_PMScheduleCntrl {
    public List<Account> customer { get;set;}
    public List<String> skillBroad { get;set;}
    public List<String> skillGroup { get;set;}
    public List<String> skillType { get;set;}
    public String selectedAccVal{get;set;}
    public String selectedSkillBoardVal{get;set;}
    public String selectedSkillTypeVal{get;set;}
    public String selectedSkillSubTypeVal{get;set;}
    
    
    public UNITYPM_PMScheduleCntrl(){
        
    }
    
    public List<Account> getCustomers(){
        customer = [SELECT ID, Name,Type, Account_Status__c 
               FROM Account 
               WHERE Type = 'Customer' 
               AND Account_Status__c = 'Active'];
               
        return customer;
    }
    
    public List<SelectOption> getskillBroad () {
         List<SelectOption> optns = new List<Selectoption>();
         List<string> skillBroadList = new List<string>{'Docks', 'Doors', 'Planned Maintenance', 'General Maintenance','Glass'}; 
         for (string skill: skillBroadList) {
            optns.add(new selectOption(skill, skill));
         }  
                             
         return optns;
    }
     public List<SelectOption> getskillGroup () {
         List<SelectOption> optns = new List<Selectoption>();
         List<string> skillGroupList = new List<string>{'Loading Docks', 'Planned Maintenance', 'Specialty Doors', 'Glass Installation/Repair','Interior/Exterior Man Doors'}; 
         for (string skill: skillGroupList) {
            optns.add(new selectOption(skill, skill));
         }  
                             
         return optns;
    }
     public List<SelectOption> getskillType () {
         List<SelectOption> optns = new List<Selectoption>();
         List<string> skillTypeList = new List<string>{'Dock Equipment','Flooring,', 'Forklift','Manual Revolving Door','PM','Battery'};
         for (string skill: skillTypeList) {
            optns.add(new selectOption(skill, skill));
         }  
                             
         return optns;
    }
      public List<SelectOption> getskillSubType () {
         List<SelectOption> optns = new List<Selectoption>();
         List<string> skillSubTypeList = new List<string>{'Automatic Sliding Door','Dock Grates,', 'Dock Ladder','Dock leveler','Security Enclosures','Sectional Door'};
         for (string skill: skillSubTypeList) {
            optns.add(new selectOption(skill, skill));
         }  
                             
         return optns;
    }
}