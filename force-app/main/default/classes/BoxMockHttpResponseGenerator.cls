/**
* Mock Response Class
*/
@IsTest
public class BoxMockHttpResponseGenerator implements HttpCalloutMock {
    private Integer statusCode;
    private String responseBody;
    private String status;
    
    public BoxMockHttpResponseGenerator(String responseBody, String status, Integer statusCode) {
        this.statusCode = statusCode;
        this.responseBody = responseBody;
        this.status = status;
    }
    
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(this.statusCode);
        res.setStatus(this.status);
        res.setBody(this.responseBody);
        return res;
    }
}