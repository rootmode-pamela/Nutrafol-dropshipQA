({   
    setColumns: function (component, helper){
    //
         var actions = [
            { label: 'Show details', name: 'show_details' },
            { label: 'New Proposal', name: 'new_proposal' }
        ];
        component.set('v.columns', [
            {label: 'Sku', fieldName: 'Sku', type: 'text'},
            {label: 'Description', fieldName: 'Description', type: 'text'},
            {label: 'Price', fieldName: 'Price', type: 'text'},
            {label: 'Quantity', fieldName: 'Quantity', type: 'integer', editable: true}, 
            {label: 'Max Quantity', fieldName: 'MaxQuantity', type: 'integer', editable: false}, 
            {label: 'Amount', fieldName: 'Amount', type: 'currency', typeAttributes: { currencyCode: 'USD'} 
            }

        ]);
	}, 
    
    getOrderFormProducts: function(component, helper, productRequestId) {
        console.log('helper getOrderFormProducts');
		var action = component.get('c.getOrderFormProductsForProductRequest');
        var params = {"productRequestId" : productRequestId};
        if(params){
            action.setParams(params);}
        action.setCallback(this, function(response){
            console.log('logging response');
            console.log(response);
         
            if (response.getState() === 'SUCCESS') {
                var rows = response.getReturnValue();
                console.log(rows);
                component.set('v.productData', response.getReturnValue());
                component.set('v.hasLabelChanged', 'true');
                this.validateForm(component,helper, component.get('v.productData'));
                this.setActiveSection(component, helper, response.getReturnValue());
            } else {
                console.log('Error retrieving Products');
                console.log(response.getState());
                let errors = response.getError();
					let message = 'Unknown error'; // Default error message
				// Retrieve the error message sent by the server
				if (errors && Array.isArray(errors) && errors.length > 0) {
    			message = errors[0].message;
				}
				// Display the message
				console.error(message);
            }
            
        });
        $A.enqueueAction(action); 

	}, 
    
    getPricebook : function (component, helper, recordId){
         console.log('helper getPricebookId');
		var action = component.get('c.getPricebook');
        var params = {"productRequestId" : recordId};
        if(params){
            action.setParams(params);}
        action.setCallback(this, function(response){
            console.log(response);
            if (response.getState() === 'SUCCESS') {
                var pricebook = response.getReturnValue();
                console.log(pricebook);
                component.set('v.pricebookName', pricebook.Name);
                component.set('v.pricebookId', pricebook.Id);
                this.getOrderFormProducts(component, helper, recordId);
                
            } else {
                console.log('Error retrieving Pricebook');
                console.log(response.getState());
                let errors = response.getError();
					let message = 'Unknown error'; // Default error message
				// Retrieve the error message sent by the server
				if (errors && Array.isArray(errors) && errors.length > 0) {
    			message = errors[0].message;
				}
				// Display the message
				console.error(message);
            }
            
        });
        $A.enqueueAction(action);   
    },
    
    setUserAccess: function(component, helper){
        var userId = $A.get("$SObjectType.CurrentUser.Id");
		//get userInfo - contact record, permission for submitAsOther, submissionsThisMonth
        var action = component.get("c.getTrunkStockUser");
        
        //if user can submitAsOthers, get RequestedBy dropdown options
        
        action.setParams({"userId": userId, "recordId": component.get("v.recordId")});

        // Configure response handler
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var data = response.getReturnValue();
                if(data.hideForm){
                    console.log('hiding form');
                    component.set('v.hideSubmissionForm', data.hideForm );	
                	component.set('v.trunkStockPeriodClosed', data.trunkStockPeriodClosed );
                    component.set('v.overAllotment', data.userAllotmentMet);
                }
 
            } else {
                console.log('Problem getting account, response state: ' + state);
            }
        });
        $A.enqueueAction(action);

    },
    
    setActiveSection: function(component, helper, productData){
        component.set('v.activeSection', productData[0].tabName);
    },
    
 
    
    
    validateForm: function(component, helper, productData){
        if(component.get("v.hideSubmissionForm") == false){
        var formValid = true;
        var sumQty = 0;
        var sumPrice = 0;
        for (var j=0; j<productData.length; j++){
          var tabProducts = productData[j].products;
          for(var i=0; i<tabProducts.length; i++){
            if(tabProducts[i].quantity != null){
                console.log(parseInt(tabProducts[i].quantity + " : " + parseFloat(tabProducts[i].totalPrice) ) );
			sumQty = sumQty + parseInt(tabProducts[i].quantity);
            sumPrice = sumPrice + parseFloat(tabProducts[i].totalAmount);    
            }
              if(productData[j].tabOrderValid == false){
                  formValid = false;
              }
        	}
        }
        
        //if orderQuantity is 0 or any section is invalid, form is invalid
  	    let button = component.find('submitButton');
        
        if(sumQty > 0 && formValid){
            component.set('v.formValid', 'true');
              button.set('v.disabled',false);
            
        } else {
            component.set('v.formValid', 'false');
            button.set('v.disabled',true);
        }
        component.set('v.totalQuantity', sumQty);
        component.set('v.totalPrice', sumPrice);
    }
    }
})