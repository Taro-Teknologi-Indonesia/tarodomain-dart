BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "gavel_ledger_entries" ADD COLUMN "buyNow" boolean NOT NULL DEFAULT false;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "gavel_lot_cards" ADD COLUMN "unpaid" boolean NOT NULL DEFAULT false;
ALTER TABLE "gavel_lot_cards" ADD COLUMN "unpaidAt" timestamp without time zone;
ALTER TABLE "gavel_lot_cards" ADD COLUMN "unpaidNote" text;

--
-- MIGRATION VERSION FOR gavel
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('gavel', '20261013191316821', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261013191316821', "timestamp" = now();

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
