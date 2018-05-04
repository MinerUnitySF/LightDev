@isTest
global class UNITY_MuleHttpCalloutMockImp implements HttpCalloutMock {
    
    // set by constructor, used to vary the mockresponse
    Boolean  isMockResponseSuccessful;

    public UNITY_MuleHttpCalloutMockImp(Boolean isMockResponseSuccessful) {
    this.isMockResponseSuccessful  = isMockResponseSuccessful;
    }
    global String supposedEndPoint {set; get;}
    
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        //System.assertEquals(supposedEndPoint, req.getEndpoint());
        System.assertEquals('POST', req.getMethod());
        
        // Create a fake response
        if(this.isMockResponseSuccessful) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"response":{"error":"","VendId":"1234"}}');
            return res;   
        } else {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            // malformed json body
            res.setBody('{');
            return res;   
        }
    }
    
}