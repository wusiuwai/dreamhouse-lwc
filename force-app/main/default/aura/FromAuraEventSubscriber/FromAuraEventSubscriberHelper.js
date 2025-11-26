({
    setupEmpApi: function (component) {
        // Dynamically create lightning:empApi for Aura and configure error handler
        $A.createComponent(
            "lightning:empApi",
            {},
            function (empApi, status, errorMessage) {
                if (status === "SUCCESS") {
                    component.set("v.empApi", empApi);
                    // Set error handler
                    var errorHandler = $A.getCallback(function (message) {
                        // eslint-disable-next-line no-console
                        console.error("EMP API error: ", JSON.stringify(message));
                    });
                    empApi.onError(errorHandler);
                } else {
                    // eslint-disable-next-line no-console
                    console.error("Failed to create lightning:empApi: ", errorMessage);
                }
            }
        );
    },

    subscribe: function (component) {
        var empApi = component.get("v.empApi");
        if (!empApi) {
            this.setupEmpApi(component);
            empApi = component.get("v.empApi");
            if (!empApi) {
                return;
            }
        }

        var channel = component.get("v.channel");
        var replayId = component.get("v.replayId"); // -1 = new events

        var self = this;
        var messageCallback = $A.getCallback(function (response) {
            // Parse event payload fields
            var payload = response && response.data && response.data.payload ? response.data.payload : {};
            var createdDate = response && response.data && response.data.event && response.data.event.createdDate ? response.data.event.createdDate : new Date().toISOString();

            var row = {
                time: createdDate,
                severity: payload.Severity__c,
                source: payload.Source__c,
                message: payload.Message__c
            };

            var list = component.get("v.events") || [];
            list.unshift(row);
            component.set("v.events", list);
        });

        var selfHandler = this;
        empApi.subscribe(channel, replayId, messageCallback).then(
            $A.getCallback(function (subscription) {
                component.set("v.subscription", subscription);
                component.set("v.isConnected", true);
            })
        ).catch(function (e) {
            // eslint-disable-next-line no-console
            console.error("Subscribe failed: ", e);
        });
    },

    unsubscribe: function (component) {
        var empApi = component.get("v.empApi");
        var subscription = component.get("v.subscription");
        if (!empApi || !subscription) {
            return;
        }
        empApi.unsubscribe(subscription, $A.getCallback(function (message) {
            component.set("v.isConnected", false);
            component.set("v.subscription", null);
        }));
    }
});
