import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pixabay_image_browser/features/gallery/services/pixabay_exception.dart';
import 'package:pixabay_image_browser/features/gallery/services/pixabay_service.dart';

import '../../../support/pixabay_fixtures.dart';

class _MockAdapter extends Mock implements HttpClientAdapter {}

void main() {
  late _MockAdapter adapter;
  late PixabayService service;

  setUpAll(() {
    registerFallbackValue(RequestOptions());
  });

  setUp(() {
    adapter = _MockAdapter();
    final dio = PixabayService.createDio()..httpClientAdapter = adapter;
    service = PixabayService(dio: dio, apiKey: 'test-key');
  });

  void answerWith(String body, int status, {bool json = true}) {
    when(() => adapter.fetch(any(), any(), any())).thenAnswer(
      (_) async => ResponseBody.fromString(
        body,
        status,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[
            json ? Headers.jsonContentType : 'text/plain',
          ],
        },
      ),
    );
  }

  RequestOptions capturedRequest() {
    return verify(
          () => adapter.fetch(captureAny(), any(), any()),
        ).captured.single
        as RequestOptions;
  }

  test('decodes a 200 response into a PixabayPage', () async {
    answerWith(jsonEncode(samplePage(hitCount: 3)), 200);

    final page = await service.fetchImages();

    expect(page.totalHits, 500);
    expect(page.hits, hasLength(3));
    expect(page.hits.first.id, 100);
  });

  test('sends the curated-feed query without q', () async {
    answerWith(jsonEncode(samplePage()), 200);

    await service.fetchImages(page: 2, perPage: 15);

    final request = capturedRequest();
    expect(request.uri.host, 'pixabay.com');
    expect(request.uri.path, '/api/');
    expect(request.uri.queryParameters, <String, String>{
      'key': 'test-key',
      'image_type': 'photo',
      'safesearch': 'true',
      'order': 'popular',
      'editors_choice': 'true',
      'per_page': '15',
      'page': '2',
    });
  });

  test('adds q when a query is given', () async {
    answerWith(jsonEncode(samplePage()), 200);

    await service.fetchImages(query: ' fog ');

    expect(capturedRequest().uri.queryParameters['q'], 'fog');
  });

  test('maps a 400 plain-text body to PixabayApiException', () async {
    answerWith('[ERROR 400] Invalid or missing API key', 400, json: false);

    await expectLater(
      service.fetchImages,
      throwsA(
        isA<PixabayApiException>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having((e) => e.path, 'path', '/api/?q=popular')
            .having((e) => e.message, 'message', contains('ERROR 400')),
      ),
    );
  });

  test('maps a 500 to PixabayApiException with the query label', () async {
    answerWith('boom', 500, json: false);

    await expectLater(
      () => service.fetchImages(query: 'fog'),
      throwsA(
        isA<PixabayApiException>().having(
          (e) => e.requestLabel,
          'requestLabel',
          'HTTP 500 · /api/?q=fog',
        ),
      ),
    );
  });

  test('maps a Dio connection error to PixabayNetworkException', () async {
    when(() => adapter.fetch(any(), any(), any())).thenThrow(
      DioException.connectionError(
        requestOptions: RequestOptions(),
        reason: 'offline',
      ),
    );

    await expectLater(
      service.fetchImages,
      throwsA(isA<PixabayNetworkException>()),
    );
  });

  test('maps a SocketException to PixabayNetworkException', () async {
    when(
      () => adapter.fetch(any(), any(), any()),
    ).thenThrow(const SocketException('Failed host lookup'));

    await expectLater(
      service.fetchImages,
      throwsA(isA<PixabayNetworkException>()),
    );
  });

  test('treats a non-JSON 200 body as an API failure', () async {
    answerWith('<html>not json</html>', 200, json: false);

    await expectLater(
      service.fetchImages,
      throwsA(
        isA<PixabayApiException>().having((e) => e.statusCode, 'status', 200),
      ),
    );
  });

  test(
    'throws PixabayMissingKeyException before any request when the key is empty',
    () async {
      final keyless = PixabayService(
        dio: PixabayService.createDio()..httpClientAdapter = adapter,
        apiKey: '',
      );

      await expectLater(
        keyless.fetchImages,
        throwsA(
          isA<PixabayMissingKeyException>().having(
            (e) => e.message,
            'message',
            contains('--dart-define=PIXABAY_API_KEY'),
          ),
        ),
      );
      verifyNever(() => adapter.fetch(any(), any(), any()));
    },
  );
}
