public with sharing class UNITY_preferenceTestCtrl {
    
    public Id customerId{get;set;}
    public Id vendorId{get;set;}
    public Id tradeId{get;set;}
    public Boolean hasVendorPreferenceRecord{get;set;}
    public Boolean canSave{get;set;}
    public List<VendorPreferenceByTrade> preferred{get;set;}
    public List<VendorPreferenceByTrade> doNotUse{get;set;}
    public List<VendorPreferenceByTrade> VPBTList{get;set;}
    public Account vendor{get;set;}
    public Account customer{get;set;}
    public FSO__Skill__c trade{get;set;}
    public Integer preferredCount{get;set;}
    public String  vendorOrder{get;set;}
    public String  vendorRankingToDelete{get;set;}
    
    private boolean haveWeAllParameters{get;set;}
    private Map<id,Integer> vendor_ranking{get;set;}
    public  Map<id,UNITY_Vendor_Preference_By_Trade__c> vendorPreferenceByTrade{get;set;}
    private Map<id,VendorPreferenceByTrade> vendor_preferenceByTrade{get;set;}
    
    public UNITY_preferenceTestCtrl(){
        this.init();
    }
    
    private void init(){
        
        this.customerId = (Id)ApexPages.currentpage().getparameters().get('customerId');
        this.vendorId   = (Id)ApexPages.currentpage().getparameters().get('vendorId');
        this.tradeId    = (Id)ApexPages.currentpage().getparameters().get('tradeId');
        this.preferred  = new List<VendorPreferenceByTrade>();
        this.doNotUse   = new List<VendorPreferenceByTrade>();
        this.VPBTList        = new List<VendorPreferenceByTrade>();
        this.vendor_preferenceByTrade = new Map<id,VendorPreferenceByTrade>();
        this.vendor_ranking = new Map<id,Integer>();
        this.canSave = true;
        this.hasVendorPreferenceRecord = false;
        this.vendorOrder = '';
        this.haveWeAllParameters = ((this.customerId!=null) && (this.vendorId!=null) && (this.tradeId!=null));
        
        this.getData();
    }
    
    private void getData(){
        
        if(this.haveWeAllParameters){
            
            Double aux_last_ranking = 0;
            
            this.vendor   = [SELECT id, Name FROM Account WHERE id =:vendorId];
            this.customer = [SELECT id, Name FROM Account WHERE id =:customerId];
            this.trade    = [SELECT id, Name FROM FSO__Skill__c WHERE id =:this.tradeId];
            
            vendorPreferenceByTrade = new Map<id,UNITY_Vendor_Preference_By_Trade__c>([SELECT 
                                                                                             Customer__c,
                                                                                             Ranking__c , 
                                                                                             Trade__c , 
                                                                                             Vendor__c , 
                                                                                             Vendor__r.Name,
                                                                                             Vendor_Preference__c,
                                                                                             Vendor_Preference__r.Type__c 
                                                                                        FROM UNITY_Vendor_Preference_By_Trade__c
                                                                                        WHERE 
                                                                                             (Customer__c = :this.customerId) AND 
                                                                                             (Trade__c    = :this.tradeId)]);
            
            for(id vptId :vendorPreferenceByTrade.keySet()){
                
                UNITY_Vendor_Preference_By_Trade__c aux_preferenceByTrade = vendorPreferenceByTrade.get(vptId);
                
                VendorPreferenceByTrade vw = this.newVendorPreferenceByTrade(aux_preferenceByTrade);
                                
                if(vw.preferenceType == UNITY_Constants.VENDOR_PREFERENCE_PREFERRED ) this.preferred.add(vw);
                else if(vw.preferenceType == UNITY_Constants.VENDOR_PREFERENCE_DO_NOT_USE) this.doNotUse.add(vw);
                
                this.vendor_preferenceByTrade.put(vw.vendorId,vw);
                
                if( vw.ranking > aux_last_ranking) aux_last_ranking = vw.ranking;  
            }
            
            if(!this.hasVendorPreferenceRecord){
                UNITY_Vendor_Preference__c vendorPreference = null;
                list<UNITY_Vendor_Preference__c> vendorPreferences =  [SELECT id, Type__c, Customer__c, Vendor__c 
                                                                       FROM UNITY_Vendor_Preference__c 
                                                                       WHERE 
                                                                            (Customer__c = :this.customerId) AND
                                                                            (Vendor__c   = :this.vendorId) ];
                
                if(vendorPreferences.size()>0) vendorPreference = vendorPreferences.get(0);
                
                VendorPreferenceByTrade vw = new VendorPreferenceByTrade();
                vw.id             = null;
                vw.ranking        = aux_last_ranking+1; 
                vw.vendorId       = vendor.id; 
                vw.VendorName     = vendor.Name; 
                vw.preferenceId   = (vendorPreference!=null)? vendorPreference.id : null; 
                vw.preferenceType = (vendorPreference!=null)? vendorPreference.Type__c : UNITY_Constants.VENDOR_PREFERENCE_PREFERRED;
                vw.canChangeRanking = (vw.preferenceType== UNITY_Constants.VENDOR_PREFERENCE_PREFERRED);
                vw.isEditing = true;
                vw.canDelete = (vw.id != null);
                this.preferred.add(vw);
                this.vendor_preferenceByTrade.put(vw.vendorId,vw);
            }  
            
            this.calculateVPTIndex();     
        }
    }
    
    public void save(){
        
        list<UNITY_Vendor_Preference_By_Trade__c> vpt_toUpdate = new list<UNITY_Vendor_Preference_By_Trade__c>();
        
        for(VendorPreferenceByTrade vendorPreferenceByTrade :this.preferred){
            if(vendorPreferenceByTrade.vendorId != this.vendorId){
                UNITY_Vendor_Preference_By_Trade__c aux_vpt = new UNITY_Vendor_Preference_By_Trade__c();
                aux_vpt.id = vendorPreferenceByTrade.id;
                aux_vpt.Ranking__c = vendorPreferenceByTrade.ranking;
                vpt_toUpdate.add(aux_vpt);
            }
        }
        
        UNITY_Vendor_Preference__c aux_vendorPreference = new UNITY_Vendor_Preference__c();
        if(this.vendor_preferenceByTrade.get(this.vendorId).preferenceId == null){
            aux_vendorPreference.Customer__c = this.customerId;
            aux_vendorPreference.Vendor__c   = this.vendorId;
        }
        aux_vendorPreference.id       = this.vendor_preferenceByTrade.get(this.vendorId).preferenceId;
        aux_vendorPreference.Type__c  = this.vendor_preferenceByTrade.get(this.vendorId).preferenceType;
        upsert aux_vendorPreference;
        
        //this.vendor_preferenceByTrade.get(this.vendorId).preferenceId = aux_vendorPreference.id;
        
        UNITY_Vendor_Preference_By_Trade__c aux_vpt = new UNITY_Vendor_Preference_By_Trade__c();
        if(this.vendor_preferenceByTrade.get(this.vendorId).id == null){
            aux_vpt.Customer__c = this.customerId;
            aux_vpt.Vendor__c   = this.vendorId;
            aux_vpt.Trade__c    = this.tradeId;
            aux_vpt.Vendor_Preference__c = aux_vendorPreference.id;
        }
        aux_vpt.id         = this.vendor_preferenceByTrade.get(this.vendorId).id;
        aux_vpt.Ranking__c = this.vendor_preferenceByTrade.get(this.vendorId).ranking;
        vpt_toUpdate.add(aux_vpt);
        
        upsert vpt_toUpdate;
        
        this.init();
        //this.vendor_preferenceByTrade.get(this.vendorId).id = aux_vpt.id;
        //this.vendor_preferenceByTrade.get(this.vendorId).canDelete = (aux_vpt.id!=null);
        
    }
    
    public VendorPreferenceByTrade newVendorPreferenceByTrade(UNITY_Vendor_Preference_By_Trade__c aux_preferenceByTrade) {
         VendorPreferenceByTrade vw = new VendorPreferenceByTrade();
         vw.id             = aux_preferenceByTrade.id;
         vw.ranking        = (aux_preferenceByTrade.Ranking__c != null)? aux_preferenceByTrade.Ranking__c : 0 ; 
         vw.vendorId       = aux_preferenceByTrade.Vendor__c; 
         vw.isEditing      = false;
         vw.VendorName     = aux_preferenceByTrade.Vendor__r.Name; 
         vw.preferenceId   = aux_preferenceByTrade.Vendor_Preference__c; 
         vw.preferenceType = aux_preferenceByTrade.Vendor_Preference__r.Type__c; 
         vw.canChangeRanking = false;
         vw.isPreferred    = (aux_preferenceByTrade.Vendor_Preference__r.Type__c == UNITY_Constants.VENDOR_PREFERENCE_PREFERRED);
         vw.isDoNotUse     = (aux_preferenceByTrade.Vendor_Preference__r.Type__c == UNITY_Constants.VENDOR_PREFERENCE_DO_NOT_USE);
         vw.canDelete = (vw.id != null);
         if(aux_preferenceByTrade.Vendor__c == vendorId){
             hasVendorPreferenceRecord = true;
             vw.isEditing = true;
             if(vw.preferenceType == UNITY_Constants.VENDOR_PREFERENCE_PREFERRED)vw.canChangeRanking = true;
         }
        
         return vw;
    }
    
    public void goUp(){
        Double oldRanking =  this.vendor_preferenceByTrade.get(vendorId).ranking;
        Double newRanking =  oldRanking-1;
        if(oldRanking > 1){
            vendor_preferenceByTrade.get(vendorId).ranking = newRanking;
            VendorPreferenceByTrade vptW = this.preferred.get(Integer.valueOf(newRanking - 1));
            vptW.ranking = oldRanking;
        }
        this.calculateVPTIndex();
    }
    
    public void goDown(){
        Double oldRanking =  this.vendor_preferenceByTrade.get(vendorId).ranking;
        Double newRanking =  oldRanking + 1;
        if(oldRanking < this.preferred.size()){
            vendor_preferenceByTrade.get(vendorId).ranking = newRanking;
            VendorPreferenceByTrade vptW = this.preferred.get(Integer.valueOf(oldRanking));
            vptW.ranking = oldRanking;
            system.debug('#### a--> '+vendor_preferenceByTrade.get(vendorId).vendorName+'/'+vendor_preferenceByTrade.get(vendorId).ranking);
            system.debug('#### b--> '+vptW.vendorName+'/'+vptW.ranking);
        }
        
        this.calculateVPTIndex();
    }
    
    public void deletePreference() {
        
        if(vendorRankingToDelete!= null){
            system.debug('#### vendorRankingToDelete ' +vendorRankingToDelete );
            UNITY_Vendor_Preference_By_Trade__c vpt = vendorPreferenceByTrade.get(vendorRankingToDelete);
            delete vpt;
        }
        this.init();
    }
    
    public void calculateVPTIndex(){
        
        this.VPBTList = new List<VendorPreferenceByTrade>();
        this.preferred.sort();
        Integer aux_ranking = 0;  
        for(VendorPreferenceByTrade vptW :this.preferred){
            aux_ranking++;
            vptW.ranking = aux_ranking;
            this.vendor_ranking.put(vptW.vendorId,  aux_ranking);
        }
        this.preferredCount = preferred.size();
        
        this.VPBTList.addAll(this.preferred);
        this.VPBTList.addAll(this.doNotUse);
        
    }
    
    public class VendorPreferenceByTrade implements Comparable {
        
        public Id id{get;set;}
        public Id vendorId {get;set;}
        public Id preferenceId {get;set;}
        
        public String vendorName {get;set;}
        public String preferenceType {get;set;}
        
        public Double ranking {get;set;}
        
        public Boolean canChangeRanking {get;set;}
        public Boolean isEditing {get;set;}
        public Boolean canDelete {get;set;}
        public Boolean isPreferred {get;set;}
        public Boolean isDoNotUse {get;set;}
        
        public Integer compareTo(Object compareTo) {
            
            Integer toReturn  = 0;
            
            VendorPreferenceByTrade compareToV = (VendorPreferenceByTrade)compareTo;
            system.debug('#### type --> '+this.preferenceType+'/'+compareToV.preferenceType );
            if( (this.preferenceType == UNITY_Constants.VENDOR_PREFERENCE_PREFERRED) && (compareToV.preferenceType != UNITY_Constants.VENDOR_PREFERENCE_PREFERRED) ){
                
                toReturn = -1;                
                
            }else if( (this.preferenceType == UNITY_Constants.VENDOR_PREFERENCE_PREFERRED) && (compareToV.preferenceType == UNITY_Constants.VENDOR_PREFERENCE_PREFERRED) ){
                
                if ( (this.ranking == 0) && (compareToV.ranking !=0)) toReturn = -1;
                if ( (this.ranking != 0) && (compareToV.ranking ==0)) toReturn = 1;
                //if (this.ranking == compareToV.ranking) toReturn = 0;
                if (this.ranking >  compareToV.ranking) toReturn = 1;  
                if (this.ranking <  compareToV.ranking) toReturn = -1;
                
            } 
            system.debug('#### toReturn --> '+toReturn);
            return toReturn;
        }
        
    }
    
    public List<SelectOption> getTypes() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption(UNITY_Constants.VENDOR_PREFERENCE_PREFERRED,UNITY_Constants.VENDOR_PREFERENCE_PREFERRED));
        options.add(new SelectOption(UNITY_Constants.VENDOR_PREFERENCE_DO_NOT_USE,UNITY_Constants.VENDOR_PREFERENCE_DO_NOT_USE));
        return options;
    }
    
    
    
}