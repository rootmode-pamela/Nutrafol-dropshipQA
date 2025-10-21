import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import USER_ID from '@salesforce/user/Id';
import getRelatedContacts from '@salesforce/apex/DropShipController.getRelatedContacts';

// Account fields to retrieve
const ACCOUNT_FIELDS = [
    'Account.ShippingStreet',
    'Account.ShippingCity',
    'Account.ShippingPostalCode',
    'Account.ShippingStateCode',
    'Account.ShippingCountry'
];

export default class DropShipQuickAction extends LightningElement {
    @api recordId; // Account Id passed from Quick Action
    
    accountRecord;
    userId = USER_ID;
    contactOptions = [];
    selectedContactId = '';

    recordTypeId = '0123u000000VQbPAAW'; // Drop Ship record type 

    
    // Pre-populated field values
    purpose = '';
    street = '';
    city = '';
    zip = '';
    state = '';
    country = '';

    @wire(getRecord, { recordId: '$recordId', fields: ACCOUNT_FIELDS })
    wiredAccount({ error, data }) {
        if (data) {
            this.accountRecord = data;
            // Pre-populate address fields from Account
            this.street = data.fields.ShippingStreet?.value || '';
            this.city = data.fields.ShippingCity?.value || '';
            this.zip = data.fields.ShippingPostalCode?.value || '';
            this.state = data.fields.ShippingStateCode?.value || '';
            this.country = data.fields.ShippingCountry?.value || '';
        } else if (error) {
            this.showToast('Error', 'Unable to load Account data', 'error');
        }
    }

    @wire(getRelatedContacts, { accountId: '$recordId' })
    wiredContacts({ error, data }) {
        if (data) {
            this.contactOptions = data.map(contact => ({
                label: contact.label,
                value: contact.value
            }));
        } else if (error) {
            this.showToast('Error', 'Unable to load related contacts', 'error');
            console.error('Error loading contacts:', error);
        }
    }

    handleContactChange(event) {
        this.selectedContactId = event.detail.value;
    }

    handleSuccess(event) {
        const recordId = event.detail.id;
        this.dispatchEvent(    
            new ShowToastEvent({
                title: 'Success',
                message: 'Product Request created successfully. {0}',
                messageData: [
                    {
                        url: `/lightning/r/Product_Request__c/${recordId}/view`,
                        label: 'View Product Request'
                    }
                ],
                variant: 'success'
            })
        );
        this.closeAction();
    }    

    handleError(event) {
        const errorMessage = event.detail.message || 'An error occurred while creating the record';
        this.showToast('Error', errorMessage, 'error');
    }

    handleCancel() {
        this.closeAction();
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}