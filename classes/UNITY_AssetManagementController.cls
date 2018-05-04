/*
 *
 * Name  : UNITY_AssetManagementController
 * Note  : Page Controller fot UNITY_AssetManagement, let the user  
 *         transfer asset and all its child asset the the target account
 * Date  : 5/11/2016
 *
 *
 *
 */

public with sharing class UNITY_AssetManagementController {

    @TestVisible private Id fromAccountId {set;get;}
    public  String             transferTo    {set;get;}
    public  String             search_name   {set;get;}
    public  Integer            n_accounts    {set;get;}
    public  Map<Id,Account>    accounts      {set;get;}
    public  List<wrapperAsset> assets        {set;get;}
    public  List<SelectOption> accountOptions{set;get;}
    
    public UNITY_AssetManagementController(ApexPages.StandardController stdController) {
        this.fromAccountId = stdController.getId();
        this.init();
    }

    public UNITY_AssetManagementController() {
        this.fromAccountId = ApexPages.currentPage().getParameters().get('id');
        this.init();
    }

    private void init(){
        this.assets   = this.getRootAssets();
        this.accounts = new Map<Id,Account>();
        this.n_accounts = 0;
    }

    private List<wrapperAsset> getRootAssets(){
        List<wrapperAsset> toReturn = new List<wrapperAsset>();

        for(Asset var :[SELECT  Id, 
                                Name, 
                                UNITY_Make__c, 
                                UNITY_Model__c, 
                                SSVY_ScanCode__c,
                                UNITY_YTD_Down_Time__c,
                                SSVY_Asset_Condition__c, 
                                UNITY_YTD_Service_Time__c,
                                UNITY_Is_Under_Warranty__c, 
                                UNITY_Last_Year_Down_Time__c,
                                UNITY_Last_Year_Service_Time__c,
                                (SELECT Id, 
                                        UNITY_Asset__c,
                                        UNITY_Account__c,
                                        UNITY_End_Date__c,
                                        UNITY_Down_Time__c,
                                        UNITY_Start_Date__c,
                                        UNITY_FiscalYear__c,
                                        UNITY_Service_Time__c
                                FROM    Asset_History__r 
                                WHERE   (UNITY_Account__c = :this.fromAccountId) 
                                        AND (UNITY_Start_Date__c <= TODAY)
                                        AND (UNITY_End_Date__c   >= TODAY))
                        FROM Asset 
                        WHERE (AccountId = :this.fromAccountId) AND (ParentId = null)]){


            toReturn.add(new wrapperAsset(var));
        }
        return toReturn;
    }

    public void search(){

        accountOptions = new List<SelectOption>();

        String searchFor = '%'+search_name+'%'; 

        if ((search_name!=null) && (search_name.trim()!='')) 
           this.accounts = new Map<Id,Account>([SELECT Id, Name, UNITY_Fiscal_Year_Based_On__c, UNITY_Fiscal_Year_Start_Month__c FROM Account WHERE Name LIKE :searchFor AND Id != :this.fromAccountId ]);
        else this.accounts = new Map<Id,Account>([SELECT Id, Name, UNITY_Fiscal_Year_Based_On__c, UNITY_Fiscal_Year_Start_Month__c FROM Account where Id != :this.fromAccountId LIMIT 20]);

        this.n_accounts = this.accounts.size();
        
        for(Account acc :this.accounts.values()){
            accountOptions.add(new SelectOption(acc.Id, acc.Name));
        }
    }

    public PageReference transfer(){

        Set<Id>                 rootAssetSelectedIds    = new Set<Id>();
        Map<Id,Asset>           toTransfer              = new Map<Id,Asset>();
        PageReference           pageToGo;
        
        
        
        if ((transferTo!=null) && ((transferTo.trim().length()==15)||(transferTo.trim().length()==18))){
            for(wrapperAsset var :assets){
                if(var.tranfer){
                    toTransfer.put(var.record.Id,var.record);
                    rootAssetSelectedIds.add(var.record.Id);
                } 
            }
            toTransfer.putAll(this.getChildAssets(fromAccountId,rootAssetSelectedIds));
            this.cloneAssets(transferTo.trim(), toTransfer);
        } 
        return pageToGo;
    }

    private void cloneAssets(Id newAccount , Map<Id,Asset> assetsMap){

        Datetime                     aux_datetime_now = DateTime.now();
        List<Asset>                  toUpdate  = new List<Asset>();
        UNITY_Asset_History__c       aux_asset_history;
        List<UNITY_Asset_History__c> toUpsert_assetHistory = new List<UNITY_Asset_History__c>();
        UNITY_AssetAvailability.FiscalYear aux_newAccountFiscalYeard;

        if((accounts.get(newAccount)!=null)&& (accounts.get(newAccount).UNITY_Fiscal_Year_Start_Month__c!=null) && (accounts.get(newAccount).UNITY_Fiscal_Year_Based_On__c!=null))
            aux_newAccountFiscalYeard = new UNITY_AssetAvailability.FiscalYear(Integer.valueOf(accounts.get(newAccount).UNITY_Fiscal_Year_Start_Month__c),accounts.get(newAccount).UNITY_Fiscal_Year_Based_On__c);

        for(Asset var :assetsMap.values()){
            var.AccountId  = newAccount;

            // Reset times , it is done by the asset trigger when the account changes too
            var.UNITY_YTD_Down_Time__c           = 0;
            var.UNITY_YTD_Service_Time__c        = 0;
            var.UNITY_Last_Year_Down_Time__c     = 0;
            var.UNITY_Last_Year_Service_Time__c  = 0;
            var.UNITY_LY_Total_Cost_Ownership__c = 0;
            var.UNITY_YTD_Total_Cost_Ownership__c= 0;
/*
            var.UNITY_Current_Fiscal_Year__c = aux_newAccountFiscalYeard.getAssetHitoryYear(aux_datetime_now);
            var.UNITY_Current_Fiscal_Year_End_Date__c = aux_newAccountFiscalYeard.getYearEnd(aux_datetime_now);
            var.UNITY_Current_Fiscal_Year_Start_Date__c = aux_datetime_now.date();
*/

            system.debug('>>> asset '+var.Name);
            system.debug('>>> asset '+var.Asset_History__r.size());

            for(UNITY_Asset_History__c asset_history :var.Asset_History__r){

                aux_asset_history                       = asset_history.clone(false,true,false,false);

                aux_asset_history.UNITY_Account__c      = newAccount;
                aux_asset_history.UNITY_Down_Time__c    = 0;
                aux_asset_history.UNITY_Start_Date__c   = Date.today();
                aux_asset_history.UNITY_Service_Time__c = 0;
                aux_asset_history.UNITY_Total_Cost_Ownership__c = 0;
                if(aux_newAccountFiscalYeard!=null)
                    aux_asset_history.UNITY_FiscalYear__c   = aux_newAccountFiscalYeard.getAssetHitoryYear(aux_datetime_now);

                asset_history.UNITY_End_Date__c         = Date.today().addDays(-1);

                toUpsert_assetHistory.add(aux_asset_history);
                toUpsert_assetHistory.add(asset_history);
            }
                toUpdate.add(var);
        }

        if(!toUpdate.isEmpty()){
            try{
                update toUpdate;
                upsert toUpsert_assetHistory;
                this.init();
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'Transference Complete.'));
            }catch(Exception e){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage())); 
            }
        }
    }


    private List<Asset> getChildAssets(Id accountFromId, Set<Id> rootAssetsId){

        List<Asset> toReturn = new List<Asset>();

        return [SELECT  Id, 
                        Name, 
                        ParentId,
                        Quantity,
                        Product2Id,
                        RootAssetId,
                        UNITY_Make__c, 
                        UNITY_Model__c, 
                        SSVY_ScanCode__c,
                        UNITY_YTD_Down_Time__c,
                        SSVY_Asset_Condition__c, 
                        UNITY_YTD_Service_Time__c,
                        UNITY_Is_Under_Warranty__c, 
                        UNITY_Last_Year_Down_Time__c,
                        UNITY_Last_Year_Service_Time__c,
                        (SELECT Id, 
                                UNITY_Asset__c,
                                UNITY_Account__c,
                                UNITY_End_Date__c,
                                UNITY_Down_Time__c,
                                UNITY_Start_Date__c,
                                UNITY_FiscalYear__c,
                                UNITY_Service_Time__c
                        FROM    Asset_History__r 
                        WHERE   (UNITY_Account__c = :accountFromId)
                                AND (UNITY_Start_Date__c <= TODAY)
                                AND (UNITY_End_Date__c   >= TODAY))
                FROM Asset 
                WHERE (RootAssetId IN :rootAssetsId) AND (Id NOT IN :rootAssetsId)];

    }

    public class wrapperAsset{
        public boolean tranfer   {get;set;}
        public Asset   record    {get;set;}
        public wrapperAsset(Asset a){
            record = a;
        }
    }
}