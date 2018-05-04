public class UNITY_UploadAttachmentController {
    
    public String selectedType {get;set;}
    //public String description {get;set;}
    @TestVisible private WorkOrder workOrder {get;set;} 
    @TestVisible private  Database.SaveResult attachmentResult {get;set;}
    @TestVisible private  Database.SaveResult customAttachmentResult {get;set;}
    public String fileName {get;set;}
    public transient Blob fileBody {get;set;}
    public String profileName {get; private set;}
    
    public UNITY_UploadAttachmentController(ApexPages.StandardController controller) { 
        this.workOrder= (WorkOrder)controller.getRecord();
    }   
    
    public Boolean getIsPortalUser() {
        if (UserInfo.getUserType() == UNITY_Constants.PROFILE_TYPE_POWER_CUSTOMER_SUCCESS)
        	return true;
        else
            return false;
    }  
    
    // creates a new Contact_Attachment__c record
    private Database.SaveResult saveCustomAttachment() {
        UNITY_Attachment__c obj = new UNITY_Attachment__c();
        obj.Work_Order__c=workOrder.Id;
       // obj.description__c = description;
        obj.UNITY_Type__c= selectedType;
       // obj.awesome__c = selectedAwesomeness;
        // fill out cust obj fields
        return Database.insert(obj);
    }
    
    // create an actual Attachment record with the Contact_Attachment__c as parent
    private Database.SaveResult saveStandardAttachment(Id parentId) {
        Database.SaveResult result;
        
        Attachment attachment = new Attachment();
        attachment.body = this.fileBody;
        attachment.name = this.fileName;
        attachment.parentId = parentId;
        // inser the attahcment
        result = Database.insert(attachment);
        // reset the file for the view state
        fileBody = Blob.valueOf(' ');
        return result;
    }
    //CLAY - dynamic picklist:
    public List<SelectOption> getTypes() {
    
        //Lets get the real picklist values. Sheesh. No mas static.
        List<SelectOption> typeOpts = new List<SelectOption>();
        //get our field     
        Schema.DescribeFieldResult fieldResult =  UNITY_Attachment__c.UNITY_Type__c.getDescribe();
    
        //get our picklist values
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    
        //get the profile name of the user, for some community users we display fewer options
        profileName = [SELECT Id,Name FROM Profile WHERE ID = :UserInfo.getProfileId() LIMIT 1].Name;
    
        //loop 'em
         for( Schema.PicklistEntry f : ple) {
            if (profileName == 'Customer Community Plus User - Customer'){
                if (f.getValue() == 'Damage & Abuse - Before & After Pictures')
                    typeOpts.add(new SelectOption(f.getLabel(), f.getValue()));
            }
            else if (profileName == 'Customer Community Plus User - Vendor'){
                if ((f.getValue() == 'Completed Survey') || (f.getValue() == 'Customer-Specific Service Report Sign-Off') || (f.getValue() == 'Damage & Abuse - Before & After Pictures')  ||  (f.getValue() == 'IVR Check in and Check out (Labor)') || (f.getValue() == 'PM Checklist completed') || (f.getValue() == 'Shipping Documents') || (f.getValue() == 'Vendor\'s Estimate') || (f.getValue() == 'Vendor\'s Invoice') || (f.getValue() == 'Warranty Information') || (f.getValue() == 'Work Acknowledgment Form (Service Sign-Off)') )
                                                
                    typeOpts.add(new SelectOption(f.getLabel(), f.getValue()));
            }
            else{
                typeOpts.add(new SelectOption(f.getLabel(), f.getValue()));
            }
        }       

        //done
        return typeOpts;

        }
    
       public PageReference processUpload() {
        try {
            // Modified By Ajay Gupta to add custom error when file is missing 8 April 2016
            if(fileBody!=NULL)
                customAttachmentResult = saveCustomAttachment();
            else{
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Required input file is missing'));  
                return NULL;
            }
        
            if (customAttachmentResult == null || !customAttachmentResult.isSuccess()) {
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Could not save attachment.'));
                return null;
            }
        
            attachmentResult = saveStandardAttachment(customAttachmentResult.getId());
        
            if (attachmentResult == null || !attachmentResult.isSuccess()) {
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Could not save attachment.'));            
                return null;
            } else {
                // update the custom attachment record with some attachment info
                UNITY_Attachment__c customAttachment = [select id from UNITY_Attachment__c where id = :customAttachmentResult.getId()];
                //customAttachment.name = this.fileName;
                customAttachment.UNITY_Standard_Attachment_Id__c= attachmentResult.getId();
                update customAttachment;
            }
        
        } catch (Exception e) {
            ApexPages.AddMessages(e);
            System.Debug('**************************************'+e);
            return null;
        }
        
        if (profileName == 'Customer Community Plus User - Vendor'){
            Network net = [SELECT id,Name FROM NETWORK WHERE Name = :Label.VendorCommunity LIMIT 1];
			
            if (net != null){
                String networkURL = String.valueOf(Network.getLoginUrl(net.id)).replace('login','');
            	system.debug('@@@networkURL' + networkURL);
                
            	PageReference secondPage = new PageReference(networkURL + 'workorder/'+ workOrder.Id);
            	secondPage.setRedirect(true);
            	return secondPage;
            }
            else
                return new PageReference('/'+workOrder.Id);
        }
        else       
        	return new PageReference('/'+workOrder.Id);
    }
    
    public PageReference back() {
        return new PageReference('/'+workOrder.Id);
    }     

}