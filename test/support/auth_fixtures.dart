library;

import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:pixabay_image_browser/features/auth/models/auth_user.dart';
import 'package:pixabay_image_browser/features/auth/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

AuthUser sampleUser({
  String id = '27183e01-fdea-4259-886d-19530b352bf8',
  String email = 'sam@aperture.app',
  DateTime? createdAt,
}) {
  return AuthUser(
    id: id,
    email: email,
    createdAt: createdAt ?? DateTime.utc(2026, 9, 4, 7, 10),
  );
}

MockAuthRepository stubAuthRepository(
  MockAuthRepository repository, {
  AuthUser? user,
  StreamController<AuthUser?>? changes,
}) {
  final stream = (changes ?? StreamController<AuthUser?>.broadcast()).stream;
  when(repository.currentUser).thenReturn(user);
  when(repository.userChanges).thenAnswer((_) => stream);
  return repository;
}
