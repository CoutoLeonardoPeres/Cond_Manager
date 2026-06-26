-- Cond Manager - Novos valores do enum ticket_status (transação isolada)
-- Migration: 00019
-- PostgreSQL exige commit antes de usar valores novos do enum (55P04).

ALTER TYPE ticket_status ADD VALUE IF NOT EXISTS 'waiting_material';
ALTER TYPE ticket_status ADD VALUE IF NOT EXISTS 'in_progress';
ALTER TYPE ticket_status ADD VALUE IF NOT EXISTS 'completed';
