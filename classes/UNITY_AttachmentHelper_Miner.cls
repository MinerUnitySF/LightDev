global class UNITY_AttachmentHelper_Miner {
    /** This Method return a Blob from a given url
     */
	public static Blob getVFPageAsPdf(String url){
        PageReference pr = new PageReference(url);
        Blob b;
        if(!Test.isRunningTest()){
            b = pr.getContentAsPDF();
        }else{
            b = Blob.toPdf('this is a test');
        }
        return b;
    }
    /**This method creates a chatter post with a document attached to the post
     * It also requests for a post to be created for the same document to be posted on
     * other records given the record ids
    @future
    public static void createOriginalPost(String recordId,String name,String url,List<String> recordIds){
        //Create the feed item
        ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
        input.subjectId = recordId;
        //Create the content input for the attached file and set the title (name)
        ConnectApi.ContentCapabilityInput contentInput = new ConnectApi.ContentCapabilityInput();
        contentInput.title = name;
        //Create the feed element capability to add the attached file
        ConnectApi.FeedElementCapabilitiesInput capabilities = new ConnectApi.FeedElementCapabilitiesInput();
        capabilities.content = contentInput;
        //Add the capability to the post
        input.capabilities = capabilities;
        //Get the file to attach to the post
        Blob myBlob = getVFPageAsPdf(url);
        //Create a binary input for the post actual doc, passing the blob , type, and file name 
        ConnectApi.BinaryInput binInput = new ConnectApi.BinaryInput(myBlob, 'application/pdf', name);
        //Make the post passing the post and the attached file
        ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), input, binInput);
        //Get the attached document. Need the document id to attach to other records
        List<ContentDocumentLink> myDocs = [SELECT Id, LinkedEntityId,ContentDocumentId,ContentDocument.LatestPublishedVersionId,ContentDocument.Title,ContentDocument.CreatedById,ContentDocument.LastModifiedDate 
                                                      FROM ContentDocumentLink WHERE LinkedEntityId = :recordId];
        for(ContentDocumentLink doc :myDocs){
            //If the attachment is found... request that file to be posted to other records
            if(doc.ContentDocument.Title == name){
                UNITY_AttachmentHelper_Miner_v36.createOtherPost(recordIds, doc.ContentDocumentId);
                break;
            }
        }
    }
	*/
    /**This method creates quote attachments and attaches these to the related case.
     * This method also updates the 'baby' quotes status to 'Pending Customer Review'
     */
    @future(callout=true)
    public static void attachQuote(String qid){
        UNITY_Constants.isExecutingContext('UNITY_AttachmentHelper_Miner.attachQuote');
        if(String.isNotBlank(qid)){
            //List of child quotes to update
            List<UNITY_Proposal__c> childToUpdate = new List<UNITY_Proposal__c>();
            //List of attachment to be inserted
            List<Attachment> attachments = new List<Attachment>();
            //Get the proposal and child proposals
            List<UNITY_Proposal__c> quotes = [SELECT Id,Name,UNITY_Case__c,UNITY_Case__r.ContactId,UNITY_Proposal_Status__c,UNITY_Business_Unit__c,UNITY_Customer__c,UNITY_Customer__r.UNITY_Customer_Team__c,
                                              UNITY_Customer__r.UNITY_MNS_Customer_Team__c,UNITY_Customer_Email__c,
                                              (SELECT Id,Name,UNITY_Master_Quote__c,UNITY_Proposal_Status__c FROM Quotes__r WHERE UNITY_Proposal_Status__c = 'Agent Review Complete') 
                                              FROM UNITY_Proposal__c WHERE Id =: qid LIMIT 1];
            Set<Id> cids = new Set<Id>();//Set to hold the case ids for the quotes
            for(UNITY_Proposal__c q :quotes){
            	cids.add(q.UNITY_Case__c);
            }
            //Get the attchments for the cases to determine which version is being created
            List<Attachment> caseAttach = [SELECT Id,Name,ParentId FROM Attachment WHERE ParentId IN : cids];
            //Put the attachments in a map by case
            Map<Id,List<Attachment>> caseAttachMap = new Map<Id,List<Attachment>>();
            //Put the attachments in a map by q
            Map<Id,List<Attachment>> qAttachMap = new Map<Id,List<Attachment>>();
            for(Attachment a :caseAttach){
                if(!caseAttachMap.containsKey(a.ParentId)){
                    List<Attachment> temp = new List<Attachment>();
                    caseAttachMap.put(a.ParentId,temp);
                }
                caseAttachMap.get(a.ParentId).add(a);
            }
            //Create the attachment to attach to case and email
            for(UNITY_Proposal__c q :quotes){
                //Create the attachment for the email
                //Get the page as pdf
                String url = '/apex/UNITY_CustomerQuote?id=' + q.Id;
                Blob b = getVFPageAsPdf(url);
                //Create the attachment name
                Integer count = 0;
                if(caseAttachMap.containsKey(q.UNITY_Case__c)){
                    for(Attachment a :caseAttachMap.get(q.UNITY_Case__c)){
                        if(a.Name.indexOf(q.Name) != -1){
                            count ++;
                        }
                    }
                }
                String name = q.Name + '-' + String.valueOf(count+1);
                //Create the attachment for the case
                Attachment a = new Attachment();
                a.Body = b;
                a.Name = name + '.pdf';
                a.ParentId = q.UNITY_Case__c;
                attachments.add(a);
                //Izay: Commented Out not to update Sub Quote Status to Pending Customer Review
                //for(UNITY_Proposal__c cq :q.Quotes__r){
                    //cq.UNITY_Proposal_Status__c = 'Pending Customer Review';
                    //childToUpdate.add(cq);
                //}
            }//End for quotes
            try{
                //if(!childToUpdate.isEmpty()){
                    //update childToUpdate;
                //}
                if(!attachments.isEmpty()){
                    insert attachments;
                }
            }catch(Exception e){
                System.debug('#####Izay: Error= ' + e.getMessage());
            }
        }
    }
    /**This method creates invoice attachments and attaches these to the related case.
     */
    @future(callout=true)
    public static void createInvoiceAttachment(Set<String> invIds){
        if(invIds != null){
            //List to hold quotes that did not processes becasue a limit was reached
            Set<String> notProcessed = new Set<String>();
            Integer index = 0;//Denotes the number of attachments created. The max is 10;
            Boolean reachedLimit = false;
            //List of attachment to be inserted
            List<Attachment> attachments = new List<Attachment>();
            //DateTime dt = DateTime.now();
            //String dtString = dt.format('M/d/yyyy h:mm aaa');
            List<UNITY_Invoice__c> invoices = [SELECT Id,Name,UNITY_Case__c,UNITY_Invoice_Status__c FROM UNITY_Invoice__c WHERE Id IN: invIds];
            for(UNITY_Invoice__c inv :invoices){
                if(index < 10){
                    String url= '/apex/UNITY_CustomerInvoice?id='+inv.Id;
                    Blob b = getVFPageAsPdf(url);
                    String name = inv.Name;
                    Attachment a = new Attachment();
                    a.Body = b;
                    a.Name = name + '.pdf';
                    a.ParentId = inv.UNITY_Case__c;
                    attachments.add(a);
                }
                index++;
            }//End for invoices
            if(attachments.size() > 0){
                try{
                    insert attachments;
                }catch(Exception e){
                    //Need to send email to user with exception here
                    //Quote pdf not attached
                }
            }//End if attachments
        }//End invIds != null
    }
    
    webservice static String sendAndAttachQuote(String qid,Boolean sendEmail){
        String result = '';
        if(String.isNotBlank(qid)){
            //Get the org default stuff
            UNITY_Email_Settings__c settings = UNITY_Email_Settings__c.getOrgDefaults();
            //List of emails to send out
            List<Messaging.SingleEmailMessage> messagesList = new List<Messaging.SingleEmailMessage>(); 
            //List of child quotes to update
            List<UNITY_Proposal__c> toUpdate = new List<UNITY_Proposal__c>();
            //List of attachment to be inserted
            List<Attachment> attachments = new List<Attachment>();
            //Get the proposal and child proposals
            List<UNITY_Proposal__c> quotes = [SELECT Id,Name,UNITY_Case__c,UNITY_Case__r.ContactId,UNITY_Proposal_Status__c,UNITY_Business_Unit__c,UNITY_Customer__c,UNITY_Customer__r.UNITY_Customer_Team__c,
                                              UNITY_Customer__r.UNITY_MNS_Customer_Team__c,UNITY_Customer_Email__c,UNITY_Email_Logo_URL__c,UNITY_Case_Thread_ID__c,UNITY_Master_PIN__c,
                                              (SELECT Id,Name,UNITY_Master_Quote__c,UNITY_Proposal_Status__c FROM Quotes__r WHERE UNITY_Proposal_Status__c = 'Agent Review Complete') 
                                              FROM UNITY_Proposal__c WHERE Id =: qid LIMIT 1];
            Set<Id> cids = new Set<Id>();//Set to hold the case ids for the quotes
            for(UNITY_Proposal__c q :quotes){
            	cids.add(q.UNITY_Case__c);
            }
            //Get the attchments for the cases to determine which version is being created
            List<Attachment> caseAttach = [SELECT Id,Name,ParentId FROM Attachment WHERE ParentId IN : cids];
            //Put the attachments in a map by case
            Map<Id,List<Attachment>> caseAttachMap = new Map<Id,List<Attachment>>();
            //Put the attachments in a map by q
            Map<Id,List<Attachment>> qAttachMap = new Map<Id,List<Attachment>>();
            for(Attachment a :caseAttach){
                if(!caseAttachMap.containsKey(a.ParentId)){
                    List<Attachment> temp = new List<Attachment>();
                    caseAttachMap.put(a.ParentId,temp);
                }
                caseAttachMap.get(a.ParentId).add(a);
            }
            //Create the attachment to attach to case and email
            for(UNITY_Proposal__c q :quotes){
                //Set variables for email setup
                String oweBUId = '';
                String oweBUAdd = '';
                String oweTeamId = '';
                String oweTeamAdd = '';
                String oweMiner = '';
                String oweMinerAdd = '';
				//Build the accept/reject links
                String acceptLink = 'mailto:'+settings.Workflow_Email_Address__c+'?subject=Re:%20Quote%20Proposed%20'+q.Name+'%20PIN%20'+q.UNITY_Master_PIN__c+'%20['+q.UNITY_Case_Thread_ID__c+']&body=ACCEPT';
                String rejLink = 'mailto:'+settings.Workflow_Email_Address__c+'?subject=Re:Quote Proposed '+q.Name+' PIN '+q.UNITY_Master_PIN__c+' ['+q.UNITY_Case_Thread_ID__c+']&body=REJECT.%0AThe reason is:';
                //Buld the email subject
                String subject = 'Quote Proposed '+q.Name+ '  PIN '+q.UNITY_Master_PIN__c+ '  ['+q.UNITY_Case_Thread_ID__c+']';
                //Build the email budy
                String htmlBody = '<html>' +
                    '<div style="display: block; height: 60px;">' +
                    '<img align="left" alt="Miner Logo" border="0" height="60px" src="'+q.UNITY_Email_Logo_URL__c+'" />&nbsp;' +
                    '</div>' +
                    '<div style="display: block">' +
                    '<p>Hello,</p>' +
                    '<p>' +
                    'Please review the attached quote and accept or reject at your earliest convenience. We will schedule work as soon as we have your approval to proceed.' +
                    '</p>'+
                    '<p>To accept or reject this quote, click the button below and send the pre-populated email.</p>'+
                    '</div>'+
                    '<div>'+
                    '<p>'+
                    'Thank you and have a great day.'+
                    '</p>'+
                    '</div>'+
                    '<div>'+
                    '<table border="0">'+
                    '<tr>'+
                    '<td>'+
                    '<a href="'+acceptLink+'" style="display:block;text-align:center;" target="_blank">'+
                    '<img border="0" src="'+settings.Icon_URL_Accept__c+'" style="padding: 5px" />'+
                    '<p>ACCEPT</p>'+
                    '</a>' +
                    '</td>'+
                    '<td>'+
                    '<a href="'+rejLink+'" style="display:block;text-align:center;" target="_blank">'+
                    '<img border="0" src="'+settings.Icon_URL_Reject__c+'" style="padding: 5px" />'+
                    '<p>REJECT</p>'+
                    '</a>'+
                    '</td>'+
                    '</tr>'+
                    '</table>'+
                    '<p>Note: If you do not see buttons or links, simply reply to this email and type <b>ACCEPT</b> or <b>REJECT</b>'+
                    '</p>'+
                    '</div>'+
                    '<div style="display: none !important;">['+q.UNITY_Case_Thread_ID__c+']</div></html>';
                System.debug('##### htmlBody: ' + htmlBody);
                String plainBody = 'Hello,\n\n'+
                    'Please review the attached quote and accept or reject at your earliest convenience. We will schedule work as soon as we have your approval to proceed.\n\n'+
                    'To accept or reject this quote, reply to this email and type ACCEPT or REJECT.\n\n'+
                    'Thank you and have a great day -\n\n'+
                    '['+q.UNITY_Case_Thread_ID__c+']';
                //Get the team field for the Business Unit. This helps with setting the currect org wide email address
                String fieldName = UNITY_BU_Team_Field_Map__c.getInstance(q.UNITY_Business_Unit__c).UNITY_Field_API_Name__c;
                String team = '';
                if(String.isNotBlank(fieldName)){
                    team = (String)q.getSObject('UNITY_Customer__r').get(fieldName);
                }
                //Iterate through all org wide email addresses to find the correct one
                for(OrgWideEmailAddress owa : [SELECT Id,Address,DisplayName FROM OrgWideEmailAddress]){
                    if(String.isNotBlank(team) && String.isNotBlank(q.UNITY_Business_Unit__c)){
                        if(owa.DisplayName.contains(q.UNITY_Business_Unit__c) && owa.DisplayName.contains(team)){
                            oweTeamId = owa.Id;
                            oweTeamAdd = owa.Address;
                        }
                    }
                    if(String.isNotBlank(q.UNITY_Business_Unit__c)){
                        if(owa.DisplayName.contains(q.UNITY_Business_Unit__c) && owa.DisplayName.contains('Customer Support')){
                            oweBUId = owa.Id;
                            oweBUAdd = owa.Address;
                        }
                    }
                    if(owa.DisplayName == 'Miner Corp'){
                        oweMiner = owa.Id;
                        oweMinerAdd = owa.Address;
                    }
                }
                //Create the attachment for the email
                //Get the page as pdf
                String url = '/apex/UNITY_CustomerQuote?id=' + q.Id;
                Blob b = getVFPageAsPdf(url);
                //Create the attachment name for the quote pdf
                Integer count = 0;
                if(caseAttachMap.containsKey(q.UNITY_Case__c)){
                    for(Attachment a :caseAttachMap.get(q.UNITY_Case__c)){
                        if(a.Name.indexOf(q.Name) != -1){
                            count ++;
                        }
                    }
                }
                String name = q.Name + '-' + String.valueOf(count+1);
                //Create the attachment
                Attachment a = new Attachment();
                a.Body = b;
                a.Name = name + '.pdf';
                a.ParentId = q.UNITY_Case__c;
                attachments.add(a);
                //Create the attachment for the email message
                Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
                emailAttachment.setFileName(a.Name);
                emailAttachment.setBody(a.Body);
                //Create message for customer
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.setOrgWideEmailAddressId(String.isNotBlank(oweTeamId)?oweTeamId:(String.isNotBlank(oweBUId)?oweBUId:oweMiner));
                message.setReplyTo(String.isNotBlank(oweTeamId)?oweTeamAdd:(String.isNotBlank(oweBUId)?oweBUAdd:oweMinerAdd));
                message.setSaveAsActivity(false);
                message.setSubject(subject);
                message.setHtmlBody(htmlBody);
                message.setPlainTextBody(plainBody);
                message.setToAddresses(new String[] {q.UNITY_Customer_Email__c});
                message.setFileAttachments(new Messaging.EmailFileAttachment[] { emailAttachment });
                //Create Message to keep in salesforce
                Messaging.SingleEmailMessage message_miner = new Messaging.SingleEmailMessage();
                message_miner.setOrgWideEmailAddressId(String.isNotBlank(oweTeamId)?oweTeamId:(String.isNotBlank(oweBUId)?oweBUId:oweMiner));
                message_miner.setReplyTo(String.isNotBlank(oweTeamId)?oweTeamAdd:(String.isNotBlank(oweBUId)?oweBUAdd:oweMinerAdd));
                message_miner.setSaveAsActivity(false);
                message_miner.setSubject(subject);
                message_miner.setHtmlBody(htmlBody);
                message_miner.setPlainTextBody(plainBody);
                message_miner.setToAddresses(new String[] {String.isNotBlank(oweTeamId)?oweTeamAdd:(String.isNotBlank(oweBUId)?oweBUAdd:oweMinerAdd)});
                messagesList.add(message_miner);
                messagesList.add(message);
                //for(UNITY_Proposal__c cq :q.Quotes__r){
                    //cq.UNITY_Proposal_Status__c = 'Pending Customer Review';
                    //toUpdate.add(cq);
                //}
                q.UNITY_Proposal_Status__c = 'Sent to Customer';
                toUpdate.add(q);
            }//End for quotes
            try{
                if(!messagesList.isEmpty() && sendEmail){
                    Messaging.sendEmail(messagesList);
                }
                if(!toUpdate.isEmpty()){
                    update toUpdate;
                }
                result = 'Success';
            }catch(Exception e){
                System.debug('#####Izay: Error= ' + e.getMessage());
                result = 'Error: ' + e.getMessage();
            }
        }else{
            //No id provided
        }
        return result;
    }
    
    public static boolean isAttachmentVendorVisible(UNITY_Attachment__c a){
        UNITY_Community_Setting__mdt visibleAttTypes = [SELECT Label,Value__c FROM UNITY_Community_Setting__mdt 
                                               WHERE Label='Vendor Attachment Types' LIMIT 1];
        
        Set<String> delimitedInvoiceableStatuses = new Set<String>(visibleAttTypes.Value__c.split(','));
        system.debug('@@@isAttachmentVendorVisible delimitedInvoiceableStatuses:'+delimitedInvoiceableStatuses);
        
        system.debug('@@@isAttachmentVendorVisible isAttachmentVendorVisible:'+delimitedInvoiceableStatuses.contains(a.UNITY_Type__c));
        return delimitedInvoiceableStatuses.contains(a.UNITY_Type__c);
    }
}