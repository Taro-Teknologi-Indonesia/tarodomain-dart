/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_type_check

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/protocol.dart' as _isp;
import 'package:serverpod/serverpod.dart' as _is;
import 'counter_row.dart' as _i4agweee;
import 'dead_letter_row.dart' as _i1pjtv3e;
import 'event_row.dart' as _impat28j;
import 'lock_row.dart' as _ihdw5bhh;
import 'processed_command_row.dart' as _i9cp555t;
import 'processed_event_row.dart' as _izqg2jed;
import 'saga_row.dart' as _i8wwser0;
import 'snapshot_row.dart' as _i7uh1079;
import 'stream_row.dart' as _ievdfapj;
import 'subscription_row.dart' as _ivv7o2v7;
import 'taro_domain_exception.dart' as _iubzmcf6;
export 'counter_row.dart';
export 'dead_letter_row.dart';
export 'event_row.dart';
export 'lock_row.dart';
export 'processed_command_row.dart';
export 'processed_event_row.dart';
export 'saga_row.dart';
export 'snapshot_row.dart';
export 'stream_row.dart';
export 'subscription_row.dart';
export 'taro_domain_exception.dart';

class Protocol extends _is.DatabaseSerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  final Set<_is.SerializationManager> _hostProtocols = {};

  static List<_isp.TableDefinition> get targetTableDefinitions => [
    _isp.TableDefinition(
      name: 'tarodomain_counters',
      dartName: 'TaroCounterRow',
      schema: 'public',
      module: 'tarodomain_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'value',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'tarodomain_counters_name_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'name',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'tarodomain_dead_letters',
      dartName: 'TaroDeadLetterRow',
      schema: 'public',
      module: 'tarodomain_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'handlerName',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'eventId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'event',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'errorMessage',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'errorCode',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'attempts',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'tarodomain_dead_letters_handler_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'handlerName',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'tarodomain_dead_letters_event_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'eventId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'handlerName',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'tarodomain_dead_letters_created_at_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'tarodomain_events',
      dartName: 'TaroEventRow',
      schema: 'public',
      module: 'tarodomain_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'eventId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'streamId',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'category',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'version',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'eventType',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'correlationId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'payload',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'position',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'tarodomain_events_event_id_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'eventId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'tarodomain_events_stream_version_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'streamId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'version',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'tarodomain_events_position_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'position',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'tarodomain_events_category_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'category',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'position',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'tarodomain_events_correlation_id_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'correlationId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'tarodomain_locks',
      dartName: 'TaroLockRow',
      schema: 'public',
      module: 'tarodomain_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'owner',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'lockedUntil',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'tarodomain_locks_name_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'name',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'tarodomain_processed_commands',
      dartName: 'TaroProcessedCommandRow',
      schema: 'public',
      module: 'tarodomain_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'commandId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'commandType',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'handlerName',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'processedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'tarodomain_processed_commands_command_id_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'commandId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'tarodomain_processed_commands_handler_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'handlerName',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'processedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'tarodomain_processed_commands_processed_at_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'processedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'tarodomain_processed_events',
      dartName: 'TaroProcessedEventRow',
      schema: 'public',
      module: 'tarodomain_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'handlerName',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'handlerInstance',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'eventId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'processedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'tarodomain_processed_events_key_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'handlerName',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'handlerInstance',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'eventId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'tarodomain_processed_events_processed_at_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'processedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'tarodomain_sagas',
      dartName: 'TaroSagaRow',
      schema: 'public',
      module: 'tarodomain_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'sagaType',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'sagaId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'correlationId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'state',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'currentStep',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'failureReason',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'startedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'completedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'tarodomain_sagas_type_id_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'sagaType',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'sagaId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'tarodomain_sagas_status_updated_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'status',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'updatedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'tarodomain_snapshots',
      dartName: 'TaroSnapshotRow',
      schema: 'public',
      module: 'tarodomain_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'sourceUuid',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'sourceType',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'sourceVersion',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'data',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'metadata',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'tarodomain_snapshots_source_version_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'sourceUuid',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'sourceVersion',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'tarodomain_streams',
      dartName: 'TaroStreamRow',
      schema: 'public',
      module: 'tarodomain_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'streamId',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'version',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'tarodomain_streams_stream_id_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'streamId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'tarodomain_subscriptions',
      dartName: 'TaroSubscriptionRow',
      schema: 'public',
      module: 'tarodomain_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'streamId',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'lastSeen',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'lastPosition',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'tarodomain_subscriptions_name_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'name',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
  ];

  void registerHostProtocol(
    String projectName,
    _is.SerializationManager protocol,
  ) {
    _hostProtocols.add(protocol);
  }

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    if (className == null) return null;
    if (!className.startsWith('tarodomain_serverpod.')) return className;
    return className.substring(21);
  }

  @override
  T deserialize<T>(dynamic data, [Type? t]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on _is.DeserializationClassNameNotFoundException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i4agweee.TaroCounterRow) {
      return _i4agweee.TaroCounterRow.fromJson(data) as T;
    }
    if (t == _i1pjtv3e.TaroDeadLetterRow) {
      return _i1pjtv3e.TaroDeadLetterRow.fromJson(data) as T;
    }
    if (t == _impat28j.TaroEventRow) {
      return _impat28j.TaroEventRow.fromJson(data) as T;
    }
    if (t == _ihdw5bhh.TaroLockRow) {
      return _ihdw5bhh.TaroLockRow.fromJson(data) as T;
    }
    if (t == _i9cp555t.TaroProcessedCommandRow) {
      return _i9cp555t.TaroProcessedCommandRow.fromJson(data) as T;
    }
    if (t == _izqg2jed.TaroProcessedEventRow) {
      return _izqg2jed.TaroProcessedEventRow.fromJson(data) as T;
    }
    if (t == _i8wwser0.TaroSagaRow) {
      return _i8wwser0.TaroSagaRow.fromJson(data) as T;
    }
    if (t == _i7uh1079.TaroSnapshotRow) {
      return _i7uh1079.TaroSnapshotRow.fromJson(data) as T;
    }
    if (t == _ievdfapj.TaroStreamRow) {
      return _ievdfapj.TaroStreamRow.fromJson(data) as T;
    }
    if (t == _ivv7o2v7.TaroSubscriptionRow) {
      return _ivv7o2v7.TaroSubscriptionRow.fromJson(data) as T;
    }
    if (t == _iubzmcf6.TaroDomainException) {
      return _iubzmcf6.TaroDomainException.fromJson(data) as T;
    }
    if (t == _is.getType<_i4agweee.TaroCounterRow?>()) {
      return (data != null ? _i4agweee.TaroCounterRow.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i1pjtv3e.TaroDeadLetterRow?>()) {
      return (data != null ? _i1pjtv3e.TaroDeadLetterRow.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_impat28j.TaroEventRow?>()) {
      return (data != null ? _impat28j.TaroEventRow.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ihdw5bhh.TaroLockRow?>()) {
      return (data != null ? _ihdw5bhh.TaroLockRow.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i9cp555t.TaroProcessedCommandRow?>()) {
      return (data != null
              ? _i9cp555t.TaroProcessedCommandRow.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_izqg2jed.TaroProcessedEventRow?>()) {
      return (data != null
              ? _izqg2jed.TaroProcessedEventRow.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i8wwser0.TaroSagaRow?>()) {
      return (data != null ? _i8wwser0.TaroSagaRow.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i7uh1079.TaroSnapshotRow?>()) {
      return (data != null ? _i7uh1079.TaroSnapshotRow.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ievdfapj.TaroStreamRow?>()) {
      return (data != null ? _ievdfapj.TaroStreamRow.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ivv7o2v7.TaroSubscriptionRow?>()) {
      return (data != null
              ? _ivv7o2v7.TaroSubscriptionRow.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iubzmcf6.TaroDomainException?>()) {
      return (data != null
              ? _iubzmcf6.TaroDomainException.fromJson(data)
              : null)
          as T;
    }
    try {
      return _isp.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i4agweee.TaroCounterRow => 'TaroCounterRow',
      _i1pjtv3e.TaroDeadLetterRow => 'TaroDeadLetterRow',
      _impat28j.TaroEventRow => 'TaroEventRow',
      _ihdw5bhh.TaroLockRow => 'TaroLockRow',
      _i9cp555t.TaroProcessedCommandRow => 'TaroProcessedCommandRow',
      _izqg2jed.TaroProcessedEventRow => 'TaroProcessedEventRow',
      _i8wwser0.TaroSagaRow => 'TaroSagaRow',
      _i7uh1079.TaroSnapshotRow => 'TaroSnapshotRow',
      _ievdfapj.TaroStreamRow => 'TaroStreamRow',
      _ivv7o2v7.TaroSubscriptionRow => 'TaroSubscriptionRow',
      _iubzmcf6.TaroDomainException => 'TaroDomainException',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst(
        'tarodomain_serverpod.',
        '',
      );
    }

    switch (data) {
      case _i4agweee.TaroCounterRow():
        return 'TaroCounterRow';
      case _i1pjtv3e.TaroDeadLetterRow():
        return 'TaroDeadLetterRow';
      case _impat28j.TaroEventRow():
        return 'TaroEventRow';
      case _ihdw5bhh.TaroLockRow():
        return 'TaroLockRow';
      case _i9cp555t.TaroProcessedCommandRow():
        return 'TaroProcessedCommandRow';
      case _izqg2jed.TaroProcessedEventRow():
        return 'TaroProcessedEventRow';
      case _i8wwser0.TaroSagaRow():
        return 'TaroSagaRow';
      case _i7uh1079.TaroSnapshotRow():
        return 'TaroSnapshotRow';
      case _ievdfapj.TaroStreamRow():
        return 'TaroStreamRow';
      case _ivv7o2v7.TaroSubscriptionRow():
        return 'TaroSubscriptionRow';
      case _iubzmcf6.TaroDomainException():
        return 'TaroDomainException';
    }
    className = _isp.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.') ? className : 'serverpod.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'TaroCounterRow') {
      return deserialize<_i4agweee.TaroCounterRow>(data['data']);
    }
    if (dataClassName == 'TaroDeadLetterRow') {
      return deserialize<_i1pjtv3e.TaroDeadLetterRow>(data['data']);
    }
    if (dataClassName == 'TaroEventRow') {
      return deserialize<_impat28j.TaroEventRow>(data['data']);
    }
    if (dataClassName == 'TaroLockRow') {
      return deserialize<_ihdw5bhh.TaroLockRow>(data['data']);
    }
    if (dataClassName == 'TaroProcessedCommandRow') {
      return deserialize<_i9cp555t.TaroProcessedCommandRow>(data['data']);
    }
    if (dataClassName == 'TaroProcessedEventRow') {
      return deserialize<_izqg2jed.TaroProcessedEventRow>(data['data']);
    }
    if (dataClassName == 'TaroSagaRow') {
      return deserialize<_i8wwser0.TaroSagaRow>(data['data']);
    }
    if (dataClassName == 'TaroSnapshotRow') {
      return deserialize<_i7uh1079.TaroSnapshotRow>(data['data']);
    }
    if (dataClassName == 'TaroStreamRow') {
      return deserialize<_ievdfapj.TaroStreamRow>(data['data']);
    }
    if (dataClassName == 'TaroSubscriptionRow') {
      return deserialize<_ivv7o2v7.TaroSubscriptionRow>(data['data']);
    }
    if (dataClassName == 'TaroDomainException') {
      return deserialize<_iubzmcf6.TaroDomainException>(data['data']);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _isp.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  @override
  Object? dynamicFieldToJson(Object? object, {bool forProtocol = false}) {
    if ((object is List || object is Set || object is Map) ||
        getClassNameForObject(object) != null) {
      return super.dynamicFieldToJson(object, forProtocol: forProtocol);
    }
    for (final protocol in _hostProtocols) {
      final className = protocol.getClassNameForObject(object);
      if (className == null) continue;
      final host = protocol.getModuleName();
      final wrapped = {
        'className': className.contains('.') ? className : '$host.$className',
        'data': object,
      };
      return forProtocol
          ? _is.SerializationManager.toEncodableForProtocol(wrapped)
          : _is.SerializationManager.toEncodable(wrapped);
    }
    return super.dynamicFieldToJson(object, forProtocol: forProtocol);
  }

  @override
  dynamic deserializeDynamicFieldValue(Object? value) {
    if (value == null) return null;
    if (value is! Map<String, dynamic> || value['className'] is! String) {
      throw FormatException(
        'Dynamic fields are encoded as a Map with className and data, but got '
        '${value.runtimeType} instead.',
      );
    }
    final className = value['className'] as String;
    for (final protocol in _hostProtocols) {
      final host = protocol.getModuleName();
      final hostPrefix = '$host.';
      if (className.startsWith(hostPrefix)) {
        final strippedClassName = className.substring(hostPrefix.length);
        if (strippedClassName.contains('.')) {
          throw FormatException(
            'Dynamic field className must not use multiple prefixes: $className',
          );
        }
        final hostData = Map<String, dynamic>.from(value);
        hostData['className'] = strippedClassName;
        return protocol.deserializeByClassName(hostData);
      }
    }
    if (className.contains('.')) {
      for (final protocol in _hostProtocols) {
        try {
          return protocol.deserializeByClassName(value);
        } on _is.DeserializationClassNameNotFoundException catch (_) {}
      }
    }
    return deserializeByClassName(value);
  }

  @override
  _is.Table? getTableForType(Type t) {
    {
      var table = _isp.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _i4agweee.TaroCounterRow:
        return _i4agweee.TaroCounterRow.t;
      case _i1pjtv3e.TaroDeadLetterRow:
        return _i1pjtv3e.TaroDeadLetterRow.t;
      case _impat28j.TaroEventRow:
        return _impat28j.TaroEventRow.t;
      case _ihdw5bhh.TaroLockRow:
        return _ihdw5bhh.TaroLockRow.t;
      case _i9cp555t.TaroProcessedCommandRow:
        return _i9cp555t.TaroProcessedCommandRow.t;
      case _izqg2jed.TaroProcessedEventRow:
        return _izqg2jed.TaroProcessedEventRow.t;
      case _i8wwser0.TaroSagaRow:
        return _i8wwser0.TaroSagaRow.t;
      case _i7uh1079.TaroSnapshotRow:
        return _i7uh1079.TaroSnapshotRow.t;
      case _ievdfapj.TaroStreamRow:
        return _ievdfapj.TaroStreamRow.t;
      case _ivv7o2v7.TaroSubscriptionRow:
        return _ivv7o2v7.TaroSubscriptionRow.t;
    }
    return null;
  }

  @override
  List<_isp.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'tarodomain_serverpod';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _isp.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
