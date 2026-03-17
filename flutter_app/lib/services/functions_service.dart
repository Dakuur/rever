import 'dart:convert';
import 'package:http/http.dart' as http;

class FunctionsService {
  static const _url =
      'https://us-central1-rever-c494a.cloudfunctions.net/verifyOrderNumber';

  /// Calls the [verifyOrderNumber] Cloud Function via plain HTTP to avoid
  /// the Int64/dart2js bug in the cloud_functions_web package.
  /// Returns `true` if the order number is prime, `false` otherwise.
  Future<bool> verifyOrderNumber(String orderNumber) async {
    final response = await http.post(
      Uri.parse(_url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'orderNumber': orderNumber}),
    );
    if (response.statusCode != 200) {
      throw Exception('verifyOrderNumber HTTP ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['isValid'] == true;
  }
}
