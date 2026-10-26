/// Resolve only identifiers supplied by the API. Never use a list index.
int? cikokoPositiveId(Map<String, dynamic> record) {
  for (final key in const ['id', 'application_id', 'request_id']) {
    final raw = record[key];
    final id = raw is int ? raw : int.tryParse((raw ?? '').toString().trim());
    if (id != null && id > 0) return id;
  }
  return null;
}

/// Public AW references may be used as fallback by the V2521 server API.
String? cikokoWarisReference(Map<String, dynamic> record) {
  if ((record['kind'] ?? 'waris').toString() != 'waris') return null;
  final ref = (record['reference_no'] ?? record['reference'] ?? '').toString().trim();
  if (!RegExp(r'^AW-[a-zA-Z0-9-]{6,80}$').hasMatch(ref)) return null;
  return ref;
}
