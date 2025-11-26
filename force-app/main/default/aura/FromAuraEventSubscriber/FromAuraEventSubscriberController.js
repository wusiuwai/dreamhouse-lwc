({
    doInit: function (component, event, helper) {
        helper.setupEmpApi(component);
    },

    handleSubscribe: function (component, event, helper) {
        helper.subscribe(component);
    },

    handleUnsubscribe: function (component, event, helper) {
        helper.unsubscribe(component);
    },

    handleClear: function (component, event, helper) {
        component.set("v.events", []);
    }
});
