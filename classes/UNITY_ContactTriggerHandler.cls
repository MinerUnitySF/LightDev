/*
 *   @programer:    Rodrigo Birriel
 *   @description:  handle the contact trigger.
 *   @date:         12/??/2015            
 */
public class UNITY_ContactTriggerHandler extends UNITY_BaseHandler {

    /*
    public override void bulkAfter() {
        try {
            //REVIEW: the users are added manually, perhaps this method could be deleted.
            //handleTradeVendorsFlow();
        } catch(Exception ex) {
            for(Contact contact : (List<Contact>)Trigger.new) {
                contact.addError(ex.getMessage());
            }
        }
        
    }
   
    private void handleTradeVendorsFlow() {
        if(Trigger.isInsert || Trigger.isUpdate) {
            Map<Id,Account> accountsMap = buildAccountMapRelatedToAccount(Trigger.new);
            List<Contact> contactsWithAccountAsVendorRelated = contactWithAccountAsVendorRelated(accountsMap);
            if( contactsWithAccountAsVendorRelated.size() > 0) {
                // keep the list of vendor trade for each vendor account
                Map<Id,List<UNITY_Vendor_Trade__c>> accountVendorTradesMap = buildAccountVendorTradesMap(contactsWithAccountAsVendorRelated);
                
                // obtain the vendor profile.
                Profile partnerTechnicianVendor = [SELECT Id FROM Profile 
                                                   WHERE Name =:UNITY_Constants.PROFILE_PARTNER_TECHNICIAN_VENDOR_NAME 
                                                   LIMIT 1];
                handleTradeVendors(contactsWithAccountAsVendorRelated, 
                                   partnerTechnicianVendor,
                                  accountVendorTradesMap);
            }   
        }
    }
    
    private Map<Id,Account> buildAccountMapRelatedToAccount(List<Contact> contactsWithVendorAccount) {
        Map<Id,Account> accountMap = new Map<Id,Account>();
        List<Id> accountIds = new List<Id>();
        for(Contact contact : contactsWithVendorAccount) {
            if(contact.AccountId != null) {
                accountIds.add(contact.AccountId);    
            }
        }
        
        for(Account account : [SELECT Id,RecordTypeID FROM Account 
                               WHERE Id IN :accountIds]) {
            accountMap.put(account.Id, account);               
        }
        return accountMap;
    }
    
    *
     *  Generate a map to keep the vendor trades related to a Vendor.
     *
     * 
    private Map<Id,List<UNITY_Vendor_Trade__c>> buildAccountVendorTradesMap(List<Contact> contactsWithVendorAccount) {
        
        List<Id> accountIds = new List<Id>();
        Map<Id,List<UNITY_Vendor_Trade__c>> accountVendorTradesMap = new Map<Id,List<UNITY_Vendor_Trade__c>>();
        
        for(Contact contact : contactsWithVendorAccount) {
            accountIds.add(contact.AccountId);
        }
     
        // recover all the vendor trade related to the vendor account
        // and build the mapping Account -> List<UNITY_Vendor_Trade__c>
        
        for(UNITY_Vendor_Trade__c vendorTrade : [SELECT Id,Vendor__c, Trade__c FROM UNITY_Vendor_Trade__c 
                                                 WHERE Vendor__c in :accountIds]){
             List<UNITY_Vendor_Trade__c> vendorTrades = accountVendorTradesMap.get(vendorTrade.Vendor__c);                               
             if(vendorTrades == null) {
                 vendorTrades = new List<UNITY_Vendor_Trade__c>();
                 accountVendorTradesMap.put(vendorTrade.Vendor__c,vendorTrades);
             }
             vendorTrades.add(vendorTrade);                                   
        } 
        
        return accountVendorTradesMap;
    }
    
     *
     * Filter by new contact or updated contact that contact.
     * Account changes when contact.account is a vendor. 
     * 
    private List<Contact> contactWithAccountAsVendorRelated(Map<Id,Account> accountsMap) {
        List<Contact> contactsWithAccountVendors = new List<Contact>();
        List<Contact> newContacts = Trigger.new;
        List<Contact> oldContacts;
        if(Trigger.isInsert) {
            oldContacts = newContacts;
        } else if(Trigger.isUpdate) {
            oldContacts = Trigger.old;
        }
        
        Contact contact, oldContact;
        Account account;
        for(Integer index = 0; index<newContacts.size(); index++) {
            contact =  newContacts.get(index);
            oldContact = oldContacts.get(index);
            account = accountsMap.get(contact.AccountId);
            if((Trigger.isInsert ||
              (Trigger.isUpdate && oldContact.AccountId != contact.AccountId)) &&
                contact.AccountId != null &&
                account.RecordTypeID == UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE) {
                    contactsWithAccountVendors.add(contact);
                }
        }
        
        return contactsWithAccountVendors;
    }
    
    private void handleTradeVendors(List<Contact> vendors, Profile technicalVendor,
                                   Map<Id,List<UNITY_Vendor_Trade__c>> accountVendorTradesMap) {
        List<User> technicianVendors = new List<User>();
        Map<Id,Contact> contactIdContactMap = new Map<Id,Contact>();
        for(Contact contact : vendors){
            User technicianVendor = createUserAsTechnicianVendor(contact,technicalVendor.Id);
            contactIdContactMap.put(contact.Id, contact);
            technicianVendors.add(technicianVendor);
        }
                                      
        insert technicianVendors;
        
        List<ProfileSkillUser> profileSkillUsers = new List<ProfileSkillUser>();                               
                                       
        // iterate over the technician vendors create, to obtain the 
        // related contact to access to the list of vendor trades,
        // to create the skill user between vendor and vendor trade.                              
        for(User vendor : technicianVendors) {
            Contact contact = contactIdContactMap.get(vendor.ContactId);
            List<UNITY_Vendor_Trade__c> vendorTrades = accountVendorTradesMap.get(contact.AccountId);
            if(vendorTrades != null && !vendorTrades.isEmpty()){
                System.debug(JSON.serialize(vendorTrades));
                for(UNITY_Vendor_Trade__c vendorTrade : vendorTrades) {
                    ProfileSkillUser skillUser = new ProfileSkillUser(ProfileSkillId=vendorTrade.Trade__c,
                                                                     UserId=vendor.Id);
                    profileSkillUsers.add(skillUser);
                }
            } 
        }
                                       
        if(!profileSkillUsers.isEmpty()) {
           insert profileSkillUsers;
        }                               
    }
    
    private User createUserAsTechnicianVendor(Contact contact, Id profileId) {
        User user = new User();
        user.ContactId = contact.Id;
        user.ProfileId = profileId;
        user.Username = contact.Email;
        user.LastName = contact.LastName;
        user.Alias = contact.LastName.substring(0,Math.min(contact.LastName.length()-1,7));
        user.Email = contact.Email;
        user.CommunityNickname = contact.LastName;
        // REVIEW: check with Hao. //
        user.TimeZoneSidKey = 'America/Chicago';
        user.LocaleSidKey = 'en_US';
        user.EmailEncodingKey = 'UTF-8';
        user.LanguageLocaleKey = 'en_US';
        //////////////////////////////
        
        return user;
    }
    */
}