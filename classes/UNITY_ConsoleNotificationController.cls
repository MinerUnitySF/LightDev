/**This class is the controller for the UNITY_ConsoleNotificationComponent vfPage
 * @programmer: Izay Ramos-Irizarry
 * @description: This class is the controller for the UNITY_ConsoleNotificationComponent vfPage
 * @date: 3/8/2016
 * @version: 1.0
 */
global class UNITY_ConsoleNotificationController {
    //The name of the push topic for the console notification
    public static final String TOPIC_NAME = Test.isRunningTest() ? 'TestNotification'+TestDataProvider.getRandomint(100,999) : 'UNITY_ConsoleNotification';
    public static final String TOPIC_QUERY = 'SELECT Id,Message__c,Record_Id__c,Record_Name__c,Subject__c,Subscriber__c,Type__c FROM UNITY_Push_Notification__c';
    /**This method subscribes the user to the notification Streaming Api Push Topic.
     * @return String result - String in JSON format returned with the created/updated Push Topic. 
     */
    @RemoteAction
    global static String subscribe(){
        //The result to return
        String result = '';
        //Create the push topic
        PushTopic pushTopic = new PushTopic();
        //See if there is a push topic already created for this user
        List<PushTopic> topics = [SELECT Id,Name,Query FROM PushTopic WHERE Name = :TOPIC_NAME AND IsDeleted = FALSE LIMIT 1];
        //If there is a topic, update it... Otherwise, create a new one
        if(topics.isEmpty()){
            pushTopic.ApiVersion = 23.0;
            pushTopic.Name = TOPIC_NAME;
            pushTopic.Description = 'Push topic for: ' + TOPIC_NAME;
            pushTopic.Query = TOPIC_QUERY;
            pushTopic.NotifyForOperationCreate = true;
            pushTopic.NotifyForOperationUpdate = false;
            pushTopic.NotifyForFields = 'Referenced';
            try{
                insert pushTopic;
                //System.debug('Created new PushTopic: '+ pushTopic.Id);
                result = '{"success":true,"topicid": "'+pushTopic.Id+'","topicname":"'+pushTopic.Name+'","topicquery":"'+pushTopic.Query+'"}';
            }catch(Exception e){
                //System.debug('======== Error: ' + e.getMessage());
                result = '{"Success":false,"Error":"'+e.getMessage()+'"}';
            }
        //Otherwise, create a new one
        }else{
            pushTopic = topics[0];
            //System.debug('Created new PushTopic: '+ pushTopic.Id);
            result = '{"success":true,"topicid": "'+pushTopic.Id+'","topicname":"'+pushTopic.Name+'","topicquery":"'+pushTopic.Query+'"}';
        }//End if topics size
        return result;//Retuen the result string
    }
    /**This method returnes a structured notification. I also retreives a notification detail if it is related to a record.
     * @param id String - The UNITY_Push_Notification__c Id
     * @return UNITY_ConsoleNotificationController.Notif - The structured notification
     */
    @RemoteAction
    global static List<UNITY_ConsoleNotificationController.Notif> getNotification(String id){
        //The list of notifications to return
        List<UNITY_ConsoleNotificationController.Notif> myNots = new List<UNITY_ConsoleNotificationController.Notif>();
        //If a push notification id was given
        if(String.isNotBlank(id)){
            //We have to create all the data required for the push topic.
            String userId = UserInfo.getUserId();//The current user id
            Set<Id> ownerIds = new Set<Id>();//Set to hold possible UNITY Push Notification subscriber ids for the current user
            //Fetch all the group member records for the current user
            List<GroupMember> myMembers = [SELECT Id,GroupId,UserOrGroupId FROM GroupMember 
                                           WHERE UserOrGroupId = :userId];
            //Set to hold the group ids
            Set<Id> gids = new Set<Id>();
            //Add group ids to gids set
            for(GroupMember gm :myMembers){
                gids.add(gm.GroupId);
            }
            //Now, need to fetch any group memeber where the UserOrGroup is one of the groups above. Doing this just once.
            myMembers = [SELECT Id,GroupId,UserOrGroupId FROM GroupMember 
                         WHERE UserOrGroupId IN :gids];
            //Add group ids to gids set
            for(GroupMember gm :myMembers){
                gids.add(gm.GroupId);
            }
            //Fetch all group in gids that are case queue or queue
            List<Group> myGroups = [SELECT Id,Name,Type FROM Group WHERE Id IN :gids AND (Type = 'Case' OR Type = 'Queue')];
            //Set the group ids in the ownerIds string formatted for the dynamic query
            for(Group g :myGroups){
                ownerIds.add(g.Id); //+= '\'' + g.Id + '\',';
            }
            //Add the userId at the end of ownerIds formatted for dynamic query
            ownerIds.add(userId);// += '\'' + userId + '\'';
            //Feth the notification record
            List<UNITY_Push_Notification__c> pushNots = [SELECT Id,Type__c,Record_Id__c,Record_Name__c,Subject__c,Subscriber__c,Message__c,CreatedDate
                                                   FROM UNITY_Push_Notification__c WHERE Id = :id AND Subscriber__c IN :ownerIds LIMIT 1];
            if(!pushNots.isEmpty()){
                //Map to hold my notification by push notification
                Map<Id,UNITY_My_Notification__c> myNotifsMap = new Map<Id,UNITY_My_Notification__c>();
                for(UNITY_Push_Notification__c pn :pushNots){
                    UNITY_My_Notification__c mn = new UNITY_My_Notification__c(
                    	Push_Notification__c = pn.Id,
                        User__c = userId,
                        Status__c = 'Unread'
                    );
                    myNotifsMap.put(pn.Id,mn);
                }
                insert myNotifsMap.values();
                myNots = constructNotifications(pushNots,myNotifsMap);
            }
        }//End if id
        return myNots;//Return the notification
    }
    /**This method returnes a list structured notifications. I also retreives all notification detail if it is related to a record.
     * @param id String - The UNITY_Push_Notification__c Id
     * @return UNITY_ConsoleNotificationController.Notif - The structured notification
     */
    @RemoteAction
    global static List<UNITY_ConsoleNotificationController.Notif> getMyNotifs(){
        //The list of notifications to return
        List<UNITY_ConsoleNotificationController.Notif> myNots = new List<UNITY_ConsoleNotificationController.Notif>();
        //Fetch UNITY_My_Notofocations__c for the user. These are notifications that the user receives but has not dismissed
        List<UNITY_My_Notification__c> myNotifs = [SELECT Id,Push_Notification__c,User__c,Status__c FROM UNITY_My_Notification__c
                                                  WHERE User__c = :UserInfo.getUserId() AND Status__c != 'Dismissed'];
        //If the user has notifications...
        if(myNotifs.size() > 0){
            //Map to hold my notification by push notification
            Map<Id,UNITY_My_Notification__c> myNotifsMap = new Map<Id,UNITY_My_Notification__c>();
            //Iterate through my notifications
            for(UNITY_My_Notification__c mn :myNotifs){
                myNotifsMap.put(mn.Push_Notification__c,mn);//Put the my notification to the myNotifsMap by pusj notification id
            }
            //Fetch push notification 
            List<UNITY_Push_Notification__c> pushNots = [SELECT Id,Type__c,Record_Id__c,Record_Name__c,Subject__c,Subscriber__c,Message__c, CreatedDate
                                                         FROM UNITY_Push_Notification__c WHERE Id IN :myNotifsMap.keySet() ORDER BY CreatedDate ASC];
            
            myNots = constructNotifications(pushNots,myNotifsMap);
        }//End if myNotifs
        return myNots;
    }
    
    global static List<UNITY_ConsoleNotificationController.Notif> constructNotifications(List<UNITY_Push_Notification__c> notifications,Map<Id,UNITY_My_Notification__c> myNotifsMap){
        //The list of notifications to return
        List<UNITY_ConsoleNotificationController.Notif> myNots = new List<UNITY_ConsoleNotificationController.Notif>();
        if(!notifications.isEmpty()){
            //Map to hold push notifications by type
            Map<String,List<UNITY_Push_Notification__c>> pushNotsMap = new Map<String,List<UNITY_Push_Notification__c>>();
            //Iterate through each push notification and put it in the pushNotsMap by the push notification type
            for(UNITY_Push_Notification__c pnot :notifications){
                if(!pushNotsMap.containsKey(pnot.Type__c))
                    pushNotsMap.put(pnot.Type__c,new List<UNITY_Push_Notification__c>());
                pushNotsMap.get(pnot.Type__c).add(pnot);
            }
            
            //Iterate throuh each type of push notification...
            for(String nType :pushNotsMap.keySet()){
                //Fetch the push notification setting record for the alert type
                UNITY_Push_Notification_Setting__c pns = UNITY_Push_Notification_Setting__c.getInstance(nType); 
                //if the type is NOT alert
                System.debug('========= pns: ' + pns);
                if(nType != 'Alert' && pns != null){
                    String recIds = '';
                    //Set the record ids in the recIds string formated for dynamic query
                    for(UNITY_Push_Notification__c pn :pushNotsMap.get(nType)){
                        recIds += String.isNotBlank(pn.Record_Id__c) ? '\'' + pn.Record_Id__c + '\',' : '';
                    }
                    if(String.isNotBlank(recIds)){
                        recIds = recIds.removeEnd(',');//Remove the last coma from the recIds string
                        //System.debug('-------- recIds: ' + recIds);
                        ////Create the query using the provided query in push notification setting 
                        String query = 'SELECT ' + pns.Query__c + ' WHERE Id IN (' + recIds + ')';
                        //System.debug('---------- query: ' + query);
                        //Fetch the records
                        sObject[] records = Database.query(query);
                        //If records are found...
                        if(records.size() > 0){
                            //Put the records in the objMap by the record id
                            Map<Id,sObject> objMap = new Map<Id,sObject>();
                            for(sObject obj :records){
                                objMap.put((Id)obj.get('Id'), obj);
                            }
                            //Iterate through each notification of this type...
                            for(UNITY_Push_Notification__c pn :pushNotsMap.get(nType)){
                                //Create the notif
                                UNITY_ConsoleNotificationController.Notif n = new UNITY_ConsoleNotificationController.Notif();
                                try{
                                    n.n_id = pn.Id;
                                    n.notif_id = myNotifsMap.get(pn.Id).Id;
                                    n.n_type = pn.Type__c;
                                    n.subject = pn.Subject__c.escapeHtml4();
                                    n.status = myNotifsMap.get(pn.Id).Status__c;
                                    n.bg_color = pns.BG_Color__c;
                                    n.record_id = String.isNotBlank(pn.Record_Id__c) ? pn.Record_Id__c : '';
                                    n.record_name = String.isNotBlank(pn.Record_Name__c) ? pn.Record_Name__c : '';
                                    n.message = String.isNotBlank(pn.Message__c) ? pn.Message__c.escapeHtml4() : '';
                                    
                                    Map<String,String> fMap = new Map<String,String>();
                                    if(String.isNotBlank(n.record_id)){
                                        //Get the label for the id
                                        n.object_label = ((Id)n.record_id).getSObjectType().getDescribe().getLabel();
                                        n.object_type = ((Id)n.record_id).getSObjectType().getDescribe().getName();
                                        
                                        JSONParser parser = JSON.createParser(pns.Fields_Order__c);
                                        while(parser.nextToken() != null){
                                            if(parser.getCurrentToken() == JSONToken.FIELD_NAME){
                                                String l = parser.getText();
                                                parser.nextToken();
                                                String v = parser.getText();
                                                fMap.put(l,v);
                                            }
                                        }
                                    }//End if record id
                                    n.html_msg += '<li  id="'+n.n_id+'" class="n-line" data-bg="'+n.bg_color+'" data-mynid="'+n.notif_id+'"><table class="line-table"><tr><td>';
                                    n.html_msg += '<input type="checkbox" class="n-select" value="'+n.notif_id+'" name="nselect"/></td>';
                                    n.html_msg += '<td><div class="n-type">'+n.n_type+' '+n.record_name+'</div>';
                                    n.html_msg += '<div class="n-subject">'+n.subject+'</div></td><td><span class="n-status '+((n.status == 'Unread') ? 'n-unread':'n-read')+'"></span></td></tr></table>';
                                    n.html_msg += '<div class="n-message"><table class="message-table">';
                                    if(String.isNotBlank(n.record_id)){
                                        n.html_msg += '<tr><th>'+n.object_label+'</th><td><a class="record-link" href="'+n.record_id+'" title="'+n.record_name+'">'+n.record_name+'</td></tr>';
                                        for(String key :fMap.keySet()){
                                            String[] vals = fMap.get(key).split('\\.');
                                            System.debug('================ vals: ' + vals);
                                            String myVal;
                                            if(vals.size() > 1){
                                                myVal = String.valueOf(objMap.get(pn.Record_Id__c).getSObject(vals[0]).get(vals[1]));
                                            }else if(vals.size() > 0){
                                                myVal = String.valueOf(objMap.get(pn.Record_Id__c).get(vals[0]));
                                            }
                                            if(String.isNotBlank(myVal)){
                                                n.html_msg += '<tr><th>'+key+'</th><td>'+myVal+'</td></tr>';
                                            }
                                        }
                                        if(String.isNotBlank(n.message)){
                                            n.html_msg += '<tr><th>Message</th><td>'+n.message+'</td></tr>';
                                        }
                                    }else{
                                        n.html_msg += '<tr><th>Subject</th><td>'+n.subject+'</td></tr>';
                                        n.html_msg += '<tr><th>Message</th><td>'+n.message+'</td></tr>';
                                        n.html_msg += '<tr><th>Notification Date</th><td>'+pn.CreatedDate+'</td></tr>';
                                    }
                                    n.html_msg += '</table></div></li>';
                                }catch(Exception e){
                                    System.debug('--------- Error: ' + e.getMessage());
                                    n.html_msg += '<tr><th>Error</th><td>'+e.getMessage()+'</td></tr>';
                                    n.html_msg += '</table></div></li>';
                                    n.error = true;
                                    continue;
                                }
                                myNots.add(n);
                            }//End for push nots map
                        }//End if records 
                    }//End if recIds
                }//End if not alert or no push notification setting found for this type...
                else{
                    String bg = '#DDEAC0';
                    for(UNITY_Push_Notification__c pn :pushNotsMap.get(nType)){
                        UNITY_ConsoleNotificationController.Notif n = new UNITY_ConsoleNotificationController.Notif();
                        try{
                            n.n_id = pn.Id;
                            n.notif_id = myNotifsMap.get(pn.Id).Id;
                            n.n_type = pn.Type__c;
                            n.subject = pn.Subject__c.escapeHtml4();
                            n.status = myNotifsMap.get(pn.Id).Status__c;
                            n.bg_color = bg;
                            n.record_id = String.isNotBlank(pn.Record_Id__c) ? pn.Record_Id__c : '';
                            n.record_name = String.isNotBlank(pn.Record_Name__c) ? pn.Record_Name__c : '';
                            n.message = String.isNotBlank(pn.Message__c) ? pn.Message__c.escapeHtml4() : '';
                            
                            n.html_msg += '<li  id="'+n.n_id+'" class="n-line" data-bg="'+n.bg_color+'" data-mynid="'+n.notif_id+'"><table class="line-table"><tr><td>';
                            n.html_msg += '<input type="checkbox" class="n-select" value="'+n.notif_id+'" name="nselect"/></td>';
                            n.html_msg += '<td><div class="n-type">'+n.n_type+' '+n.record_name+'</div>';
                            n.html_msg += '<div class="n-subject">'+n.subject+'</div></td><td><span class="n-status '+((n.status == 'Unread') ? 'n-unread':'n-read')+'"></span></td></tr></table>';
                            n.html_msg += '<div class="n-message"><table class="message-table">';
                            
                            if(String.isNotBlank(n.record_id)){
                                //Get the label for the id
                                n.object_label = ((Id)n.record_id).getSObjectType().getDescribe().getLabel();
                                n.object_type = ((Id)n.record_id).getSObjectType().getDescribe().getName();
                                n.html_msg += '<tr><th>'+n.object_label+'</th><td><a class="record-link" href="'+n.record_id+'" title="'+n.record_name+'">'+n.record_name+'</td></tr>';
                            }
                            
                            n.html_msg += '<tr><th>Subject</th><td>'+n.subject+'</td></tr>';
                            n.html_msg += '<tr><th>Message</th><td>'+n.message+'</td></tr>';
                            n.html_msg += '<tr><th>Notification Date</th><td>'+pn.CreatedDate+'</td></tr>';
                            n.html_msg += '</table></div></li>';
                        }catch(Exception e){
                            System.debug('--------- Error: ' + e.getMessage());
                            n.html_msg += '<tr><th>Error</th><td>'+e.getMessage()+'</td></tr>';
                            n.html_msg += '</table></div></li>';
                            n.error = true;
                            continue;
                        }
                        myNots.add(n);
                    }
                }//End if alert
            }//End for nType
        }
        return myNots;
    }
    
    global class Notif{
        String n_id {get;set;}
        String notif_id {get;set;}
        String n_type {get;set;}
        String subject {get;set;}
        String status {get;set;}
        String object_label {get;set;}
        String object_type {get;set;}
        String record_id {get;set;}
        String record_name {get;set;}
        String message {get;set;}
        String html_msg {get;set;}
        String bg_color {get;set;}
        Boolean error {get;set;}
        
        public Notif(){
            this.n_id = '';
            this.notif_id = '';
            this.n_type='';
            this.subject='';
            this.status = '';
            this.object_label = '';
            this.object_type = '';
            this.message = '';
            this.html_msg='';
            this.bg_color = '';
            this.error = false;
        }
    }
}