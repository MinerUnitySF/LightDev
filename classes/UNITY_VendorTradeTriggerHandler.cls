/*
 *   @programer:    Rodrigo Birriel
 *   @description:  handle the vendor trade trigger.
 *   @date:         12/10/2015            
 */
public class UNITY_VendorTradeTriggerHandler extends UNITY_BaseHandler{

    public override void bulkBefore() {
        try {
            handleVendorTradeFlow();
        } catch(Exception ex) {
            List<UNITY_Vendor_Trade__c> vendorTrades;
            if(Trigger.isInsert) {
                vendorTrades = (List<UNITY_Vendor_Trade__c>)Trigger.new;
            } else if(Trigger.isDelete) {
                vendorTrades = (List<UNITY_Vendor_Trade__c>)Trigger.old;
            }
            for(UNITY_Vendor_Trade__c vendorTrade : vendorTrades) {
                vendorTrade.addError(ex.getMessage());
            }
        }
        
    }
    
    private void handleVendorTradeFlow(){
        if(Trigger.isInsert && checkVendorTradesIntegrity((List<UNITY_Vendor_Trade__c>)Trigger.new)) {
            addSkillUsersRelatedToVendorTrades((List<UNITY_Vendor_Trade__c>) Trigger.new);
        } else if (Trigger.isDelete) {
            deleteSkillUsersRelatedToVendorTrades((List<UNITY_Vendor_Trade__c>) Trigger.old);
        }
    }
 
    /*
     * Delete the skill users related to vendor trades deleted
     */  
    private void deleteSkillUsersRelatedToVendorTrades(List<UNITY_Vendor_Trade__c> vendorTrades){
        List<Id> tradeIds = UNITY_Utils.joiningByFieldList(vendorTrades,'Trade__c');
        List<Id> accountIds = UNITY_Utils.joiningByFieldList(vendorTrades,'Vendor__c');
        List<Id> userIds = new List<Id>();
        for(User user : UNITY_Vendor_Utils.retrieveUsersConcerningToVendorTrades(accountIds)) {
            userIds.add(user.Id);
        }
        // delete the skillUsers record associated to user mention above
        // and trades belongs to vendor trades.
        delete [SELECT Id FROM FSO__SkillUser__c 
                WHERE FSO__User__c IN (SELECT Id FROM User WHERE Id IN : userIds) 
                AND FSO__Skill__c IN (SELECT Id FROM FSO__Skill__c WHERE Id IN : tradeIds)];
    }
    
    /*
     * Add the skill users related to vendor trades added
     */
    private void addSkillUsersRelatedToVendorTrades(List<UNITY_Vendor_Trade__c> vendorTrades){
        
        List<Id> accountIds = UNITY_Utils.joiningByFieldList(vendorTrades,'Vendor__c');
        
        // map to keep the users related to an account
        Map<Id,List<User>> accountIdToListUsers = new Map<Id,List<User>>();
        for(User user : UNITY_Vendor_Utils.retrieveUsersConcerningToVendorTrades(accountIds)) {
            List<User> users = accountIdToListUsers.get(user.Contact.AccountId);
            if(users == null){
                users = new List<User>();
                accountIdToListUsers.put(user.Contact.AccountId, users);
            }
            users.add(user);
        }
        
        // map to keep the trade ids related to an account
        Map<Id,List<Id>> accountIdToListTradeIds = new Map<Id,List<Id>>();
        for(UNITY_Vendor_Trade__c vendorTrade : vendorTrades) {
            List<Id> tradeIds = accountIdToListTradeIds.get(vendorTrade.Vendor__c);
            if(tradeIds == null){
                tradeIds = new List<Id>();
                accountIdToListTradeIds.put(vendorTrade.Vendor__c, tradeIds);
            }
            tradeIds.add(vendorTrade.Trade__c);
        }
        
        List<FSO__SkillUser__c> skillUsers = new List<FSO__SkillUser__c>();
        
        // generate user skills record for the list of users and trades related to the accounts
        // REVIEW: optimize nested loops
        System.debug('>>>>>>>>>>>>>accountIds:'+accountIds);
        for(Id accountId : accountIds) {
            if(accountIdToListUsers.get(accountId) != null) {
                System.debug('++++++accountIdToListUsers:'+accountIdToListUsers.get(accountId));
                for(User user : accountIdToListUsers.get(accountId)) {
                    for(Id tradeId : accountIdToListTradeIds.get(accountId)) {
                        System.debug('++++++accountIdToListTradeIds:'+accountIdToListTradeIds.get(accountId));
                        FSO__SkillUser__c skillUser = new FSO__SkillUser__c(FSO__Skill__c=tradeId,
                                                                          FSO__User__c=user.Id);
                        skillUsers.add(skillUser);
                    }
                } 
            }

        }
        if(!skillUsers.isEmpty()) {
            insert skillUsers;    
        }
    }
    
    /*
     * Verify the integrity of the Vendor Trades records, validating the compound key by
     * vendor accounts and trades.
     */ 
    private Boolean checkVendorTradesIntegrity(List<UNITY_Vendor_Trade__c> vendorTrades) {
        List<Id> vendorAccountIds = new List<Id>();
        List<Id> tradeIds = new List<Id>();
        Set<String> currentVendorTradeSet = new Set<String>();
        for(UNITY_Vendor_Trade__c vendorTrade : vendorTrades) {
            vendorAccountIds.add(vendorTrade.Vendor__c);
            tradeIds.add(vendorTrade.Trade__c);
            String compoundKey = (String)vendorTrade.Vendor__c+(String)vendorTrade.Trade__c;
            currentVendorTradeSet.add(compoundKey);
        }
        List<String> vendorTradeSavedList = new List<String>();
        for(UNITY_Vendor_Trade__c vendorTradeSaved : [SELECT Id,Vendor__c,Trade__c FROM UNITY_Vendor_Trade__c
                                                      WHERE Vendor__c IN :vendorAccountIds AND
                                                      Trade__c IN : tradeIds]) {
            String compoundKey = (String)vendorTradeSaved.Vendor__c+(String)vendorTradeSaved.Trade__c;                                              
            vendorTradeSavedList.add(compoundKey);                  
        }
        Boolean result = currentVendorTradeSet.retainAll(vendorTradeSavedList);
        
        if(!result) {
            throw new UNITY_VendorTradeDuplicatedException('Please review the Vendor and Trade fields, because there is another record with the same attributes');
        }
        return result;
    }
    
    public class UNITY_VendorTradeDuplicatedException extends Exception {}   
}