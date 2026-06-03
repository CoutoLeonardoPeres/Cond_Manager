# Edge Functions — Cond Manager

## send-user-invite

Envia e-mail com link de convite quando um gerente/admin cadastra um novo usuário.

### Pré-requisitos

1. Conta no [Resend](https://resend.com) (plano gratuito funciona para testes).
2. Domínio verificado no Resend **ou** use `onboarding@resend.dev` só para testes (e-mails só para o e-mail da sua conta Resend).

### Secrets (Supabase Dashboard)

Em **Project Settings → Edge Functions → Secrets**, adicione:

| Secret | Exemplo | Obrigatório |
|--------|---------|-------------|
| `RESEND_API_KEY` | `re_xxxx` | Sim |
| `INVITE_FROM_EMAIL` | `Cond Manager <noreply@seudominio.com>` | Sim* |
| `APP_PUBLIC_URL` | `https://app.seudominio.com` | Sim |

\* No sandbox do Resend use: `Cond Manager <onboarding@resend.dev>`

`SUPABASE_URL`, `SUPABASE_ANON_KEY` e `SUPABASE_SERVICE_ROLE_KEY` são injetados automaticamente pelo Supabase.

### Deploy

Com [Supabase CLI](https://supabase.com/docs/guides/cli) instalada e logada:

```bash
supabase functions deploy send-user-invite
```

Ou no Dashboard: **Edge Functions → Deploy new function** e cole o conteúdo de `send-user-invite/index.ts`.

### App Flutter

Configure no `.env`:

```env
APP_PUBLIC_URL=https://seu-app.com
```

O app chama a function automaticamente após criar o convite. Se o e-mail falhar, o link ainda aparece na tela para copiar manualmente.
