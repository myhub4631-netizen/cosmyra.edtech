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
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing Authorization header" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: authError } = await userClient.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized user session" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body = await req.json();
    const { order_id, utr_number, action = "submit_utr", payment_id } = body;

    if (!order_id) {
      return new Response(JSON.stringify({ error: "Missing order_id" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Create service role client for privileged operations
    const adminClient = createClient(supabaseUrl, supabaseServiceKey || supabaseAnonKey);

    if (action === "submit_utr") {
      if (!utr_number || utr_number.trim().length < 6) {
        return new Response(JSON.stringify({ error: "Invalid UTR / Transaction Reference number" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      // Verify order belongs to caller
      const { data: order, error: orderErr } = await adminClient
        .from("orders")
        .select("id, user_id, status")
        .eq("id", order_id)
        .single();

      if (orderErr || !order) {
        return new Response(JSON.stringify({ error: "Order not found" }), {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      if (order.user_id !== user.id) {
        return new Response(JSON.stringify({ error: "Access denied: Order does not belong to caller" }), {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const cleanUtr = utr_number.trim();
      const { data: updatedOrder, error: updateErr } = await adminClient
        .from("orders")
        .update({
          status: "pending_verification",
          payment_reference: cleanUtr,
          payment_id: `UTR_${cleanUtr}`,
          notes: `UPI Payment submitted with UTR: ${cleanUtr}. Awaiting admin verification.`,
          updated_at: new Date().toISOString(),
        })
        .eq("id", order_id)
        .select()
        .single();

      if (updateErr) {
        return new Response(JSON.stringify({ error: updateErr.message }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      return new Response(JSON.stringify({ success: true, message: "UTR submitted successfully for verification", order: updatedOrder }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });

    } else if (action === "verify_approve") {
      // Check admin status
      const { data: isAdmin, error: adminCheckErr } = await adminClient.rpc("is_admin", { user_id: user.id });

      if (adminCheckErr || !isAdmin) {
        return new Response(JSON.stringify({ error: "Forbidden: Admin authorization required" }), {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      // Execute atomic order fulfillment RPC
      const { data: fulfillResult, error: fulfillErr } = await adminClient.rpc("approve_and_fulfill_order", {
        p_order_id: order_id,
        p_admin_id: user.id,
        p_payment_id: payment_id || `VERIFIED_BY_ADMIN_${user.id.substring(0, 8)}`,
      });

      if (fulfillErr) {
        return new Response(JSON.stringify({ error: fulfillErr.message }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      return new Response(JSON.stringify({ success: true, result: fulfillResult }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });

    } else {
      return new Response(JSON.stringify({ error: "Invalid action specified" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
