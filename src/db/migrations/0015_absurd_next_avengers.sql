CREATE TYPE "public"."user_themes" AS ENUM('light', 'dark', 'system');--> statement-breakpoint
ALTER TABLE "user" ADD COLUMN "theme" "user_themes" DEFAULT 'light' NOT NULL;