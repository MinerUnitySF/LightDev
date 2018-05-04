public with sharing class FlexxApplicationScorecardCtrl extends genesis.ApplicationWizardBaseClass{
    
    public Double total {get; set;}
    public List<PieWedgeData> pieData {set;get;}
    public List<PieWedgeData> pieData2 {set;get;}
    public List<genesis__Application_s_Scorecard__c> scorecardList {get; set;}
    
    public FlexxApplicationScorecardCtrl(ApexPages.StandardController controller) {
       super(controller);
       this.application = (genesis__Applications__c)controller.getRecord();
       scorecardList = [SELECT Id, Name, 
                           LastModifiedById, 
                           CreatedById,genesis__Scorecard__c, 
                           genesis__Scorecard_Criteria__c, 
                           genesis__Matching_Type__c, 
                           genesis__Matching_Value__c, 
                           genesis__Score__c,genesis__Weighted_Score__c, 
                           genesis__Weight__c from 
                           genesis__Application_s_Scorecard__c 
                           where genesis__Application__c =: this.application.Id];
    }
    
    //edited to remove security scanner issues -- Arjun
    public PageReference init(){
        if(this.application.id != null)
            modify();
        onload();
        return null;
    }
    
    public void modify(){
        //delete existing checklist records
         List<genesis__Application_s_Scorecard__c> scL = [select Id from genesis__Application_s_Scorecard__c 
                                                where genesis__Application__c = :this.application.id];
         if(Schema.sObjectType.genesis__Application_s_Scorecard__c.isDeletable()){
              delete scL;
          }
          else{
              ApexPages.Message message = new ApexPages.message(ApexPages.severity.ERROR,'Insufficient access');
              ApexPages.addMessage(message);
              return ;       
          }
        total = 0.00;
        //recreate new ones
        pieData = new List<PieWedgeData>();
        pieData2 = new List<PieWedgeData>();
        Set<Id> scIds = new Set<Id>();
        try{
            String ascardId = application.Scorecard_Set__c;
            if(ascardId != null){
                List<Scorecard_Set__c> aslist = [select name,id,Scorecard__c from Scorecard_Set__c where id =: ascardId ]; 
                for(Scorecard_Set__c sc : aslist){
                    scIds.add(sc.Scorecard__c);
                }
                
            }

            List<genesis__Application_s_Scorecard__c> rSCMainList = new List<genesis__Application_s_Scorecard__c>();
            String type = 'genesis__Scorecard__c';
            String query = 'SELECT ' + CommonUtil.fetchAllFields(type)+ ' from ' + 
                            type + ' where genesis__Enabled__c = true and id =: scIds';
            List<genesis__Scorecard__c> Scorecard = Database.query(query);                           
            System.debug('Scorecard: ' + Scorecard);                                    
            
            //step 2. Evaluate each rule
            for(genesis__Scorecard__c r : Scorecard){
                rSCMainList.addAll(genesis.ScorecardAPI.evaluateScorecardCriteria(r,application));
            }
            //scL = genesis.ScorecardAPI.evaluateScorecards(application);    
            Map<String,Integer> scoreCardMap = new Map<String,Integer>();
            if(rSCMainList!=null){
                for(genesis__Application_s_Scorecard__c s:rSCMainList){
                    total = total + s.genesis__Weighted_Score__c;
                }
            }
           if(Schema.sObjectType.genesis__Application_s_Scorecard__c.isCreateable()){
               insert rSCMainList;
           }
           else{
               ApexPages.Message message = new ApexPages.message(ApexPages.severity.ERROR,'Insufficient access');
               ApexPages.addMessage(message);
               return ;       
           }
            //insert scL; 
            List<genesis__Application_s_Scorecard__c> scL1 = [select name,Id,
                                                genesis__score__c,genesis__scorecard__c,genesis__scorecard__r.name,
                                                genesis__Weighted_Score__c,genesis__Weight__c,
                                                genesis__Scorecard_Criteria__c,genesis__Scorecard_Criteria__r.name  
                                                from genesis__Application_s_Scorecard__c 
                                                where genesis__Application__c = :this.application.id];
            if(scL1!=null){
                for(genesis__Application_s_Scorecard__c s:scL1){
                  //  pieData2.add(new PieWedgeData(s.Scorecard_Criteria__r.name ,s.Weighted_Score__c.intValue()));
                     Integer val ;
                    if(scoreCardMap.containsKey(s.genesis__scorecard__r.name)){
                        val = scoreCardMap.get(s.genesis__scorecard__r.name);
                        val = val + s.genesis__score__c.intValue();
                    }else{
                        val = s.genesis__score__c.intValue();
                    }
                    scoreCardMap.put(s.genesis__scorecard__r.name,val);
                }
                Integer totalScore = 0;
                for(String k : scoreCardMap.keySet()){
                    totalScore = totalScore  + scoreCardMap.get(k);
                }
                if(totalScore!=0){
                    for(String k : scoreCardMap.keySet()){
                        Decimal scorePercent = (scoreCardMap.get(k)*100)/totalScore ;
                        System.debug('scorePercent :'+scorePercent );
                        pieData.add(new PieWedgeData(k,scorePercent.intValue()));
                    }
                }
                
            }
        }catch(Exception e){
            ApexPages.Message message = new ApexPages.message(ApexPages.severity.ERROR,e.getMessage());
            ApexPages.addMessage(message);
        }
    }
    
    public class PieWedgeData {

        public String name { get; set; }
        public Integer data { get; set; }
        public PieWedgeData(String name, Integer data) {
            this.name = name;
            this.data = data;
       }
    }
}