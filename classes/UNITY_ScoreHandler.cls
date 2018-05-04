public with sharing class UNITY_ScoreHandler {
    
    public UNITY_ScoreHandler() {}


    // Store prefix for score factors fields in SObjects 
    private static String UNITY_SCORE_FACTOR = 'UNITY_Score_Factor_';
    // Dynamic factor fields retrieved by the SObject type 
    // factor fields start with 'UNITY_Score_Factor_' prefix 
    private static List<String>       factors  = new List<String>();
    // SObject from where we get the factors 
    private static Schema.SObjectType SO_Type;
    // This are the 3 Sobject defined for Scoring for now : WorkOrder, UNITY_Vendor_Assignment__c, UNITY_Warranty__c
    private static Schema.SObjectType WO_Type  = WorkOrder.getSObjectType();
    private static Schema.SObjectType VA_Type  = UNITY_Vendor_Assignment__c.getSObjectType();
    private static Schema.SObjectType WA_Type  = UNITY_Warranty__c.getSObjectType();
    // Fields of the SObject from where we get the score factors
    private static Map<String,Schema.SObjectField> SO_TypeFieldsDescribe;
    // Map of SObject type to String Abbr 
    // Use this to handle dynamic field by SObject factors : UNITY_Score_Factor_[WO,VA,WA]_1_SR__c
    // WorkOrder                   = WO
    // UNITY_Vendor_Assignment__c  = VA
    // UNITY_Warranty__c           = WA
    private static Map< Schema.SObjectType, String > SOType_abbr = new Map< Schema.SObjectType, String >{WO_Type=>'WO',VA_Type=>'VA',WA_Type=>'WA'};
    // Map of String Request type Name  to String Request type Abbr
    // Preventative Maintenance = PM
    // Project Management       = Project
    // Service Request          = SR
    // Site Survey              = SS
    private static Map< String, String > requestType_abbr = new Map<String,String>{'Preventative Maintenance'=>'PM','Project Management'=>'Project','Service Request'=>'SR','Site Survey'=>'SS'};
    private static Map< String, String > abbr_requestType = new Map<String,String>{'PM'=>'Preventative Maintenance','Project'=>'Project Management','SR'=>'Service Request','SS'=>'Site Survey'}; 
    

    private static Map<String,Schema.SObjectField> WO_fieldsDescribe  = WO_Type.getDescribe().fields.getMap();
    private static Map<String,Schema.SObjectField> VT_fieldsDescribe  = UNITY_Vendor_Trade__c.getSObjectType().getDescribe().fields.getMap();
    private static Map<String,Schema.SObjectField> VA_fieldsDescribe  = VA_Type.getDescribe().fields.getMap();

    // Name    : execute
    // Param 1 : SObject type 
    // Param 2 : List of records 
    // Param 3 : Map< Vendor Id + Trade Id , vendor trade wrapper > , this map will be updated by reference 
    // Return  : Set< Vendor Id + Trade Id > set of vandor trade updated in the chunk of data 
    public static Set<String> execute(Schema.SObjectType soType ,List<SObject> soList, Map<String, VendorTradeHandler> VTHelperMap){

        Id  aux_tradeId;
        Id  aux_vendorId;

        String  aux_key;
        
        Set<Id> aux_criteria_tradeIds    = new Set<Id>();
        Set<Id> aux_criteria_vendorIds   = new Set<Id>();
        
        Set<Id> aux_vendorId_tradeId_key = new Set<Id>();

        Set<String> keys_in_execute = new Set<String>();

        Map<String,List<SObject>> key_sobject_in_execute = new Map<String,List<SObject>>();
        
        SO_Type = soType;
        SO_TypeFieldsDescribe = SO_Type.getDescribe().fields.getMap();

        // Get factor fields with prefix 'UNITY_Score_Factor_'
        for(String fieldName :SO_TypeFieldsDescribe.keySet()){
            if(fieldName.indexOf(UNITY_SCORE_FACTOR.toLowerCase())>-1)factors.add(fieldName);
        }

        // Go through records  
        for(SObject so :soList){
            // Collect Vendor Id and Trade Id 
            if(SO_Type == VA_Type){
                aux_tradeId  = (Id)so.get('Trade__c');
                aux_vendorId = (Id)so.get('Vendor__c');
            }else if(SO_Type == WO_Type){
                aux_tradeId  = (Id)so.get('UNITY_Trade__c');
                aux_vendorId = (Id)so.get('UNITY_Assigned_Vendor__c');
            }

            if((aux_vendorId!=null) && (aux_tradeId!=null)){

                aux_key = aux_vendorId+'-'+aux_tradeId; 

                // check the if we already have the VT record for the Trade and Vendor
                if(VTHelperMap.get(aux_key) == null){
                    // add ids for query VT
                    aux_criteria_tradeIds.add(aux_tradeId);
                    aux_criteria_vendorIds.add(aux_vendorId);
                }
                // Keep tracking of the pair Vandor Id and Trade Id within execute method 
                if(key_sobject_in_execute.get(aux_key)==null) 
                    key_sobject_in_execute.put(aux_key, new List<SObject>{so});
                else 
                    key_sobject_in_execute.get(aux_key).add(so);

                // add the pair Vandor Id and Trade Id within execute method 
                keys_in_execute.add(aux_key);
            }
        }

        // query for those VT we dont have in the map reference VTHelperMap
        Map<Id,UNITY_Vendor_Trade__c> VTMap = getVendorTrades(aux_criteria_vendorIds, aux_criteria_tradeIds);


        for(UNITY_Vendor_Trade__c onVT :VTMap.values()){
            aux_key = onVT.Vendor__c+'-'+onVT.Trade__c;
            // Create new instance for the VT
            if(VTHelperMap.get(aux_key)==null) VTHelperMap.put(aux_key,new VendorTradeHandler(SO_Type));

            if(VTHelperMap.get(aux_key)!=null){
                VTHelperMap.get(aux_key).addVendorTrade(onVT); // add the VT to the wrapper 
                if(key_sobject_in_execute.get(aux_key)!=null)
                    VTHelperMap.get(aux_key).addSO(key_sobject_in_execute.get(aux_key)); // add list of records which affect the VT score values 
            }   
        }
        return keys_in_execute;
    }

    // Wrapper for Vendor Trade Records 
    public class VendorTradeHandler{
        // Sobject type fro where we get the score 
        public Schema.SObjectType     SOType                  {get;set;}
        // Store the Request types from which are affected  
        public Set<String>            requetTypesUsed         {get;set;}
        // Vendor Trade Record
        public UNITY_Vendor_Trade__c  vendorTrade             {get;set;}
        // Map for all Records with factor = [0,1]
        // Key   : Request Type Name 
        // Value : Key   : Score Factor Field 
        //         Value : List of Records SObjects 
        public Map<String ,Map<String,List<SObject>>> all     {get;set;}
        // Map for Records with factor = [1]
        // Key   : Request Type Name 
        // Value : Key   : Score Factor Field 
        //         Value : List of Records SObjects 
        public Map<String ,Map<String,List<SObject>>> metrics {get;set;}

        // Contructor 
        public VendorTradeHandler(Schema.SObjectType soT){
            this.SOType = soT;
            this.requetTypesUsed =  new Set<String>();
            this.all = new Map<String ,Map<String,List<SObject>>>();
            this.metrics =  new Map<String ,Map<String,List<SObject>>>();
        }

        // Name  : addVendorTrade
        // Param : VT Record 
        public void addVendorTrade(UNITY_Vendor_Trade__c vt){
            this.vendorTrade = vt;
        }

        // Name  : addSO
        // Param : Sobject for calculate score 
        public void addSO(SObject so){
            // Go through the Factor Fields in the SObject 
            for(String factor_fields :factors)
                // check if the field belongs to the SObject 
                if(SO_TypeFieldsDescribe.keySet().contains(factor_fields.toLowerCase()))
                    this.dispatchRecord(factor_fields, so);
                
        }

        // Name  : addSO
        // Param : Sobject for calculate score bulk
        public void addSO(List<SObject> soList){
            if(soList!=null)
                for(SObject so :soList) this.addSO(so);
        }

        // Name    : dispatchRecord
        // Param 1 : String score field 
        // Param 2 : SObject record 
        public void dispatchRecord(String factorField, SObject so){

            String aux_requestType = null;
            // Get the Request type 
            if(this.SOType == VA_Type)
                aux_requestType = (String)so.get('Request_Type__c');
            else if(this.SOType == WO_Type)
                aux_requestType = (String)so.getSObject('RecordType').get('Name');

            if(aux_requestType != null){
                // add key for Request Type
                if(this.metrics.get(aux_requestType) == null ) 
                    this.metrics.put(aux_requestType, new Map<String,List<SObject>>()); 

                // add key for field factor 
                if(this.metrics.get(aux_requestType).get(factorField) == null ) 
                    this.metrics.get(aux_requestType).put(factorField, new List<SObject>());


                if(this.all.get(aux_requestType) == null ) 
                    this.all.put(aux_requestType,new Map<String,List<SObject>>());

                if(this.all.get(aux_requestType).get(factorField) == null) 
                    this.all.get(aux_requestType).put(factorField, new List<SObject>());

                // Evaluate the factor field value 
                if( so.get(factorField) == 1) this.metrics.get(aux_requestType).get(factorField).add(so);
                if((so.get(factorField) == 1) || (so.get(factorField) == 0)) this.all.get(aux_requestType).get(factorField).add(so);
                
                // get the Request type used 
                this.requetTypesUsed.add(aux_requestType);
            }
        }

        // Name : calculate
        // Note : Calculate score per Field Factor 
        public void calculate(){

            // set up the score field in the VT, add the SObject type Abbr
            String aux_field_name = 'UNITY_Score_Factor_'+SOType_abbr.get(this.SOType)+'_{f}_{rt}__c';
            // set up the last score field in the VT, add the SObject type Abbr
            String aux_lastScored_field_name = 'UNITY_LastScored_'+SOType_abbr.get(this.SOType)+'__c';

            // key   : abbr Request Type
            // value : key   : String Factor field
            //         value : Decimal factor value 
            Map<String,Map<String,Decimal>> aux_scores = new Map<String,Map<String,Decimal>>();

            for(String requestType :this.requetTypesUsed ){

                aux_scores.put(requestType_abbr.get(requestType), new Map<String,Decimal>());

                if(this.metrics.get(requestType) != null)
                    for(String factorField :this.metrics.get(requestType).keySet())
                        aux_scores.get(requestType_abbr.get(requestType)).put(factorField, calculateScore(requestType,factorField));
                
            }

            // Go per Request type 
            for(String abbrRT :aux_scores.keySet()){
                // Go per field factor
                for(String factorField :aux_scores.get(abbrRT).keySet()){
                    // check if the field factor exist in the VT
                    if(VT_fieldsDescribe.get(aux_field_name.replace('{rt}',abbrRT).replace('{f}',factorField.replaceAll('\\D','')).toLowerCase())!=null)                        
                        // check if the score factor value should affect the overoll score
                        if(aux_scores.get(abbrRT).get(factorField) > 0 ){
                            this.vendorTrade.put(aux_lastScored_field_name, DateTime.now());
                            this.vendorTrade.put(aux_field_name.replace('{rt}',abbrRT).replace('{f}',factorField.replaceAll('\\D','')),aux_scores.get(abbrRT).get(factorField));
                        }
                }
            }
        }

        // Name : calculate
        // Note : Calculate score per Field Factor 
        private Decimal calculateScore(String requestType, String factorField){
            Decimal aux_value_to_return = 0;
            Decimal aux_number_of_so_in_factor = ((!this.metrics.get(requestType).get(factorField).isEmpty())? this.metrics.get(requestType).get(factorField).size():0);
            if(aux_number_of_so_in_factor>0) aux_value_to_return = ((1 - (aux_number_of_so_in_factor/this.all.get(requestType).get(factorField).size())));
            if((aux_value_to_return==0)&&(aux_number_of_so_in_factor!=0)) aux_value_to_return = 1;
            return (aux_value_to_return*10);
        }

    }

    private static Map<Id,UNITY_Vendor_Trade__c> getVendorTrades(Set<Id> vendorIds, Set<Id> tradeIds){

        return new Map<Id,UNITY_Vendor_Trade__c>(  [SELECT  id , 
                                                            Trade__c, 
                                                            Vendor__c,
                                                            UNITY_LastScored_VA__c,
                                                            UNITY_LastScored_WO__c,
                                                            UNITY_LastScored_WA__c,
                                                            UNITY_Score_Factor_VA_2_SR__c,
                                                            UNITY_Score_Factor_VA_1_SR__c,
                                                            UNITY_Score_Factor_VA_1_PM__c,
                                                            UNITY_Score_Factor_VA_2_PM__c,
                                                            UNITY_Score_Factor_VA_1_SS__c,
                                                            UNITY_Score_Factor_VA_2_SS__c,
                                                            UNITY_Score_Factor_VA_1_Project__c,
                                                            UNITY_Score_Factor_VA_2_Project__c,
                                                            UNITY_Score_Factor_WO_1_SR__c,
                                                            UNITY_Score_Factor_WO_2_SR__c,
                                                            UNITY_Score_Factor_WO_3_SR__c,
                                                            UNITY_Score_Factor_WO_4_SR__c,
                                                            UNITY_Score_Factor_WO_5_SR__c,
                                                            UNITY_Score_Factor_WO_1_PM__c,
                                                            UNITY_Score_Factor_WO_2_PM__c,
                                                            UNITY_Score_Factor_WO_3_PM__c,
                                                            UNITY_Score_Factor_WO_4_PM__c,
                                                            UNITY_Score_Factor_WO_5_PM__c,
                                                            UNITY_Score_Factor_WO_1_SS__c,
                                                            UNITY_Score_Factor_WO_2_SS__c,
                                                            UNITY_Score_Factor_WO_3_SS__c,
                                                            UNITY_Score_Factor_WO_4_SS__c,
                                                            UNITY_Score_Factor_WO_5_SS__c,
                                                            UNITY_Score_Factor_WO_1_Project__c,
                                                            UNITY_Score_Factor_WO_2_Project__c,
                                                            UNITY_Score_Factor_WO_3_Project__c,
                                                            UNITY_Score_Factor_WO_4_Project__c,
                                                            UNITY_Score_Factor_WO_5_Project__c
                                                    FROM    UNITY_Vendor_Trade__c 
                                                    WHERE   Trade__c  IN :tradeIds AND 
                                                            Vendor__c IN :vendorIds]);

    }

}