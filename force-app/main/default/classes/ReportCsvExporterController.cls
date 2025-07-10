public with sharing class ReportCsvExporterController {

    @AuraEnabled(cacheable=true)
    public static List<Report> getReportsForDashboard(Id dashboardId) {
        List<Report> usedReports = new List<Report>();
        List<DashboardComponent> components = [
            SELECT CustomReportId 
            FROM DashboardComponent 
            WHERE DashboardId = :dashboardId AND CustomReportId != null
        ];
        Set<Id> reportIds = new Set<Id>();
        for (DashboardComponent comp : components) {
            reportIds.add(comp.CustomReportId);
        }
        if (!reportIds.isEmpty()) {
            usedReports = [
                SELECT Id, Name 
                FROM Report 
                WHERE Id IN :reportIds
                ORDER BY Name
            ];
        }
        return usedReports;
    }

@AuraEnabled
public static String runReportAndExportCsv(Id reportId) {
    Reports.ReportResults results = Reports.ReportManager.runReport(reportId, true);
    Map<String, Reports.ReportFact> factMap = results.getFactMap();
    Reports.ReportMetadata reportMetadata = results.getReportMetadata();
    List<String> detailColumns = reportMetadata.getDetailColumns();
    List<String> headers = new List<String>();

    // Build header row
    for (String fieldApiName : detailColumns) {
        headers.add('"' + getFieldLabelFromApiName(fieldApiName) + '"');
    }
    String csv = String.join(headers, ',') + '\n';

    // Check if grouped report using groupingsDown
    if (!results.getGroupingsDown().getGroupings().isEmpty()) {
        List<Reports.GroupingValue> rowGroups = results.getGroupingsDown().getGroupings();
        for (Reports.GroupingValue grouping : rowGroups) {
            csv += buildGroupedCsv(grouping, factMap, detailColumns, 0);
        }

    } else {
        // For tabular reports
        if (factMap.containsKey('T!T')) {
            Reports.ReportFactWithDetails factWithDetails = (Reports.ReportFactWithDetails) factMap.get('T!T');
            for (Reports.ReportDetailRow row : factWithDetails.getRows()) {
                csv += formatRow(row, detailColumns);
            }
        }
    }

    return csv;
}

private static String buildGroupedCsv(Reports.GroupingValue grouping, Map<String, Reports.ReportFact> factMap, List<String> detailColumns, Integer level) {
    String csv = '';
    String indent = String.join(new List<String>(new String[level]), '\t');
    csv += indent + '"' + grouping.getLabel() + '"\n';

    if (grouping.getGroupings() != null && !grouping.getGroupings().isEmpty()) {
        for (Reports.GroupingValue subgroup : grouping.getGroupings()) {
            csv += buildGroupedCsv(subgroup, factMap, detailColumns, level + 1);
        }
    } else {
        // Leaf node — use its key to get rows
        String key = grouping.getKey()+ '!T';
        if (factMap.containsKey(key)) {
            Reports.ReportFact fact = factMap.get(key);
            if (fact instanceof Reports.ReportFactWithDetails) {
                for (Reports.ReportDetailRow row : ((Reports.ReportFactWithDetails) fact).getRows()) {
                    csv += formatRow(row, detailColumns);
                }
            }
        }
    }

    return csv;
}

private static String formatRow(Reports.ReportDetailRow row, List<String> detailColumns) {
    List<String> values = new List<String>();
    for (Reports.ReportDataCell cell : row.getDataCells()) {
        String val = cell.getLabel();
        values.add('"' + (val != null ? val.replace('"', '""') : '') + '"');
    }
    return String.join(values, ',') + '\n';
}



    private static String getFieldLabelFromApiName(String fieldApiName) {
        List<String> parts = fieldApiName.split('\\.');
        if(parts.size() == 2) {
            String objectApiName = parts[0];
            String fieldName = parts[1];
            try {
                Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectApiName);
                if(objType != null) {
                    Map<String, Schema.SObjectField> fieldsMap = objType.getDescribe().fields.getMap();
                    if(fieldsMap.containsKey(fieldName)) {
                        return fieldsMap.get(fieldName).getDescribe().getLabel();
                    }
                }
            } catch(Exception e) {
                // ignore and fallback
            }
        }
        return fieldApiName; // fallback
    }
}