import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: req.headers.get("Authorization")! } } }
    );

    const { code } = await req.json();

    if (!code) {
      return new Response(JSON.stringify({ error: "Invite code is required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Lookup invite code
    const { data: invite, error: inviteErr } = await supabaseClient
      .from("test_invites")
      .select("*, tests(*, profiles(full_name, avatar_url), exams(name))")
      .eq("code", code)
      .eq("is_active", true)
      .single();

    if (inviteErr || !invite) {
      return new Response(JSON.stringify({ error: "Invalid or expired test invitation link" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Check expiration and max uses
    if (invite.expires_at && new Date(invite.expires_at) < new Date()) {
      return new Response(JSON.stringify({ error: "Test invitation link has expired" }), {
        status: 410,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (invite.max_uses > 0 && invite.uses_count >= invite.max_uses) {
      return new Response(JSON.stringify({ error: "Maximum invitation uses reached" }), {
        status: 429,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Fetch test question count
    const { count: questionCount } = await supabaseClient
      .from("test_questions")
      .select("*", { count: "exact", head: true })
      .eq("test_id", invite.test_id);

    return new Response(
      JSON.stringify({
        success: true,
        test: {
          id: invite.tests.id,
          title: invite.tests.title,
          description: invite.tests.description,
          exam: invite.tests.exams.name,
          duration_minutes: invite.tests.duration_minutes,
          total_marks: invite.tests.total_marks,
          negative_marking: invite.tests.default_negative_marking,
          teacher_name: invite.tests.profiles.full_name,
          teacher_avatar: invite.tests.profiles.avatar_url,
          question_count: questionCount ?? 0,
        },
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
