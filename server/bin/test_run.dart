import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:http/http.dart' as http;

final users = <String, String>{
  'passenger': 'pass123',
};

String generateToken(String username) => base64Url
    .encode(utf8.encode('$username:${DateTime.now().millisecondsSinceEpoch}'));
Response _json(Object obj, {int status = 200}) => Response(status,
    body: json.encode(obj), headers: {'content-type': 'application/json'});

Future<Response> loginHandler(Request req) async {
  final payload = json.decode(await req.readAsString());
  final username = payload['username'] as String?;
  final password = payload['password'] as String?;
  if (username == null || password == null) {
    return _json({'error': 'Missing username or password'}, status: 400);
  }
  final expected = users[username];
  if (expected == null || expected != password) {
    return _json({'error': 'Invalid credentials'}, status: 401);
  }
  final token = generateToken(username);
  return _json({'token': token, 'username': username});
}

void main() async {
  final app = Router();
  app.post('/auth/login', loginHandler);
  final handler =
      const Pipeline().addMiddleware(logRequests()).addHandler(app.call);
  final server = await io.serve(handler, InternetAddress.loopbackIPv4, 0);
  final port = server.port;
  print('Test server running on :$port');

  final resp = await http.post(Uri.parse('http://localhost:$port/auth/login'),
      headers: {'content-type': 'application/json'},
      body: json.encode({'username': 'passenger', 'password': 'pass123'}));
  print('Response status: ${resp.statusCode}');
  print('Body: ${resp.body}');
  await server.close(force: true);
}
