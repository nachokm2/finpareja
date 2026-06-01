import 'package:dio/dio.dart';
import 'package:flutter_app/core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Proveedor compartido del cliente Dio con interceptores JWT.
/// Todos los datasources financieros usan este mismo cliente para
/// que el refresh automático de tokens funcione globalmente.
final dioProvider = FutureProvider<Dio>((ref) async {
  final client = await ApiClient.create();
  return client.dio;
});
