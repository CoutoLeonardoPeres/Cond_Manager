-- Migration: 00021 — Local do problema: Apartamento
ALTER TYPE location_type ADD VALUE IF NOT EXISTS 'apartment';
