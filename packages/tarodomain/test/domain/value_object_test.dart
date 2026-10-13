import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

class Email extends ValueObject<String> with OrderedValueObject<String> {
  Email(super.value);

  @override
  void validate(String value) {
    if (!value.contains('@')) {
      throw ValueObjectInvalidError('Not an email: $value');
    }
  }
}

class Name extends ValueObject<String> with OrderedValueObject<String> {
  Name(super.value);
}

class Tags extends ValueObject<List<String>> {
  Tags(List<String> tags) : super(List.unmodifiable(tags));
}

class Broken extends ValueObject<int> {
  Broken(super.value);

  @override
  void validate(int value) => throw StateError('bug');
}

class Money extends ValueObject<({int cents, String currency})> {
  Money(super.value);

  Money copyWith({int? cents}) =>
      Money((cents: cents ?? value.cents, currency: value.currency));
}

void main() {
  group('ValueObject', () {
    test('runs validate on construction', () {
      expect(Email('a@b.c').value, 'a@b.c');
      expect(() => Email('nope'), throwsA(isA<ValueObjectInvalidError>()));
    });

    test('wraps unexpected validation errors', () {
      expect(
        () => Broken(1),
        throwsA(
          isA<ValueObjectConstructionFailedError>().having(
            (e) => e.cause,
            'cause',
            isStateError,
          ),
        ),
      );
    });

    test('equality is structural and per type', () {
      expect(Email('a@b.c'), Email('a@b.c'));
      expect(Email('a@b.c').hashCode, Email('a@b.c').hashCode);
      expect(Email('a@b.c'), isNot(Email('x@b.c')));
      expect(Email('a@b.c'), isNot(Name('a@b.c')));
    });

    test('compares collections deeply', () {
      expect(Tags(['a', 'b']), Tags(['a', 'b']));
      expect(Tags(['a', 'b']).hashCode, Tags(['a', 'b']).hashCode);
      expect(Tags(['a', 'b']), isNot(Tags(['b', 'a'])));
    });

    test('compareTo orders values of the same type', () {
      expect(Name('a').compareTo(Name('b')), lessThan(0));
      expect([Name('c'), Name('a')]..sort(), [Name('a'), Name('c')]);
    });

    test('compareTo across types throws IncomparableValueError', () {
      expect(
        () => Name('a').compareTo(Email('a@b.c')),
        throwsA(isA<IncomparableValueError>()),
      );
    });

    test('subclasses provide copyWith', () {
      final price = Money((cents: 100, currency: 'IDR'));
      final updated = price.copyWith(cents: 250);
      expect(updated.value, (cents: 250, currency: 'IDR'));
      expect(price.value.cents, 100);
    });
  });
}
