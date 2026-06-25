/// Matches the backend error shape:
/// { "detail": "...", "errors": { "field": ["msg", ...] } }
class ApiError implements Exception {
  const ApiError({
    required this.statusCode,
    required this.message,
    this.fieldErrors = const {},
  });

  final int statusCode;
  final String message;
  final Map<String, List<String>> fieldErrors;

  factory ApiError.fromResponse(int statusCode, dynamic body) {
    if (body is Map<String, dynamic>) {
      final detail = body['detail'] as String? ?? _extractFirst(body);
      final raw = body['errors'];
      final fields = <String, List<String>>{};
      if (raw is Map<String, dynamic>) {
        raw.forEach((k, v) {
          if (v is List) {
            fields[k] = v.map((e) => e.toString()).toList();
          }
        });
      }
      return ApiError(statusCode: statusCode, message: detail, fieldErrors: fields);
    }
    return ApiError(
      statusCode: statusCode,
      message: 'Unexpected error ($statusCode)',
    );
  }

  factory ApiError.network(String message) =>
      ApiError(statusCode: 0, message: message);

  static String _extractFirst(Map<String, dynamic> body) {
    for (final v in body.values) {
      if (v is String) return v;
      if (v is List && v.isNotEmpty) return v.first.toString();
    }
    return 'Unknown error';
  }

  @override
  String toString() => 'ApiError($statusCode): $message';
}
