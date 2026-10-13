BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "gavel_lot_cards" ADD COLUMN "buyNowPrice" bigint;

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
