({
	   submitForm: function(component, event, helper) {
           var approvalBoolean = "false";
           var approval = event.getSource().getLocalId();
           if(approval == 'approvalYes'){
               approvalBoolean = "true";
           }
        console.log('helper submitForm');
           console.log('button:' + approval);
           console.log(approvalBoolean);

		var action = component.get('c.submitProductRequestOrderForm');
           console.log(component.get('v.pricebookName'));
        var params = {"pricebookName" : component.get("v.pricebookName"),
                      "productRequestId" : component.get("v.recordId"),
                      "orderFormProductCategoryData" : JSON.stringify(component.get("v.productData")),
                      "submitForApproval" : approvalBoolean
                     };
           console.log(params);
        if(params){
            action.setParams(params);}
        action.setCallback(this, function(response){
            console.log('logging response');
            console.log(response);
         
            if (response.getState() === 'SUCCESS') {
                var rows = response.getReturnValue();
				//navigate to Opportunity
			var navService = component.find("navService");
        	// Uses the pageReference definition in the init handler
        		var pageReference = component.get("v.pageReference");
        		navService.navigate(pageReference);
                $A.get('e.force:refreshView').fire();
            } else {
                console.log('Error submitting Order');
                console.log(response.getState());
                let errors = response.getError();
					let message = 'Unknown error'; // Default error message
				// Retrieve the error message sent by the server
				if (errors && Array.isArray(errors) && errors.length > 0) {
    			message = errors[0].message;
				}
				// Display the message
				alert(message);
            }
            
        });
        $A.enqueueAction(action); 
    },
})