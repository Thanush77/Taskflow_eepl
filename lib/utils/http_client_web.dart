import 'package:dio/dio.dart';

void configurePlatformHttpClient(Dio dio, bool isProduction) {
  // Web doesn't need certificate configuration
  // The browser handles SSL/TLS certificates automatically
}