import 'package:tarodomain/tarodomain.dart';
import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart';

import '../generated/protocol.dart';

/// Identifies an [AccountHolder].
class HolderId extends AggregateId {
  /// A new ID.
  HolderId.generate() : super.generate();

  /// An ID read back from storage or a request.
  HolderId.fromExisting(super.uuid) : super.fromExisting();
}

/// Events of an [AccountHolder].
sealed class HolderEvent extends DomainEvent {
  HolderEvent(this.holderId);

  /// The holder the event belongs to.
  final String holderId;
}

/// A holder was registered.
class HolderRegistered extends HolderEvent {
  /// Creates the event.
  HolderRegistered(super.holderId, this.name, this.email);

  /// Rebuilds the event from [toData]'s output.
  factory HolderRegistered.fromData(Map<String, Object?> data) =>
      HolderRegistered(
        data['holderId']! as String,
        data['name']! as String,
        data['email']! as String,
      );

  /// The holder's name.
  final String name;

  /// The holder's email address.
  final String email;

  @override
  String get eventName => 'HolderRegistered';

  @override
  Map<String, Object?> toData() => {
    'holderId': holderId,
    'name': name,
    'email': email,
  };
}

/// A holder's email address changed.
class HolderEmailChanged extends HolderEvent {
  /// Creates the event.
  HolderEmailChanged(super.holderId, this.email);

  /// Rebuilds the event from [toData]'s output.
  factory HolderEmailChanged.fromData(Map<String, Object?> data) =>
      HolderEmailChanged(data['holderId']! as String, data['email']! as String);

  /// The new address.
  final String email;

  @override
  String get eventName => 'HolderEmailChanged';

  @override
  Map<String, Object?> toData() => {'holderId': holderId, 'email': email};
}

/// A bank customer: a state-based aggregate (spec §6.3), stored as a row of
/// `bank_account_holders` instead of as events.
class AccountHolder extends AggregateRoot<HolderId, HolderEvent> {
  /// An empty holder, before its state is set.
  AccountHolder(super.id);

  /// Registers a new holder.
  factory AccountHolder.register(HolderId id, String name, String email) {
    _checkEmail(email);
    return AccountHolder(id)..raise(HolderRegistered(id.uuid, name, email));
  }

  /// The holder stored in [row].
  AccountHolder.fromRow(AccountHolderRow row)
    : super(HolderId.fromExisting(row.id!.uuid)) {
    name = row.name;
    email = row.email;
    restoreVersion(row.version);
  }

  /// The holder's name.
  String name = '';

  /// The holder's email address.
  String email = '';

  /// Changes the email address. Does nothing if it is the same.
  void changeEmail(String email) {
    _checkEmail(email);
    if (email != this.email) raise(HolderEmailChanged(id.uuid, email));
  }

  static void _checkEmail(String email) {
    if (!email.contains('@')) {
      throw CommandValidationError(
        'Not an email address: $email',
        context: {'email': email},
      );
    }
  }

  @override
  void apply(HolderEvent event) => switch (event) {
    HolderRegistered(:final name, :final email) => (
      this.name = name,
      this.email = email,
    ),
    HolderEmailChanged(:final email) => this.email = email,
  };

  @override
  Map<String, Object?> toSnapshot() => {'name': name, 'email': email};

  @override
  void restoreSnapshotState(Map<String, Object?> data) {
    name = data['name']! as String;
    email = data['email']! as String;
  }
}

/// Stores [AccountHolder]s in the app's `bank_account_holders` table.
class AccountHolderRepository
    extends
        ServerpodStateRepository<AccountHolder, HolderId, AccountHolderRow> {
  /// Creates the repository for a runtime.
  AccountHolderRepository(super.context);

  @override
  AccountHolderRow toRow(AccountHolder holder) => AccountHolderRow(
    id: holder.id.value,
    name: holder.name,
    email: holder.email,
    version: holder.version,
  );

  @override
  AccountHolder fromRow(AccountHolderRow row) => AccountHolder.fromRow(row);
}

/// Registers an account holder.
class RegisterHolder extends Command {
  /// Creates the command.
  RegisterHolder(this.holderId, this.name, this.email);

  /// The new holder's ID.
  final HolderId holderId;

  /// The holder's name.
  final String name;

  /// The holder's email address.
  final String email;
}

/// Changes an account holder's email address.
class ChangeHolderEmail extends Command {
  /// Creates the command.
  ChangeHolderEmail(this.holderId, this.email);

  /// The holder.
  final HolderId holderId;

  /// The new address.
  final String email;
}

/// Handles [RegisterHolder] and [ChangeHolderEmail].
class HolderHandler<C extends Command>
    extends AggregateCommandHandler<C, AccountHolder, HolderId> {
  /// Creates the handler.
  HolderHandler(super.repository);

  @override
  Future<void> handle(C command) async {
    switch (command) {
      case RegisterHolder(:final holderId, :final name, :final email):
        if (await exists(holderId)) {
          throw AggregateAlreadyExistsError(
            'Holder $holderId already exists',
            context: {'holderId': holderId.uuid},
          );
        }
        await save(AccountHolder.register(holderId, name, email));
      case ChangeHolderEmail(:final holderId, :final email):
        await save((await load(holderId))..changeEmail(email));
    }
  }
}
