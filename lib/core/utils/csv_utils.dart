// lib/core/utils/csv_utils.dart

class CsvUtils {
  /// Converts a list of maps to a CSV string.
  /// The keys of the first map are used as headers.
  static String mapListToCsv(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return '';

    final headers = data.first.keys.toList();
    final List<String> csvRows = [];

    // Add headers
    csvRows.add(headers.map((h) => _escapeCsvField(h)).join(','));

    // Add data rows
    for (final row in data) {
      csvRows.add(headers.map((h) => _escapeCsvField(row[h]?.toString() ?? '')).join(','));
    }

    return csvRows.join('\n');
  }

  /// Escapes a field for CSV according to RFC 4180.
  /// If the field contains a comma, double-quote, or newline, it is enclosed in double-quotes.
  /// Double-quotes within the field are escaped by another double-quote.
  static String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n') || field.contains('\r')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}
