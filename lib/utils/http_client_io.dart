import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

void configurePlatformHttpClient(Dio dio, bool isProduction) {
  (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
    final client = HttpClient();
    if (!isProduction) {
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    }
    return client;
  };
}