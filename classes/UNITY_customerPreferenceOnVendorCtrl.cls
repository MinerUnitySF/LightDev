public class UNITY_customerPreferenceOnVendorCtrl {

    public Id vendorId{get;set;}
    public Id customerId{get;set;}
    
    public Account onVendor{get;set;}
    public Account onCustomer{get;set;}
    
    public Boolean isEditableVendor{get;set;}
    
    public list<vendorPreference>  preferences{get;set;}
    
    public Map< id, TradeCovered>  tradeCovered{get;set;}
    
    public UNITY_customerPreferenceOnVendorCtrl(){
         
        preferences  = new list<vendorPreference>();
        tradeCovered = new Map< id, TradeCovered> ();
        
        vendorId   = ApexPages.currentpage().getparameters().get('vendorId');
        customerId = ApexPages.currentpage().getparameters().get('customerId');
        
        isEditableVendor = true;
            
        if( (vendorId != null) && (customerId != null) ){
             onVendor   = [SELECT id, name FROM Account WHERE id =:vendorId];
             onCustomer = [SELECT id, name FROM Account WHERE id =:customerId];
        }
        
        
    }
    
    public void getData(){
        
        boolean alreadyExistPreferenceForVendor = false;
        double countPreferred = 0;
        
        // we need the customer id and vendor id 
        if( (vendorId != null) && (customerId != null) ){
            
            // get all  the customer preferences 
            list<UNITY_Vendor_Preference__c>  aux_preferences = [SELECT  Customer__c, 
                                                                         Id,  
                                                                         Name, 
                                                                         Ranking__c, 
                                                                         Type__c, 
                                                                         Vendor__c, 
                                                                         Vendor__r.Name 
                                                                 FROM UNITY_Vendor_Preference__c 
                                                                 WHERE Customer__c = :customerId];
                        
            for(UNITY_Vendor_Preference__c var :aux_preferences){
                
                vendorPreference aux_v = new vendorPreference();
                aux_v.Name = var.Vendor__r.Name; 
                aux_v.id   = var.Vendor__c; 
                aux_v.preferenceId = var.Id; 
                aux_v.preferenceType = var.Type__c; 
                //aux_v.ranking = (var.Ranking__c != null)? var.Ranking__c : 0 ; 
                // now the ranking is defined by trade 
                aux_v.ranking = 0 ; 
                
                if(aux_v.id == vendorId){
                    alreadyExistPreferenceForVendor = true ;
                    if(aux_v.preferenceType != 'Preferred')isEditableVendor = false;
                } 
                //if((aux_v.preferenceType == 'Preferred')&&(aux_v.ranking>=countPreferred) ) countPreferred = aux_v.ranking;
                preferences.add(aux_v);
            }
            
            if(!alreadyExistPreferenceForVendor){
                vendorPreference aux_v = new vendorPreference();
                aux_v.Name = onVendor.Name; 
                aux_v.id   = onVendor.id; 
                aux_v.preferenceId   = null; 
                aux_v.preferenceType = 'Preferred'; 
                aux_v.ranking = countPreferred + 1 ; 
                preferences.add(aux_v);
                
            }
            
            //preferences.sort();
            
            list<UNITY_Vendor_Trade__c>  aux_trades = new list<UNITY_Vendor_Trade__c>();
                
            aux_trades = [SELECT  Id, Name, Trade__r.Name, Trade__c, Vendor__c FROM UNITY_Vendor_Trade__c WHERE Vendor__c = :vendorId ];
            
                
            for(UNITY_Vendor_Trade__c var :aux_trades){
                
                TradeCovered aux_t = new TradeCovered();
                aux_t.Name = var.Trade__r.Name; 
                aux_t.id   = var.Trade__c; 
                aux_t.hasPreference = false; 
                
                tradeCovered.put( var.Trade__c , aux_t);
                
            }
            system.debug('###123 '+tradeCovered);
            list<UNITY_Vendor_Preference_By_Trade__c>  aux_preferenceByTrade = [ SELECT Customer__c, Id, Name, Trade__c, Vendor__c, Vendor_Preference__c 
                                                                                 FROM UNITY_Vendor_Preference_By_Trade__c 
                                                                                 WHERE Vendor__c = :vendorId AND Customer__c = :customerId];
            system.debug('###124 '+aux_preferenceByTrade);
            for(UNITY_Vendor_Preference_By_Trade__c var :aux_preferenceByTrade){
                
                if(tradeCovered.get(var.Trade__c) != null){
                   tradeCovered.get(var.Trade__c).hasPreference =  true;
                   tradeCovered.get(var.Trade__c).tradePreferenceId =  var.id;
                }
                   
            }
                
        }
        
        
        
        
    }
    
    public class VendorPreference implements Comparable {
        
        public String Name {get;set;}
        public Double ranking {get;set;}
        public String id {get;set;}
        public String preferenceType {get;set;}
        public String preferenceId   {get;set;}
        
        public Integer compareTo(Object compareTo) {
            
            vendorPreference compareToV = (vendorPreference)compareTo;
            
            if( (preferenceType == 'Preferred') && (compareToV.preferenceType != 'Preferred') ){
                
                return -1;                
                
            }else if( (preferenceType == 'Preferred') && (compareToV.preferenceType == 'Preferred') ){
                
                if ( (ranking == 0) && (compareToV.ranking !=0)) return -1;
                if ( (ranking != 0) && (compareToV.ranking ==0)) return -1;
                if (ranking == compareToV.ranking) return 0;
                if (ranking >  compareToV.ranking) return 1;  
                if (ranking <  compareToV.ranking) return -1;
                
            }else if( (preferenceType != 'Preferred') && (compareToV.preferenceType != 'Preferred') ){
                return 0;
            } 
            
            return 1;
            
        }
        
    }
    
    public class TradeCovered{
        
        public String id {get;set;}
        public String tradePreferenceId {get;set;}
        public String Name  {get;set;}
        public Boolean hasPreference {get;set;}   
        
        public TradeCovered(){
            tradePreferenceId = null;
        }
         
    }
    
    @RemoteAction 
    public static map<String, String> createTradesPreference(list<String> tradeIds , String cId , String vId, String vpId  ){
        
        map<String, String> toReturn  = new map<String, String>();
        list<UNITY_Vendor_Preference_By_Trade__c> toInsert = new list<UNITY_Vendor_Preference_By_Trade__c>();
        
        if( (cId!= null)&&(vId!= null)&& (vpId!= null) ){
            
            
            for(String tId :tradeIds){
                
                UNITY_Vendor_Preference_By_Trade__c  qux_tp = new UNITY_Vendor_Preference_By_Trade__c();
                qux_tp.Customer__c  = cId;
                qux_tp.Vendor__c    = vId;
                qux_tp.Vendor_Preference__c = vpId;
                qux_tp.Trade__c  = tId;
                    
                toInsert.add(qux_tp);
                
            }
            
            insert toInsert;
        }
        
        for(UNITY_Vendor_Preference_By_Trade__c var :toInsert){
            toReturn.put(var.Trade__c , var.id);
        }
        
        return toReturn;
        
    }
    
    @RemoteAction 
    public static String upsertVendorPreference(list<UNITY_customerPreferenceOnVendorCtrl.VendorPreference> vendorPreferences , String cId , String vId ){
        
        list<UNITY_Vendor_Preference__c> vp = new list<UNITY_Vendor_Preference__c>();
        UNITY_Vendor_Preference__c editingVendor = new UNITY_Vendor_Preference__c();
        
        
        if(vendorPreferences.size()>0){
            for(VendorPreference var :vendorPreferences){
                
                UNITY_Vendor_Preference__c aux_p = new UNITY_Vendor_Preference__c();
                
                if(var.preferenceId != null){
                    aux_p.Id = var.preferenceId;
                }else{    
                    aux_p.Customer__c = cId;
                    aux_p.Vendor__c   = vId;
                }
                
                if((id)var.id == (id)vId) editingVendor  = aux_p;
                
                aux_p.Ranking__c = (double) var.ranking;
                aux_p.Type__c = var.preferenceType;
                
                vp.add(aux_p);
            }
            
            upsert vp;
        }
        
        
        return editingVendor.id;
        
    }
    
    @RemoteAction 
    public static string deletePreferencesOnVendor(String cId , String vId, String vpId ){
        
        if( (cId != null) && (vId != null) && (vpId!= null)){
            
            list<UNITY_Vendor_Preference_By_Trade__c>  aux_preferenceByTrade = [ SELECT Customer__c, Id, Name, Trade__c, Vendor__c, Vendor_Preference__c 
                                                                                 FROM UNITY_Vendor_Preference_By_Trade__c 
                                                                                 WHERE Vendor__c = :vId AND Customer__c = :cId];
            if(aux_preferenceByTrade.size()>0){
                
                delete aux_preferenceByTrade;
                
            }
            
            UNITY_Vendor_Preference__c toDelete = new UNITY_Vendor_Preference__c(id=vpId);
            delete toDelete;
            
        }
        
        return vId;
         
    }
    
}