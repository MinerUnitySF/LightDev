/**This class serves as handler for account triggers Mary
** @programer: Izay Ramos-Irizarry
** @version: 1.0
** @date: 2/19/2016
========================================
Changelog
========================================
date:2/2016
description: updated for the unity project. 
             Added naming convention for all accounts with the Customer record type.
             If the Type field is Customer Location, it will be renamed with the parent account name.
             Also added funtionality to update child account names if parent is renamed.
programer: Izay
========================================
*/
public without sharing class AccountTriggerHandler {

    public static Map<Id,User> ownersMap;
    ////////////////////
    //Trigger methods //
    ////////////////////
    public static void onBeforeInsert(List<Account> newAccs){
        if(runTriggerOnce_Before()){
            System.debug('=================== onBeforeInsert:');
            //logic on before insert
            //Get the record type id for prospect accounts
            String prospectRTId = [SELECT Id FROM recordType WHERE SObjectType = 'Account' AND Name = 'Prospect Accounts' LIMIT 1].Id;
            String custRTId = [SELECT Id FROM recordType WHERE SObjectType = 'Account' AND DeveloperName = 'UNITY_Customer' LIMIT 1].Id;
            //Set to hold the accounts owner ids
            Set<Id> ownerIds = new Set<Id>();
            //List to hold new accounts that have a parent set
            List<Account> hasParent = new List<Account>();
            //List to hold accounts that need account approver populated
            List<Account> needApprover = new List<Account>();
            //For each new account...
            for(Account a :newAccs){
                //Put the OwnerId in the ownerIds set
                ownerIds.add(a.OwnerId);
            }
            //String to hold any messages to be sent to support
            String errMsg = '';
            //Query the user record for the account owners to get the super center they are assigned to
            if(ownersMap == null){
                ownersMap = new Map<Id,User>([SELECT Id,Name,Super_Center__c,Business_Unit__c FROM User WHERE Id IN :ownerIds]);
            }
            Boolean isMiner = false;//Denotes if the current user is miner business unit
            //For each new account...
            for(Account a :newAccs){
                //Check if account is a prospect account
                if(a.RecordTypeId == prospectRTId || a.RecordTypeId == custRTId){
                    //if the ownersMap has this account's 
                    if(ownersMap.containsKey(a.OwnerId)){
                        String busUnit = ownersMap.get(a.OwnerId).Business_Unit__c;//Get the current users business unit
                        if((busUnit == 'Miner Corp' && a.RecordTypeId == prospectRTId) || a.RecordTypeId == custRTId){
                            isMiner = true;
                        }
                        //Check if the owner has a super center set
                        if(String.isNotBlank(ownersMap.get(a.OwnerId).Super_Center__c) && a.RecordTypeId == prospectRTId && isMiner){
                            needApprover.add(a);
                        }//End oif owner has a super center
                        if(String.isBlank(a.Business_Unit__c) && String.isNotBlank(busUnit)){
                            a.Business_Unit__c = busUnit;
                            System.debug('=================== Set Business Unit to: ' + a.Business_Unit__c);
                        }
                    }//End if ownerMap has the account owner
                }//End if prospect accounts rt
                //Need to set the account name if it has a parent
                //Check if it has a parent
                //need to check if the parent changed. If it changes... : Izay
                if(isMiner /*&& a.recordTypeId != custRTId*/){
                    if(!a.Residential__c && String.isNotBlank(a.ParentId)){
                        hasParent.add(a);//Add the ParentId to pids
                    }else if(a.Residential__c && String.isNotBlank(a.MH_Primary_Contact__c)){
                        hasParent.add(a);
                    }//End if parent changed
                }
                //Need to get the tier and team
                
            }//End for new Accounts
            if(isMiner){
                //Set the account name if it has parents 
                if(!hasParent.isEmpty()){
                    setAccountsName(hasParent);
                    updateParentRollups(hasParent);
                }
                if(!needApprover.isEmpty()){
                    setAccountApprover(needApprover);
                }
            }
        }
    }
    
    public static void onAfterInsert(List<Account> newList){
        if(runTriggerOnce_After()){
            /* ************************************************ *
             * Add the account approver as Account Tream member *
             * ************************************************ */
            Set<Id> setUltP = new Set<Id>();
            System.debug('=================== onAfterInsert:');
            List<AccountTeamMember> atms = new List<AccountTeamMember>();
            for(Account a :newList){
                if(String.isNotBlank(a.ParentId)){
                    setUltP.add(a.Id);
                }
                if(String.isNotBlank(a.Account_Approver__c)){
                    AccountTeamMember atm = new AccountTeamMember();
                    atm.AccountId = a.Id;
                    atm.TeamMemberRole = 'Account Approver';
                    atm.UserId = a.Account_Approver__c;
                    atms.add(atm);
                }
            }
            if(atms.size() > 0){
                try{
                    insert atms;
                    List<AccountShare> aShare = new List<AccountShare>();
                    for(AccountTeamMember atm :atms){
                        AccountShare ash = new AccountShare();
                        ash.AccountAccessLevel = 'Edit';
                        ash.AccountId = atm.AccountId;
                        ash.OpportunityAccessLevel = 'None';
                        ash.CaseAccessLevel = 'Read';
                        ash.UserOrGroupId = atm.UserId;
                        aShare.add(ash);
                    }
                    if(aShare.size() > 0){
                        insert aShare;
                    }
                }catch(Exception e){
                    System.debug('========= Error message: ' + e.getmessage());
                }
            }
            /* **************************************************** *
             * END Add the account approver as Account Tream member *
             * **************************************************** */
            if(!setUltP.isEmpty() && !System.isFuture())
                setUltimateParent(setUltP);
        }
    }
    
    //
    public static void onBeforeUpdate(Map<Id, Account>newAccs, Map<Id, Account>oldAccs){
        if(runTriggerOnce_Before()){
            
            //get our record type id
            Id prospectRTId = [SELECT Id from RecordType WHERE DeveloperName = 'Prospect_Accounts' LIMIT 1].Id;
            String custRTId = [SELECT Id FROM recordType WHERE SObjectType = 'Account' AND DeveloperName = 'UNITY_Customer' LIMIT 1].Id;
            Id recTypeId_Parent = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Parent Account' LIMIT 1].Id;
            Boolean isAdmin = false;
            String profName = [SELECT Id,Name FROM Profile WHERE ID = :UserInfo.getProfileId() LIMIT 1].Name;
            if(profName == 'System Administrator'){
                isAdmin = true;
            }
            //Set to hold parent ids
            List<Account> hasParent = new List<Account>();
            //List to hold accounts that need account approver populated
            List<Account> needApprover = new List<Account>();
            //List to hold accounts that SL Notes Text changed
            List<Account> slNoteChanged = new List<Account>();
            //loop through new accounts
            for(Account acc : newAccs.values()){
                Boolean isApprover = false;
                if((acc.Business_Unit__c == 'Miner Corp') || acc.RecordTypeId == custRTId){
                    //need to check if the parent changed. If it changes... : Izay
                    if(!acc.Residential__c && String.isNotBlank(acc.ParentId)){
                        if((acc.ParentId != oldAccs.get(acc.Id).ParentId) || 
                           (acc.Name != oldAccs.get(acc.Id).Name) || 
                           (acc.ShippingStreet != oldAccs.get(acc.Id).ShippingStreet && acc.Type == 'Site/Location')||
                           (acc.Residential__c != oldAccs.get(acc.Id).Residential__c)){
                                hasParent.add(acc);//Add the ParentId to pids
                        }
                    }else if(acc.Residential__c && String.isNotBlank(acc.MH_Primary_Contact__c)){
                        if((acc.MH_Primary_Contact__c != oldAccs.get(acc.Id).MH_Primary_Contact__c) || 
                           (acc.Name != oldAccs.get(acc.Id).Name) || 
                           (acc.BillingStreet != oldAccs.get(acc.Id).BillingStreet && acc.Residential__c)||
                           (acc.Residential__c != oldAccs.get(acc.Id).Residential__c)){
                                hasParent.add(acc);
                        }
                    }//End if parent changed
                }
                //we need to check for our prospect account type first:
                if(acc.RecordTypeId == prospectRTId && (acc.Business_Unit__c == 'Miner Corp' || acc.Business_Unit__c == 'Miner National')){
                    if(String.isNotBlank(acc.Account_Approver__c)){
                        if(acc.Account_Approver__c == UserInfo.getUserId()){
                            isApprover = true;
                        }
                    }else{
                        needApprover.add(acc);
                    }
                    //now we check against the old map to ensure the convert to customer field has JUST been added
                    if(acc.Ready_To_Convert__c && !oldAccs.get(acc.Id).Ready_To_Convert__c){
                        //next we need to make sure there is a parentid
                        if(!acc.Residential__c){
                            if(String.isNotBlank(acc.ParentId)){
                                //now we need to check if the billing street is blank
                                if(String.isBlank(acc.BillingStreet)){
                                    ////the billing street was not found
                                    acc.BillingStreet.addError(' The Billing Street is required before assigning a Parent Account');
                                }                   
                            }else{
                                //this means it has no parent so we add error
                                acc.ParentId.addError(' This account requires a Parent Account for approval. Please return to the account to reject the approval request or add a Parent Account before approving.');
                            }//End if has parent
                        }else{
                            if(String.isNotBlank(acc.MH_Primary_Contact__c)){
                                //now we need to check if the billing street is blank
                                if(String.isBlank(acc.BillingStreet)){
                                    ////the billing street was not found
                                    acc.BillingStreet.addError(' The Billing Street is required before assigning a Primary Contact');
                                }                   
                            }else{
                                //this means it has no parent so we add error
                                acc.MH_Primary_Contact__c.addError(' This account requires a Primary Contact for approval. Please return to the account to reject the approval request or add a Primary Contact before approving.');
                            }//End if has parent
                        }
                    }else if(acc.Ready_To_Convert__c && oldAccs.get(acc.Id).Ready_To_Convert__c && (!isApprover && !isAdmin)){
                        Trigger.new[0].addError(' This account is waiting on conversion to Active Customer. It is locked until the process is completed. Try again later.');
                    }//End if ready to convert
                }//End if record type & business unit
                if(acc.SL_Notes_Text__c != oldAccs.get(acc.Id).SL_Notes_Text__c){
                    slNoteChanged.add(acc);
                }
            }//End for new accounts
            //if there are parent ids in the set...
            if(!hasParent.isEmpty()){
                //Call the updateAccountsName method passing the list of accounts and parent ids
                setAccountsName(hasParent);
                updateParentRollups(hasParent);
            }//End if pids
            if(!needApprover.isEmpty()){
                setAccountApprover(needApprover);
            }
            if(!slNoteChanged.isEmpty()){
                updateSLNotes(slNoteChanged,(Map<Id,Account>)Trigger.oldMap);
            }
        }
    }
    
    public static void onAfterUpdate(List<Account>newAccs, Map<Id, Account>oldAccs){
        if(runTriggerOnce_After()){
            Set<Id> setUltP = new Set<Id>();
            Id recId = [SELECT Id from RecordType WHERE DeveloperName = 'Prospect_Accounts' LIMIT 1].Id;
            Id custRTId = [SELECT Id FROM recordType WHERE SObjectType = 'Account' AND DeveloperName = 'UNITY_Customer' LIMIT 1].Id;
            Id recTypeId_Parent = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Parent Account' LIMIT 1].Id;
            //List to hold account which Name changed
            List<Account> changedAccs = new List<Account>();
            for(Account a :newAccs){
                //If it is a parent account and its name changed
                if((a.Name != oldAccs.get(a.Id).Name) 
                   && (a.RecordTypeId == recId || (a.RecordTypeId == custRTId && a.Type != 'Site/Location') || a.RecordTypeId == recTypeId_Parent)){
                    changedAccs.add(a);//Add to changedAccs list
                    System.debug('============ Account Name changed...');
                    System.debug('============ Added to changedAccs list...');
                }
                if((String.isNotBlank(a.ParentId) && a.ParentId != oldAccs.get(a.Id).ParentId) || (String.isNotBlank(a.ParentId) && String.isBlank(a.UNITY_Ultimate_Parent__c))){
                    setUltP.add(a.Id);
                }
            }
            System.debug('============ Checking changedAccs list size...');
            System.debug('============ changedAccs list size: ' + changedAccs.size() + '...');
            if(changedAccs.size() > 0){
                System.debug('============ Calling setChildrenAccountsName...');
                setChildrenAccountsName(changedAccs);
            }
            
            if(!setUltP.isEmpty() && !System.isFuture() && !System.isBatch())
                setUltimateParent(setUltP);
            
        }
    }
    //Method to update the account name based on the account parent
    //@param acctList - List<Account>: The accounts to be updated
    //@param pids - Set<Id>: The parent ids
    
    public static List<Account> setAccountsName(List<Account> acctList){
        //System.debug('Izay: in setAccountName method...');
        String prospectRTId = [SELECT Id FROM recordType WHERE SObjectType = 'Account' AND Name = 'Prospect Accounts' LIMIT 1].Id;
        String custRTId = [SELECT Id FROM recordType WHERE SObjectType = 'Account' AND Name = 'Customer Account' LIMIT 1].Id;
        
        List<Account> updatedAccounts = new List<Account>();
        //If has parent ids
        if(acctList.size() > 0){
            Map<Id,Account> allParentsMap = new Map<Id,Account>();//Hold all the queried parent accounts
            Map<Id,Id> pIdsMap = new map<Id,Id>();//Holds accountids with parent account ids
            Set<Id> tempPIds = new Set<Id>();//Holds the next set of parent ids
            //get the parent ids
            Set<Id> pids = new Set<Id>();
            Set<Id> cids = new Set<Id>();
            for(Account a :acctList){
                if(String.isNotBlank(a.ParentId) && !a.Residential__c){
                    pids.add(a.ParentId);
                }else if(a.Residential__c && String.isNotBlank(a.MH_Primary_Contact__c)){
                    cids.add(a.MH_Primary_Contact__c);
                }else{
                    pids.add(a.Id);
                }
            }
            tempPIds.addAll(pids);
            //Fetch the parent record in a map
            Map<Id,Account> tempMap = new Map<Id,Account>([SELECT Id,Name,ParentId,BillingStreet,ShippingStreet,Type,RecordTypeId,Residential__c FROM Account WHERE Id IN: pids]);
            //Fetch the primary contacts in map
            Map<Id,Contact> contactsMap = new Map<Id,Contact>([SELECT Id,FirstName,LastName FROM Contact WHERE Id IN: cids]);
            //While the parentsMap has values in it...
            while(!tempPIds.isEmpty()){
                tempPIds.clear();
                for(Account a :tempMap.values()){
                    if((String.isNotBlank(a.ParentId) && a.Type == 'Site/Location' && !a.Residential__c)||
                       (String.isNotBlank(a.ParentId) && a.Type == 'Customer' && (a.RecordTypeId == prospectRTId || a.RecordTypeId == custRTId ))){
                        tempPIds.add(a.ParentId);
                        pIdsMap.put(a.Id,a.ParentId);
                    }else if(!a.Residential__c){
                        pIdsMap.put(a.Id,a.Id);
                    }
                    allParentsMap.put(a.Id,a);
                }
                tempMap.clear();
                if(!tempPIds.isEmpty()){
                    tempMap = new Map<Id,Account>([SELECT Id,Name,ParentId,BillingStreet,ShippingStreet,Type,RecordTypeId,Residential__c FROM Account WHERE Id IN :tempPIds]);
                }
            }
            //System.debug('Izay: pIdsMap = ' + pIdsMap);
            //Iterate through each account
            for(Account a :acctList){
                //If the account has a parent...
                if(String.isNotBlank(a.ParentId) && !a.Residential__c){
                    Boolean found = false;
                    String pid = a.ParentId;
                    while(!found){
                        if(pIdsMap.containsKey(pid)){
                            //System.debug('Izay: pid = ' + pid);
                            //System.debug('Izay: pIdsMap.get(pid) = ' + pIdsMap.get(pid));
                            //System.debug('Izay: a.RecordTypeId = ' + a.RecordTypeId);
                            //System.debug('Izay: prospectRTId = ' + prospectRTId + ', custRTId = ' + custRTId);
                            //System.debug('Izay: a.Type = ' + a.Type);
                            if(pid == pIdsMap.get(pid) && (a.RecordTypeId == prospectRTId || a.RecordTypeId == custRTId || a.Type == 'Site/Location')){
                                //Update the account name with the parent name + account billing street
                                String street = String.isNotBlank(a.ShippingStreet) ? a.ShippingStreet : a.BillingStreet;
                                a.Name = allParentsMap.get(pid).Name + ' - ' + street;
                                updatedAccounts.add(a);
                                found = true;
                            }else if(pid == pIdsMap.get(pid) && a.Type == 'Customer'){
                                found = true;
                            }else{
                                pid = pIdsMap.get(pid);
                            }
                        }else{
                            found = true;
                        }
                    }
                }else if(a.Residential__c && String.isNotBlank(a.MH_Primary_Contact__c)){
                    if(contactsMap.containsKey(a.MH_Primary_Contact__c)){
                        a.Name = contactsMap.get(a.MH_Primary_Contact__c).LastName + ' - ' + a.BillingStreet;
                    }
                }//End if parent id
            }//End for accounts
        }//End if pids
        return updatedAccounts;
    }//End method
    
    //Method to set the child names when the parent account name changes
    //@param parents - List<Account>: the parents
    public static void setChildrenAccountsName(List<Account> parents){
        System.debug('============ In setChildrenAccountsName method...');
        System.debug('============ Checking parents size()...');
        System.debug('============ parents size: ' + parents.size() + '...');
        if(parents.size() > 0){
            Map<Id,Account> children = new Map<Id,Account>();
            Set<Id> pids = new Set<Id>();
            Set<Id> tempPIds = new Set<Id>();
            Map<Id, Account> parentsMap = new Map<Id,Account>();
            for(Account a :parents){
                parentsMap.put(a.Id,a);
            }
            System.debug('============ Fetching child accounts...');
            List<Account> tempList = [SELECT Id,Name,BillingStreet,ShippingStreet,ParentId,Residential__c,MH_Primary_Contact__c,Type,RecordTypeId FROM Account WHERE ParentId IN :parentsMap.keySet()];
            System.debug('============ Child accounts found: ' + tempList.size() + '...');
            while(tempList.size() > 0){
                tempPIds.clear();
                System.debug('============ Adding chid accounts to children list...');
                System.debug('============ children list size: ' + children.size() + '...');
                for(Account a :tempList){
                    children.put(a.Id,a);
                    pids.add(a.ParentId);
                    tempPIds.add(a.Id);
                }
                if(tempPIds.size() > 0){
                    System.debug('============ Fetching child accounts of the children...');
                    tempList = [SELECT Id,Name,ShippingStreet,BillingStreet,ParentId,Residential__c,MH_Primary_Contact__c,Type,RecordTypeId FROM Account WHERE ParentId IN :tempPIds];
                    System.debug('============ Child accounts found: ' + tempList.size() + '...');
                }
            }
            System.debug('============ Total children: ' + children.size() + '...');
            if(children.values().size() > 0){
                System.debug('============ Calling the setAccountsName method...');
                List<Account> toUpdate = new List<Account>();
                toUpdate = setAccountsName(children.values());
                System.debug('============ Results: ' + toUpdate + ' ...');
                try{
                    update toUpdate;
                }catch(Exception e){
                    if(e.getTypeName() == 'System.DmlException'){
                        Trigger.new[0].addError(' ' + e.getDmlMessage(0));
                    }else{
                        Trigger.new[0].addError(' ' + e.getMessage());
                    }
                }
            }
        }
    }
    
    public static void setAccountApprover(List<Account> accounts){
        //Set to hold the accounts owner ids
        Set<Id> ownerIds = new Set<Id>();
        for(Account a :accounts){
            ownerIds.add(a.OwnerId);
        }
        //Query the user record for the account owners to get the super center they are assigned to
        if(ownersMap == null){
            ownersMap = new Map<Id,User>([SELECT Id,Name,Super_Center__c,Business_Unit__c FROM User WHERE Id IN :ownerIds]);
        }
        //Check if the owner has a super center set
        for(Account a :accounts){
            if(String.isNotBlank(ownersMap.get(a.OwnerId).Super_Center__c)){
                //Get the approver for that supe center...
                Account_Approver__c aapp = Account_Approver__c.getInstance(ownersMap.get(a.OwnerId).Super_Center__c);
                //If the super center has an approver...
                if(aapp != null){
                    a.Account_Approver__c = aapp.User_Id__c;//Set the account approver
                    System.debug('=================== Set Account Approver to: ' + a.Account_Approver__c);
                }
            }
        }
        
    }
    /** This method updates the SL Notes field on the account record with changes in the SL Notes Text field
    *@param accounts - List<Account>: The list of accounts that have a new SL Notes Text value
    *@param oldMap - Map<Id,Account>: The trigger.oldMap containing the priorvalue for the SL Notes Text field
    */  
    public static void updateSLNotes(List<Account> accounts, Map<Id,Account> oldMap){
        if(!accounts.isEmpty()){
            List<Note> notesToInsert = new List<Note>();
            for(Account a :accounts){
                if(oldMap.containsKey(a.Id)){
                    if(String.isNotBlank(a.SL_Notes_Text__c)){
                        if(a.SL_Notes_Text__c != oldMap.get(a.Id).SL_Notes_Text__c){
                            //The note text changed... need to get diff, highlight new text and populate to SL_Notes__c
                            List<String> textInNote = a.SL_Notes_Text__c.split('\r\n');
                            List<String> textInOldNote = String.isNotBlank(oldMap.get(a.Id).SL_Notes_Text__c) ? oldMap.get(a.Id).SL_Notes_Text__c.split('\r\n'): new List<String>();
                            List<Integer> diffIndex = new List<Integer>();
                            String lastEntry = '';
                            String otherChanges = '';
                            Integer index = 0;
                            for(String text :textInNote){
                                if(!textInOldNote.isEmpty()){
                                    if((textInOldNote.size()-1) >= index){
                                        if(text.trim() != textInOldNote.get(index).trim()){
                                            if(oldMap.get(a.Id).SL_Notes_Text__c.indexOf(text) == -1){
                                                diffIndex.add(index);
                                            }
                                        }
                                    }else{
                                        if(oldMap.get(a.Id).SL_Notes_Text__c.indexOf(text) == -1){
                                            diffIndex.add(index);
                                        }
                                    }
                                }else{
                                    diffIndex.add(index);
                                }
                                index++;
                            }
                            for(Integer i :diffIndex){
                                String text = textInNote.get(i);
                                if(i >= textInOldNote.size()){
                                    lastEntry +=  text + '\r\n';
                                }else{
                                    otherChanges += text + '\r\n';
                                }
                                text = '<b>'+text.trim()+'</b>';
                                textInNote.set(i,text);
                            }
                            if(!textInNote.isEmpty()){
                                String newNote = String.join(textInNote, '<br>');
                                a.SL_Notes__c = newNote;
        
                                Note n = new Note();
                                n.Title = 'SL Notes Update - ' + System.now().format('M/d/yyyy h:mm aaa');
                                n.Body = 'Notes from SL updated on ' + System.now().format('M/d/yyyy h:mm aaa') + '.\r\n';
                                n.Body += '\r\n';
                                n.Body += 'Promise Date:  ' + ((a.SL_Promise_Date__c != null) ? DateTime.newInstance(a.SL_Promise_Date__c,Time.newInstance(0,0,0,0)).format('M/d/yyyy') : 'Blank') + '.\r\n';
                               
                                n.Body += '\r\n';
                                n.Body += 'New Notes'+ '\r\n';
                                n.Body += '**********'+ '\r\n';
                                n.Body += String.isNotBlank(lastEntry) ? lastEntry : 'None\r\n';
                                n.Body += '**********'+ '\r\n';
        
                                n.Body += '\r\n';
                                n.Body += 'Other Changes'+ '\r\n';
                                n.Body += '**********'+ '\r\n';
                                n.Body += String.isNotBlank(otherChanges) ? otherChanges : 'None\r\n';
                                n.Body += '**********'+ '\r\n';
                                
                                n.ParentId = a.Id;
                                notesToInsert.add(n);
                            }
                                
                        }
                    }
                        
                }
            }
            if(!notesToInsert.isEmpty()){
                insert notesToInsert;
            }
        }
    }
    @future
    public static void setUltimateParent(Set<Id> aids){
        UNITY_Constants.isExecutingContext('AccountTriggerHandler.setUltimateParent');
        List<Account> accounts = [SELECT Id,ParentId,UNITY_Ultimate_Parent__c FROM Account WHERE Id IN :aids];
        Map<Id,Account> lastParent = new Map<Id,Account>();
        String ultParentId = '';
        List<Account> tempAccts = accounts;
        Boolean doneUp = false;
        Boolean doneDown = false;
        Set<Id> temp = new Set<Id>();
        //Find all the accounts up the hierarchy
        while(!doneUp){
            temp.clear();
            for(Account a :tempAccts){
                if(String.isNotBlank(a.ParentId)){
                    temp.add(a.ParentId);
                }else{
                    lastParent.put(a.Id,a);
                }
            }
            if(!temp.isEmpty()){
                tempAccts = [SELECT Id,ParentId,UNITY_Ultimate_Parent__c FROM Account WHERE Id IN :temp];
            }else{
                doneUp = true;
            }
        }
        //Find all the accounts down the hierarchy
        accounts = new List<Account>();
        tempAccts = [SELECT Id,ParentId,UNITY_Ultimate_Parent__c FROM Account WHERE ParentId IN :lastParent.keySet()];
        while(!doneDown){
            temp.clear();
            for(Account a :tempAccts){
                temp.add(a.Id);
                accounts.add(a);
            }
            if(!temp.isEmpty()){
                tempAccts = [SELECT Id,ParentId,UNITY_Ultimate_Parent__c FROM Account WHERE ParentId IN :temp];
            }else{
                doneDown = true;
            }
        }
        System.debug('#### accounts.size(): ' + accounts.size());
        //Now Find the ultimate parent for all the accounts
        List<Account> toUpdate = new List<Account>();
        Map<Id,Id> acctParentMap = new Map<Id,Id>();
        for(Account a :accounts){
            if(String.isNotBlank(a.ParentId)){
                acctParentMap.put(a.id,a.ParentId);
            }
        }
        
        for(Account a :accounts){
            if(String.isNotBlank(a.ParentId)){
                Boolean found = false;
                String pid = a.ParentId;
                while(!found){
                    if(acctParentMap.containsKey(pid)){
                        pid = acctParentMap.get(pid);
                    }else if(lastParent.containsKey(pid)){
                        a.UNITY_Ultimate_Parent__c = pid;
                        found = true;
                    }
                }
            }
        }
        
        if(!accounts.isEmpty()){
            try{
                update accounts;
            }catch(Exception e){
                System.debug('##### Error while setting ultimate parent: ' + e.getMessage());
            }
        }
        
    }
    
    //Method to update the parent account rollup
    public static void updateParentRollups(List<Account> children){
        
        Set<Id> pids = new Set<Id>();
        for(Account a :children){
            if(String.isNotBlank(a.ParentId))
                pids.add(a.ParentId);
        }
        if(!pids.isEmpty()){
            Map<Id,Account> parentsMap = new Map<Id,Account>([SELECT Id,Name,MH_Current_Balance__c,NTE_Threshold__c,Available_Credit__c,MH_Credit_Limit__c,
                                                              AnnualRevenue,Number_of_Locations__c,NumberOfEmployees,Opportunity_Trade__c FROM Account WHERE Id IN :pids]);
            children = [SELECT Id,Name,ParentId,MH_Current_Balance__c,NTE_Threshold__c,Available_Credit__c,MH_Credit_Limit__c,
                        AnnualRevenue,Number_of_Locations__c,NumberOfEmployees,Opportunity_Trade__c FROM Account WHERE ParentId IN :pids];
            Map<Id,List<Account>> childMap = new Map<Id,List<Account>>();
            for(Account a :children){
                if(!childMap.containsKey(a.ParentId)){
                    List<account> temp = new List<Account>();
                    temp.add(a);
                    childMap.put(a.ParentId, temp);
                }else{
                    childMap.get(a.ParentId).add(a);
                }
            }
            for(Account parent :parentsMap.values()){
                if(childMap.containsKey(parent.Id)){
                    Decimal currBal = 0;
                    Decimal nte = 0;
                    Decimal cred = 0;
                    Decimal credLimit = 0;
                    Decimal rev = 0;
                    Decimal locs = 0;
                    Integer emps = 0;
                    String opptyTrades = '';
                    for(Account a :childMap.get(parent.Id)){
                        currBal += (a.MH_Current_Balance__c != null) ? a.MH_Current_Balance__c : 0;
                        nte += (a.NTE_Threshold__c != null) ? a.NTE_Threshold__c : 0;
                        cred += (a.Available_Credit__c != null) ? a.Available_Credit__c : 0;
                        credLimit += (a.MH_Credit_Limit__c != null) ? a.MH_Credit_Limit__c : 0;
                        rev += (a.AnnualRevenue != null) ? a.AnnualRevenue : 0;
                        locs += (a.Number_of_Locations__c != null) ? a.Number_of_Locations__c : 0;
                        emps += (a.NumberOfEmployees != null) ? a.NumberOfEmployees : 0;
                        if(opptyTrades.length() > 0){
                            opptyTrades += (String.isNotBlank(a.Opportunity_Trade__c)) ? ';'+a.Opportunity_Trade__c : '';
                        }else{
                            opptyTrades += (String.isNotBlank(a.Opportunity_Trade__c)) ? a.Opportunity_Trade__c : '';
                        }
                    }
                    parent.MH_Current_Balance__c = currBal;
                    parent.NTE_Threshold__c = nte;
                    parent.Available_Credit__c = cred;
                    parent.MH_Credit_Limit__c = credLimit;
                    parent.AnnualRevenue = rev;
                    parent.Number_of_Locations__c = locs;
                    parent.NumberOfEmployees = emps;
                    parent.Opportunity_Trade__c = opptyTrades;
                }
            }
            try{
                update parentsMap.values();
            }catch(Exception e){
                if(e.getTypeName() == 'System.DmlException'){
                    Trigger.new[0].addError(' ' + e.getDmlMessage(0));
                }else{
                    Trigger.new[0].addError(' ' + e.getMessage());
                }
            }
        }
    }
    /**
    *** This variable and method are used to prevent triggers recursion on before insert/update
    */
    public static Boolean isFirstTriggerRun_Before = true;
    public static Boolean runTriggerOnce_Before(){
        if(isFirstTriggerRun_Before){
            isFirstTriggerRun_Before = false;
            return true;
        }else{
            return isFirstTriggerRun_Before;
        }
    }
    /**
    *** This variable and method are used to prevent triggers recursion on afterinsert/update
    */
    public static Boolean isFirstTriggerRun_After = true;
    public static Boolean runTriggerOnce_After(){
        if(isFirstTriggerRun_After){
            isFirstTriggerRun_After = false;
            return true;
        }else{
            return isFirstTriggerRun_After;
        }
    }
}