import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

final users = <String, String>{
  'passenger01@gmail.com': 'pass123',
  'passenger': 'pass123',
  'operator': 'op123',
  'user': 'pass123',
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

Future<Response> verifyHandler(Request req) async {
  final auth = req.headers['authorization'];
  if (auth == null || !auth.startsWith('Bearer ')) {
    return _json({'error': 'Missing Authorization header'}, status: 401);
  }
  final token = auth.substring(7);
  // In this simple demo, any token that decodes to username:ts is accepted
  try {
    final decoded = utf8.decode(base64Url.decode(token));
    final parts = decoded.split(':');
    if (parts.length < 2) return _json({'error': 'Invalid token'}, status: 401);
    final username = parts[0];
    if (!users.containsKey(username)) {
      return _json({'error': 'Unknown user'}, status: 401);
    }
    return _json({'username': username});
  } catch (e) {
    return _json({'error': 'Invalid token'}, status: 401);
  }
}

void main(List<String> args) async {
  final app = Router();
  app.post('/auth/login', loginHandler);
  app.get('/auth/verify', verifyHandler);

  final handler =
      const Pipeline().addMiddleware(logRequests()).addHandler(app.call);

  final portEnv = Platform.environment['PORT'];
  final port = portEnv == null ? 8080 : int.parse(portEnv);
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  print('Server listening on port ${server.port}');
}
