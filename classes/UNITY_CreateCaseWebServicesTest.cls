@isTest
public class UNITY_CreateCaseWebServicesTest
{
    @isTest
    public static void testPost()
    {
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = 'https://sfdev02-minercorp.cs23.force.com/customers/services/apexrest/CreateCase';  
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        req.requestBody = Blob.valueOf('{"Pin": 40487,"Id": "247406008","Call": {"Type": "WOUPDATE","Problem": {"Value": "test problem"},"Attr": {"Value": "THE SERVICE REQUEST TRACKING #:65722859 WAS DECLINED BY ABC COMPANY","Name": "NOTE","LineString": "3","Datetime": "2015/12/07 08:31:00","CreatedBy": "40487","NewSchedDatetime": "2015/12/09 00:00:00","SentTo": "rgaddam@altimetrik.com","Line": 3},"Datetime": "2015/12/07 00:00:00","Operator": "BulkPMDispatcher","Caller": "BulkPMDispatcher","Category": "MAINTENANCE","Sub": 2000001305,"Loc": "2310","Trade": "FLOOR MAINTENANCE-WOOD","Pro": 2000000109,"TrNum": 65722859,"WoNum": "test2-526652123","PoNum": "65722859","Status": "DECLINED","Priority": "Normal","Nte": 325.0,"NteProxy": "325","SchedDatetime": "2015/12/09 00:00:00","LastNoteId": 0,"CreatedDate": "2015-12-07T08:31:25.38","NoteCreatedDate": "2015-12-07T08:31:00"}}');
           // UNITY_CreateCaseWebServices.createCase();
    }
}