import 'dart:convert';
import 'package:http/http.dart' as http;

/// Thrown whenever the server returns ok:false (wrong student code/phone,
/// missing fields, or any other application-level error). The message is
/// already written for a parent to read directly.
class ParentApiException implements Exception {
  final String message;
  ParentApiException(this.message);
  @override
  String toString() => message;
}

/// Talks to the Smart School Transport Manager parent_server.py backend.
///
/// Every call sends the same (studentCode, phone) pair the parent typed in
/// on the login screen — there is no session token, because the backend
/// re-validates that pair on every single request. Change [baseUrl] once
/// you know your Render URL (see README in this folder).
class ParentApi {
  // TODO: replace with your deployed Render URL, e.g.
  // "https://sstm-parent-api.onrender.com"
  static const String baseUrl = "https://sstm-parent-api.onrender.com";

  final String studentCode;
  final String phone;

  ParentApi({required this.studentCode, required this.phone});

  Future<Map<String, dynamic>> _post(String path) async {
    final uri = Uri.parse("$baseUrl$path");
    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"student_code": studentCode, "phone": phone}),
          )
          .timeout(const Duration(seconds: 25));
      // Render free-tier instances sleep after inactivity and can take
      // 30-50s to wake on the very first request — the timeout above is
      // generous on purpose so a cold start doesn't look like a crash.
    } catch (_) {
      throw ParentApiException(
        "Couldn't reach the server. Check your internet connection and try again.",
      );
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ParentApiException("Unexpected response from server.");
    }

    if (body["ok"] != true) {
      throw ParentApiException(body["error"]?.toString() ?? "Something went wrong.");
    }
    return body;
  }

  /// Verifies the (student_code, phone) pair and returns the student
  /// summary in one call — used for both login and the home screen refresh.
  Future<Map<String, dynamic>> login() async {
    final body = await _post("/api/parent/login");
    return body["data"] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSummary() async {
    final body = await _post("/api/parent/summary");
    return body["data"] as Map<String, dynamic>;
  }

  Future<List<dynamic>> getPaymentHistory() async {
    final body = await _post("/api/parent/payments");
    return body["data"] as List<dynamic>;
  }

  Future<List<dynamic>> getLedgerStatus() async {
    final body = await _post("/api/parent/ledger");
    return body["data"] as List<dynamic>;
  }
}
