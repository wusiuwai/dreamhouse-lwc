/**
 * @description Publishes sample Platform Events for fromAuraEvent__e and fromJavaEvent__e.
 * Invocable from Flow and usable from Execute Anonymous for quick testing.
 * Follows general Salesforce development requirements: user mode DML via Database methods,
 * early returns, and documented code.
 */
public with sharing class PlatformEventPublisher {
    /**
     * Types of severity for events.
     */
    public enum SEVERITY { INFO, WARNING, ERROR }

    /**
     * Request payload for invocable method.
     */
    public class PublishRequest {
        @InvocableVariable(required=true)
        public String message;

        @InvocableVariable(required=false)
        public String source;

        @InvocableVariable(required=false)
        public String severity; // INFO | WARNING | ERROR

        @InvocableVariable(required=false)
        public Boolean publishAuraEvent;

        @InvocableVariable(required=false)
        public Boolean publishJavaEvent;
    }

    /**
     * Result payload for invocable method.
     */
    public class PublishResult {
        @InvocableVariable
        public Boolean auraPublished;
        @InvocableVariable
        public Boolean javaPublished;
        @InvocableVariable
        public String error;
    }

    /**
     * Invocable entry point to publish one or both events from a Flow.
     */
    @InvocableMethod(label='Publish Platform Events' description='Publish fromAuraEvent__e and/or fromJavaEvent__e with provided values')
    public static List<PublishResult> publishEvents(List<PublishRequest> requests) {
        List<PublishResult> results = new List<PublishResult>();
        if (requests == null || requests.isEmpty()) {
            PublishResult r = new PublishResult();
            r.error = 'No requests provided';
            results.add(r);
            return results;
        }

        for (PublishRequest req : requests) {
            PublishResult r = new PublishResult();

            try {
                SEVERITY sev = SEVERITY.INFO;
                if (req.severity != null) {
                    // Normalize input and map to enum; default to INFO on invalid value
                    String norm = req.severity.trim().toUpperCase();
                    if (norm == 'WARNING') {
                        sev = SEVERITY.WARNING;
                    } else if (norm == 'ERROR') {
                        sev = SEVERITY.ERROR;
                    } else {
                        sev = SEVERITY.INFO;
                    }
                }

                // Defaults
                String src = (req.source == null) ? 'Apex' : req.source;
                String msg = (req.message == null) ? 'Hello from Apex' : req.message;

                // Determine targets (default to both if none specified)
                Boolean sendAura = (req.publishAuraEvent == null && req.publishJavaEvent == null) ? true : (req.publishAuraEvent == true);
                Boolean sendJava = (req.publishAuraEvent == null && req.publishJavaEvent == null) ? true : (req.publishJavaEvent == true);

                if (sendAura) {
                    r.auraPublished = publishFromAuraEvent(msg, src, sev);
                }
                if (sendJava) {
                    r.javaPublished = publishFromJavaEvent(msg, src, sev);
                }
            } catch (Exception ex) {
                r.error = ex.getMessage();
            }
            results.add(r);
        }
        return results;
    }

    /**
     * Publish fromAuraEvent__e
     */
    public static Boolean publishFromAuraEvent(String message, String source, SEVERITY severity) {
        fromAuraEvent__e evt = new fromAuraEvent__e();
        evt.Message__c = message;
        evt.Source__c = source;
        evt.Severity__c = String.valueOf(severity).substring(0,1).toUpperCase() + String.valueOf(severity).substring(1).toLowerCase();
        // Use Database method for user mode where supported
        Database.SaveResult sr = EventBus.publish(evt);
        return sr != null && sr.isSuccess();
    }

    /**
     * Publish fromJavaEvent__e
     */
    public static Boolean publishFromJavaEvent(String message, String source, SEVERITY severity) {
        fromJavaEvent__e evt = new fromJavaEvent__e();
        evt.Message__c = message;
        evt.Source__c = source;
        evt.Severity__c = String.valueOf(severity).substring(0,1).toUpperCase() + String.valueOf(severity).substring(1).toLowerCase();
        Database.SaveResult sr = EventBus.publish(evt);
        return sr != null && sr.isSuccess();
    }
}
