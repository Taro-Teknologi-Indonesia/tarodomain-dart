BEGIN;

--
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- MIGRATION VERSION FOR gavel
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('gavel', '20261013163427557', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261013163427557', "timestamp" = now();

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
