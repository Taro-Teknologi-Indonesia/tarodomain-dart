BEGIN;

--
-- Function: gen_random_uuid_v7()
-- Source: https://gist.github.com/kjmph/5bd772b2c2df145aa645b837da7eca74
-- License: MIT (copyright notice included on the generator source code).
--
create or replace function gen_random_uuid_v7()
returns uuid
as $$
begin
  -- use random v4 uuid as starting point (which has the same variant we need)
  -- then overlay timestamp
  -- then set version 7 by flipping the 2 and 1 bit in the version 4 string
  return encode(
    set_bit(
      set_bit(
        overlay(uuid_send(gen_random_uuid())
                placing substring(int8send(floor(extract(epoch from clock_timestamp()) * 1000)::bigint) from 3)
                from 1 for 6
        ),
        52, 1
      ),
      53, 1
    ),
    'hex')::uuid;
end
$$
language plpgsql
volatile;

--
-- Class AuctionView as table gavel_auctions
--
CREATE TABLE "gavel_auctions" (
    "id" bigserial PRIMARY KEY,
    "auctionId" uuid NOT NULL,
    "code" text NOT NULL,
    "title" text NOT NULL,
    "closeAt" timestamp without time zone NOT NULL,
    "status" text NOT NULL,
    "lotCount" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "gavel_auctions_code_idx" ON "gavel_auctions" USING btree ("code");
CREATE UNIQUE INDEX "gavel_auctions_auction_id_idx" ON "gavel_auctions" USING btree ("auctionId");
CREATE INDEX "gavel_auctions_status_close_idx" ON "gavel_auctions" USING btree ("status", "closeAt");

--
-- Class LedgerEntry as table gavel_ledger_entries
--
CREATE TABLE "gavel_ledger_entries" (
    "id" bigserial PRIMARY KEY,
    "lotId" uuid NOT NULL,
    "sequence" bigint NOT NULL,
    "participantId" uuid NOT NULL,
    "bidderName" text NOT NULL,
    "amount" bigint NOT NULL,
    "placedAt" timestamp without time zone NOT NULL,
    "retracted" boolean NOT NULL,
    "retractedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "gavel_ledger_lot_seq_idx" ON "gavel_ledger_entries" USING btree ("lotId", "sequence");

--
-- Class LotCard as table gavel_lot_cards
--
CREATE TABLE "gavel_lot_cards" (
    "id" bigserial PRIMARY KEY,
    "lotId" uuid NOT NULL,
    "auctionId" uuid NOT NULL,
    "code" text NOT NULL,
    "position" bigint NOT NULL,
    "name" text NOT NULL,
    "description" text NOT NULL,
    "imageUrl" text,
    "tileEmoji" text NOT NULL,
    "tileColor" text NOT NULL,
    "openBid" bigint NOT NULL,
    "increments" json NOT NULL,
    "buyNowPrice" bigint,
    "currentPrice" bigint NOT NULL,
    "leaderId" uuid,
    "leaderName" text,
    "bidCount" bigint NOT NULL,
    "status" text NOT NULL,
    "version" bigint NOT NULL,
    "winnerName" text,
    "finalPrice" bigint,
    "closeCause" text,
    "closedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "gavel_lot_cards_lot_idx" ON "gavel_lot_cards" USING btree ("lotId");
CREATE INDEX "gavel_lot_cards_code_idx" ON "gavel_lot_cards" USING btree ("code", "position");

--
-- Class ParticipantRow as table gavel_participants
--
CREATE TABLE "gavel_participants" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "auctionId" uuid NOT NULL,
    "displayName" text NOT NULL,
    "keyHash" text NOT NULL,
    "version" bigint NOT NULL
);

-- Indexes
CREATE INDEX "gavel_participants_auction_idx" ON "gavel_participants" USING btree ("auctionId");

--
-- Class CloudStorageEntry as table serverpod_cloud_storage
--
CREATE TABLE "serverpod_cloud_storage" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "addedTime" timestamp without time zone NOT NULL,
    "expiration" timestamp without time zone,
    "byteData" bytea NOT NULL,
    "verified" boolean NOT NULL,
    "contentType" text,
    "cacheControl" text,
    "contentDisposition" text,
    "contentEncoding" text,
    "customMetadata" text
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_path_idx" ON "serverpod_cloud_storage" USING btree ("storageId", "path");
CREATE INDEX "serverpod_cloud_storage_expiration" ON "serverpod_cloud_storage" USING btree ("expiration");

--
-- Class CloudStorageDirectDownloadEntry as table serverpod_cloud_storage_direct_download
--
CREATE TABLE "serverpod_cloud_storage_direct_download" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "expiration" timestamp without time zone NOT NULL,
    "authKey" text NOT NULL,
    "downloadFileName" text,
    "contentType" text
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_direct_download_auth_key" ON "serverpod_cloud_storage_direct_download" USING btree ("authKey");
CREATE INDEX "serverpod_cloud_storage_direct_download_expiration" ON "serverpod_cloud_storage_direct_download" USING btree ("expiration");

--
-- Class CloudStorageDirectUploadEntry as table serverpod_cloud_storage_direct_upload
--
CREATE TABLE "serverpod_cloud_storage_direct_upload" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "expiration" timestamp without time zone NOT NULL,
    "authKey" text NOT NULL,
    "maxFileSize" bigint NOT NULL DEFAULT 10485760,
    "contentLength" bigint,
    "preventOverwrite" boolean NOT NULL DEFAULT false,
    "contentType" text,
    "cacheControl" text,
    "contentDisposition" text,
    "contentEncoding" text,
    "customMetadata" text
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_direct_upload_storage_path" ON "serverpod_cloud_storage_direct_upload" USING btree ("storageId", "path");

--
-- Class FutureCallEntry as table serverpod_future_call
--
CREATE TABLE "serverpod_future_call" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "serializedObject" text,
    "serverId" text NOT NULL,
    "identifier" text,
    "scheduling" json
);

-- Indexes
CREATE INDEX "serverpod_future_call_time_idx" ON "serverpod_future_call" USING btree ("time");
CREATE INDEX "serverpod_future_call_serverId_idx" ON "serverpod_future_call" USING btree ("serverId");
CREATE INDEX "serverpod_future_call_identifier_idx" ON "serverpod_future_call" USING btree ("identifier");

--
-- Class FutureCallClaimEntry as table serverpod_future_call_claim
--
CREATE TABLE "serverpod_future_call_claim" (
    "id" bigserial PRIMARY KEY,
    "futureCallId" bigint,
    "lastHeartbeatTime" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "future_call_unique_idx" ON "serverpod_future_call_claim" USING btree ("futureCallId");

--
-- Class ServerHealthConnectionInfo as table serverpod_health_connection_info
--
CREATE TABLE "serverpod_health_connection_info" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "active" bigint NOT NULL,
    "closing" bigint NOT NULL,
    "idle" bigint NOT NULL,
    "granularity" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_health_connection_info_timestamp_idx" ON "serverpod_health_connection_info" USING btree ("timestamp", "serverId", "granularity");

--
-- Class ServerHealthMetric as table serverpod_health_metric
--
CREATE TABLE "serverpod_health_metric" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "isHealthy" boolean NOT NULL,
    "value" double precision NOT NULL,
    "granularity" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_health_metric_timestamp_idx" ON "serverpod_health_metric" USING btree ("timestamp", "serverId", "name", "granularity");

--
-- Class LogEntry as table serverpod_log
--
CREATE TABLE "serverpod_log" (
    "id" bigserial PRIMARY KEY,
    "sessionLogId" bigint NOT NULL,
    "messageId" bigint,
    "reference" text,
    "serverId" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "logLevel" bigint NOT NULL,
    "message" text NOT NULL,
    "error" text,
    "stackTrace" text,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_log_sessionLogId_idx" ON "serverpod_log" USING btree ("sessionLogId", "order");

--
-- Class MessageLogEntry as table serverpod_message_log
--
CREATE TABLE "serverpod_message_log" (
    "id" bigserial PRIMARY KEY,
    "sessionLogId" bigint NOT NULL,
    "serverId" text NOT NULL,
    "messageId" bigint NOT NULL,
    "endpoint" text NOT NULL,
    "messageName" text NOT NULL,
    "duration" double precision NOT NULL,
    "error" text,
    "stackTrace" text,
    "slow" boolean NOT NULL,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_message_log_sessionLogId_idx" ON "serverpod_message_log" USING btree ("sessionLogId", "order");

--
-- Class MethodInfo as table serverpod_method
--
CREATE TABLE "serverpod_method" (
    "id" bigserial PRIMARY KEY,
    "endpoint" text NOT NULL,
    "method" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_method_endpoint_method_idx" ON "serverpod_method" USING btree ("endpoint", "method");

--
-- Class DatabaseMigrationVersion as table serverpod_migrations
--
CREATE TABLE "serverpod_migrations" (
    "id" bigserial PRIMARY KEY,
    "module" text NOT NULL,
    "version" text NOT NULL,
    "timestamp" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_migrations_ids" ON "serverpod_migrations" USING btree ("module");

--
-- Class QueryLogEntry as table serverpod_query_log
--
CREATE TABLE "serverpod_query_log" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "sessionLogId" bigint NOT NULL,
    "messageId" bigint,
    "query" text NOT NULL,
    "duration" double precision NOT NULL,
    "numRows" bigint,
    "error" text,
    "stackTrace" text,
    "slow" boolean NOT NULL,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_query_log_sessionLogId_idx" ON "serverpod_query_log" USING btree ("sessionLogId", "order");

--
-- Class ReadWriteTestEntry as table serverpod_readwrite_test
--
CREATE TABLE "serverpod_readwrite_test" (
    "id" bigserial PRIMARY KEY,
    "number" bigint NOT NULL
);

--
-- Class RuntimeSettings as table serverpod_runtime_settings
--
CREATE TABLE "serverpod_runtime_settings" (
    "id" bigserial PRIMARY KEY,
    "logSettings" json NOT NULL,
    "logSettingsOverrides" json NOT NULL,
    "logServiceCalls" boolean NOT NULL,
    "logMalformedCalls" boolean NOT NULL
);

--
-- Class SessionLogEntry as table serverpod_session_log
--
CREATE TABLE "serverpod_session_log" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "module" text,
    "endpoint" text,
    "method" text,
    "duration" double precision,
    "numQueries" bigint,
    "slow" boolean,
    "error" text,
    "stackTrace" text,
    "authenticatedUserId" bigint,
    "userId" text,
    "isOpen" boolean,
    "touched" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_session_log_serverid_idx" ON "serverpod_session_log" USING btree ("serverId");
CREATE INDEX "serverpod_session_log_time_idx" ON "serverpod_session_log" USING btree ("time");
CREATE INDEX "serverpod_session_log_touched_idx" ON "serverpod_session_log" USING btree ("touched");
CREATE INDEX "serverpod_session_log_isopen_idx" ON "serverpod_session_log" USING btree ("isOpen");

--
-- Class TaroCounterRow as table tarodomain_counters
--
CREATE TABLE "tarodomain_counters" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "value" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "tarodomain_counters_name_idx" ON "tarodomain_counters" USING btree ("name");

--
-- Class TaroDeadLetterRow as table tarodomain_dead_letters
--
CREATE TABLE "tarodomain_dead_letters" (
    "id" bigserial PRIMARY KEY,
    "handlerName" text NOT NULL,
    "eventId" uuid NOT NULL,
    "event" text NOT NULL,
    "errorMessage" text NOT NULL,
    "errorCode" text,
    "attempts" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "tarodomain_dead_letters_handler_idx" ON "tarodomain_dead_letters" USING btree ("handlerName", "createdAt");
CREATE INDEX "tarodomain_dead_letters_event_idx" ON "tarodomain_dead_letters" USING btree ("eventId", "handlerName");
CREATE INDEX "tarodomain_dead_letters_created_at_idx" ON "tarodomain_dead_letters" USING btree ("createdAt");

--
-- Class TaroEventRow as table tarodomain_events
--
CREATE TABLE "tarodomain_events" (
    "id" bigserial PRIMARY KEY,
    "eventId" uuid NOT NULL,
    "streamId" text NOT NULL,
    "category" text NOT NULL,
    "version" bigint NOT NULL,
    "eventType" text NOT NULL,
    "correlationId" uuid NOT NULL,
    "payload" text NOT NULL,
    "position" bigint
);

-- Indexes
CREATE UNIQUE INDEX "tarodomain_events_event_id_idx" ON "tarodomain_events" USING btree ("eventId");
CREATE UNIQUE INDEX "tarodomain_events_stream_version_idx" ON "tarodomain_events" USING btree ("streamId", "version");
CREATE UNIQUE INDEX "tarodomain_events_position_idx" ON "tarodomain_events" USING btree ("position");
CREATE INDEX "tarodomain_events_category_idx" ON "tarodomain_events" USING btree ("category", "position");
CREATE INDEX "tarodomain_events_correlation_id_idx" ON "tarodomain_events" USING btree ("correlationId");

--
-- Class TaroLockRow as table tarodomain_locks
--
CREATE TABLE "tarodomain_locks" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "owner" text NOT NULL,
    "lockedUntil" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "tarodomain_locks_name_idx" ON "tarodomain_locks" USING btree ("name");

--
-- Class TaroProcessedCommandRow as table tarodomain_processed_commands
--
CREATE TABLE "tarodomain_processed_commands" (
    "id" bigserial PRIMARY KEY,
    "commandId" uuid NOT NULL,
    "commandType" text NOT NULL,
    "handlerName" text NOT NULL,
    "processedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "tarodomain_processed_commands_command_id_idx" ON "tarodomain_processed_commands" USING btree ("commandId");
CREATE INDEX "tarodomain_processed_commands_handler_idx" ON "tarodomain_processed_commands" USING btree ("handlerName", "processedAt");
CREATE INDEX "tarodomain_processed_commands_processed_at_idx" ON "tarodomain_processed_commands" USING btree ("processedAt");

--
-- Class TaroProcessedEventRow as table tarodomain_processed_events
--
CREATE TABLE "tarodomain_processed_events" (
    "id" bigserial PRIMARY KEY,
    "handlerName" text NOT NULL,
    "handlerInstance" text NOT NULL,
    "eventId" uuid NOT NULL,
    "processedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "tarodomain_processed_events_key_idx" ON "tarodomain_processed_events" USING btree ("handlerName", "handlerInstance", "eventId");
CREATE INDEX "tarodomain_processed_events_processed_at_idx" ON "tarodomain_processed_events" USING btree ("processedAt");

--
-- Class TaroSagaRow as table tarodomain_sagas
--
CREATE TABLE "tarodomain_sagas" (
    "id" bigserial PRIMARY KEY,
    "sagaType" text NOT NULL,
    "sagaId" uuid NOT NULL,
    "correlationId" uuid NOT NULL,
    "state" text NOT NULL,
    "status" text NOT NULL,
    "currentStep" text,
    "failureReason" text,
    "startedAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "completedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "tarodomain_sagas_type_id_idx" ON "tarodomain_sagas" USING btree ("sagaType", "sagaId");
CREATE INDEX "tarodomain_sagas_status_updated_idx" ON "tarodomain_sagas" USING btree ("status", "updatedAt");

--
-- Class TaroSnapshotRow as table tarodomain_snapshots
--
CREATE TABLE "tarodomain_snapshots" (
    "id" bigserial PRIMARY KEY,
    "sourceUuid" uuid NOT NULL,
    "sourceType" text NOT NULL,
    "sourceVersion" bigint NOT NULL,
    "data" text NOT NULL,
    "metadata" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "tarodomain_snapshots_source_version_idx" ON "tarodomain_snapshots" USING btree ("sourceUuid", "sourceVersion");

--
-- Class TaroStreamRow as table tarodomain_streams
--
CREATE TABLE "tarodomain_streams" (
    "id" bigserial PRIMARY KEY,
    "streamId" text NOT NULL,
    "version" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "tarodomain_streams_stream_id_idx" ON "tarodomain_streams" USING btree ("streamId");

--
-- Class TaroSubscriptionRow as table tarodomain_subscriptions
--
CREATE TABLE "tarodomain_subscriptions" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "streamId" text,
    "lastSeen" uuid,
    "lastPosition" bigint,
    "createdAt" timestamp without time zone NOT NULL,
    "failedEventId" uuid,
    "failedAttempts" bigint NOT NULL DEFAULT 0
);

-- Indexes
CREATE UNIQUE INDEX "tarodomain_subscriptions_name_idx" ON "tarodomain_subscriptions" USING btree ("name");

--
-- Foreign relations for "serverpod_future_call_claim" table
--
ALTER TABLE ONLY "serverpod_future_call_claim"
    ADD CONSTRAINT "serverpod_future_call_claim_fk_0"
    FOREIGN KEY("futureCallId")
    REFERENCES "serverpod_future_call"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_log" table
--
ALTER TABLE ONLY "serverpod_log"
    ADD CONSTRAINT "serverpod_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_message_log" table
--
ALTER TABLE ONLY "serverpod_message_log"
    ADD CONSTRAINT "serverpod_message_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_query_log" table
--
ALTER TABLE ONLY "serverpod_query_log"
    ADD CONSTRAINT "serverpod_query_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR gavel
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('gavel', '20261013173050599', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261013173050599', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();

--
-- MIGRATION VERSION FOR tarodomain_serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('tarodomain_serverpod', '20261013112101284', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261013112101284', "timestamp" = now();


COMMIT;
