({
    doInit : function(component, event, helper) {
        var navService = component.find("navService");

        let pageReference = component.get("v.pageReference");
        // Set the URL on the link or use the default if there's an error
        var defaultUrl = "#";
        navService.generateUrl(pageReference)
            .then($A.getCallback(function(url) {
                component.set("v.url", url ? url : defaultUrl);
            }), $A.getCallback(function(error) {
                component.set("v.url", defaultUrl);
            }));
    },
    
	handleCancel : function(component, event, helper) {
		component.find("previewModal").notifyClose();
	},
    
    handleSubmitOrderForm : function(component, event, helper) {
        helper.submitForm(component, event, helper);
        
    }
})