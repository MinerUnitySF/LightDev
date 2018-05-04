public with sharing class UNITY_AssetHistoryTriggerHandler extends UNITY_BaseHandler{

    private Map<Id,Asset>   assetsDataMap               = new Map<Id,Asset>();
    private Map<Id,Asset>   assetsToUpdateMap           = new Map<Id,Asset>();
    private Map<Id,Asset>   updateThisYearOnAsset       = new Map<Id,Asset>();
    private Map<Id,Decimal> update_TCO_onAsset          = new Map<Id,Decimal>();
    private Map<Id,Decimal> update_down_time_onAsset    = new Map<Id,Decimal>();
    private Map<Id,Decimal> update_service_time_onAsset = new Map<Id,Decimal>();


    public UNITY_AssetHistoryTriggerHandler() {
        assetsToUpdateMap = new Map<Id,Asset>();
    }

    public override void bulkAfter(){

        Set<Id> aux_assetIds_to_query     = new Set<Id>();
        Set<Id> aux_updateThisYearOnAsset = new Set<Id>();
        Map<String,Set<Id>> aux_context   = new Map<String,Set<Id>>();

        for( SObject so :Trigger.new){
            UNITY_Asset_History__c newAH = (UNITY_Asset_History__c)so;
            UNITY_Asset_History__c oldAH;


            if(Trigger.isUpdate){
                oldAH = (UNITY_Asset_History__c)Trigger.oldMap.get(newAH.Id);
            }
            
            if(this.filterUpdateThisYearOnAsset(newAH,oldAH)) aux_updateThisYearOnAsset.add(newAH.UNITY_Asset__c);
            
        }

        aux_context.put('updateThisYearOnAsset',aux_updateThisYearOnAsset);

        aux_assetIds_to_query.addAll(aux_updateThisYearOnAsset);

        this.getAssets(aux_assetIds_to_query);
        this.filterContext(aux_context);
    }

    public override void  afterInsert(SObject newSo){
        UNITY_Asset_History__c newAH = (UNITY_Asset_History__c)newSo;
        this.checkThisYearValues(newAH,null);
        
    }

    public override void afterUpdate(SObject oldSo, SObject newSo){
        UNITY_Asset_History__c newAH = (UNITY_Asset_History__c)newSo;
        UNITY_Asset_History__c oldAH = (UNITY_Asset_History__c)oldSo;

        this.checkThisYearValues(newAH,oldAH);
    }

    public override void andFinally(){

        this.updateThisYearOnAssets();
    }

    private void filterContext(Map<String,Set<Id>> aux_context){

        for(Asset  onAsset :assetsDataMap.values()){

            if((aux_context.get('updateThisYearOnAsset')!=null) && (aux_context.get('updateThisYearOnAsset').contains(onAsset.Id)))
                updateThisYearOnAsset.put(onAsset.Id, onAsset);
            
        } 
    }

    private Boolean filterUpdateThisYearOnAsset(UNITY_Asset_History__c newAH, UNITY_Asset_History__c oldAH){
        Date today = Date.today();
        Boolean toReturn;
        if(   (newAH.UNITY_Asset__c == null)
            ||((toReturn==null)&&!((newAH.UNITY_Start_Date__c <= today)&&(today <= newAH.UNITY_End_Date__c)))){
            toReturn = false;
        }else if((toReturn==null)&&(oldAH==null)&&Trigger.isInsert){
            toReturn = true;
        }else if(toReturn==null){
            Boolean aux_changed_TCO_time      = (((newAH.UNITY_Total_Cost_Ownership__c!=null)||(newAH.UNITY_Total_Cost_Ownership__c!=0))&&(newAH.UNITY_Total_Cost_Ownership__c != oldAH.UNITY_Total_Cost_Ownership__c));
            Boolean aux_changed_down_time     = (((newAH.UNITY_Down_Time__c!=null)   ||(newAH.UNITY_Down_Time__c!=0))   &&(newAH.UNITY_Down_Time__c    != oldAH.UNITY_Down_Time__c));
            Boolean aux_changed_service_time  = (((newAH.UNITY_Service_Time__c!=null)||(newAH.UNITY_Service_Time__c!=0))&&(newAH.UNITY_Service_Time__c != oldAH.UNITY_Service_Time__c));
            if(aux_changed_down_time || aux_changed_service_time || aux_changed_TCO_time) 
                toReturn = true;
            else toReturn = false;
        }
        return toReturn;
    }

    /*
     * Name : getAssets
     */
    private void getAssets(Set<Id> assetsId){

        assetsDataMap = new Map<Id,Asset>([SELECT   Id,
                                                    UNITY_YTD_Down_Time__c,
                                                    SSVY_Asset_Condition__c, 
                                                    UNITY_YTD_Service_Time__c,
                                                    UNITY_Is_Under_Warranty__c, 
                                                    UNITY_Last_Year_Down_Time__c,
                                                    UNITY_Last_Year_Service_Time__c,
                                                    UNITY_YTD_Total_Cost_Ownership__c
                                            FROM Asset
                                            WHERE Id IN :assetsId]);
    }

    /*
     * Name : checkThisYearValues
     * Param 1 : new Record
     * Param 2 : old Record
     */
    private void checkThisYearValues(UNITY_Asset_History__c newAH, UNITY_Asset_History__c oldAH){

        Date    today      = Date.today();
        Decimal aux_time   = 0;
        Boolean aux_update = false;

        if((newAH.UNITY_Start_Date__c <= today)&& (today <= newAH.UNITY_End_Date__c)){

            if(Trigger.isInsert && !updateThisYearOnAsset.isEmpty() &&updateThisYearOnAsset.get(newAH.UNITY_Asset__c)!=null){
                updateThisYearOnAsset.get(newAH.UNITY_Asset__c).UNITY_Current_Fiscal_Year__c            = newAH.UNITY_FiscalYear__c;
                updateThisYearOnAsset.get(newAH.UNITY_Asset__c).UNITY_Current_Fiscal_Year_End_Date__c   = newAH.UNITY_End_Date__c;
                updateThisYearOnAsset.get(newAH.UNITY_Asset__c).UNITY_Current_Fiscal_Year_Start_Date__c = newAH.UNITY_Start_Date__c;
            }
            
            if((newAH.UNITY_Down_Time__c!=null)||(newAH.UNITY_Down_Time__c!=0)){
                /*
                if((oldAH!=null)&&(newAH.UNITY_Down_Time__c != oldAH.UNITY_Down_Time__c))
                    aux_time = (newAH.UNITY_Down_Time__c - ((oldAH.UNITY_Down_Time__c == null)? 0:oldAH.UNITY_Down_Time__c));

                if(oldAH==null)    
                    aux_time = newAH.UNITY_Down_Time__c;

                if((aux_time!=null) && (aux_time>0)){
                    if(update_down_time_onAsset.get(newAH.UNITY_Asset__c)==null) update_down_time_onAsset.put(newAH.UNITY_Asset__c,0);
                    update_down_time_onAsset.put(newAH.UNITY_Asset__c, (( aux_time==null)?0:aux_time) + update_down_time_onAsset.get(newAH.UNITY_Asset__c));
                }*/
                if((oldAH!=null)&&(newAH.UNITY_Down_Time__c != oldAH.UNITY_Down_Time__c)) aux_update = true;
                
                if(oldAH==null) aux_update = true;

                if(aux_update)
                    if(update_down_time_onAsset.get(newAH.UNITY_Asset__c)==null) 
                        update_down_time_onAsset.put(newAH.UNITY_Asset__c,newAH.UNITY_Down_Time__c);
                    
            }

            if((newAH.UNITY_Service_Time__c!=null)||(newAH.UNITY_Service_Time__c!=0)){
                
                aux_update = false;
                /*
                if((oldAH!=null)&&(newAH.UNITY_Service_Time__c != oldAH.UNITY_Service_Time__c))
                    aux_time = (newAH.UNITY_Service_Time__c - ((oldAH.UNITY_Service_Time__c == null)? 0:oldAH.UNITY_Service_Time__c));

                if(oldAH==null)    
                    aux_time = newAH.UNITY_Service_Time__c;

                system.debug('>>> aux_time '+aux_time);
                if((aux_time!=null) && (aux_time>0)){
                    if(update_service_time_onAsset.get(newAH.UNITY_Asset__c)==null) update_service_time_onAsset.put(newAH.UNITY_Asset__c,0);
                    update_service_time_onAsset.put(newAH.UNITY_Asset__c, aux_time + update_service_time_onAsset.get(newAH.UNITY_Asset__c));
                }*/

                if((oldAH!=null)&&(newAH.UNITY_Service_Time__c != oldAH.UNITY_Service_Time__c)) aux_update = true;
                
                if(oldAH==null) aux_update = true;
                
                if(aux_update)
                    if(update_service_time_onAsset.get(newAH.UNITY_Asset__c)==null) 
                        update_service_time_onAsset.put(newAH.UNITY_Asset__c, newAH.UNITY_Service_Time__c);
                
            }

            if((newAH.UNITY_Total_Cost_Ownership__c!=null)||(newAH.UNITY_Total_Cost_Ownership__c!=0)){
                /*
                if((oldAH!=null)&&(newAH.UNITY_Total_Cost_Ownership__c != oldAH.UNITY_Total_Cost_Ownership__c))
                    aux_time = (newAH.UNITY_Total_Cost_Ownership__c - ((oldAH.UNITY_Total_Cost_Ownership__c == null)? 0:oldAH.UNITY_Total_Cost_Ownership__c));

                if(oldAH==null)    
                    aux_time = newAH.UNITY_Total_Cost_Ownership__c;

                if(update_TCO_onAsset.get(newAH.UNITY_Asset__c)==null) update_TCO_onAsset.put(newAH.UNITY_Asset__c,0);
                    update_TCO_onAsset.put(newAH.UNITY_Asset__c,(( aux_time==null)?0:aux_time) + update_TCO_onAsset.get(newAH.UNITY_Asset__c));*/
                
                aux_update = false;

                if((oldAH!=null)&&(newAH.UNITY_Total_Cost_Ownership__c != oldAH.UNITY_Total_Cost_Ownership__c)) aux_update = true;
                
                if(oldAH==null) aux_update = true;
                system.debug('>>> aux_time '+aux_update);
                if(aux_update)
                    if(update_TCO_onAsset.get(newAH.UNITY_Asset__c)==null) 
                        update_TCO_onAsset.put(newAH.UNITY_Asset__c, newAH.UNITY_Total_Cost_Ownership__c);
            }
        }
    }


    /*
     * Name : updateThisYearOnAssets
     */
    private void updateThisYearOnAssets(){

        Boolean assetUpdated = false;
        system.debug('>>> assetsDataMap '+assetsDataMap);
        for(Asset onAsset :assetsDataMap.values()){

            assetUpdated = false;

            if(update_down_time_onAsset.get(onAsset.Id)!=null){
                //if(onAsset.UNITY_YTD_Down_Time__c==null)onAsset.UNITY_YTD_Down_Time__c =0;
                //onAsset.UNITY_YTD_Down_Time__c += update_down_time_onAsset.get(onAsset.Id);
                onAsset.UNITY_YTD_Down_Time__c = update_down_time_onAsset.get(onAsset.Id);
                assetUpdated = true ;
            }

            if(update_service_time_onAsset.get(onAsset.Id)!=null){

                //if(onAsset.UNITY_YTD_Service_Time__c==null)onAsset.UNITY_YTD_Service_Time__c =0;
                //onAsset.UNITY_YTD_Service_Time__c += update_service_time_onAsset.get(onAsset.Id);
                onAsset.UNITY_YTD_Service_Time__c = update_service_time_onAsset.get(onAsset.Id);
                assetUpdated = true ;
                system.debug('>>> onAsset.UNITY_YTD_Service_Time__c '+onAsset.UNITY_YTD_Service_Time__c);
            }

            system.debug('>>> update_TCO_onAsset '+update_TCO_onAsset);
            if(update_TCO_onAsset.get(onAsset.Id)!=null){

                //if(onAsset.UNITY_YTD_Total_Cost_Ownership__c==null)onAsset.UNITY_YTD_Total_Cost_Ownership__c =0;
                //onAsset.UNITY_YTD_Total_Cost_Ownership__c += update_TCO_onAsset.get(onAsset.Id);
                onAsset.UNITY_YTD_Total_Cost_Ownership__c = update_TCO_onAsset.get(onAsset.Id);
                assetUpdated = true ;
            }

            if(!updateThisYearOnAsset.isEmpty() && (updateThisYearOnAsset.get(onAsset.Id)!=null))
                assetUpdated = true ;

            if(assetUpdated) assetsToUpdateMap.put(onAsset.Id, onAsset);
        }
        if(!assetsToUpdateMap.isEmpty()) update assetsToUpdateMap.values();
    }


}