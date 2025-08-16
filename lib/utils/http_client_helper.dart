import 'package:dio/dio.dart';
import 'http_client_stub.dart'
    if (dart.library.io) 'http_client_io.dart'
    if (dart.library.html) 'http_client_web.dart';

class HttpClientHelper {
  static void configureHttpClient(Dio dio, bool isProduction) {
    configurePlatformHttpClient(dio, isProduction);
  }
}