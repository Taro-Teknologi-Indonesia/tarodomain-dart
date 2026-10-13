BEGIN;

--
-- Class AuctionView as table gavel_auctions
--
CREATE TABLE "gavel_auctions" (
    "id" INTEGER PRIMARY KEY,
    "auctionId" BLOB NOT NULL,
    "code" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "closeAt" INTEGER NOT NULL,
    "status" TEXT NOT NULL,
    "lotCount" INTEGER NOT NULL
) STRICT;

-- Indexes
CREATE UNIQUE INDEX "gavel_auctions_code_idx" ON "gavel_auctions" ("code");
CREATE UNIQUE INDEX "gavel_auctions_auction_id_idx" ON "gavel_auctions" ("auctionId");
CREATE INDEX "gavel_auctions_status_close_idx" ON "gavel_auctions" ("status", "closeAt");


--
-- Class CloudStorageEntry as table serverpod_cloud_storage
--
CREATE TABLE "serverpod_cloud_storage" (
    "id" INTEGER PRIMARY KEY,
    "storageId" TEXT NOT NULL,
    "path" TEXT NOT NULL,
    "addedTime" INTEGER NOT NULL,
    "expiration" INTEGER,
    "byteData" BLOB NOT NULL,
    "verified" INTEGER NOT NULL,
    "contentType" TEXT,
    "cacheControl" TEXT,
    "contentDisposition" TEXT,
    "contentEncoding" TEXT,
    "customMetadata" TEXT
) STRICT;

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_path_idx" ON "serverpod_cloud_storage" ("storageId", "path");
CREATE INDEX "serverpod_cloud_storage_expiration" ON "serverpod_cloud_storage" ("expiration");


--
-- Class CloudStorageDirectDownloadEntry as table serverpod_cloud_storage_direct_download
--
CREATE TABLE "serverpod_cloud_storage_direct_download" (
    "id" INTEGER PRIMARY KEY,
    "storageId" TEXT NOT NULL,
    "path" TEXT NOT NULL,
    "expiration" INTEGER NOT NULL,
    "authKey" TEXT NOT NULL,
    "downloadFileName" TEXT,
    "contentType" TEXT
) STRICT;

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_direct_download_auth_key" ON "serverpod_cloud_storage_direct_download" ("authKey");
CREATE INDEX "serverpod_cloud_storage_direct_download_expiration" ON "serverpod_cloud_storage_direct_download" ("expiration");


--
-- Class CloudStorageDirectUploadEntry as table serverpod_cloud_storage_direct_upload
--
CREATE TABLE "serverpod_cloud_storage_direct_upload" (
    "id" INTEGER PRIMARY KEY,
    "storageId" TEXT NOT NULL,
    "path" TEXT NOT NULL,
    "expiration" INTEGER NOT NULL,
    "authKey" TEXT NOT NULL,
    "maxFileSize" INTEGER NOT NULL DEFAULT (10485760),
    "contentLength" INTEGER,
    "preventOverwrite" INTEGER NOT NULL DEFAULT (0),
    "contentType" TEXT,
    "cacheControl" TEXT,
    "contentDisposition" TEXT,
    "contentEncoding" TEXT,
    "customMetadata" TEXT
) STRICT;

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_direct_upload_storage_path" ON "serverpod_cloud_storage_direct_upload" ("storageId", "path");


--
-- Class FutureCallEntry as table serverpod_future_call
--
CREATE TABLE "serverpod_future_call" (
    "id" INTEGER PRIMARY KEY,
    "name" TEXT NOT NULL,
    "time" INTEGER NOT NULL,
    "serializedObject" TEXT,
    "serverId" TEXT NOT NULL,
    "identifier" TEXT,
    "scheduling" TEXT
) STRICT;

-- Indexes
CREATE INDEX "serverpod_future_call_time_idx" ON "serverpod_future_call" ("time");
CREATE INDEX "serverpod_future_call_serverId_idx" ON "serverpod_future_call" ("serverId");
CREATE INDEX "serverpod_future_call_identifier_idx" ON "serverpod_future_call" ("identifier");


--
-- Class FutureCallClaimEntry as table serverpod_future_call_claim
--
CREATE TABLE "serverpod_future_call_claim" (
    "id" INTEGER PRIMARY KEY,
    "futureCallId" INTEGER,
    "lastHeartbeatTime" INTEGER NOT NULL,
    CONSTRAINT "serverpod_future_call_claim_fk_0" FOREIGN KEY ("futureCallId") REFERENCES "serverpod_future_call" ("id") ON DELETE CASCADE ON UPDATE NO ACTION
) STRICT;

-- Indexes
CREATE UNIQUE INDEX "future_call_unique_idx" ON "serverpod_future_call_claim" ("futureCallId");


--
-- Class ServerHealthConnectionInfo as table serverpod_health_connection_info
--
CREATE TABLE "serverpod_health_connection_info" (
    "id" INTEGER PRIMARY KEY,
    "serverId" TEXT NOT NULL,
    "timestamp" INTEGER NOT NULL,
    "active" INTEGER NOT NULL,
    "closing" INTEGER NOT NULL,
    "idle" INTEGER NOT NULL,
    "granularity" INTEGER NOT NULL
) STRICT;

-- Indexes
CREATE UNIQUE INDEX "serverpod_health_connection_info_timestamp_idx" ON "serverpod_health_connection_info" ("timestamp", "serverId", "granularity");


--
-- Class ServerHealthMetric as table serverpod_health_metric
--
CREATE TABLE "serverpod_health_metric" (
    "id" INTEGER PRIMARY KEY,
    "name" TEXT NOT NULL,
    "serverId" TEXT NOT NULL,
    "timestamp" INTEGER NOT NULL,
    "isHealthy" INTEGER NOT NULL,
    "value" REAL NOT NULL,
    "granularity" INTEGER NOT NULL
) STRICT;

-- Indexes
CREATE UNIQUE INDEX "serverpod_health_metric_timestamp_idx" ON "serverpod_health_metric" ("timestamp", "serverId", "name", "granularity");


--
-- Class LogEntry as table serverpod_log
--
CREATE TABLE "serverpod_log" (
    "id" INTEGER PRIMARY KEY,
    "sessionLogId" INTEGER NOT NULL,
    "messageId" INTEGER,
    "reference" TEXT,
    "serverId" TEXT NOT NULL,
    "time" INTEGER NOT NULL,
    "logLevel" INTEGER NOT NULL,
    "message" TEXT NOT NULL,
    "error" TEXT,
    "stackTrace" TEXT,
    "order" INTEGER NOT NULL,
    CONSTRAINT "serverpod_log_fk_0" FOREIGN KEY ("sessionLogId") REFERENCES "serverpod_session_log" ("id") ON DELETE CASCADE ON UPDATE NO ACTION
) STRICT;

-- Indexes
CREATE INDEX "serverpod_log_sessionLogId_idx" ON "serverpod_log" ("sessionLogId", "order");


--
-- Class MessageLogEntry as table serverpod_message_log
--
CREATE TABLE "serverpod_message_log" (
    "id" INTEGER PRIMARY KEY,
    "sessionLogId" INTEGER NOT NULL,
    "serverId" TEXT NOT NULL,
    "messageId" INTEGER NOT NULL,
    "endpoint" TEXT NOT NULL,
    "messageName" TEXT NOT NULL,
    "duration" REAL NOT NULL,
    "error" TEXT,
    "stackTrace" TEXT,
    "slow" INTEGER NOT NULL,
    "order" INTEGER NOT NULL,
    CONSTRAINT "serverpod_message_log_fk_0" FOREIGN KEY ("sessionLogId") REFERENCES "serverpod_session_log" ("id") ON DELETE CASCADE ON UPDATE NO ACTION
) STRICT;

-- Indexes
CREATE INDEX "serverpod_message_log_sessionLogId_idx" ON "serverpod_message_log" ("sessionLogId", "order");


--
-- Class MethodInfo as table serverpod_method
--
CREATE TABLE "serverpod_method" (
    "id" INTEGER PRIMARY KEY,
    "endpoint" TEXT NOT NULL,
    "method" TEXT NOT NULL
) STRICT;

-- Indexes
CREATE UNIQUE INDEX "serverpod_method_endpoint_method_idx" ON "serverpod_method" ("endpoint", "method");


--
-- Class DatabaseMigrationVersion as table serverpod_migrations
--
CREATE TABLE "serverpod_migrations" (
    "id" INTEGER PRIMARY KEY,
    "module" TEXT NOT NULL,
    "version" TEXT NOT NULL,
    "timestamp" INTEGER
) STRICT;

-- Indexes
CREATE UNIQUE INDEX "serverpod_migrations_ids" ON "serverpod_migrations" ("module");


--
-- Class QueryLogEntry as table serverpod_query_log
--
CREATE TABLE "serverpod_query_log" (
    "id" INTEGER PRIMARY KEY,
    "serverId" TEXT NOT NULL,
    "sessionLogId" INTEGER NOT NULL,
    "messageId" INTEGER,
    "query" TEXT NOT NULL,
    "duration" REAL NOT NULL,
    "numRows" INTEGER,
    "error" TEXT,
    "stackTrace" TEXT,
    "slow" INTEGER NOT NULL,
    "order" INTEGER NOT NULL,
    CONSTRAINT "serverpod_query_log_fk_0" FOREIGN KEY ("sessionLogId") REFERENCES "serverpod_session_log" ("id") ON DELETE CASCADE ON UPDATE NO ACTION
) STRICT;

-- Indexes
CREATE INDEX "serverpod_query_log_sessionLogId_idx" ON "serverpod_query_log" ("sessionLogId", "order");


--
-- Class ReadWriteTestEntry as table serverpod_readwrite_test
--
CREATE TABLE "serverpod_readwrite_test" (
    "id" INTEGER PRIMARY KEY,
    "number" INTEGER NOT NULL
) STRICT;


--
-- Class RuntimeSettings as table serverpod_runtime_settings
--
CREATE TABLE "serverpod_runtime_settings" (
    "id" INTEGER PRIMARY KEY,
    "logSettings" TEXT NOT NULL,
    "logSettingsOverrides" TEXT NOT NULL,
    "logServiceCalls" INTEGER NOT NULL,
    "logMalformedCalls" INTEGER NOT NULL
) STRICT;


--
-- Class SessionLogEntry as table serverpod_session_log
--
CREATE TABLE "serverpod_session_log" (
    "id" INTEGER PRIMARY KEY,
    "serverId" TEXT NOT NULL,
    "time" INTEGER NOT NULL,
    "module" TEXT,
    "endpoint" TEXT,
    "method" TEXT,
    "duration" REAL,
    "numQueries" INTEGER,
    "slow" INTEGER,
    "error" TEXT,
    "stackTrace" TEXT,
    "authenticatedUserId" INTEGER,
    "userId" TEXT,
    "isOpen" INTEGER,
    "touched" INTEGER NOT NULL
) STRICT;

-- Indexes
CREATE INDEX "serverpod_session_log_serverid_idx" ON "serverpod_session_log" ("serverId");
CREATE INDEX "serverpod_session_log_time_idx" ON "serverpod_session_log" ("time");
CREATE INDEX "serverpod_session_log_touched_idx" ON "serverpod_session_log" ("touched");
CREATE INDEX "serverpod_session_log_isopen_idx" ON "serverpod_session_log" ("isOpen");


--
-- Class TaroCounterRow as table tarodomain_counters
--
CREATE TABLE "tarodomain_counters" (
    "id" INTEGER PRIMARY KEY,
    "name" TEXT NOT NULL,
    "value" INTEGER NOT NULL
) STRICT;

-- Indexes
CREATE UNIQUE INDEX "tarodomain_counters_name_idx" ON "tarodomain_counters" ("name");


--
-- Class TaroDeadLetterRow as table tarodomain_dead_letters
--
CREATE TABLE "tarodomain_dead_letters" (
    "id" INTEGER PRIMARY KEY,
    "handlerName" TEXT NOT NULL,
    "eventId" BLOB NOT NULL,
    "event" TEXT NOT NULL,
    "errorMessage" TEXT NOT NULL,
    "errorCode" TEXT,
    "attempts" INTEGER NOT NULL,
    "createdAt" INTEGER NOT NULL
) STRICT;

-- Indexes
CREATE INDEX "tarodomain_dead_letters_handler_idx" ON "tarodomain_dead_letters" ("handlerName", "createdAt");
CREATE INDEX "tarodomain_dead_letters_event_idx" ON "tarodomain_dead_letters" ("eventId", "handlerName");
CREATE INDEX "tarodomain_dead_letters_created_at_idx" ON "tarodomain_dead_letters" ("createdAt");


--
-- Class TaroEventRow as table tarodomain_events
--
CREATE TABLE "tarodomain_events" (
    "id" INTEGER PRIMARY KEY,
    "eventId" BLOB NOT NULL,
    "streamId" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "version" INTEGER NOT NULL,
    "eventType" TEXT NOT NULL,
    "correlationId" BLOB NOT NULL,
    "payload" TEXT NOT NULL,
    "position" INTEGER
) STRICT;

-- Indexes
CREATE UNIQUE INDEX "tarodomain_events_event_id_idx" ON "tarodomain_events" ("eventId");
CREATE UNIQUE INDEX "tarodomain_events_stream_version_idx" ON "tarodomain_events" ("streamId", "version");
CREATE UNIQUE INDEX "tarodomain_events_position_idx" ON "tarodomain_events" ("position");
CREATE INDEX "tarodomain_events_category_idx" ON "tarodomain_events" ("category", "position");
CREATE INDEX "tarodomain_events_correlation_id_idx" ON "tarodomain_events" ("correlationId");


--
-- Class TaroLockRow as table tarodomain_locks
--
CREATE TABLE "tarodomain_locks" (
    "id" INTEGER PRIMARY KEY,
    "name" TEXT NOT NULL,
    "owner" TEXT NOT NULL,
    "lockedUntil" INTEGER NOT NULL
) STRICT;

-- Indexes
CREATE UNIQUE INDEX "tarodomain_locks_name_idx" ON "tarodomain_locks" ("name");


--
-- Class TaroProcessedCommandRow as table tarodomain_processed_commands
--
CREATE TABLE "tarodomain_processed_commands" (
    "id" INTEGER PRIMARY KEY,
    "commandId" BLOB NOT NULL,
    "commandType" TEXT NOT NULL,
    "handlerName" TEXT NOT NULL,
    "processedAt" INTEGER NOT NULL
) STRICT;

-- Indexes
CREATE UNIQUE INDEX "tarodomain_processed_commands_command_id_idx" ON "tarodomain_processed_commands" ("commandId");
CREATE INDEX "tarodomain_processed_commands_handler_idx" ON "tarodomain_processed_commands" ("handlerName", "processedAt");
CREATE INDEX "tarodomain_processed_commands_processed_at_idx" ON "tarodomain_processed_commands" ("processedAt");


--
-- Class TaroProcessedEventRow as table tarodomain_processed_events
--
CREATE TABLE "tarodomain_processed_events" (
    "id" INTEGER PRIMARY KEY,
    "handlerName" TEXT NOT NULL,
    "handlerInstance" TEXT NOT NULL,
    "eventId" BLOB NOT NULL,
    "processedAt" INTEGER NOT NULL
) STRICT;

-- Indexes
CREATE UNIQUE INDEX "tarodomain_processed_events_key_idx" ON "tarodomain_processed_events" ("handlerName", "handlerInstance", "eventId");
CREATE INDEX "tarodomain_processed_events_processed_at_idx" ON "tarodomain_processed_events" ("processedAt");


--
-- Class TaroSagaRow as table tarodomain_sagas
--
CREATE TABLE "tarodomain_sagas" (
    "id" INTEGER PRIMARY KEY,
    "sagaType" TEXT NOT NULL,
    "sagaId" BLOB NOT NULL,
    "correlationId" BLOB NOT NULL,
    "state" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "currentStep" TEXT,
    "failureReason" TEXT,
    "startedAt" INTEGER NOT NULL,
    "updatedAt" INTEGER NOT NULL,
    "completedAt" INTEGER
) STRICT;

-- Indexes
CREATE UNIQUE INDEX "tarodomain_sagas_type_id_idx" ON "tarodomain_sagas" ("sagaType", "sagaId");
CREATE INDEX "tarodomain_sagas_status_updated_idx" ON "tarodomain_sagas" ("status", "updatedAt");


--
-- Class TaroSnapshotRow as table tarodomain_snapshots
--
CREATE TABLE "tarodomain_snapshots" (
    "id" INTEGER PRIMARY KEY,
    "sourceUuid" BLOB NOT NULL,
    "sourceType" TEXT NOT NULL,
    "sourceVersion" INTEGER NOT NULL,
    "data" TEXT NOT NULL,
    "metadata" TEXT NOT NULL,
    "createdAt" INTEGER NOT NULL
) STRICT;

-- Indexes
CREATE UNIQUE INDEX "tarodomain_snapshots_source_version_idx" ON "tarodomain_snapshots" ("sourceUuid", "sourceVersion");


--
-- Class TaroStreamRow as table tarodomain_streams
--
CREATE TABLE "tarodomain_streams" (
    "id" INTEGER PRIMARY KEY,
    "streamId" TEXT NOT NULL,
    "version" INTEGER NOT NULL,
    "createdAt" INTEGER NOT NULL,
    "updatedAt" INTEGER NOT NULL
) STRICT;

-- Indexes
CREATE UNIQUE INDEX "tarodomain_streams_stream_id_idx" ON "tarodomain_streams" ("streamId");


--
-- Class TaroSubscriptionRow as table tarodomain_subscriptions
--
CREATE TABLE "tarodomain_subscriptions" (
    "id" INTEGER PRIMARY KEY,
    "name" TEXT NOT NULL,
    "streamId" TEXT,
    "lastSeen" BLOB,
    "lastPosition" INTEGER,
    "createdAt" INTEGER NOT NULL,
    "failedEventId" BLOB,
    "failedAttempts" INTEGER NOT NULL DEFAULT (0)
) STRICT;

-- Indexes
CREATE UNIQUE INDEX "tarodomain_subscriptions_name_idx" ON "tarodomain_subscriptions" ("name");


--
-- STORE COLUMN TYPES FOR MIGRATIONS
--
DROP TABLE IF EXISTS "serverpod_sqlite_schema";

CREATE TABLE "serverpod_sqlite_schema" (
    "table_name" TEXT NOT NULL,
    "column_name" TEXT NOT NULL,
    "column_type" TEXT NOT NULL,
    "column_vector_dimension" INTEGER,
    PRIMARY KEY ("table_name", "column_name")
);

INSERT INTO "serverpod_sqlite_schema" VALUES
    ('gavel_auctions', 'auctionId', 'uuid', NULL),
    ('gavel_auctions', 'closeAt', 'timestampWithoutTimeZone', NULL),
    ('serverpod_cloud_storage', 'addedTime', 'timestampWithoutTimeZone', NULL),
    ('serverpod_cloud_storage', 'expiration', 'timestampWithoutTimeZone', NULL),
    ('serverpod_cloud_storage', 'verified', 'boolean', NULL),
    ('serverpod_cloud_storage_direct_download', 'expiration', 'timestampWithoutTimeZone', NULL),
    ('serverpod_cloud_storage_direct_upload', 'expiration', 'timestampWithoutTimeZone', NULL),
    ('serverpod_cloud_storage_direct_upload', 'preventOverwrite', 'boolean', NULL),
    ('serverpod_future_call', 'time', 'timestampWithoutTimeZone', NULL),
    ('serverpod_future_call', 'scheduling', 'json', NULL),
    ('serverpod_future_call_claim', 'lastHeartbeatTime', 'timestampWithoutTimeZone', NULL),
    ('serverpod_health_connection_info', 'timestamp', 'timestampWithoutTimeZone', NULL),
    ('serverpod_health_metric', 'timestamp', 'timestampWithoutTimeZone', NULL),
    ('serverpod_health_metric', 'isHealthy', 'boolean', NULL),
    ('serverpod_log', 'time', 'timestampWithoutTimeZone', NULL),
    ('serverpod_message_log', 'slow', 'boolean', NULL),
    ('serverpod_migrations', 'timestamp', 'timestampWithoutTimeZone', NULL),
    ('serverpod_query_log', 'slow', 'boolean', NULL),
    ('serverpod_runtime_settings', 'logSettings', 'json', NULL),
    ('serverpod_runtime_settings', 'logSettingsOverrides', 'json', NULL),
    ('serverpod_runtime_settings', 'logServiceCalls', 'boolean', NULL),
    ('serverpod_runtime_settings', 'logMalformedCalls', 'boolean', NULL),
    ('serverpod_session_log', 'time', 'timestampWithoutTimeZone', NULL),
    ('serverpod_session_log', 'slow', 'boolean', NULL),
    ('serverpod_session_log', 'isOpen', 'boolean', NULL),
    ('serverpod_session_log', 'touched', 'timestampWithoutTimeZone', NULL),
    ('tarodomain_dead_letters', 'eventId', 'uuid', NULL),
    ('tarodomain_dead_letters', 'createdAt', 'timestampWithoutTimeZone', NULL),
    ('tarodomain_events', 'eventId', 'uuid', NULL),
    ('tarodomain_events', 'correlationId', 'uuid', NULL),
    ('tarodomain_locks', 'lockedUntil', 'timestampWithoutTimeZone', NULL),
    ('tarodomain_processed_commands', 'commandId', 'uuid', NULL),
    ('tarodomain_processed_commands', 'processedAt', 'timestampWithoutTimeZone', NULL),
    ('tarodomain_processed_events', 'eventId', 'uuid', NULL),
    ('tarodomain_processed_events', 'processedAt', 'timestampWithoutTimeZone', NULL),
    ('tarodomain_sagas', 'sagaId', 'uuid', NULL),
    ('tarodomain_sagas', 'correlationId', 'uuid', NULL),
    ('tarodomain_sagas', 'startedAt', 'timestampWithoutTimeZone', NULL),
    ('tarodomain_sagas', 'updatedAt', 'timestampWithoutTimeZone', NULL),
    ('tarodomain_sagas', 'completedAt', 'timestampWithoutTimeZone', NULL),
    ('tarodomain_snapshots', 'sourceUuid', 'uuid', NULL),
    ('tarodomain_snapshots', 'createdAt', 'timestampWithoutTimeZone', NULL),
    ('tarodomain_streams', 'createdAt', 'timestampWithoutTimeZone', NULL),
    ('tarodomain_streams', 'updatedAt', 'timestampWithoutTimeZone', NULL),
    ('tarodomain_subscriptions', 'lastSeen', 'uuid', NULL),
    ('tarodomain_subscriptions', 'createdAt', 'timestampWithoutTimeZone', NULL),
    ('tarodomain_subscriptions', 'failedEventId', 'uuid', NULL);

--
-- MIGRATION VERSION FOR gavel
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('gavel', '20261013133221734', (unixepoch('now', 'subsecond') * 1000))
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261013133221734', "timestamp" = (unixepoch('now', 'subsecond') * 1000);

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', (unixepoch('now', 'subsecond') * 1000))
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = (unixepoch('now', 'subsecond') * 1000);

--
-- MIGRATION VERSION FOR tarodomain_serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('tarodomain_serverpod', '20261013112101284', (unixepoch('now', 'subsecond') * 1000))
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261013112101284', "timestamp" = (unixepoch('now', 'subsecond') * 1000);


COMMIT;
