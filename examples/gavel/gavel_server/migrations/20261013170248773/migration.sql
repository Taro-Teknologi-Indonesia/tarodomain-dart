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
-- ACTION CREATE TABLE
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
-- MIGRATION VERSION FOR gavel
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('gavel', '20261013170248773', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261013170248773', "timestamp" = now();

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
