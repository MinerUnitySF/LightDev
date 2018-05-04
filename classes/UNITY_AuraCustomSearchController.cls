public class UNITY_AuraCustomSearchController {
    @AuraEnabled
    public static List<SObject> searchForIds(String searchText) {
        List<List<SObject>> results = [FIND :searchText IN ALL FIELDS  RETURNING Account(Id, Name, UNITY_LOC__c, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry,  Phone), Case(Id, CaseNumber, UNITY_Customer_WO__c,  Customer_Status__c, Most_Recent_Case_Notes__c, UNITY_Resolution__c), UNITY_Attachment__c(Id, Name, UNITY_Type__c, Work_Order__r.WorkOrderNumber)];
        List<SObject> ids = new List<SObject>();
        for (List<SObject> sobjs : results) {
          for (SObject sobj : sobjs) {
            ids.add(sobj);
          }
        }
        return ids;
    }
}