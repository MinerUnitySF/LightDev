/**This class serves as utility class for the account object
***@Developer: Izay Ramos-Irizarry
***@Date:      7/17/2015
***@Version:   1.0
*/
global class AccountUtil {
    
    webservice static String readyToConvert(String[] args){
        String result = 'Error: ';
        if(args.size() > 0){
            Map<Id,RecordType> recTypes = new Map<Id,RecordType>([SELECT Id,Name,DeveloperName FROM RecordType WHERE SObjectType = 'Account']);
            List<Account> accts = [SELECT Id,Name,RecordTypeId,Type,Account_Status__c FROM Account WHERE Id IN :args AND IsDeleted = FALSE];
            if(accts.size() > 0){
                for(Account a :accts){
                    if(recTypes.containsKey(a.RecordTypeId)){
                        string rtName = recTypes.get(a.RecordTypeId).Name;
                        if(rtName == 'FLEXX Accounts' && a.Type == 'Customer' && a.Account_Status__c == 'Prospect'){
                            a.Ready_to_Convert__c = true;
                            for(RecordType rt :recTypes.values()){
                                if(rt.Name == 'Prospect Accounts'){
                                    a.RecordTypeId = rt.Id;
                                    break;
                                }
                            }
                        }else if(rtName == 'FLEXX Accounts' && a.Type == 'Vendor' && a.Account_Status__c == 'Prospect'){
                            a.Ready_to_Convert__c = true;
                            for(RecordType rt :recTypes.values()){
                                if(rt.Name == 'Vendor Account'){
                                    a.RecordTypeId = rt.Id;
                                    break;
                                }
                            }
                        }
                    }
                }
                try{
                    update accts;
                    result = 'Success';
                }catch(Exception e){
                    result += e.getMessage();
                }
            }else{
                result += 'Account not found. Contact HELPDESK for help with this problem.';
            }
        }else{
            result += 'List of parameters is empty. Contact HELPDESK for help with this problem.';
        }
        return result;
    }
}