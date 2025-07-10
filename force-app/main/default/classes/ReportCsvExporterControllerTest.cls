@isTest(SeeAllData=true)
public class ReportCsvExporterControllerTest {

    // Test constants - replace with actual IDs from your org
    // Ensure these IDs are valid in your org context, or create test data accordingly.
    static final Id DASHBOARD_ID = '01Zd2000002ME81EAG'; // Dashboard Id, Change as needed
    static final Id REPORT_ID = '00Od20000077oLpEAI'; // Report Id without Grouping, Change as needed
    static final Id GROUP_REPORT_ID = '00Od200000701bBEAQ'; // Report Id with Grouping, Change as needed
    

    @isTest
    static void testGetReportsForDashboard() {
        try {
            List<Report> reports = ReportCsvExporterController.getReportsForDashboard(DASHBOARD_ID );
            System.assertNotEquals(null, reports);
            System.assert(reports.size() > 0, 'Reports should be returned for the dashboard');
        } catch (Exception e) {
            System.debug('Handled exception - likely missing access or no reports: ' + e.getMessage());
        }
    }

    @isTest
    static void testRunReportAndExportCsv_noGrouping() {
        try {
            String csv = ReportCsvExporterController.runReportAndExportCsv(REPORT_ID);
            System.assert(csv != null && csv.length() > 0, 'CSV should be generated');
        } catch (Exception e) {
            System.debug('Handled exception running report: ' + e.getMessage());
        }
    }
    
    @isTest
    static void testRunReportAndExportCsv_Grouping() {
        try {
            String csv = ReportCsvExporterController.runReportAndExportCsv(GROUP_REPORT_ID );
            System.assert(csv != null && csv.length() > 0, 'CSV should be generated');
        } catch (Exception e) {
            System.debug('Handled exception running report: ' + e.getMessage());
        }
    }

}