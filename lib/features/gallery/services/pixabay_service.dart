import 'dart:io';

import 'package:dio/dio.dart';

import '../models/pixabay_page.dart';
import 'pixabay_exception.dart';

/// Talks to the Pixabay REST API. Owns endpoint construction, request
/// parameters, decoding and the mapping of transport failures to
/// [PixabayException]s. Nothing above this layer sees Dio.
class PixabayService {
  PixabayService({required this._dio, required this._apiKey});

  static const String baseUrl = 'https://pixabay.com';
  static const String apiPath = '/api/';

  static Dio createDio() {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        responseType: ResponseType.json,
      ),
    );
  }

  final Dio _dio;
  final String _apiKey;

  /// Fetches one page of photos. Without [query] this is the curated feed
  /// (editor's choice, most popular first).
  Future<PixabayPage> fetchImages({
    String query = '',
    int page = 1,
    int perPage = 20,
  }) async {
    if (_apiKey.isEmpty) throw const PixabayMissingKeyException();

    final hasQuery = query.trim().isNotEmpty;
    // Mirrors the distinguishing parameter actually sent, minus the API key.
    final requestLabel = hasQuery
        ? '$apiPath?q=${Uri.encodeQueryComponent(query.trim())}'
        : '$apiPath?editors_choice=true';

    final Response<Object?> response;
    try {
      response = await _dio.get<Object?>(
        apiPath,
        queryParameters: <String, Object?>{
          'key': _apiKey,
          'image_type': 'photo',
          'safesearch': 'true',
          'order': 'popular',
          if (!hasQuery) 'editors_choice': 'true',
          'per_page': perPage,
          'page': page,
          if (hasQuery) 'q': query.trim(),
        },
      );
    } on DioException catch (error) {
      throw _mapDioException(error, requestLabel);
    }

    final data = response.data;
    if (data is Map<String, dynamic>) return PixabayPage.fromJson(data);
    throw PixabayApiException(
      statusCode: response.statusCode,
      path: requestLabel,
      message: 'Unexpected response body from Pixabay.',
    );
  }

  PixabayException _mapDioException(DioException error, String requestLabel) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return PixabayNetworkException(error.message);
      case DioExceptionType.badResponse:
        final response = error.response;
        return PixabayApiException(
          statusCode: response?.statusCode,
          path: requestLabel,
          message: response?.data?.toString(),
        );
      case DioExceptionType.badCertificate:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return PixabayNetworkException(error.message);
        }
        return PixabayApiException(
          statusCode: error.response?.statusCode,
          path: requestLabel,
          message: error.message,
        );
    }
  }
}
