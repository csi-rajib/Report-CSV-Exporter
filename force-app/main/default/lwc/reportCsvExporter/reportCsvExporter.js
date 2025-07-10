import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';

import getReportsForDashboard from '@salesforce/apex/ReportCsvExporterController.getReportsForDashboard';
import runReportAndExportCsv from '@salesforce/apex/ReportCsvExporterController.runReportAndExportCsv';

export default class ReportCsvExporter extends LightningElement {
    @api dashboardId;
    @api reportIds;

    reportOptions = [];
    selectedReportId;
    isLoading = false;

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        if (currentPageReference?.state?.c__dashboardId) {
            this.dashboardId = currentPageReference.state.c__dashboardId;
            this.fetchReports(this.dashboardId);
        } else {
            this.showToast('Error', 'No Dashboard Selected.', 'error');
        }
    }

    fetchReports(dashboardId) {
        this.isLoading = true;
        getReportsForDashboard({ dashboardId })
            .then(data => {
                this.reportOptions = data.map(report => ({
                    label: report.Name,
                    value: report.Id
                }));
                this.selectedReportId = null;
                if (this.reportOptions.length === 0) {
                    this.showToast('Info', 'No reports found for the selected dashboard.', 'error');
                }
            })
            .catch(() => {
                this.showToast('Error', 'Failed to fetch reports for the dashboard.', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleReportChange(event) {
        this.selectedReportId = event.detail.value;
    }

    async handleExportCsv() {
        if (!this.selectedReportId) {
            this.showToast('Error', 'No report selected', 'error');
            return;
        }

        this.isLoading = true;
        try {
            const csvContent = await runReportAndExportCsv({ reportId: this.selectedReportId });
            this.downloadCsv(csvContent);
            this.showToast('Success', 'CSV file downloaded successfully.', 'success');
        } catch (error) {
            this.showToast('Error', 'Failed to export report', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    downloadCsv(csvContent) {
        const BOM = '\uFEFF';
        const csvWithBOM = BOM + csvContent;
        const reportName = this.reportOptions.find(opt => opt.value === this.selectedReportId)?.label || 'report';
        const encodedUri = encodeURI(`data:text/csv;charset=utf-8,${csvWithBOM}`);
        const link = document.createElement('a');
        link.setAttribute('href', encodedUri);
        link.setAttribute('download', `${reportName}.csv`);
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}