/**
 * Service class for creating 1GP (First Generation Package) upload package requests
 * using the Salesforce Tooling API
 */
public with sharing class PackageUploadService {
    
    /**
     * Creates a 1GP upload package request using the Tooling API
     * @param packageName The name of the package
     * @param versionName The version name (e.g., "1.0.0")
     * @param description Optional description for the package
     * @return PackageUploadResult containing the request ID and status
     */
    @AuraEnabled
    public static PackageUploadResult createPackageUploadRequest(
        String packageName,
        String versionName,
        String description
    ) {
        PackageUploadResult result = new PackageUploadResult();
        
        try {
            // Get the session ID for authentication
            String sessionId = UserInfo.getSessionId();
            String instanceUrl = URL.getOrgDomainUrl().toExternalForm();
            String apiVersion = '64.0';
            
            // Construct the Tooling API endpoint
            String endpoint = instanceUrl + '/services/data/v' + apiVersion + '/tooling/sobjects/PackageUploadRequest/';
            
            // Build the request payload
            Map<String, Object> payload = new Map<String, Object>();
            payload.put('PackageName', packageName);
            payload.put('VersionName', versionName);
            if (String.isNotBlank(description)) {
                payload.put('Description', description);
            }
            
            // Make the HTTP callout
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('POST');
            request.setHeader('Authorization', 'Bearer ' + sessionId);
            request.setHeader('Content-Type', 'application/json');
            request.setBody(JSON.serialize(payload));
            
            HttpResponse response = http.send(request);
            
            // Parse the response
            if (response.getStatusCode() == 201) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                result.success = true;
                result.requestId = (String) responseMap.get('id');
                result.message = 'Package upload request created successfully';
            } else {
                result.success = false;
                result.message = 'Error creating package upload request: ' + response.getStatus() + ' - ' + response.getBody();
            }
            
        } catch (Exception e) {
            result.success = false;
            result.message = 'Exception occurred: ' + e.getMessage();
        }
        
        return result;
    }
    
    /**
     * Gets the status of a package upload request
     * @param requestId The ID of the PackageUploadRequest
     * @return PackageUploadResult containing the status information
     */
    @AuraEnabled
    public static PackageUploadResult getPackageUploadStatus(String requestId) {
        PackageUploadResult result = new PackageUploadResult();
        
        try {
            String sessionId = UserInfo.getSessionId();
            String instanceUrl = URL.getOrgDomainUrl().toExternalForm();
            String apiVersion = '64.0';
            
            String endpoint = instanceUrl + '/services/data/v' + apiVersion + '/tooling/sobjects/PackageUploadRequest/' + requestId;
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('GET');
            request.setHeader('Authorization', 'Bearer ' + sessionId);
            request.setHeader('Content-Type', 'application/json');
            
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                result.success = true;
                result.requestId = requestId;
                result.status = (String) responseMap.get('Status');
                result.message = 'Status retrieved successfully';
            } else {
                result.success = false;
                result.message = 'Error retrieving status: ' + response.getStatus() + ' - ' + response.getBody();
            }
            
        } catch (Exception e) {
            result.success = false;
            result.message = 'Exception occurred: ' + e.getMessage();
        }
        
        return result;
    }
    
    /**
     * Wrapper class for package upload results
     */
    public class PackageUploadResult {
        @AuraEnabled
        public Boolean success { get; set; }
        
        @AuraEnabled
        public String requestId { get; set; }
        
        @AuraEnabled
        public String status { get; set; }
        
        @AuraEnabled
        public String message { get; set; }
        
        public PackageUploadResult() {
            this.success = false;
        }
    }
}

