# Matriz de permissões (referência)

Legenda: **C** criar · **L** listar/ver · **E** editar · **A** aprovar · **—** sem acesso

| Recurso | Platform Admin | Condo Admin | Síndico | Zelador | Gestor Manut. | Func. Interno | Prestador | Fornecedor | Morador | Financeiro | Auditor |
|---------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Condomínios (cadastro global) | CLE | — | — | — | — | — | — | — | — | — | — |
| Estrutura do condomínio | CLE | CLE | CLE | CLE | CLE | L | L | L | L | L | L |
| Usuários / convites | CLE | CLE | CLE | — | L | — | — | — | — | — | L |
| Prestadores / fornecedores | CLE | CLE | CLE | CLE | CLE | L | L* | L* | — | L | L |
| Materiais / estoque | CLE | CLE | CLE | CE | CE | CE | — | — | — | L | L |
| Chamados | CLE | CLE | CLE | CLE | CLE | CLE | L** | — | CL*** | L | L |
| Ordens de Serviço | CLE | CLE | CLE | CLE | CLE | CE** | CE** | — | L*** | L | L |
| Aprovações OS | A | A | A | — | A | — | — | — | — | A | L |
| Preventiva | CLE | CLE | CLE | CLE | CLE | E | E** | — | — | L | L |
| Financeiro | CLE | CLE | CLE | — | L | — | — | — | — | CLE | L |

\* Prestador/fornecedor: apenas próprio cadastro vinculado ao `user_id`.  
\*\* Prestador: OS atribuídas ao seu `provider_id`.  
\*\*\* Morador: apenas chamados/OS onde é solicitante.

> As policies RLS em `00011_rls_policies.sql` implementam este modelo no banco. A UI deve esconder ações não permitidas com base em `UserRole` + condomínio selecionado.
