public class OpportunityTriggerHandler {
    private boolean m_isExecuting = false;
    private integer BatchSize = 0;
    
    //constructor for the handler which will help us deal with batch (if needed).    
    public OpportunityTriggerHandler(boolean isExecuting, integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    ////////////////////
    //Trigger methods //
    ////////////////////
    public void onBeforeInsert(List<Opportunity> newList){
        if(runTriggerOnce_Before()){
            //logic on before insert
            String opptyRTId = [SELECT Id FROM recordType WHERE SObjectType = 'Opportunity' AND DeveloperName = 'Miner_Corp_BDC_Opportunities' LIMIT 1].Id;
            //Set to hold the oppty owner ids
            Set<Id> ownerIds = new Set<Id>();
            //For each new account...
            for(Opportunity opp :newList){
                //Put the OwnerId in the ownerIds set
                ownerIds.add(opp.OwnerId);
            }
            //Query the user record for the account owners to get the super center they are assigned to
            Map<Id,User> ownersMap = new Map<Id,User>([SELECT Id,Name,Super_Center__c,Business_Unit__c FROM User WHERE Id IN :ownerIds]);
            for(Opportunity opp :newList){
                if(opp.RecordTypeId == opptyRTId){
                    //if the ownersMap has this account's 
                    if(ownersMap.containsKey(opp.OwnerId)){
                        //Check if the owner has a super center set
                        if(String.isNotBlank(ownersMap.get(opp.OwnerId).Super_Center__c)){
                            if(String.isBlank(opp.Miner_Corp_Company__c)){
                                opp.Miner_Corp_Company__c = ownersMap.get(opp.OwnerId).Super_Center__c;
                            }
                        }
                        if(String.isBlank(opp.Business_Unit__c)){
                            if(String.isNotBlank(ownersMap.get(opp.OwnerId).Business_Unit__c)){
                                opp.Business_Unit__c = ownersMap.get(opp.OwnerId).Business_Unit__c;
                            }
                        }
                    }
                }
            }
        }
    }
	
    public void onBeforeUpdate(Map<Id, Opportunity> newOpps, Map<Id, Opportunity> oldOpps){
        if(runTriggerOnce_Before()){
            //Get miner oppty record types
            String opptyRTId = [SELECT Id FROM recordType WHERE SObjectType = 'Opportunity' AND DeveloperName = 'Miner_Corp_BDC_Opportunities' LIMIT 1].Id;
            //the opportunities that have now been flagged for sending an at risk email
            System.debug('=================OnBeforeUpdate Opp Trigger:==================');
            List<Opportunity> atRiskOpps = new List<Opportunity>();
            
            //build our user Ids from the ownerIds of the opps
            Set<Id> ownerIds = new Set<Id>();
    
            //List of email messages we will be sending:
            List<Messaging.SingleEmailMessage> messageList = new List<Messaging.SingleEmailMessage>();
            //the email template name:
            String template = 'Opportunity_At_Risk_Alert';
            //TODO Should I look to see if it exists first?
            Id templateId = [SELECT id FROM EmailTemplate WHERE DeveloperName = :template LIMIT 1].Id;
    
            //go through the list of new opportunities and add to our list of at risk if flagged
            for (Opportunity opp : newOpps.values()){
                if(opp.RecordTypeId == opptyRTId){
                    //CLAY: Adding a check to compare the at risk field compared to the old value. 
                    //If it got flagged, we need to flag the at risk send email manually
                    if (opp.At_Risk__c && !(oldOpps.get(opp.Id).At_Risk__c))
                        opp.At_Risk_Send_Email__c = true;
                    //if we havent sent an email yet, this box will be checked
                    if (opp.At_Risk_Send_Email__c)
                        atRiskOpps.add(opp);
                    ownerIds.add(opp.OwnerId);
                    //Izay: Moved vertiba code here
                    if (opp.CloseDate != oldOpps.get(opp.Id).CloseDate && opp.CloseDate > oldOpps.get(opp.Id).CloseDate &&
                        opp.ForecastCategory != 'Closed' && opp.ForecastCategory != 'Omitted'){
                            opp.Send_Close_Date_Email__c = true;
                        }
                    if(opp.StageName != oldOpps.get(opp.Id).StageName && (opp.StageName != 'Closed Won' && opp.StageName != 'Closed Lost') ){
                        if(oldOpps.get(opp.Id).StageName == 'Closed Won'){
                            opp.Probability = 0;
                        }else{
                            opp.Probability = oldOpps.get(opp.Id).Probability;
                        }
                    }
                }
            }
            
            ///////////////////////////////////////////////////////////////////////////////////////////////////////////
            //this is where we send the list of opportunites flagged for at risk to the build user email list method //
            ///////////////////////////////////////////////////////////////////////////////////////////////////////////
            Map<Id, Map<String, User[]>>userRoleTree = buildUserRoleTree(ownerIds);
    
            ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            //we can go through our At Risk Opps now, and just build a list of users to email (for at risk emails, it will be sales manager) //
            ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            for (Opportunity opp : atRiskOpps){
                //all of the parent role names, and the users for those roles for the owner of this at risk opportunity
                Map<String, User[]>myRoleTree = userRoleTree.get(opp.OwnerId); 
                System.debug('Role tree for current user:' + myRoleTree);
                //the list of users to email to:
                List<User> myBosses = new List<User>();            
    
                //loop through the roles above the opportunity owner, and get all the users that live there.
                for (String roleName : myRoleTree.keySet()){
                    //now we check against the names of the roles above us and find the ones we want:
                    if (String.isNotBlank(roleName)){
                        System.debug('Current role name: ' + roleName);
                        if (roleName.contains('Sales Manager')){
                            //now we add this list of users to the myBosses list
                            myBosses.addAll(myRoleTree.get(roleName));
                        }    
                    }
                    
                }//end of loop through rolenames
    
                ////////////////////////////////////////////////////////////////
                //now we should build out a message that will go to the users //
                ////////////////////////////////////////////////////////////////
                //we have to do this per person in the myBosses list unfortunately.
                //We only want this email to go the managers?? Or also the opp owner?
                System.debug('========= Our bosses list:' + myBosses);
    
                for(User u: myBosses) {
                    System.debug('user we may email: ' + u);
                    if (u != null){
                        //instantiate our message to add to the list of messages
                        Messaging.SingleEmailMessage oppMsg = new Messaging.SingleEmailMessage();
                        oppMsg.setTemplateId(templateId);
                        //set the current user id (boss Id) as the target object for this message
                        oppMsg.setTargetObjectId(u.Id);
                        //set the what id (opportunity) to the current at risk opportunity
                        oppMsg.setWhatId(opp.Id);   
                        //should we set the reply to as the owner for the opportunity? OR set the OrgWideEmailAddressId
                        oppMsg.setOrgWideEmailAddressId(Label.Org_Wide_Email_Address_Record);
                        //Dont let it save as an activity. Which has to do with HTML email tracking?
                        oppMsg.setSaveAsActivity(false);
                        messageList.add(oppMsg);    
                    }                
                }
                //////////////////////////////////////
                //also send a message to the owner: //
                //////////////////////////////////////
                Messaging.SingleEmailMessage oppMsg = new Messaging.SingleEmailMessage();
                oppMsg.setTemplateId(templateId);
                //set the current user id (boss Id) as the target object for this message
                oppMsg.setTargetObjectId(opp.OwnerId);
                //set the what id (opportunity) to the current at risk opportunity
                oppMsg.setWhatId(opp.Id);   
                //should we set the reply to as the owner for the opportunity? OR set the OrgWideEmailAddressId
                oppMsg.setOrgWideEmailAddressId(Label.Org_Wide_Email_Address_Record);
                //Dont let it save as an activity. Which has to do with HTML email tracking?
                oppMsg.setSaveAsActivity(false);
                messageList.add(oppMsg);
    
                opp.At_Risk_Send_Email__c = false;
            }//end of at risk opportunities loop
    
            //////////////////////////////////////
            //Now we send our list of messages: //
            //////////////////////////////////////
            try {
            
                Messaging.sendEmail(messageList);  
                
            } catch(Exception e) {
    
                System.debug('==============Email failed to send: '+e.getMessage());
            }
        }
    }

    public void onAfterInsert(Map<Id,Opportunity> newOpps ){
        if(runTriggerOnce_After()){
            //////////////////////////////////////////////
            //Send alerts for High Value Opportunities: //
            //////////////////////////////////////////////
            
            //This map contains the High Value Opportunity and which roles to send an alert to
            Map<Opportunity, Set<String>> oppHVWho = matchHVOppRules(newOpps.values());
    
            if(oppHVWho.size() > 0){
                //Now we send the oppHVWho map to our buildHVEmails method, which will return the list of messages
                List<Messaging.SingleEmailMessage> messages = buildHVEmails(oppHVWho);
        
                //now try to send these messages:
                try {
                
                    Messaging.sendEmail(messages);  
                    
                } catch(Exception e) {
        
                    System.debug('==============Email failed to send: '+e.getMessage());
                }
            }
        }
    }//end of onafter insert

    public void onAfterUpdate(Map<Id, Opportunity> newOpps, Map<Id, Opportunity> oldOpps){
        if(runTriggerOnce_After()){
            //our list of changed opps:
            List<Opportunity> changedOpps = new List<Opportunity>();
    
            for(Opportunity opp : newOpps.values()){
                //pull our old values
                String oldType = oldOpps.get(opp.Id).Type;
                Decimal oldAmount = oldOpps.get(opp.Id).Amount;
                //make sure they have values
                if (String.isNotBlank(oldType) && oldAmount != null){
                    //check against new values - did they change?
                    if (opp.Type != oldType || opp.Amount != oldAmount){
                        //lets add this opp to the list of those that changed
                        System.debug('new Opportunity:' + opp.Name + ' ' + opp.Amount);
                        changedOpps.add(opp);
                    }//end of if changed
    
                }// end of if not blank
            }//end of opps loop
            //This map contains the High Value Opportunity and which roles to send an alert to
            
            Map<Opportunity, Set<String>> oppHVWho = new Map<Opportunity, Set<String>>();
            if (changedOpps.size() > 0){
                oppHVWho = matchHVOppRules(changedOpps);
    
                if(oppHVWho.size() > 0){
                    //Now we send the oppHVWho map to our buildHVEmails method, which will return the list of messages
                    List<Messaging.SingleEmailMessage> messages = buildHVEmails(oppHVWho);
            
                    //now try to send these messages:
                    try {
                    
                        Messaging.sendEmail(messages);  
                        
                    } catch(Exception e) {
            
                        System.debug('==============Email failed to send: '+e.getMessage());
                    }
                }
            }
        }
    }

    /////////////////////
    //Helper methods// //
    /////////////////////
    public Map<Opportunity, Set<String>> matchHVOppRules(Opportunity[] opps){
        //this method recieves a list of opps to check against our custom setting for High Value matches
        //This map contains the High Value Opportunity and which roles to send an alert to
        Map<Opportunity, Set<String>> oppHVWho = new Map<Opportunity, Set<String>>();

        //here are all the rules for High Value opportunities in our custom setting:
        List<OppHighValue__c> rules = [SELECT Id, Type__c, Threshold__c, Who__c FROM OppHighValue__c ORDER BY Threshold__c DESC NULLS LAST];
        if (rules.size() > 0){
            //we will go through our opportunities and pull the ones who match our rules, and add them to our map
            for (Opportunity opp : opps){

                //loop through our rules:
                for(OppHighValue__c r : rules){
                    //temporary set string of roles to send email to:
                    Set<String> who = new Set<String>();

                    //check if rule matches type and opp amount is over the threshold;:
                    if(opp.Type == r.Type__c && opp.Amount >= r.Threshold__c){
                        //it matches, but is it the best match? we need to keep going until we find one that doesnt match?
                        
                        //check our map to see if this opp is already in there, if not add it
                        if (!oppHVWho.containsKey(opp)){
                                //add the who__c, split by comma, to our temporary who list
                                who.addAll(r.Who__c.split(','));
                                //add a line to our map with the matched opportunity and who to send it to
                                oppHVWho.put(opp, who);
                            }else{//if this opp is already in the map
                                //add to the set of strings, this wont duplicate
                                oppHVWho.get(opp).addAll(r.Who__c.split(','));
                            }
                    }
                }//end of for every rule

            }//end of for every opportunity    
        }//end of rules size check

        return oppHVWho;

        
    }
    
    public List<Messaging.SingleEmailMessage> buildHVEmails(Map<Opportunity, Set<String>>hvOppWho){
        //this method wil recieve a map of high value opportunities, and build a message list
        
        //payload: our messages list
        List<Messaging.SingleEmailMessage> messageList = new List<Messaging.SingleEmailMessage>();
        //the email template name:
        String template = 'Opportunity_High_Value';
        //TODO Should I look to see if it exists first?
        Id templateId = [SELECT id FROM EmailTemplate WHERE DeveloperName = :template LIMIT 1].Id;

        //we need a list of opportunity Ids to get the roletree for:
        Set<Id> ownerIds = new Set<Id>();
        for (Opportunity opp : hvOppWho.keyset()){
            ownerIds.add(opp.OwnerId);
        }

        //here is our returned map of owner Id to their role tree:
        Map<Id, Map<String, User[]>>userRoleTree = buildUserRoleTree(ownerIds);

        //////////////////////////////
        //now we build the messages //
        //////////////////////////////    
        for (Opportunity opp : hvOppWho.keyset()){
            //all of the parent role names, and the users for those roles for the owner of this at risk opportunity
            Map<String, User[]>myRoleTree = userRoleTree.get(opp.OwnerId); 
            System.debug('Role tree for current user:' + myRoleTree);
            //the list of users to email to:
            List<User> sendToUsers = new List<User>();            
            
            //list of User Ids we match outside of our role tree? Org Wide Emails in this case
            Set<Id> sendToIds = new Set<Id>();
            //add our opporunity owner id to the set
            sendToIds.add(opp.OwnerId);

            //loop through the people who the email should be sent to (matched custom setting names)
            for (String whoName : hvOppWho.get(opp)){
                System.debug('====This is one of the who\'s we need to send it to: ' + whoName.trim() );
                //now we loop through the role names we pulled back for this opp owner
                for (String roleName : myRoleTree.keySet()){
                //now we check against the names of the roles above us and find the ones we want:
                    if (String.isNotBlank(roleName)){
                        System.debug('About to check our role name:' + roleName);
                        if (roleName.contains(whoName.trim())){
                            //now we add this list of users to the sendToUsers list
                            sendToUsers.addAll(myRoleTree.get(roleName));
                        }else{//didnt match a who, will it match an org wide email?
                            //if we find them via the Name of the custom setting, we can add them to the Ids
                            if (Org_Wide_Emails__c.getInstance(whoName.trim()) != null)
                                sendToIds.add(Org_Wide_Emails__c.getInstance(whoName.trim()).UserId__c);
                        }    
                    }
                
                }//end of loop through rolenames
            }//end of loop through the who names 


            //loop through our gathered users
            for(User u: sendToUsers) {
                System.debug('user we may email: ' + u);
                if (u != null){
                    //instantiate our message to add to the list of messages
                    Messaging.SingleEmailMessage oppMsg = new Messaging.SingleEmailMessage();
                    oppMsg.setTemplateId(templateId);
                    //set the current user id (boss Id) as the target object for this message
                    oppMsg.setTargetObjectId(u.Id);
                    //set the what id (opportunity) to the current at risk opportunity
                    oppMsg.setWhatId(opp.Id);   
                    //should we set the reply to as the owner for the opportunity? OR set the OrgWideEmailAddressId
                    oppMsg.setOrgWideEmailAddressId(Label.Org_Wide_Email_Address_Record);
                    //Dont let it save as an activity. Which has to do with HTML email tracking?
                    oppMsg.setSaveAsActivity(false);
                    messageList.add(oppMsg);    
                }                
            }
            
            /////////////////////////////////////////////////////////
            //also send a message to the owner and matched Ids: // //
            /////////////////////////////////////////////////////////
            System.debug('Our send To Id:' + sendToIds);
            for(Id id: sendToIds){

                Messaging.SingleEmailMessage oppMsg = new Messaging.SingleEmailMessage();
                oppMsg.setTemplateId(templateId);
                //set the current user id (boss Id) as the target object for this message
                oppMsg.setTargetObjectId(id);
                //set the what id (opportunity) to the current at risk opportunity
                oppMsg.setWhatId(opp.Id);   
                //should we set the reply to as the owner for the opportunity? OR set the OrgWideEmailAddressId
                oppMsg.setOrgWideEmailAddressId(Label.Org_Wide_Email_Address_Record);
                //Dont let it save as an activity. Which has to do with HTML email tracking?
                oppMsg.setSaveAsActivity(false);
                messageList.add(oppMsg);                
            }
            
        }//end of opportunities loop

        //now return our message list
        
        return messageList;
        
    }

    /**
     * buildUserRoleTree
     * Recieves a list of user ids
     * Returns a map of User Ids with the RoleNames and All the Users under that role
     * This can be used to determine which Roles (by name) to send emails to.
     */
    public Map<Id, Map<String, User[]>> buildUserRoleTree(Set<Id> ids){
        
        
        //grab our users
        Set<User> users = new set<User>([SELECT Id, Email, UserRoleId FROM User Where Id IN :ids]);
        
        //our final map payload
        Map<Id, Map<String, User[]>> payload = new Map<Id, Map<String, User[]>>();
        
        
        //collecting the UserId => RoleId for all opp owners
        Map<Id, Id>uIdrIds = new Map<Id, Id>(); 
        
        //map of our role Ids to Role Name
        Map<Id, String>roleIdName = new Map<Id, String>();
        
        //loop through our users and get their role Ids
        for (User u :users){
            //add to our collection of roleIds
            if (u.UserRoleId != null)
                uIdrIds.put(u.Id, u.UserRoleId);
            
        }
        
        //This map is RoleId => ParentRoleId in their role tree
        Map<Id, Id> roleTree = new Map<Id, Id>();
        
        //get the role tied to the current userid
        UserRole[] role = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Id = :uIdrIds.values()];
        
        //our list of parentIds for this current user. Will be added to the role tree
        Set<Id> parents = new Set<Id>();
        for (UserRole ur : role){
            if (String.isNotBlank(ur.ParentRoleId)) {
                roleTree.put(ur.Id, ur.ParentRoleId);
                roleIdName.put(ur.Id, ur.Name);
                parents.add(ur.ParentRoleId);
                
            }
        }
        
        
        //is there a parent role listed? If so do it again?
        while (parents.size() > 0){
            //requery our role so the while loop will check again:
            role = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Id IN :parents];
            parents.clear();
            
            for (UserRole ur : role){
                if (String.isNotBlank(ur.ParentRoleId)) {
                    roleTree.put(ur.Id, ur.ParentRoleId);
                    roleIdName.put(ur.Id, ur.Name);
                    parents.add(ur.ParentRoleId);
                }
            }
            
        }
        
        Set<Id> roleIds = new Set<Id>();
        roleIds.addAll(roleTree.keyset());
        roleIds.addAll(roleTree.values());
        
        //get our list of users for all of the roles we have collected
        User[] userList = [SELECT Id, Email, UserRoleId FROM User WHERE UserRoleId IN :roleIds];
        
        //map of role id, and list of users
        Map<Id, User[]> roleIdUserList = new Map<Id, User[]>();
        
        //go through ALL of the users, and collect them by roleId
        for (User u : userList){
            //temporary list of users
            List<User> tempUsers = new List<User>();
            
            //does our map have this current users role id? If not, add it and the first user
            if (!roleIdUserList.containsKey(u.UserRoleId)){
                tempUsers.add(u);
                roleIdUserList.put(u.UserRoleId, tempUsers);
            }else{ //this role Id already is in map
                //need to get the list of users already there, add to it, and then put it back
                roleIdUserList.get(u.UserRoleId).add(u);
            }//end if roleIdUserList contains current user
            
        }//end for loop
        
        //now its time to build the payload
        //payload = UserId => Map {RoleName => List of Users}
        //we have four maps to go through:
        //uIdrIds = userIds => userRoleId
        //roleIdName = userRoleId => Name for UserRole
        //roleTree = userRoleId => ParentRoleId
        //roleIdUserList = usrRoleId => List of users in that role
        
        //go through our userIds:
        for(Id uId : uIdrIds.keyset()){
            //temporary parent Id set for this user:
            Set<Id> myParents = new Set<Id>();
            
            //temporary map for roleName and list of users:
            Map<String, User[]> innerMap = new Map<String, User[]>();
            
            //placeholder for roleId - this will changed to the parent Id in the while loop
            Id roleId = uIdrIds.get(uId);
            
            //this loop keeps going until the roletree map does not contain the roleId as a key anylonger
            while(roleTree.containsKey(roleId)){
                //now we add to the set of parents the parentId which is the value of the current roleId in the roleTree Map
                myParents.add(roleTree.get(roleId));
                roleId = roleTree.get(roleId);
            }
            
            //now we have a set of all the Parent Ids for the current user, we can build our inner map:
            //loop through all of the parents
            for (Id parentRole : myParents){
                //we want to get the name of this current parentRole, and then all the users and put it in our innerMap
                String roleName = roleIdName.get(parentRole);
                User[] roleUsers = roleIdUserList.get(parentRole);
                //add to our innerMap
                innerMap.put(roleName, roleUsers);
            }
            
            //now we can fill out the payload for this userId:
            payload.put(uId, innerMap);
        }
        
        System.debug('=======Here is our payload' + payload);
        return payload;
    }    
    //Just to tell us if we are calling these from a trigger.
    public boolean isTriggerContext{
        get{ return m_isExecuting;}
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