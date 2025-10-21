({
	processProductData : function(component, helper, productData) {
		console.log('processProductData method entry');
        console.log(productData.length);
        if (productData.length == 0){
            console.log('Retrieve Product Data');
            this.getProductData(component, event, helper);
            productData = component.get('v.productData');
            console.log('productData');
            console.log(component.get('v.productData'));
        } else {
        
        var tableData  = [];
        
        productData.forEach((row) =>{
          let tabProducts = row.products;
          console.log('tabProducts: ' + tabProducts);
          tabProducts.forEach((prod) =>{

            if(prod.quantity> 0){
               console.log(prod.sku);
                let line = {};
                line.sku = prod.sku;
                line.description = prod.description;
                line.quantity = prod.quantity;
                console.log(line);
        		tableData.push(line);
                } 
          	});
        });
    
        component.set('v.data', tableData);
		}
	},
        
    getProductData : function(component,event,helper){
        console.log('getProductData method entry');
        var action = component.get('c.getOrderFormProductsForProductRequest');
        var params = {"productRequestId" : component.get('v.recordId')};
        if(params){
            action.setParams(params);}
        action.setCallback(this, function(response){         
            if (response.getState() === 'SUCCESS') {
                var rows = response.getReturnValue();
                component.set('v.productData', response.getReturnValue());
                let productData = component.get('v.productData');
                        var tableData  = [];
        
        	productData.forEach((row) =>{
          		let tabProducts = row.products;
          		console.log('tabProducts: ' + tabProducts);
          		tabProducts.forEach((prod) =>{

            if(prod.quantity> 0){
               console.log(prod.sku);
                let line = {};
                line.sku = prod.sku;
                line.description = prod.description;
                line.price = prod.price;
                line.quantity = prod.quantity;
                line.amount = prod.totalAmount;
                console.log(line);
        		tableData.push(line);
                } 
          	});
        });
    
        component.set('v.data', tableData);
                
                
                
                
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
            
        }    
})