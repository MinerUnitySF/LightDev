public class UNITY_CaseHandlerHelper{

    public static void populateNTEFromServiceContract(List<Case> caseList){
        List<Id> relatedServiceContract = new List<Id>();
        for (Case iter: caseList){
            relatedServiceContract.add(iter.UNITY_Customer_Service_Contract__c);
        }
        //Map<serviceContractId, List<tradeId, SCLI>>
        Map<Id, Map<String,UNITY_Service_Contract_Line_Item__c>> serviceContractLineByTradeMap = new Map<Id, Map<String,UNITY_Service_Contract_Line_Item__c>>();
        //Map<serviceContractId, serviceContract>
        Map<Id, UNITY_Service_Contract__c> serviceContractMap = new Map<Id, UNITY_Service_Contract__c>();
        
        List<UNITY_Service_Contract__c> serviceContractList = [select id,RecordTypeId , UNITY_Default_NTE__c, (select id, recordTypeId, UNITY_Priority__c, UNITY_Trade__c, Unity_NTE__c 
                                                                                                               from UNITY_Service_Contract_Line_Items__r) 
                                                               from UNITY_Service_Contract__c where id in: relatedServiceContract];
        for (UNITY_Service_Contract__c sc: serviceContractList){
            serviceContractMap.put(sc.Id, sc);
            serviceContractLineByTradeMap.put(sc.Id, new Map<String, UNITY_Service_Contract_Line_Item__c>());
            for (UNITY_Service_Contract_Line_Item__c scli: sc.UNITY_Service_Contract_Line_Items__r){
                if(scli.UNITY_Priority__c == null){ 
                    serviceContractLineByTradeMap.get(sc.Id).put(scli.UNITY_Trade__c, scli);
                } else {
                    serviceContractLineByTradeMap.get(sc.Id).put(scli.UNITY_Trade__c + scli.UNITY_Priority__c, scli);
                }
            }
        }
        
        System.debug('#serviceContractMap '+serviceContractMap);
        System.debug('#serviceContractLineByTradeMap '+serviceContractLineByTradeMap);
        
        for(Case iter: caseList){
            Id serviceContractId = iter.UNITY_Customer_Service_Contract__c;
            Id trade = iter.UNITY_Trade__c;
            String priority = iter.Priority;
            
            if(serviceContractMap.get(serviceContractId)!= null){
                if (iter.UNITY_NTE_Threshold__c == null){
                    if (trade != null && priority != null && serviceContractLineByTradeMap.get(serviceContractId) != null && serviceContractLineByTradeMap.get(serviceContractId).get(trade + priority) != null && serviceContractLineByTradeMap.get(serviceContractId).get(trade + priority).RecordTypeId == UNITY_Constants.SCLI_NTE_RECORDTYPE){ 
                        iter.UNITY_NTE_Threshold__c = serviceContractLineByTradeMap.get(serviceContractId).get(trade + priority).Unity_NTE__c;
                    }
                    else if (serviceContractMap.get(serviceContractId) != null && serviceContractMap.get(serviceContractId).UNITY_Default_NTE__c != null){
                        iter.UNITY_NTE_Threshold__c = serviceContractMap.get(serviceContractId).UNITY_Default_NTE__c;
                    }
                }
            } else {
                if (iter.UNITY_NTE_Threshold__c == null){
                    if (trade != null && serviceContractLineByTradeMap.get(serviceContractId) != null && serviceContractLineByTradeMap.get(serviceContractId).get(trade) != null){ 
                        iter.UNITY_NTE_Threshold__c = serviceContractLineByTradeMap.get(serviceContractId).get(trade).Unity_NTE__c;
                    }
                    else if (serviceContractMap.get(serviceContractId) != null && serviceContractMap.get(serviceContractId).UNITY_Default_NTE__c != null){
                        iter.UNITY_NTE_Threshold__c = serviceContractMap.get(serviceContractId).UNITY_Default_NTE__c;
                    }
                }
            }
        }
        System.debug('#caseList '+caseList);
    }
    
    public static void popoulateServiceContract(List<Case> caseList){
        
        Set<Id> relatedCustomerIdSet = new Set<Id>();
        Set<Id> relatedAccountIdSet = new Set<Id>();
        Set<Id> relatedbusUnitAccountIdSet = new Set<Id>();
        
        //collect customer account
        for(Case iter: caseList){
            relatedCustomerIdSet.add(iter.UNITY_Customer__c);
            relatedAccountIdSet.add(iter.AccountId);
            relatedbusUnitAccountIdSet.add(iter.UNITY_Business_Unit_Account__c);
        }
        
        // get related customer accounts
        List<Account> relatedCustomerList = [SELECT Id, ParentId, UNITY_Bill_To_Account__c, Residential__c,
                                            
                                            (SELECT Id, UNITY_Account__c, UNITY_Business_Unit__c, UNITY_End_Customer__c, Default_Customer_Service_Contract__c, Residential__c
                                            FROM Service_Contracts__r 
                                            WHERE RecordTypeId =:UNITY_Constants.SC_SERVICE_REQUEST_RECORDTYPE and UNITY_IS_Active__c = true)
                                            
                                            FROM Account WHERE id IN : relatedCustomerIdSet OR id IN : relatedbusUnitAccountIdSet];
        
        System.debug('Izay: relatedCustomerList: ' + JSON.serializePretty(relatedCustomerList));
        
        // get related accounts                                    
        //List<Account> relatedAccountList = [SELECT Id, ParentId, UNITY_Bill_To_Account__c FROM Account WHERE id IN : relatedAccountIdSet];
        Map<Id, Account> relatedAccountMap = new Map<Id, Account>( [SELECT Id, ParentId, UNITY_Bill_To_Account__c,Residential__c FROM Account WHERE id IN : relatedAccountIdSet] );

        Map<Id, List<UNITY_Service_Contract__c>> accountServiceContractMap = new Map<Id, List<UNITY_Service_Contract__c>>();
        Map<Id, List<UNITY_Service_Contract__c>> customerServiceContractMap = new Map<Id, List<UNITY_Service_Contract__c>>();
        
        Map<Id, Id> parentAccount = new Map<Id, Id>();
        Map<Id, Id> billToAccount = new Map<Id, Id>();
        
        //set the customer's service contract map
        for (Account iter: relatedCustomerList){
            
            if (iter.Service_Contracts__r != null){
                accountServiceContractMap.put(iter.Id, iter.Service_Contracts__r);
                customerServiceContractMap.put(iter.Id, iter.Service_Contracts__r);
            }
        }
        
        //set the account parent and billTo maps
        for (Account iter: relatedAccountMap.values() ){
            
            if (iter.ParentId != null){
                parentAccount.put(iter.Id, iter.ParentId);
            }
            
            if (iter.UNITY_Bill_To_Account__c != null){
                billToAccount.put(iter.Id, iter.UNITY_Bill_To_Account__c);
            }
        }
        
        //search for a contract in customer account
        for (Case iter: caseList){
            
            List<UNITY_Service_Contract__c> customerServiceContracts = accountServiceContractMap.get(iter.UNITY_Customer__c);
            
            //3rd Party Scenario
            if (iter.UNITY_Customer__c != iter.AccountId){
                setCustomerServiceContract3rdParty(iter, accountServiceContractMap.get(iter.UNITY_Customer__c), iter.AccountId);
            }
            else if (setCustomerServiceContract(iter, customerServiceContracts)){
                
                //the customer contract was populated so we stop the searching in parent and billToAccount
                parentAccount.remove(iter.AccountId);
                billToAccount.remove(iter.AccountId);
            }    
        }
        
        //search for a contract in customer parent account or customer bill to account

        List<UNITY_Service_Contract__c> serviceContractList = [select id, UNITY_Account__c, UNITY_End_Customer__c, UNITY_Business_Unit__c from UNITY_Service_Contract__c
                                                                    where RecordTypeId =:UNITY_Constants.SC_SERVICE_REQUEST_RECORDTYPE and UNITY_IS_Active__c = true and (UNITY_Account__c in: billToAccount.values() or UNITY_Account__c in: parentAccount.values())];
            
        //accountServiceContractMap = new Map<Id, List<UNITY_Service_Contract__c>>();
            
        for (UNITY_Service_Contract__c iter: serviceContractList){
        
            List<UNITY_Service_Contract__c> relatedServiceContract = accountServiceContractMap.get(iter.UNITY_Account__c);
            
            if (relatedServiceContract == null){
                relatedServiceContract = new List<UNITY_Service_Contract__c>();
            }
            
            relatedServiceContract.add(iter);
            
            accountServiceContractMap.put(iter.UNITY_Account__c, relatedServiceContract);
        }
            
        for (Case iter: caseList){
            
            if (iter.UNITY_Customer_Service_Contract__c == null){
                
                Boolean serviceContractPopulated = false;
                
                Id parentAccountId = parentAccount.get(iter.AccountId);
                Id billToAccountId = billToAccount.get(iter.AccountId);
                
                //3rd Party Scenario
                if (iter.UNITY_Customer__c != iter.AccountId){
                    //End Customer = parentAccount
                    serviceContractPopulated = setCustomerServiceContract3rdParty(iter, customerServiceContractMap.get(iter.UNITY_Customer__c), parentAccountId);
                    if (!serviceContractPopulated){
                        //End Customer = billToAccountId
                        serviceContractPopulated = setCustomerServiceContract3rdParty(iter, customerServiceContractMap.get(iter.UNITY_Customer__c), billToAccountId);
                    }
                    if (!serviceContractPopulated){
                        //End Customer = null
                        setCustomerServiceContract3rdParty(iter, customerServiceContractMap.get(iter.UNITY_Customer__c), null);
                    }
                }
                else{
                    //search in parent customer account
                    if (parentAccountId != null){
                        serviceContractPopulated = setCustomerServiceContract(iter, accountServiceContractMap.get(parentAccountId));
                    }
                    
                    //search in billToAccount
                    if (billToAccountId != null && !serviceContractPopulated){
                        serviceContractPopulated = setCustomerServiceContract(iter, accountServiceContractMap.get(billToAccountId));
                    }
                }
				System.debug('Izay: serviceContractPopulated = '+serviceContractPopulated);
                System.debug('Izay: iter.UNITY_Business_Unit_Account__c = ' + iter.UNITY_Business_Unit_Account__c);
                System.debug('Izay: accountServiceContractMap.containsKey( iter.UNITY_Business_Unit_Account__c) = ' + accountServiceContractMap.containsKey( iter.UNITY_Business_Unit_Account__c));
                if ( !serviceContractPopulated && iter.UNITY_Business_Unit_Account__c != null && accountServiceContractMap.containsKey( iter.UNITY_Business_Unit_Account__c) ) {
                    System.debug('Izay: no sc, bu not null, and sc in map');
                    if ( iter.AccountId != null && relatedAccountMap.containsKey(iter.AccountId) && relatedAccountMap.get(iter.AccountId).Residential__c  ) {
                        System.debug('Izay: acctid != null, map contains acctid, and residential');
                        serviceContractPopulated = setCustomerServiceToBusinessUnitDefault(iter, accountServiceContractMap.get( iter.UNITY_Business_Unit_Account__c ), true );
                    }
                    if ( !serviceContractPopulated ) serviceContractPopulated = setCustomerServiceToBusinessUnitDefault( iter, accountServiceContractMap.get( iter.UNITY_Business_Unit_Account__c ), false );
                }
            }
        }
    }
    
    private static Boolean setCustomerServiceToBusinessUnitDefault(Case caseRecord, List<UNITY_Service_Contract__c> serviceContractList, Boolean isResidential){
        System.debug('Izay: in setCustomerServiceToBusinessUnitDefault()');
        if ( serviceContractList != null ) {
            for (UNITY_Service_Contract__c serviceContract : serviceContractList) {
                if ( serviceContract.Default_Customer_Service_Contract__c && serviceContract.Residential__c == isResidential) {
                    caseRecord.UNITY_Customer_Service_Contract__c = serviceContract.Id;
                    return true;
                }
            }       
        }
        return false; 
    }

    public static Boolean setCustomerServiceContract(Case caseRecord, List<UNITY_Service_Contract__c> serviceContractList){
        
        if(serviceContractList != null){
                
            for(UNITY_Service_Contract__c serviceContract : serviceContractList){
                
                if(serviceContract.UNITY_Business_Unit__c!=null){
                    
                    Set<String> delimitedBusinessUnit = new Set<String>(serviceContract.UNITY_Business_Unit__c.split(';'));
                    
                    if(delimitedBusinessUnit.contains(caseRecord.UNITY_Business_Unit__c)){
                        
                        caseRecord.UNITY_Customer_Service_Contract__c = serviceContract.Id;
                        
                        return true;
                        
                        break;
                    }        
                }
            }
            
            return false;           
        }
        
        return false; 
    }
    
    public static Boolean setCustomerServiceContract3rdParty(Case caseRecord, List<UNITY_Service_Contract__c> serviceContractList, Id endCustomer){
        
        if (serviceContractList != null){
            
            for(UNITY_Service_Contract__c serviceContract : serviceContractList){
                
                if(serviceContract.UNITY_Business_Unit__c!=null){
                    
                    Set<String> delimitedBusinessUnit = new Set<String>(serviceContract.UNITY_Business_Unit__c.split(';'));
                    
                    System.debug('#serviceContract.UNITY_End_Customer__c '+serviceContract.UNITY_End_Customer__c);
                    System.debug('#endCustomer '+endCustomer);
                    
                    if(delimitedBusinessUnit.contains(caseRecord.UNITY_Business_Unit__c) && serviceContract.UNITY_End_Customer__c == endCustomer){
                        
                        caseRecord.UNITY_Customer_Service_Contract__c = serviceContract.Id;
                        
                        return true;
                        
                        break;
                    }        
                }
            }
            
            return false;                         
        }
        return false; 
    }

    /*
    public static void populateNTEFromServiceContract(List<Case> caseList){
        List<Id> relatedServiceContract = new List<Id>();
        for (Case iter: caseList){
            relatedServiceContract.add(iter.UNITY_Customer_Service_Contract__c);
        }
        //Map<serviceContractId, List<tradeId, SCLI>>
        Map<Id, Map<Id,UNITY_Service_Contract_Line_Item__c>> serviceContractLineByTradeMap = new Map<Id, Map<Id,UNITY_Service_Contract_Line_Item__c>>();
        //Map<serviceContractId, serviceContract>
        Map<Id, UNITY_Service_Contract__c> serviceContractMap = new Map<Id, UNITY_Service_Contract__c>();
        
        List<UNITY_Service_Contract__c> serviceContractList = [select id, UNITY_Default_NTE__c, (select id, recordTypeId, UNITY_Trade__c, Unity_NTE__c from UNITY_Service_Contract_Line_Items__r) from UNITY_Service_Contract__c where id in: relatedServiceContract];
        for (UNITY_Service_Contract__c sc: serviceContractList){
            serviceContractMap.put(sc.Id, sc);
            serviceContractLineByTradeMap.put(sc.Id, new Map<Id, UNITY_Service_Contract_Line_Item__c>());
            for (UNITY_Service_Contract_Line_Item__c scli: sc.UNITY_Service_Contract_Line_Items__r){ 
                serviceContractLineByTradeMap.get(sc.Id).put(scli.UNITY_Trade__c, scli);
            }
        }
        
        System.debug('#serviceContractMap '+serviceContractMap);
        System.debug('#serviceContractLineByTradeMap '+serviceContractLineByTradeMap);
        
        for(Case iter: caseList){
            Id serviceContractId = iter.UNITY_Customer_Service_Contract__c;
            Id trade = iter.UNITY_Trade__c;
            
            if (iter.UNITY_NTE_Threshold__c == null){
                if (trade != null && serviceContractLineByTradeMap.get(serviceContractId) != null && serviceContractLineByTradeMap.get(serviceContractId).get(trade) != null){ 
                    iter.UNITY_NTE_Threshold__c = serviceContractLineByTradeMap.get(serviceContractId).get(trade).Unity_NTE__c;
                }
                else if (trade != null && serviceContractMap.get(serviceContractId) != null && serviceContractMap.get(serviceContractId).UNITY_Default_NTE__c != null){
                    iter.UNITY_NTE_Threshold__c = serviceContractMap.get(serviceContractId).UNITY_Default_NTE__c;
                }
            }
        }
        System.debug('#caseList '+caseList);
    }*/

}