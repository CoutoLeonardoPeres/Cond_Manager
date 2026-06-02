-- Cond Manager - Extensions and Enums
-- Migration: 00001

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Perfis de usuário da plataforma
CREATE TYPE user_role AS ENUM (
  'platform_admin',
  'condominium_admin',
  'syndic',
  'caretaker',
  'maintenance_manager',
  'internal_employee',
  'service_provider',
  'supplier',
  'resident',
  'financial',
  'auditor'
);

CREATE TYPE entity_status AS ENUM (
  'active',
  'inactive',
  'blocked',
  'pending'
);

CREATE TYPE service_type AS ENUM (
  'electrical',
  'plumbing',
  'mechanical',
  'masonry',
  'painting',
  'gates',
  'access_control',
  'cctv',
  'intercom',
  'cleaning',
  'water_tank',
  'lighting',
  'landscaping',
  'elevators',
  'pumps',
  'pool',
  'roof',
  'waterproofing',
  'other'
);

CREATE TYPE priority_level AS ENUM (
  'low',
  'medium',
  'high',
  'urgent'
);

CREATE TYPE ticket_status AS ENUM (
  'open',
  'in_analysis',
  'waiting_info',
  'converted_to_os',
  'resolved',
  'cancelled'
);

CREATE TYPE work_order_status AS ENUM (
  'open',
  'triage',
  'waiting_budget',
  'budget_received',
  'waiting_approval',
  'approved',
  'in_progress',
  'paused',
  'waiting_material',
  'completed',
  'rejected',
  'cancelled',
  'closed'
);

CREATE TYPE preventive_frequency AS ENUM (
  'daily',
  'weekly',
  'monthly',
  'quarterly',
  'semiannual',
  'annual'
);

CREATE TYPE provider_type AS ENUM (
  'supplier',
  'outsourced',
  'subcontracted',
  'internal_team'
);

CREATE TYPE approval_type AS ENUM (
  'budget',
  'execution',
  'closure'
);

CREATE TYPE approval_status AS ENUM (
  'pending',
  'approved',
  'rejected'
);

CREATE TYPE attachment_phase AS ENUM (
  'before',
  'during',
  'after',
  'document',
  'signature'
);

CREATE TYPE stock_movement_type AS ENUM (
  'entry',
  'exit',
  'adjustment'
);

CREATE TYPE financial_record_type AS ENUM (
  'expense',
  'income',
  'budget'
);

CREATE TYPE location_type AS ENUM (
  'unit',
  'common_area',
  'block',
  'tower',
  'equipment',
  'other'
);
