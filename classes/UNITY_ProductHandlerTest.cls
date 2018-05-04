@isTest
public class UNITY_ProductHandlerTest {

    static testMethod void changeActiveDependOnStatusTest() {
        Product2 product = new Product2(Name = 'Test');
        product.UNITY_Status__c = 'Active';
        product.Make1__c = 'test';
        product.Model__c = 'test';
        product.Description = 'test';
        product.Broad__c = 'MHE';
        product.UNITY_Product_Cost__c = 123.0;
        product.Group__c = 'Battery';
        product.UNITY_Unit_Of_Measure__c = 'Hour';
        product.Type__c = 'Walkie';
        insert product;
        
        product = [SELECT Id,UNITY_Status__c,IsActive FROM Product2 LIMIT 1];
        
        System.assert(product.UNITY_Status__c == 'Active','The status should be Active,'+product.UNITY_Status__c);
        System.assert(product.IsActive,'The IsActive field should be inactive,'+product.IsActive);
        
    }
    
}