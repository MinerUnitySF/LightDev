public class UNITY_AuraAccountRedirectController {
	@AuraEnabled
    public static User getLoggedInUser(){
        return [SELECT Contact.AccountId FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
    }
}