BEGIN;

--
-- ACTION ALTER TABLE
--
CREATE TABLE "new_tarodomain_subscriptions" (
    "id" INTEGER PRIMARY KEY,
    "name" TEXT NOT NULL,
    "streamId" TEXT,
    "lastSeen" BLOB,
    "lastPosition" INTEGER,
    "createdAt" INTEGER NOT NULL,
    "failedEventId" BLOB,
    "failedAttempts" INTEGER NOT NULL DEFAULT (0)
) STRICT;

INSERT INTO "new_tarodomain_subscriptions" ("id", "name", "streamId", "lastSeen", "lastPosition", "createdAt") SELECT "id", "name", "streamId", "lastSeen", "lastPosition", "createdAt" FROM "tarodomain_subscriptions";
DROP TABLE "tarodomain_subscriptions";
ALTER TABLE "new_tarodomain_subscriptions" RENAME TO "tarodomain_subscriptions";

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
    ('bank_account_balances', 'accountId', 'uuid', NULL),
    ('bank_account_holders', 'id', 'uuid', NULL),
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
-- MIGRATION VERSION FOR bank_account_serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('bank_account_serverpod', '20261013112202714', (unixepoch('now', 'subsecond') * 1000))
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261013112202714', "timestamp" = (unixepoch('now', 'subsecond') * 1000);

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
