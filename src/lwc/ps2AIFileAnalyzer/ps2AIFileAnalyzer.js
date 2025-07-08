import { LightningElement, api, track } from 'lwc';
import { RefreshEvent } from "lightning/refresh";
import analyzeFile from '@salesforce/apex/PS2AIFileAnalyzerController.analyzeFile';
import getPromptTemplateList from '@salesforce/apex/PS2AIFileAnalyzerController.getPromptTemplateList';
import getRecordDocuments from '@salesforce/apex/PS2AIFileAnalyzerController.getRecordDocuments';
import getObjectName from '@salesforce/apex/PS2AIFileAnalyzerController.getObjectName';
import storeAIAnalysis from '@salesforce/apex/PS2AIFileAnalyzerController.storeAIAnalysis';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Ps2AIFileAnalyzer extends LightningElement {
    @api recordId;

    @api title = 'File Analyzer';
    @api subTitle = 'Let AI review your files';
    @api btnAnalyzeText = 'Analyze File';

    @api defPrompt = null;

    @api recFieldname = null;


    @track uploadedFileId;
    @track uploadedFileName;
    @track aiResult = '';
    @track errorMessage = '';
    @track isAnalyzing = false;
    @track isFileUpload = false;
    //@track disableAnalyzeButton = true;

    @track showActionToast = false;
    @track actionToastMessage = '';

    @track templateOptions = null;
    templateSelection;
    fileOptions = null;
    fileSelection;
    objectName;

    connectedCallback() {
        this.loadObjectName();
        this.loadTemplates();
        this.loadFiles();
    }

    get isLoading() {
        return ((this.templateOptions != null || this.templateSelection != null) && this.fileOptions != null ? false : true);
    }

    loadTemplates() {
        this.templateOptions = null;
        this.templateSelection = this.defPrompt == null || this.defPrompt == '' ? null : this.defPrompt;

        if (this.defPrompt == null || this.defPrompt == '' ) {
            getPromptTemplateList()
                .then(result => {
                    console.log(result);
                    this.templateOptions = JSON.parse(result);
                })
                .catch(error => {
                    console.log(error);
                    const message = this.getErrorMessage(error);
                    this.showToast('Error', message, 'error', 'sticky');
                });
        }
    }

    loadFiles() {
        this.fileOptions = null;
        this.fileSelection = null;

        getRecordDocuments({ recordId: this.recordId })
            .then(result => {
                console.log(result);
                this.fileOptions = JSON.parse(result);
            })
            .catch(error => {
                console.log(error);
                const message = this.getErrorMessage(error);
                this.showToast('Error', message, 'error', 'sticky');
            });
    }

    loadObjectName() {
        getObjectName({ recordId: this.recordId })
            .then(result => {
                console.log(result);
                this.objectName = result;
            })
            .catch(error => {
                console.log(error);
                const message = this.getErrorMessage(error);
                this.showToast('Error', message, 'error', 'sticky');
            });
    }

    handleTemplateChange(event) {
        this.templateSelection = event.detail.value;
        this.aiResult = '';
    }

    handleFileChange(event) {
        this.fileSelection = event.detail.value;
        this.aiResult = '';
    }

    handleUpload(event) {
        this.isFileUpload = !this.isFileUpload;

    }

    handleRefresh(event) {
        this.aiResult = '';
        this.loadTemplates();
        this.loadFiles();
    }

    handleClear(event) {
        this.aiResult = '';
    }

    get addButtonLabel() {
        return 'Add to ' + this.objectName;
    }
    get disableAnalyzeButton() {
        return this.templateSelection && this.fileSelection ? false : true;
    }

    get uploadRecordId() {
        return this.recordId;
    }

    get isPromptDefault() {
        return this.defPrompt == null || this.defPrompt == '' ? true : false;
    }

    get isFieldName() {
        return this.recFieldname == null || this.recFieldname == '' ? false : true;
    }

    fileUploadHandler(event) {
        const uploadedFiles = event.detail.files;
        if (uploadedFiles && uploadedFiles.length > 0) {
            this.fileSelection = uploadedFiles[0].documentId;
            //this.uploadedFileName = uploadedFiles[0].name;

            this.loadFiles();
            this.isFileUpload = false;

            this.showToastMessage(
                'File Uploaded',
                `${this.uploadedFileName} has been uploaded successfully`,
                'success'
            );
        }
    }

    async handleAnalyzeFiles() {
        /*
        if (!this.uploadedFileId) {
            this.errorMessage = 'No file uploaded for analysis.';
            return;
        }
        */
        this.isAnalyzing = true;
        this.errorMessage = '';
        this.aiResult = '';
        try {
            const result = await analyzeFile({ promptId: this.templateSelection, fileId: this.fileSelection });

            let formattedText = result.replace(/\t/g, '  ');  // Replace each tab with 2 spaces
            formattedText = formattedText.replace(/ /g, '&nbsp;');
            formattedText = result.replace(/\r\n/g, '<br/>'); // Use regex with 'g' for global replacement
            formattedText = formattedText.replace(/\n/g, '<br/>');   // Use regex with 'g' for global replacement


            this.aiResult = formattedText;
            this.showToastMessage(
                'AI Analysis Complete',
                'The AI-powered analysis is now ready!',
                'success'
            );
        } catch (err) {
            this.errorMessage =
                (err && err.body && err.body.message) ||
                'Error analyzing file. Please try again.';
            this.showToastMessage(
                'Analysis Error',
                this.errorMessage,
                'error'
            );
        } finally {
            this.isAnalyzing = false;
            this.disableAnalyzeButton = true;
        }
    }

    // --- Button Group Handlers ---
    handleAddToRecord() {
        storeAIAnalysis({ recordId: this.recordId, analysisResult: this.aiResult, fieldName: this.recFieldname })
            .then(result => {
                this.aiResult = '';
                this.dispatchEvent(new RefreshEvent());    // refresh record screen to show updated values
                this.showSimpleActionToast('Added to ' + this.objectName);
            })
            .catch(error => {
                console.log(error);
                const message = this.getErrorMessage(error);
                this.showToast('Error', message, 'error', 'sticky');
            });

    }

    handleCopyToClipboard() {
        // Strip HTML for copy
        const tempElement = document.createElement('div');
        tempElement.innerHTML = this.aiResult;
        const plainText = tempElement.innerText || tempElement.textContent;
        navigator.clipboard.writeText(plainText);
        this.showSimpleActionToast('Copied to clipboard!');
    }

    /*
    handleDownloadPdf() {
        // Not implemented: Demo only
        this.showSimpleActionToast('Download as PDF (not implemented)');
    }
    */

    getErrorMessage(error) {
        if (Array.isArray(error.body)) {
            return error.body.map(e => e.message).join(', ');
        } else if (error?.body?.message) {
            return error.body.message;
        }
        return 'An unexpected error occurred';
    }

    showToast(title, message, variant, mode) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant,
                mode
            })
        );
    }

    showSimpleActionToast(msg) {
        this.actionToastMessage = msg;
        this.showActionToast = true;
        setTimeout(() => { this.showActionToast = false; }, 1500);
    }

    showToastMessage(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant || 'info'
            })
        );
    }
}