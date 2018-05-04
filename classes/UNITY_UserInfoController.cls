/**
 * @programer: Rodrigo Birriel
 * @date:      01/28/2016
 */
public class UNITY_UserInfoController {
    public Id userId {     get; 
                           set {
                               userId = value;
                               retrieveUser(value,NULL);
                           }
                     }
    public Id contactId {   get;
                            set {
                               retrieveUser(NULL,value);
                           }
                        }
    
    public Id accountId {
                            get;
                            set {
                                retrieveAccount(value);
                            }
        
                        }
    
    public InfoDetail infoDetail {get; set;}
    
    private void retrieveUser(Id aUserId, Id aContactId) {
        List<User> users = new List<User>();
        if(aUserId != NULL){
            users = [SELECT Name,City,CompanyName,Country,Address,Email,Phone,State,PostalCode,Street,Contact.Account.Name
                                        FROM User
                                        WHERE Id=:aUserId];
        } else if(aContactId != NULL){
            users = [SELECT Name,City,CompanyName,Country,Address,Email,Phone,State,PostalCode,Street,Contact.Account.Name
                                        FROM User
                                        WHERE ContactId IN (SELECT Id FROM Contact WHERE Id =:aContactId)];
        }
        if(!users.isEmpty()) { 
            infoDetail = new InfoDetail(users.get(0));
        } 
    }
    
    private void retrieveAccount(Id accountId) {
        for(Account account : [SELECT Id, Name, UNITY_Account_ID__c, BillingCity, BillingCountry, BillingStreet, BillingState, BillingPostalCode 
                               FROM Account 
                               WHERE Id =:accountId]){
            infoDetail = new InfoDetail(account);
        }
    }
    
    public class InfoDetail {
        public String name {get; set;}
        public String companyName {get; set;} 
        public String city {get; set;}
        public String country {get; set;} 
        public String street {get; set;}
        public String phone {get; set;}
        public String email {get; set;}
        public String state {get; set;}
        public String zip {get; set;}
        
        public InfoDetail(User user) {
            name = user.Name;
            companyName = user.CompanyName;
            city = user.City;
            country = user.Country;
            street = user.Street;
            phone = user.Phone;
            email = user.Email;
            state = '';
            zip = '';
        }
        
        public InfoDetail(Account account) {
            name = account.Name;
            companyName = account.UNITY_Account_ID__c;
            city = account.BillingCity;
            country = account.BillingCountry;
            street = account.BillingStreet;
            state = account.BillingState;
            zip = account.BillingPostalCode;
        }
    }
    
}