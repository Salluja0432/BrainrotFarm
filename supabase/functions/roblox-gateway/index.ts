import { createClient } from "npm:@supabase/supabase-js@2";

const ALLOWED_EVENTS = new Set([
  "server_started",
  "player_joined",
  "egg_purchased",
  "creature_placed",
  "creature_stored",
  "creature_sold",
  "creature_stolen",
  "protection_activated",
]);

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}

function safeEquals(left: string, right: string): boolean {
  let mismatch = left.length ^ right.length;
  const length = Math.max(left.length, right.length);
  for (let index = 0; index < length; index += 1) {
    mismatch |= (left.charCodeAt(index) || 0) ^ (right.charCodeAt(index) || 0);
  }
  return mismatch === 0;
}

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204 });
  }

  const expectedKey = Deno.env.get("BRAINROTFARM_ROBLOX_API_KEY") ?? "";
  const suppliedKey = request.headers.get("x-brainrot-server-key") ?? "";

  if (!expectedKey || !suppliedKey || !safeEquals(suppliedKey, expectedKey)) {
    return jsonResponse({ error: "unauthorized" }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

  if (!supabaseUrl || !serviceRoleKey) {
    return jsonResponse({ error: "server_configuration_missing" }, 503);
  }

  const database = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const url = new URL(request.url);
  const path = url.pathname;

  // Somente DEVELOPMENT está habilitado nesta primeira entrega.
  // Staging/production exigirão projetos e segredos separados.
  if (request.method === "GET" && path.endsWith("/config")) {
    const { data, error } = await database
      .from("game_config")
      .select("config_key, config_value, version, updated_at")
      .eq("environment", "development")
      .eq("visible_to_game", true)
      .order("config_key");

    if (error) {
      return jsonResponse({ error: "config_read_failed" }, 500);
    }

    const config: Record<string, unknown> = {};
    for (const row of data ?? []) {
      config[row.config_key] = row.config_value;
    }

    return jsonResponse({
      environment: "development",
      config,
      entries: data?.length ?? 0,
    });
  }

  if (request.method === "POST" && path.endsWith("/events")) {
    let body: unknown;
    try {
      body = await request.json();
    } catch {
      return jsonResponse({ error: "invalid_json" }, 400);
    }

    if (!isPlainObject(body)) {
      return jsonResponse({ error: "invalid_payload" }, 400);
    }

    const eventName = body.event_name;
    if (typeof eventName !== "string" || !ALLOWED_EVENTS.has(eventName)) {
      return jsonResponse({ error: "event_not_allowed" }, 400);
    }

    const payload = body.payload === undefined ? {} : body.payload;
    if (!isPlainObject(payload)) {
      return jsonResponse({ error: "payload_must_be_object" }, 400);
    }

    if (new TextEncoder().encode(JSON.stringify(payload)).byteLength > 4096) {
      return jsonResponse({ error: "payload_too_large" }, 413);
    }

    const placeId = body.place_id;
    if (placeId !== undefined &&
        (typeof placeId !== "number" || !Number.isSafeInteger(placeId) || placeId <= 0)) {
      return jsonResponse({ error: "invalid_place_id" }, 400);
    }

    const serverJobId = body.server_job_id;
    if (serverJobId !== undefined &&
        (typeof serverJobId !== "string" || serverJobId.length > 128)) {
      return jsonResponse({ error: "invalid_server_job_id" }, 400);
    }

    const { error } = await database.from("game_events").insert({
      event_name: eventName,
      environment: "development",
      place_id: placeId ?? null,
      server_job_id: serverJobId ?? null,
      payload,
    });

    if (error) {
      return jsonResponse({ error: "event_write_failed" }, 500);
    }

    return jsonResponse({ accepted: true }, 202);
  }

  return jsonResponse({ error: "route_not_found" }, 404);
});
