-- PRÉVIA: duplicatas (contrato + reserva, mesmo imóvel/mês). Deve retornar 0 linhas após o reparo.
WITH rent AS (
  SELECT
    rc.id,
    rc.property_id,
    COALESCE(rc.reference_month, date_trunc('month', rc.due_date)::date) AS ref_month,
    CASE
      WHEN rc.lease_id IS NOT NULL THEN 'contrato'
      WHEN rc.booking_id IS NOT NULL THEN 'reserva'
      ELSE 'outro'
    END AS origem,
    rc.description,
    rc.amount,
    rc.due_date,
    rc.status
  FROM rental_charges rc
  WHERE rc.charge_type = 'rent'
    AND rc.status <> 'cancelled'
    AND rc.property_id IS NOT NULL
),
dup_groups AS (
  SELECT property_id, ref_month
  FROM rent
  GROUP BY property_id, ref_month
  HAVING COUNT(*) > 1
    AND COUNT(*) FILTER (WHERE origem = 'contrato') >= 1
    AND COUNT(*) FILTER (WHERE origem = 'reserva') >= 1
)
SELECT
  rp.title AS imovel,
  r.ref_month AS mes_referencia,
  r.origem,
  r.description,
  r.amount,
  r.due_date,
  r.id AS charge_id
FROM rent r
JOIN dup_groups d
  ON d.property_id = r.property_id
 AND d.ref_month = r.ref_month
JOIN rental_properties rp ON rp.id = r.property_id
ORDER BY r.ref_month DESC, rp.title, r.origem;
