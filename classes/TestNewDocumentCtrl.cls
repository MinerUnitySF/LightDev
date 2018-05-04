@isTest
public class TestNewDocumentCtrl{
     public static testMethod void testDocumentCtrl(){
        genesis__Applications__c a = genesis.TestHelper.createApplication();
        
        genesis.TestHelper th1 = new genesis.TestHelper();
        ApexPages.StandardController sc = new ApexPages.StandardController(a);
        NewDocumentCtrl ctrl  = new NewDocumentCtrl(sc);
        ctrl.cancelFileUpload();
        ctrl.uploadFile();
        //ctrl.attach = TestHelper.addAttachmentToParent(a.Id);
        Blob b = Blob.valueOf('Test Data');     
        Attachment att = new Attachment();  
        att.Name = 'Test.pdf';  
        att.Body = b;  
        ctrl.attach = att;
        genesis.TestHelper.createDocumentMaster();
        System.assertEquals(ctrl.processUpload(),null);
        ctrl.genDocument();
        
        
        //save application..
        ctrl.saveApp();
        
    }
    
}