import 'package:flutter_test/flutter_test.dart';
import 'package:pixabay_image_browser/features/auth/models/auth_user.dart';

void main() {
  test('the initial is the upper-cased first letter of the email', () {
    expect(const AuthUser(id: 'u1', email: 'sam@aperture.app').initial, 'S');
    expect(const AuthUser(id: 'u1', email: '  ana@x.io').initial, 'A');
    expect(const AuthUser(id: 'u1', email: '').initial, '');
  });

  test('users compare by value', () {
    final created = DateTime.utc(2026, 9, 4);
    expect(
      AuthUser(id: 'u1', email: 'a@b.c', createdAt: created),
      AuthUser(id: 'u1', email: 'a@b.c', createdAt: created),
    );
    expect(
      const AuthUser(id: 'u1', email: 'a@b.c'),
      isNot(const AuthUser(id: 'u2', email: 'a@b.c')),
    );
  });
}
