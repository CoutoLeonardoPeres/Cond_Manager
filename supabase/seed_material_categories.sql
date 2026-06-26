-- =============================================================================
-- COND MANAGER — Categorias padrão de materiais
-- Execute no SQL Editor do Supabase (após ter ao menos um condomínio cadastrado)
--
-- • Insere as categorias em TODOS os condomínios existentes
-- • Seguro para rodar mais de uma vez (ignora duplicatas por condomínio + nome)
--
-- Para um condomínio específico, descomente o filtro no final do script.
-- =============================================================================

INSERT INTO public.material_categories (condominium_id, name, description)
SELECT c.id, cat.name, cat.description
FROM public.condominiums c
CROSS JOIN (
  VALUES
    ('Elétrica',                    'Materiais elétricos gerais'),
    ('Iluminação',                  'Lâmpadas, luminárias, reatores e sensores'),
    ('Quadros e disjuntores',       'DR, DPS, barramentos e disjuntores'),
    ('Cabos e conectores',          'Cabos, terminais e eletrodutos'),
    ('Hidráulica',                  'Registros, conexões, sifões e torneiras'),
    ('Tubos e conexões',            'PVC, cobre, roscáveis, colas e soldas'),
    ('Bombas e pressurização',      'Bombas, pressostatos e válvulas'),
    ('Caixas d''água',              'Boias, tampas, limpeza e acessórios'),
    ('Portões e motores',           'Motores, cremalheiras, fotocélulas e controles'),
    ('Controle de acesso',          'Tags, leitores e fechaduras eletrônicas'),
    ('Ferragens e fechaduras',      'Maçanetas, dobradiças e cilindros'),
    ('CFTV',                        'Câmeras, DVR/NVR, fontes e cabos'),
    ('Interfonia',                  'Interfones, centrais, ramais e acessórios'),
    ('Alarmes e sensores',          'Sensores, sirenes e centrais'),
    ('Alvenaria',                   'Cimento, argamassa, tijolos e vergalhões'),
    ('Pintura',                     'Tintas, massas, rolos, lixas e seladores'),
    ('Impermeabilização',           'Mantas, selantes e impermeabilizantes'),
    ('Telhado e calhas',            'Telhas, rufo, calhas e parafusos'),
    ('Elevadores',                  'Peças, cabos, botoeiras e sensores'),
    ('Equipamentos gerais',         'Ferramentas de uso e consumíveis leves'),
    ('Piscina',                     'Cloro, filtros, bombas e acessórios'),
    ('Limpeza e higiene',           'Produtos de limpeza, panos e desinfetantes'),
    ('Paisagismo',                  'Adubos, mudas, irrigação e substrato'),
    ('Mobiliário urbano',           'Bancos, lixeiras e placas de sinalização'),
    ('Fixação e ferragens',         'Parafusos, buchas, arruelas e rebites'),
    ('Adesivos e vedantes',         'Silicone, fita veda-rosca e colas'),
    ('Descartáveis e consumíveis', 'Luvas, fitas, abrasivos e EPIs leves'),
    ('Outros',                      'Itens que não se encaixam nas demais categorias')
) AS cat(name, description)
-- Descomente para limitar a um condomínio:
-- WHERE c.name = 'Nome do seu condomínio'
ON CONFLICT (condominium_id, name) DO NOTHING;

-- Conferência (opcional)
SELECT
  c.name AS condominio,
  COUNT(mc.id) AS total_categorias
FROM public.condominiums c
LEFT JOIN public.material_categories mc ON mc.condominium_id = c.id
GROUP BY c.id, c.name
ORDER BY c.name;
