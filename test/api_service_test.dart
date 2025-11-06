import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:helloworld/services/api_service.dart';

void main() {
  group('ApiService', () {
    test(
      'submitReport returns success result when server replies success',
      () async {
        final mockClient = MockClient((request) async {
          if (request.method == 'POST' &&
              request.url.path.endsWith('/report/submit')) {
            return http.Response(
              jsonEncode({'success': true, 'id': 'r123'}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('not found', 404);
        });

        final service = ApiService(
          baseUrl: 'http://example.test',
          client: mockClient,
        );
        final res = await service.submitReport({'title': 't'});

        expect(res.success, isTrue);
        expect(res.id, 'r123');
      },
    );

    test('fetchRoutes parses list responses', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'GET' && request.url.path.endsWith('/routes')) {
          return http.Response(
            jsonEncode([
              {'id': 'a', 'name': 'Route A'},
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('not found', 404);
      });

      final service = ApiService(
        baseUrl: 'http://example.test',
        client: mockClient,
      );
      final routes = await service.fetchRoutes(vehicle: 'lrt-1', type: 'rail');

      expect(routes, isNotEmpty);
      expect(routes.first['id'], 'a');
    });
  });
}
