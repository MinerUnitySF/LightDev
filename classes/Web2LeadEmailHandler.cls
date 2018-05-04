global class Web2LeadEmailHandler implements Messaging.InboundEmailHandler {
  
  global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email,
                                Messaging.InboundEnvelope env) {
     
    // Create an InboundEmailResult object for returning the result of the
    // Apex Email Service
    Lead l;    
    Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
    String emailBody = email.plainTextbody;
    //split on new line - which is a problem right now
    String[] emailBodyLines = emailBody.split('[\n\r]');
    System.debug('emailBodyLines: ' + emailBodyLines);
    //temporary solution for the description field (new line characters)
      try {
        l = new Lead();
        String description = '';
        for (String line : emailBodyLines){
          if(!line.contains('-END-')){
            if(line.contains('Description:')){
              description += line; //add the first line of the description field to the string
            } else if(line.contains(':')){
                String[] keyValue = line.split(':');
                System.debug(keyValue[0] + ':' + keyValue[1]);
                if(keyValue.size() > 1 && !keyValue[0].contains(' ')){
                    l.put(keyValue[0], keyValue[1]);
                }
            }else{
              //line does not contain colon - need to add it to the string before it if a part of description
              if(String.isNotBlank(description))
                description += ' '+line;
            }
          //now put the description into the lead:\
          if(String.isNotBlank(description) && description.contains(':')){
            string[] keyValueDescript = description.split(':');
            l.put(keyValueDescript[0], keyValueDescript[1]);
          }
            
          }else{
            break;
          }
        }
       Id recId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Miner_Corp_BDC_Leads' LIMIT 1].Id;
       l.LeadSource = 'Miner Website';
       l.Business_Unit__c = 'Miner Corp';
       l.RecordTypeId = recId;
        System.debug('Lead Sh*t:' + l);
        // to turn the Assignment Rules on
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        dmo.EmailHeader.triggerUserEmail = true;
        l.setOptions(dmo);
        Database.insert(l);
        //to save attachment to the newly inserted lead. Attachment size currently via inbound mail is restricted to 5MB
        if(email.binaryAttachments != null && email.binaryAttachments.size() > 0){
          for (integer i = 0; i < email.binaryAttachments.size(); i++){
            Attachment attachment = new Attachment();
            attachment.ParentId = l.Id;
            attachment.Name = email.binaryAttachments[i].filename;
            attachment.Body = email.binaryAttachments[i].body;
            insert attachment;
          }
        }        
        result.success = true;
    } catch (Exception e) {
        result.success = false;
        result.message = 'Failed to insert Lead. ' + e.getMessage() +'=========='+ emailBodyLines;
    }
    /**String myPlainText= '';
    myPlainText = email.plainTextBody;
    
    result.success = true;
    **/
    return result;

  }
}