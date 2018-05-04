public with sharing class NewDocumentCtrl extends genesis.ApplicationWizardBaseClass{
    
    public boolean showAttachFileBtn {set; get;}
    public boolean showUploadPanelGrid {set; get;}
    public Attachment attach {get;set;}
    public String apiSessionId {get;set;} 
    public genesis__Applications__c application {get; set;}
    public NewDocumentCtrl(ApexPages.StandardController controller) {
        super(controller);
        
        this.application = (genesis__Applications__c)controller.getRecord();
        this.application = [Select Id,Name from genesis__Applications__c 
                                where id =: this.application.Id];
                                
        showAttachFileBtn = true;
        showUploadPanelGrid = false;
        
        attach = new Attachment();
        //apiSessionId = UserInfo.getSessionId();
        
        //List<attachment> empAttachments = [Select Id,Name from attachment where parentId in :empId];
    }
    public PageReference genDocument(){
        String contactId = [Select genesis__Contact__r.Id from genesis__Applications__c where id =: application.id].genesis__Contact__r.Id;
        Contact contactInfo = [Select Id,Email,Name from Contact where Id =: contactId];
        String email = contactInfo.Email;
        String name = contactInfo.Name;
        apiSessionId = UserInfo.getSessionID();
        System.debug('apiSessionId: ' + apiSessionId);
        String documentUrl =  '/apex/loop__looplus?sessionId=' + apiSessionId+ '&eid='+ this.application.Id + '&param_email=' + email + '&param_name=' + Name;
        system.debug(documentUrl);
        Pagereference pageRef = new Pagereference(documentUrl);
        
        return pageRef.setRedirect(true);
        
    }
    public PageReference cancelFileUpload(){
        showAttachFileBtn = true;
        showUploadPanelGrid = false;
        return null;
    }
    
    public PageReference uploadFile(){
        showAttachFileBtn = false;
        showUploadPanelGrid = true;
        return null;
    }
    
    public void saveApp(){
        try{
            update this.application;
        }catch(Exception e){
            createMessage(ApexPages.severity.Error,'Error : ' + e.getMessage());
        }
        createMessage(ApexPages.Severity.Confirm,'Document Checklist updated.');
    }
    
    private void insertDocumentStatus(String title){
        genesis__Document_Status__c obj = new genesis__Document_Status__c();
        if(title.contains('.')){
            title = title.split('\\.')[0];
        }
        System.debug('title ' + title);
        obj.genesis__Application__c = this.application.Id;
        List<genesis__Document_Master__c> dmList = new List<genesis__Document_Master__c>();
        dmList = [SELECT Name,Id,genesis__Doc_Name__c from genesis__Document_Master__c where genesis__Doc_Name__c =:title ];
        System.debug('dmList ::'+dmList);
        if(dmList!=null && dmList.size() == 1){
            obj.genesis__Doc_Name__c = dmList[0].Id;
            obj.genesis__Attachment_Name__c = title;
            obj.genesis__Status__c = 'CREATED';
        }else{
            obj.genesis__Attachment_Name__c = title;
            obj.genesis__Doc_Name__c = null;
            obj.genesis__Status__c = null;
        }
        obj.genesis__Document_Url__c = URL.getSalesforceBaseUrl().toExternalForm() + '/' + attach.id;
        System.debug('obj ::'+obj);
        insert obj;
    }

    private Attachment insertAttachment(Id parentId){       
        
        attach.ParentId = parentId;
        insert attach;
        System.debug('Success');
        attach.Body = null; 
        return attach;
    }

    public PageReference processUpload(){
        try{
            insertAttachment(this.application.Id);
            String title = attach.Name;
            insertDocumentStatus(title);
            System.debug('Record Inserted');
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'File uploaded successsfully'));
        }catch (Exception e){
            System.debug(e);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Some exception has occured'));
        }
    
        
        return null;
    }

    private void createMessage(ApexPages.severity severity, String message) {
        ApexPages.getMessages().clear();
        ApexPages.addmessage(new ApexPages.message(severity, message));
    }
}