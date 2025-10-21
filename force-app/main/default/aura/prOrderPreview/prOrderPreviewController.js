({
	doInit : function(component, event, helper) {
        console.log('prOrderPreview component init');
         component.set('v.columns', [
            {label: 'Sku', fieldName: 'sku', type: 'text'},
            {label: 'Description', fieldName: 'description', type: 'text'},
            {label: 'Quantity', fieldName: 'quantity', type: 'integer'},

        ]);
       
       
       helper.processProductData(component, helper, component.get("v.productData"));

	}
})