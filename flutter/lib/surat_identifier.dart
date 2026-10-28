/// The only valid numeric identifier is the positive database ID from the API.
/// Never infer a primary key from the list index or a citizen's name.
int? cikokoPositiveId(Map<String, dynamic> record) {
  for (final key in const ['id', 'application_id', 'request_id', 'record_id']) {
    final raw = record[key];
    final id = raw is int ? raw : int.tryParse((raw ?? '').toString().trim());
    if (id != null && id > 0) return id;
  }
  return null;
}

/// AW references are a legitimate exact-match server lookup. Legacy versions
/// sometimes put the reference in "title" instead of "reference".
String? cikokoWarisReference(Map<String, dynamic> record) {
  for (final key in const ['reference_no', 'reference', 'document_key', 'title']) {
    final raw = record[key];
    if (raw is! String) continue;
    final candidate = raw.trim().replaceFirst(RegExp(r'^waris:', caseSensitive: false), '');
    if (RegExp(r'^AW-[A-Za-z0-9-]{6,80}$').hasMatch(candidate)) {
      return candidate;
    }
  }
  return null;
}

/// Treat a valid AW reference as authoritative for the document type even if
/// an older API accidentally supplies report as its kind.
String cikokoDocumentKind(Map<String, dynamic> row) {
  if (cikokoWarisReference(row) != null) return 'waris';
  return (row['kind'] ?? 'report').toString();
}
