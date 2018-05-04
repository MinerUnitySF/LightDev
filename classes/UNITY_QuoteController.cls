/**
 * @programer: Rodrigo Birriel
 * @date:      03/06/2016
 */
public with sharing class UNITY_QuoteController {
    public UNITY_Proposal__c relatedTo {get; set;}
    public Id quoteID { get;
                        set {   
                                quoteID = value;
                                List<UNITY_Proposal__c> proposals = [SELECT Id,Name,UNITY_Agent__c,UNITY_Case_Thread_ID__c,CreatedDate,
                                                                            UNITY_Customer_PIN__c,UNITY_Email_Logo_URL__c,UNITY_Shared_to_Contact__c,
                                                                            UNITY_Work_Order__c,UNITY_Total_Price__c,RecordTypeId,
                                                                            UNITY_Work_Order__r.UNITY_Business_Unit_Account__r.Name,
                                                                            UNITY_Work_Order__r.workOrderNumber,UNITY_Business_Unit_Account__r.Website,
                                                                            UNITY_Work_Order__r.UNITY_Customer__c                                                     
                                                                     FROM UNITY_Proposal__c WHERE Id =: quoteID];
                                if(!proposals.isEmpty()) {
                                    relatedTo = proposals.get(0);
                                    List<User> users = [SELECT Id,TimeZoneSidKey FROM User WHERE Id =: relatedTo.UNITY_Agent__c];
                                    if(!users.isEmpty()){
                                        UNITY_Utils.DateTimeZone dtz = UNITY_Utils.getDateTime(relatedTo.CreatedDate,
                                                                                          'MMM d,  yyyy',
                                                                                          users.get(0).TimeZoneSidKey);
                                        CreatedDate= dtz.format;
                                    }   
                                    if(relatedTo.UNITY_Business_Unit_Account__r != null && relatedTo.UNITY_Business_Unit_Account__r.Website != null) {
                                        String site = relatedTo.UNITY_Business_Unit_Account__r.Website;
                                        beginSite = site.substringBefore('.');
                                        middleSite = site.substring(site.indexOf('.'), site.lastIndexOf('.')+1);
                                        endSite = site.substringAfterLast('.');
                                    }
                                }
                            }
    }
    
    public String CreatedDate{get;set;}
    
    public String beginSite {get; set;}
    public String middleSite {get; set;}
    public String endSite {get; set;}
}