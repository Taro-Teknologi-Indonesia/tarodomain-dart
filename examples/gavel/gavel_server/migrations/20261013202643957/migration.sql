BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "gavel_auctions" ADD COLUMN "organizerUserId" text;
CREATE INDEX "gavel_auctions_organizer_close_idx" ON "gavel_auctions" USING btree ("organizerUserId", "closeAt");

--
-- UC-15: fill the creator from the auction's own AuctionCreated event. The
-- payload is the serialized event, with the event's own fields under "data".
--
UPDATE "gavel_auctions" a
SET "organizerUserId" = e."payload"::jsonb -> 'data' ->> 'organizerUserId'
FROM "tarodomain_events" e
WHERE e."eventType" = 'AuctionCreated'
  AND (e."payload"::jsonb -> 'data' ->> 'auctionId')::uuid = a."auctionId"
  AND e."payload"::jsonb -> 'data' ->> 'organizerUserId' IS NOT NULL;

--
-- MIGRATION VERSION FOR gavel
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('gavel', '20261013202643957', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261013202643957', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260924105404509', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924105404509', "timestamp" = now();

--
-- MIGRATION VERSION FOR tarodomain_serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('tarodomain_serverpod', '20261013112101284', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261013112101284', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260924105232991', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924105232991', "timestamp" = now();


COMMIT;
