public class UNITY_AssetChildListController{

    public Asset asset {get;set;}
    public List<Asset> assetChildList {get;set;}
    
    public UNITY_AssetChildListController(ApexPages.StandardController stdController) {
        this.asset = (Asset)stdController.getRecord();
        assetChildList = [SELECT Name, Id, UNITY_Make__c, UNITY_Model__c, SSVY_ScanCode__c, SSVY_Asset_Condition__c, UNITY_Is_Under_Warranty__c FROM Asset WHERE ParentId =: asset.Id];
    }
}