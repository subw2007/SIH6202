String reportAuthorName(Map<String, dynamic> report) {
  final user = report['user'];
  final userMap = user is Map ? Map<String, dynamic>.from(user) : null;
  final candidates = [
    report['userName'],
    report['reporterName'],
    userMap?['name'],
    report['author_name'],
    report['user_name'],
  ];

  for (final candidate in candidates) {
    final name = candidate?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
  }
  return 'Anonymous Citizen';
}