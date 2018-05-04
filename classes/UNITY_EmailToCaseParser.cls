public class UNITY_EmailToCaseParser {

    public static Case parse(Messaging.inboundEmail email){

        Case newCase;

        String subject     = email.subject.trim();
        String fromAddress = email.fromAddress;
        String fromDomain  = fromAddress.split('@')[1];
        String toDomain    = email.toAddresses[0].split('@')[1];
        
        List<Attachment> attachments = new List<Attachment>();
        //Get any Text Attachment
        if (email.textAttachments != null) {
            for(Messaging.Inboundemail.TextAttachment tAttachment : email.textAttachments) {
                Attachment txtAttachment = new Attachment();
                txtAttachment.Name = tAttachment.fileName;
                txtAttachment.Body = Blob.valueOf(tAttachment.body);
                attachments.add(txtAttachment);
            }
        }
        
        //Get any Binary Attachment
        if (email.binaryAttachments != null) {
            for(Messaging.Inboundemail.BinaryAttachment bAttachment : email.binaryAttachments) {
                Attachment binAttachment = new Attachment();
                binAttachment.Name = bAttachment.fileName;
                binAttachment.Body = bAttachment.body;
                attachments.add(binAttachment);
            }
        }
        
        //Get default values based on "To" email address domain
        List<UNITY_EmailDomainMap__c> domainMaps = [SELECT Case_Origin__c, Business_Unit__c, Owner_Name__c FROM UNITY_EmailDomainMap__c WHERE To_Email_Domain__c = :toDomain];
        String bu = domainMaps.size() > 0 ? domainMaps[0].Business_Unit__c : null;
        String origin = domainMaps.size() > 0 ? domainMaps[0].Case_Origin__c : null;
        Id ownerId;
        if(domainMaps.size() > 0) {
            List<QueueSobject> caseOwner = [SELECT QueueId FROM QueueSobject WHERE Queue.Name = :domainMaps[0].Owner_Name__c AND SobjectType = 'Case'];
            ownerId = caseOwner.size() > 0 ? caseOwner[0].QueueId : null;
        }
        
        // Create a Case
        newCase = new Case(Subject = subject, SuppliedName = email.fromName, SuppliedEmail = email.fromAddress, UNITY_Business_Unit__c = bu, Origin = origin, OwnerId = ownerId);
        
        //CLAY: Debug for parsing
        System.debug('=====================CLAY: defining maps');
        System.debug('>>> Subject: ' + newCase.Subject);
        System.debug('>>> SuppliedName: '  + newCase.SuppliedName);
        System.debug('>>> SuppliedEmail: ' + newCase.SuppliedEmail);
        System.debug('>>> BU: '            + newCase.UNITY_Business_Unit__c);
        System.debug('>>> Origin: '        + newCase.Origin);
        System.debug('>>> OwnerId: '       + newCase.OwnerId);

        System.debug('>>> fromDomain: '    + fromDomain);


        Map<String, Schema.sObjectField> caseFieldsMap = Schema.SObjectType.Case.fields.getMap();
        
        // Populate default fields
        Map<String, UNITY_CaseFromEmailFields__c> fieldMappings = new Map<String, UNITY_CaseFromEmailFields__c>();
        Map<String, List<UNITY_CaseFromEmailFields__c>> emailFieldMatches = new Map<String, List<UNITY_CaseFromEmailFields__c>>();
        Map<String, String> searchWord_delimiter = new Map<String, String>();
        //CLAY: -The Generic template key is to cover for not finding any emailFieldMatches
        //To use this, you would have to have a setting for generic UNITY Case From Email Field custom setting.
        //Another way to solve this would be to utilize the TO email address for origin: lbrands@nsbs.net but failed parsing would create a 
        String templateKey = 'Generic';
        String delimiter   = ':';

        for (UNITY_CaseFromEmailFields__c def : [SELECT Additional_Description__c, Field_Name__c, Search_Attribute__c, 
                                            Template_Key__c, Template_Delimiter__c 
                                            FROM UNITY_CaseFromEmailFields__c 
                                            WHERE Template_Key__c like :'%'+fromDomain OR Template_Key__c = :templateKey]) {
            System.debug('>>> Case From Email Fields');
            System.debug('>>> Field_Name__c          -->'+def.Field_Name__c);
            System.debug('>>> Search_Attribute__c    -->'+def.Search_Attribute__c);
            System.debug('>>> Template_Delimiter__c  -->'+def.Template_Delimiter__c);
            searchWord_delimiter.put(def.Search_Attribute__c,def.Template_Delimiter__c);
            if(delimiter != def.Template_Delimiter__c && def.Template_Delimiter__c != null) delimiter = def.Template_Delimiter__c;
            if(emailFieldMatches.get(def.Template_Key__c) == null ) emailFieldMatches.put(def.Template_Key__c, new List<UNITY_CaseFromEmailFields__c>());
            
            emailFieldMatches.get(def.Template_Key__c).add(def);
            /*
            if(matches == null) {
               
                matches = new List<UNITY_CaseFromEmailFields__c>();
                emailFieldMatches.put(def.Template_Key__c, matches);
            }
            matches.add(def);*/
        }
        System.debug('>>> delimiter : ' + delimiter);
        System.debug('>>> emailFieldMatches :' + emailFieldMatches);
        
        //CLAY: Debug for parsing
        //System.debug('=====================CLAY:');
        //System.debug('==: emailFieldMatches:' + emailFieldMatches);
        
        // Extract the template name from the "from" email address/domain
        List<UNITY_CaseFromEmailFields__c> templates = new List<UNITY_CaseFromEmailFields__c>();
        if(emailFieldMatches.containsKey(fromDomain)) {
            templates = emailFieldMatches.get(fromDomain);
            templateKey = fromDomain;
        } else if(emailFieldMatches.containsKey(fromAddress)) {
            templates = emailFieldMatches.get(fromAddress);
            templateKey = fromAddress;
        } else {
            templates = emailFieldMatches.get('Generic');
        }
        
        for (UNITY_CaseFromEmailFields__c def : templates) {
            fieldMappings.put(def.Search_Attribute__c, def);
        }
        
        System.debug('>>> fieldMappings :' + fieldMappings);

        // Populate a map of source field values and their corresponding final values in Salesforce
        Map<String, Map<String, String>> fieldValuesMap = new Map<String, Map<String, String>>();

        for (UNITY_CaseFromEmailFieldValues__c values : [SELECT Field_Name__c, Source_Value__c, Final_Value__c 
                                                    FROM UNITY_CaseFromEmailFieldValues__c WHERE Template_Key__c = :templateKey]) {
            
            if(fieldValuesMap.get(values.Field_Name__c) == null) fieldValuesMap.put(values.Field_Name__c, new Map<String, String>());
            fieldValuesMap.get(values.Field_Name__c).put(values.Source_Value__c, values.Final_Value__c);
        }

        System.debug('>>> fieldValuesMap : '+fieldValuesMap);

        // Search "*: *\n" pattern in the email body using regex
        String emailBody = email.plainTextBody.replace('*','');

        emailBody = emailBody.replace(delimiter + '\n\n', delimiter + ' ');

        // Remove any text between '<'+ text +'>''
        emailBody = emailBody.replaceAll('<(.*?)>','');

        System.debug('>>> emailBody : '+emailBody);

        delimiter = ':';

        // Match anything 'key:value' (value can be AAAA:aaaaa)
        Matcher myMatcher = Pattern.compile('.*' + delimiter + '.*').matcher(emailBody);

        
        String       myMatch             = '';
        List<String> matchSet            = new List<String>();
        String       description         = '';
        Boolean      aux_found_key_value = false;
        

        while (myMatcher.find()) {

            myMatch = myMatcher.group(0);

            System.debug('>>> match : ' + myMatch);

            // pattern 'key '+': '+'Value'
            matchSet = myMatch.split(': ');

            aux_found_key_value = (matchSet.size() == 2);

            if(!aux_found_key_value)  continue;

            // Get the search literal or key
            string searchStr = matchSet[0].trim();
            System.debug('>>> searchStr : '   + searchStr);

            // Get the source value from email
            String sourceValue = matchSet[1].trim();
            System.debug('>>> sourceValue : ' + sourceValue);

            // Get the field name
            String fieldName = fieldMappings.get(searchStr) == null ? null : fieldMappings.get(searchStr).Field_Name__c;
            if(fieldName == null) continue;

            // Get Final field value from email Source value
            String fieldValue = sourceValue;
            if(fieldValuesMap.get(fieldName) != null) {
                Map<String, String> valuesMap = fieldValuesMap.get(fieldName);
                fieldValue = valuesMap.get(sourceValue) == null ? sourceValue : valuesMap.get(sourceValue);
            }
            
            // Get any additional one-off description text
            if(fieldMappings.get(searchStr) != null && fieldMappings.get(searchStr).Additional_Description__c != null) {
                description += fieldMappings.get(searchStr).Additional_Description__c + ': ' + fieldValue + '\n';
            }
            
            // Set the field value
            if(caseFieldsMap.get(fieldName) != null) {
                Schema.DescribeFieldResult F = caseFieldsMap.get(fieldName).getDescribe();
                string typename = F.getType().name().toLowerCase();
                
                // Convert to desired data type
                if(typename == 'reference') {
                    // Retrieve the lookup record based on fieldValue match
                    String sobjname = String.valueOf(F.getReferenceTo()).substringBetween('(',')'); 

                    if(sobjname == 'Account'){

                        String street, city, state, zip;
                        
                        String[] address = sourceValue.split(',');
                        street = address[0].trim();
                        city = address.size() > 1 ? address[1].trim() : null;
                        String [] stateZip = address.size() > 2 ? address[2].trim().split(' ') : null;
                        state = stateZip[0];
                        zip = stateZip.size() > 1 ? stateZip[1].trim() : null;
                       
                        String queryStr='select id from ' + sobjname ;
                        String queryStr_WHERE ='';
                        boolean allParameters = false;
                        if((street != null)&&(street != '')) {
                            queryStr_WHERE += 'ShippingStreet = \'' + street + '\'';

                            if((city != null)&&(city != '')) {
                                queryStr_WHERE += ' and ShippingCity = \'' + city + '\'';
                                allParameters  = true;/*
                                if((zip != null)&&(zip != '')) {
                                    queryStr_WHERE += ' and ShippingPostalCode = \'' + zip + '\'';
                                    allParameters  = true;
                                }*/
                            }
                        }
                        
                        /* State filter is not accurate because the data and email values mismatch based on state's full name or 2 char
                        if(state != null && state.length() > 2) {
                            queryStr += ' and ShippingState = \'' + state + '\'';
                        }*/
                        
                        
                        //CLAY: Debugging parser - need to see how we look for account:
                        System.debug('=======================CLAY: Querying for account:');
                        System.debug('Query String from email: ' + queryStr);
                        System.debug('Query String where part: ' + queryStr_WHERE);
                        if(allParameters){
                            List<sobject> objects = Database.query(queryStr+ ' where '+queryStr_WHERE);
                            System.debug('>>> Query : ' + objects);
                            if((!objects.isEmpty())&&(objects.size()==1)) {
                                newCase.put(fieldName, objects[0].Id);
                                if(fieldName == 'UNITY_Customer__c') {
                                    List<UNITY_Service_Contract__c> serviceContracts = [SELECT Id 
                                                                                        FROM   UNITY_Service_Contract__c 
                                                                                        WHERE  UNITY_Account__c = :objects[0].Id and UNITY_IS_Active__c = TRUE];
                                
                                    if(! serviceContracts.isEmpty()) {
                                        
                                        newCase.put('UNITY_Customer_Service_Contract__c', serviceContracts[0].Id);
                                    }
                                }
                            }
                        }
                    }
                    
                } else if (typename == 'percent' || typename == 'double') {
                    newCase.put(fieldName, Double.valueOf(fieldValue));
                } else if (typename == 'currency') {
                    if(fieldValue.contains('$')) {
                        fieldValue = fieldValue.replace( '$' , '' );
                    } else if(fieldValue.contains('USD')) {
                        fieldValue = fieldValue.replace( 'USD' , '' );
                    }
                    fieldValue = fieldValue.replace( ',' , '' );
                    newCase.put(fieldName, Double.valueOf(fieldValue));
                } else if (typename == 'integer') {
                    //fieldValue = fieldValue.replace( '$' , '' );
                    fieldValue = fieldValue.replace( ',' , '' );
                    newCase.put(fieldName, Integer.valueOf(fieldValue));
                }else if (typename == 'boolean') {
                    newCase.put(fieldName, Boolean.valueOf(fieldValue));
                }else if (typename == 'date') {
                    newCase.put(fieldName, Date.valueOf(fieldValue));
                } else if (typename == 'datetime') {
                    newCase.put(fieldName, DateTime.valueOf(fieldValue));
                } else {
                    newCase.put(fieldName, fieldValue);
                }
            }
        }
        
        newCase.Description = description + '\n' + email.plainTextBody;
        insert newCase;

        // Save attachments, if any
        if(! attachments.isEmpty()) {
            for(Attachment att : attachments) {
                att.ParentId = newCase.Id;
            }
            insert attachments;
        }

        return newCase;

    }

}