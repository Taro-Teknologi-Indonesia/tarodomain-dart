import '../errors/error_codes.dart';

/// A type-safe key for a dependency in a [Container] (spec §23.1).
///
/// `resolve(token)` returns a [T]. Tokens are compared by identity, so two
/// `const` tokens with the same type and name are the same token:
///
/// ```dart
/// const balances = Token<BalanceStore>('balances');
/// ```
final class Token<T> {
  /// Creates a token. [name] appears in errors.
  const Token(this.name);

  /// The name shown in errors.
  final String name;

  @override
  String toString() => 'Token<$T>($name)';
}

/// How long a resolved dependency lives (spec §23.2).
enum Lifetime {
  /// One instance per container the binding was made on, usually the root.
  singleton,

  /// A new instance for every resolve.
  transient,

  /// One instance per scope from [Container.createScope]. Resolving it from
  /// the root treats the root as a scope of its own.
  scoped,
}

/// Creates a dependency, resolving its own dependencies from [container].
typedef Provide<T> = T Function(Container container);

/// A dependency injection container (spec §23.2).
///
/// Bindings made on a container are visible to it and its scopes. A scope
/// may bind tokens of its own, for example per-request resources, which its
/// parent doesn't see.
///
/// A singleton is created with the container it was bound on, so it can't
/// depend on anything bound only in a scope; a scoped or transient
/// dependency is created with the container it was resolved from.
final class Container {
  /// Creates an empty root container.
  Container() : _parent = null;

  Container._scope(Container this._parent);

  final Container? _parent;
  final _bindings = <Token<Object?>, _Binding<Object?>>{};
  final _scoped = <_Binding<Object?>, Object?>{};

  /// Tokens being resolved, across the whole tree, to detect cycles.
  final _resolving = <Token<Object?>>[];

  Container get _root => _parent?._root ?? this;

  /// Binds [token] to [create] with [lifetime], replacing any binding of
  /// [token] on this container.
  Container bind<T>(
    Token<T> token,
    Provide<T> create, {
    Lifetime lifetime = Lifetime.singleton,
  }) {
    _bindings[token] = _Binding<T>(this, create, lifetime);
    return this;
  }

  /// Binds [token] to one instance per container it was bound on.
  Container bindSingleton<T>(Token<T> token, Provide<T> create) =>
      bind(token, create);

  /// Binds [token] to a new instance per resolve.
  Container bindTransient<T>(Token<T> token, Provide<T> create) =>
      bind(token, create, lifetime: Lifetime.transient);

  /// Binds [token] to one instance per scope.
  Container bindScoped<T>(Token<T> token, Provide<T> create) =>
      bind(token, create, lifetime: Lifetime.scoped);

  /// Binds [token] to [instance], which is already created.
  Container bindInstance<T>(Token<T> token, T instance) {
    _bindings[token] = _Binding<T>.instance(this, instance);
    return this;
  }

  /// The dependency bound to [token].
  ///
  /// Throws [MissingDependencyError] if [token] isn't bound here or in a
  /// parent, and [CircularDependencyError] if creating it needs itself.
  T resolve<T>(Token<T> token) => _lookup(token) != null
      ? resolveOrNull(token) as T
      : throw MissingDependencyError(
          'No binding for $token',
          context: {'token': token.name},
        );

  /// The dependency bound to [token], or null if there is no binding.
  ///
  /// Throws [CircularDependencyError] if creating it needs itself.
  T? resolveOrNull<T>(Token<T> token) {
    final binding = _lookup(token);
    if (binding == null) return null;
    return switch (binding.lifetime) {
          Lifetime.singleton => binding.singleton(
            () => _create(token, binding, binding.owner),
          ),
          Lifetime.transient => _create(token, binding, this),
          Lifetime.scoped =>
            _scoped.containsKey(binding)
                ? _scoped[binding]
                : _scoped[binding] = _create(token, binding, this),
        }
        as T?;
  }

  /// Whether [token] is bound here or in a parent.
  bool has<T>(Token<T> token) => _lookup(token) != null;

  /// A child container whose scoped dependencies are its own (spec §23.2).
  Container createScope() => Container._scope(this);

  _Binding<Object?>? _lookup(Token<Object?> token) =>
      _bindings[token] ?? _parent?._lookup(token);

  Object? _create(
    Token<Object?> token,
    _Binding<Object?> binding,
    Container container,
  ) {
    final resolving = _root._resolving;
    if (resolving.contains(token)) {
      final path = [...resolving.skipWhile((t) => t != token), token];
      throw CircularDependencyError(
        'Circular dependency: ${path.map((t) => t.name).join(' -> ')}',
        context: {
          'path': [for (final t in path) t.name],
        },
      );
    }
    resolving.add(token);
    try {
      return binding.create(container);
    } finally {
      resolving.removeLast();
    }
  }
}

final class _Binding<T> {
  _Binding(this.owner, this.create, this.lifetime);

  _Binding.instance(this.owner, T instance)
    : create = ((_) => instance),
      lifetime = Lifetime.singleton,
      _created = true,
      _instance = instance;

  final Container owner;
  final Provide<T> create;
  final Lifetime lifetime;

  bool _created = false;
  T? _instance;

  /// The cached instance, created with [create] on first use.
  T singleton(Object? Function() create) {
    if (!_created) {
      _instance = create() as T;
      _created = true;
    }
    return _instance as T;
  }
}
