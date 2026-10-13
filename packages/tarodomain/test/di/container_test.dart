import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

class Counter {
  Counter(this.id);

  final int id;
}

void main() {
  const counter = Token<Counter>('counter');
  const name = Token<String>('name');
  var created = 0;
  Counter next(Container _) => Counter(++created);

  setUp(() => created = 0);

  group('lifetimes', () {
    test('singleton is created once, even from scopes', () {
      final root = Container()..bindSingleton(counter, next);
      final scope = root.createScope();
      expect(root.resolve(counter), same(root.resolve(counter)));
      expect(scope.resolve(counter), same(root.resolve(counter)));
      expect(created, 1);
    });

    test('singleton is created lazily', () {
      Container().bindSingleton(counter, next);
      expect(created, 0);
    });

    test('transient is created for every resolve', () {
      final root = Container()..bindTransient(counter, next);
      expect(root.resolve(counter), isNot(same(root.resolve(counter))));
      expect(created, 2);
    });

    test('scoped is one instance per scope', () {
      final root = Container()..bindScoped(counter, next);
      final a = root.createScope();
      final b = root.createScope();
      expect(a.resolve(counter), same(a.resolve(counter)));
      expect(a.resolve(counter), isNot(same(b.resolve(counter))));
      expect(created, 2);
    });

    test('scoped from the root treats the root as a scope', () {
      final root = Container()..bindScoped(counter, next);
      expect(root.resolve(counter), same(root.resolve(counter)));
      expect(
        root.createScope().resolve(counter),
        isNot(same(root.resolve(counter))),
      );
    });

    test('bindInstance returns the instance', () {
      final instance = Counter(42);
      final root = Container()..bindInstance(counter, instance);
      expect(root.createScope().resolve(counter), same(instance));
    });

    test('bind with an explicit lifetime', () {
      final root = Container()
        ..bind(counter, next, lifetime: Lifetime.transient);
      root
        ..resolve(counter)
        ..resolve(counter);
      expect(created, 2);
    });
  });

  group('scopes', () {
    test('a scope sees its parent, but not the other way round', () {
      final root = Container();
      final scope = root.createScope()..bindInstance(name, 'request');
      expect(scope.resolve(name), 'request');
      expect(root.has(name), isFalse);
      expect(scope.has(name), isTrue);
    });

    test('a scope binding overrides its parent', () {
      final root = Container()..bindInstance(name, 'root');
      final scope = root.createScope()..bindInstance(name, 'scope');
      expect(scope.resolve(name), 'scope');
      expect(root.resolve(name), 'root');
    });

    test('a singleton resolves its dependencies from where it was bound', () {
      const greeting = Token<String>('greeting');
      final root = Container()
        ..bindSingleton(greeting, (c) => 'hello ${c.resolve(name)}');
      final scope = root.createScope()..bindInstance(name, 'request');
      expect(
        () => scope.resolve(greeting),
        throwsA(isA<MissingDependencyError>()),
      );
    });

    test('a scoped dependency resolves from the requesting scope', () {
      const greeting = Token<String>('greeting');
      final root = Container()
        ..bindScoped(greeting, (c) => 'hello ${c.resolve(name)}');
      final scope = root.createScope()..bindInstance(name, 'request');
      expect(scope.resolve(greeting), 'hello request');
    });

    test('rebinding replaces the binding and its instance', () {
      final root = Container()..bindSingleton(counter, next);
      final first = root.resolve(counter);
      root.bindSingleton(counter, next);
      expect(root.resolve(counter), isNot(same(first)));
    });
  });

  group('errors', () {
    test('resolve throws MissingDependencyError for an unbound token', () {
      expect(
        () => Container().resolve(counter),
        throwsA(
          isA<MissingDependencyError>().having(
            (e) => e.context['token'],
            'token',
            'counter',
          ),
        ),
      );
    });

    test('resolveOrNull returns null for an unbound token', () {
      expect(Container().resolveOrNull(counter), isNull);
    });

    test('a cycle throws CircularDependencyError with the path', () {
      const a = Token<Object>('a');
      const b = Token<Object>('b');
      final root = Container()
        ..bindSingleton(a, (c) => c.resolve(b))
        ..bindTransient(b, (c) => c.resolve(a));
      expect(
        () => root.resolve(a),
        throwsA(
          isA<CircularDependencyError>().having(
            (e) => e.context['path'],
            'path',
            ['a', 'b', 'a'],
          ),
        ),
      );
    });

    test('a cycle across scopes is detected', () {
      const a = Token<Object>('a');
      final root = Container()..bindScoped(a, (c) => c.resolve(a));
      expect(
        () => root.createScope().resolve(a),
        throwsA(isA<CircularDependencyError>()),
      );
    });

    test('the container recovers after a failed resolve', () {
      const a = Token<Object>('a');
      var fail = true;
      final root = Container()
        ..bindTransient(a, (_) => fail ? throw StateError('down') : 'ok');
      expect(() => root.resolve(a), throwsStateError);
      fail = false;
      expect(root.resolve(a), 'ok');
    });

    test('the same token resolved twice in sequence is not a cycle', () {
      const pair = Token<List<Counter>>('pair');
      final root = Container()
        ..bindTransient(counter, next)
        ..bindSingleton(pair, (c) => [c.resolve(counter), c.resolve(counter)]);
      expect(root.resolve(pair), hasLength(2));
    });
  });
}
