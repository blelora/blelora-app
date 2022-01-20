import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'src/app.dart';
import 'src/http.dart';

void main() {
  dio.interceptors.add(LogInterceptor());
  runApp(App());
}
