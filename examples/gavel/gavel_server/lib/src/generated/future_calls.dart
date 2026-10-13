/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: depend_on_referenced_packages

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _ida;
import 'package:clock/clock.dart' as _io0w16m8;
import 'package:serverpod/serverpod.dart' as _is;
import '../future_calls/auction_close_calls.dart' as _ij043ien;
import '../future_calls/taro_domain_calls.dart' as _ish7r71q;
import 'future_calls_generated_models/auction_close_calls_close_model.dart'
    as _ijzrfwlf;

/// Invokes a future call.
typedef _InvokeFutureCall =
    Future<void> Function(String name, _is.SerializableModel? object);

extension ServerpodFutureCallsGetter on _is.Serverpod {
  /// Generated future calls.
  FutureCalls get futureCalls => FutureCalls();
}

class FutureCalls extends _is.FutureCallDispatch<_FutureCallRef> {
  FutureCalls._();

  factory FutureCalls() {
    return _instance;
  }

  static final FutureCalls _instance = FutureCalls._();

  _is.FutureCallManager? _futureCallManager;

  String? _serverId;

  String get _effectiveServerId {
    if (_serverId == null) {
      throw StateError('FutureCalls is not initialized.');
    }
    return _serverId!;
  }

  _is.FutureCallManager get _effectiveFutureCallManager {
    if (_futureCallManager == null) {
      throw StateError('FutureCalls is not initialized.');
    }
    return _futureCallManager!;
  }

  @override
  void initialize(_is.FutureCallManager futureCallManager, String serverId) {
    var registeredFutureCalls = <String, _is.InvokableFutureCall>{
      'AuctionCloseCallsCloseFutureCall': AuctionCloseCallsCloseFutureCall(),
      'AuctionCloseCallsSweepFutureCall': AuctionCloseCallsSweepFutureCall(),
      'TaroDomainCallsCatchUpFutureCall': TaroDomainCallsCatchUpFutureCall(),
      'TaroDomainCallsSagaTimeoutsFutureCall':
          TaroDomainCallsSagaTimeoutsFutureCall(),
      'TaroDomainCallsCleanupFutureCall': TaroDomainCallsCleanupFutureCall(),
    };
    _futureCallManager = futureCallManager;
    _serverId = serverId;
    for (final entry in registeredFutureCalls.entries) {
      _futureCallManager?.registerFutureCall(entry.value, entry.key);
    }
  }

  @override
  _FutureCallRef callAtTime(DateTime time, {String? identifier}) {
    return _FutureCallRef((name, object) {
      return _effectiveFutureCallManager.scheduleFutureCall(
        name,
        object,
        time,
        _effectiveServerId,
        identifier,
      );
    });
  }

  @override
  _FutureCallRef callWithDelay(Duration delay, {String? identifier}) {
    return _FutureCallRef((name, object) {
      return _effectiveFutureCallManager.scheduleFutureCall(
        name,
        object,
        DateTime.now().toUtc().add(delay),
        _effectiveServerId,
        identifier,
      );
    });
  }

  @override
  _is.RecurringFutureCallDispatch<_FutureCallRef> callRecurring({
    String? identifier,
  }) {
    return _RecurringFutureCallDispatchImpl(
      _effectiveFutureCallManager,
      _effectiveServerId,
      identifier,
    );
  }

  @override
  Future<void> cancel(String identifier) async {
    await _effectiveFutureCallManager.cancelFutureCall(identifier);
  }
}

class _RecurringFutureCallDispatchImpl
    extends _is.RecurringFutureCallDispatch<_FutureCallRef> {
  _RecurringFutureCallDispatchImpl(
    this._futureCallManager,
    this._serverId,
    this._identifier,
  );

  final _is.FutureCallManager _futureCallManager;

  final String _serverId;

  final String? _identifier;

  @override
  _FutureCallRef cron(String cronExpression) {
    return _FutureCallRef((name, object) {
      return _futureCallManager.scheduleFutureCall(
        name,
        object,
        _is.Cron.parse(cronExpression).nextTime(),
        _serverId,
        _identifier,
        scheduling: _is.CronFutureCallScheduling(cron: cronExpression),
      );
    });
  }

  @override
  _FutureCallRef every(Duration interval, {DateTime? start}) {
    final now = _io0w16m8.clock.now().toUtc();
    return _FutureCallRef((name, object) {
      return _futureCallManager.scheduleFutureCall(
        name,
        object,
        start ?? now.add(interval),
        _serverId,
        _identifier,
        scheduling: _is.IntervalFutureCallScheduling(
          interval: interval,
          start: start,
        ),
      );
    });
  }
}

class _FutureCallRef {
  _FutureCallRef(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  late final auctionCloseCalls = _AuctionCloseCallsFutureCallDispatcher(
    _invokeFutureCall,
  );

  late final taroDomainCalls = _TaroDomainCallsFutureCallDispatcher(
    _invokeFutureCall,
  );
}

class _AuctionCloseCallsFutureCallDispatcher {
  _AuctionCloseCallsFutureCallDispatcher(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  Future<void> close(_is.UuidValue auctionId) {
    var object = _ijzrfwlf.AuctionCloseCallsCloseModel(auctionId: auctionId);
    return _invokeFutureCall('AuctionCloseCallsCloseFutureCall', object);
  }

  Future<void> sweep() {
    return _invokeFutureCall('AuctionCloseCallsSweepFutureCall', null);
  }
}

class _TaroDomainCallsFutureCallDispatcher {
  _TaroDomainCallsFutureCallDispatcher(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  Future<void> catchUp() {
    return _invokeFutureCall('TaroDomainCallsCatchUpFutureCall', null);
  }

  Future<void> sagaTimeouts() {
    return _invokeFutureCall('TaroDomainCallsSagaTimeoutsFutureCall', null);
  }

  Future<void> cleanup() {
    return _invokeFutureCall('TaroDomainCallsCleanupFutureCall', null);
  }
}

/// Closes the auction [auctionId].
class AuctionCloseCallsCloseFutureCall
    extends _is.FutureCall<_ijzrfwlf.AuctionCloseCallsCloseModel>
    implements _is.InvokableFutureCall<_ijzrfwlf.AuctionCloseCallsCloseModel> {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _ijzrfwlf.AuctionCloseCallsCloseModel? object,
  ) async {
    if (object != null) {
      await _ij043ien.AuctionCloseCalls().close(session, object.auctionId);
    }
  }
}

/// Closes every OPEN auction past its close time, every 5 seconds: the
/// safety net for a restart over a deadline or a lost scheduled close.
class AuctionCloseCallsSweepFutureCall extends _is.FutureCall
    implements _is.InvokableFutureCall {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _is.SerializableModel? object,
  ) async {
    await _ij043ien.AuctionCloseCalls().sweep(session);
  }
}

/// Catches projections and sagas up from the event store.
class TaroDomainCallsCatchUpFutureCall extends _is.FutureCall
    implements _is.InvokableFutureCall {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _is.SerializableModel? object,
  ) async {
    await _ish7r71q.TaroDomainCalls().catchUp(session);
  }
}

/// Times out stuck sagas.
class TaroDomainCallsSagaTimeoutsFutureCall extends _is.FutureCall
    implements _is.InvokableFutureCall {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _is.SerializableModel? object,
  ) async {
    await _ish7r71q.TaroDomainCalls().sagaTimeouts(session);
  }
}

/// Deletes expired idempotency records and dead letters.
class TaroDomainCallsCleanupFutureCall extends _is.FutureCall
    implements _is.InvokableFutureCall {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _is.SerializableModel? object,
  ) async {
    await _ish7r71q.TaroDomainCalls().cleanup(session);
  }
}
