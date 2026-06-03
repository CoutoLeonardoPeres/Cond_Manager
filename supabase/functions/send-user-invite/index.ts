import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const roleLabels: Record<string, string> = {
  manager: "Gerente",
  analyst: "Analista",
  field_team: "Equipe de campo",
  client: "Usuário cliente",
};

type InvitePayload = {
  token?: string;
  inviteLink?: string;
  fullName?: string;
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonError("Não autenticado", 401);
    }

    const body = (await req.json()) as InvitePayload;
    const token = body.token?.trim();
    if (!token) {
      return jsonError("Token do convite é obrigatório", 400);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");

    if (!supabaseUrl || !serviceRoleKey || !anonKey) {
      return jsonError("Configuração Supabase incompleta na Edge Function", 500);
    }

    const admin = createClient(supabaseUrl, serviceRoleKey);
    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();

    if (userError || !user) {
      return jsonError("Não autenticado", 401);
    }

    const { data: invitation, error: invError } = await admin
      .from("user_invitations")
      .select(
        `
        id,
        email,
        token,
        organization_role,
        company_id,
        expires_at,
        accepted_at,
        management_companies ( legal_name, trade_name )
      `,
      )
      .eq("token", token)
      .maybeSingle();

    if (invError || !invitation) {
      return jsonError("Convite não encontrado", 404);
    }

    if (invitation.accepted_at) {
      return jsonError("Convite já foi aceito", 400);
    }

    const { data: profile } = await admin
      .from("profiles")
      .select("is_platform_admin")
      .eq("id", user.id)
      .maybeSingle();

    const isAdmin = profile?.is_platform_admin === true;

    if (!isAdmin) {
      const { data: membership } = await admin
        .from("company_memberships")
        .select("role, status")
        .eq("user_id", user.id)
        .eq("company_id", invitation.company_id)
        .eq("status", "active")
        .maybeSingle();

      if (membership?.role !== "manager") {
        return jsonError("Sem permissão para enviar este convite", 403);
      }
    }

    const resendKey = Deno.env.get("RESEND_API_KEY");
    if (!resendKey) {
      return jsonError(
        "RESEND_API_KEY não configurada. Defina em Edge Functions → Secrets.",
        500,
      );
    }

    const fromEmail =
      Deno.env.get("INVITE_FROM_EMAIL") ?? "Cond Manager <onboarding@resend.dev>";
    const appPublicUrl = (Deno.env.get("APP_PUBLIC_URL") ?? "").replace(/\/+$/, "");
    const inviteLink =
      body.inviteLink?.trim() ||
      (appPublicUrl ? `${appPublicUrl}/invite/${token}` : null);

    if (!inviteLink) {
      return jsonError(
        "Link do convite ausente. Configure APP_PUBLIC_URL ou envie inviteLink no body.",
        400,
      );
    }

    const company = invitation.management_companies as {
      legal_name?: string;
      trade_name?: string;
    } | null;

    const companyName =
      company?.trade_name?.trim() ||
      company?.legal_name?.trim() ||
      "Cond Manager";

    const roleLabel =
      roleLabels[invitation.organization_role ?? ""] ??
      invitation.organization_role ??
      "Usuário";

    const guestName = body.fullName?.trim() || invitation.email;
    const expiresAt = invitation.expires_at
      ? new Date(invitation.expires_at).toLocaleDateString("pt-BR")
      : null;

    const html = buildEmailHtml({
      guestName,
      companyName,
      roleLabel,
      inviteLink,
      expiresAt,
    });

    const emailRes = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${resendKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: fromEmail,
        to: [invitation.email],
        subject: `Convite Cond Manager — ${companyName}`,
        html,
      }),
    });

    if (!emailRes.ok) {
      const detail = await emailRes.text();
      console.error("Resend error:", detail);
      return jsonError(`Falha ao enviar e-mail: ${detail}`, 502);
    }

    const sent = await emailRes.json();

    return new Response(
      JSON.stringify({ success: true, messageId: sent.id }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    console.error(error);
    const message = error instanceof Error ? error.message : "Erro interno";
    return jsonError(message, 500);
  }
});

function jsonError(message: string, status: number) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function buildEmailHtml(input: {
  guestName: string;
  companyName: string;
  roleLabel: string;
  inviteLink: string;
  expiresAt: string | null;
}) {
  const expiryLine = input.expiresAt
    ? `<p style="color:#64748b;font-size:14px;">Este convite é válido até <strong>${input.expiresAt}</strong>.</p>`
    : "";

  return `<!DOCTYPE html>
<html lang="pt-BR">
  <body style="margin:0;padding:0;background:#f1f5f9;font-family:Arial,sans-serif;">
    <table width="100%" cellpadding="0" cellspacing="0" style="padding:32px 16px;">
      <tr>
        <td align="center">
          <table width="100%" cellpadding="0" cellspacing="0" style="max-width:560px;background:#ffffff;border-radius:16px;padding:32px;">
            <tr>
              <td>
                <h1 style="margin:0 0 12px;font-size:24px;color:#0f172a;">Você foi convidado</h1>
                <p style="margin:0 0 16px;color:#334155;line-height:1.6;">
                  Olá, <strong>${escapeHtml(input.guestName)}</strong>!<br/>
                  A empresa <strong>${escapeHtml(input.companyName)}</strong> convidou você para acessar o
                  <strong>Cond Manager</strong> como <strong>${escapeHtml(input.roleLabel)}</strong>.
                </p>
                <p style="margin:0 0 24px;color:#334155;line-height:1.6;">
                  Clique no botão abaixo para criar sua conta ou entrar e aceitar o convite.
                </p>
                <p style="margin:0 0 24px;text-align:center;">
                  <a href="${input.inviteLink}"
                     style="display:inline-block;background:#2563eb;color:#ffffff;text-decoration:none;
                            padding:14px 28px;border-radius:999px;font-weight:700;">
                    Aceitar convite
                  </a>
                </p>
                ${expiryLine}
                <p style="color:#64748b;font-size:13px;line-height:1.5;margin-top:24px;">
                  Se o botão não funcionar, copie e cole este link no navegador:<br/>
                  <a href="${input.inviteLink}" style="color:#2563eb;word-break:break-all;">${input.inviteLink}</a>
                </p>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>`;
}

function escapeHtml(value: string) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}
