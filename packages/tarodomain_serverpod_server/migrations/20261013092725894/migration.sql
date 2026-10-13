BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "tarodomain_counters" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "value" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "tarodomain_counters_name_idx" ON "tarodomain_counters" USING btree ("name");

--
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
--
CREATE TABLE "tarodomain_subscriptions" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "streamId" text,
    "lastSeen" uuid,
    "lastPosition" bigint,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "tarodomain_subscriptions_name_idx" ON "tarodomain_subscriptions" USING btree ("name");


--
-- MIGRATION VERSION FOR tarodomain_serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('tarodomain_serverpod', '20261013092725894', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261013092725894', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();


COMMIT;
