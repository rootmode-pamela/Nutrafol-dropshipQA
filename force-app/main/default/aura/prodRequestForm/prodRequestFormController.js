({
	doInit : function(component, event, helper) {
        var a = component.get('c.showSpinner');
        var navService = component.find("navService");
        helper.getPricebook(component, helper, component.get('v.recordId') );
        helper.setUserAccess(component, helper);
		 // Sets the route to /lightning/o/Product_Request__c/recordId
		 let record = component.get('v.recordId');
        console.log('PRId: ' + record);
         var pageReference = {
			type: "standard__recordPage",
            attributes: {
	        	objectApiName: 'Product_Request__c',
    		    recordId: component.get('v.recordId'),
        		actionName: 'view'
             }
        };
        component.set("v.pageReference", pageReference);
        var a = component.get('c.hideSpinner');
	},
      
    
   showSpinner: function(component, event, helper) {
        component.set("v.spinner", true); 
   },
    
   hideSpinner : function(component,event,helper){
        component.set("v.spinner", false);
    },
    
    handleChange : function(component,event,helper){
        var itemId = event.getSource().get('v.name');
		
        if(event.getSource().checkValidity()){
        
        var tabId = parseInt(itemId.substring(0, itemId.indexOf('-')));
        var prodId = parseInt(itemId.substring(itemId.indexOf('-')+1, itemId.length));
        
        var itemQuantity = event.getSource().get('v.value');
        var productData = JSON.parse(JSON.stringify(component.get('v.productData')));
        var tabProducts = productData[tabId].products;
        var tabQuantity = 0;
        for(var i=0; i<tabProducts.length; i++){
            if(tabProducts[i].quantity != null){
            tabQuantity = tabQuantity + parseInt(tabProducts[i].quantity);
            }
        }
		var productPrice = tabProducts[prodId].price;
        if(productData[tabId].tabCaseQuantity>0){
            var tabCaseQty = parseInt(productData[tabId].tabCaseQuantity);
        	var itemAmount = productPrice * itemQuantity;
            productData[tabId].tabOrderValid = true;
        }
       
        productData[tabId].tabOrderQuantity = tabQuantity;
    	tabProducts[prodId].totalAmount = itemAmount;
        component.set('v.productData', productData);
        component.set('v.section', component.get('v.openSections'))
        helper.validateForm(component, helper, productData);
        } else {
            component.set('v.formValid', 'false');
             let button = component.find('submitButton');
            button.set('v.disabled',true);
        }
	},
    
    handleSectionToggle: function (component, event) {
        var openSections = event.getParam('openSections');
        console.log(openSections);
 		if (openSections.length === 0) {
            console.log("All sections are closed");
            component.set('v.openSections', "[]");
        } else {
            console.log(openSections);
            component.set('v.openSections', openSections.join(', '));
        }
    },
    
    
    handleShowPreview: function (component, event, helper){
        console.log('showPreview');
        var modalBody;
        var modalFooter;
        $A.createComponents([
            ["c:prOrderPreview", {
            productData: component.get("v.productData")
        }],
            ["c:prOrderPreviewFooter", {
                productData: component.get('v.productData'),
                pricebookId: component.get('v.pricebookId'),
                recordId: component.get('v.recordId'),
                pageReference: component.get('v.pageReference')
            }]],
           function(components, status) {
               if (status === "SUCCESS") {
                   modalBody = components[0];
                   modalFooter = components[1];
                   component.find('previewModal').showCustomModal({
                       header: "Product Request Order Confirmation",
                       body: modalBody,
                       footer: modalFooter,
                       showCloseButton: true,
                       cssClass: "slds-modal_large",
                       closeCallback: function() {
                         
                       }
                   })
               }
           });
    },

    
})