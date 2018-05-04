public with sharing class UNITY_ProductHandler extends UNITY_BaseHandler {
    
    public override void beforeUpdate(SObject oldSo, SObject so){
        Product2 product = (Product2) so;
        if(product.UNITY_Status__c == 'Active') {
            product.IsActive = true;
        } else if(product.UNITY_Status__c == 'Inactive') {
            product.IsActive = false;
        }

    }
    
}