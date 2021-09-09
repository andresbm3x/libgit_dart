import 'package:libgit_dart/libgit_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Libgit tests', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('Open repo Test', () {
      Repository.open(Libgit.instance, 'C:\Projects\Dart\password_manager');
      expect(true, isTrue);
    });
  });
}
