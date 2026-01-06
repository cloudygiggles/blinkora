import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import * as djwt from "https://deno.land/x/djwt@v3.0.1/mod.ts"

Deno.serve(async (req) => {
  try {
    const body = await req.json()
    const { record, old_record } = body

    if (!record || !old_record || record.status === old_record.status) {
      return new Response("No status change detected", { status: 200 })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('fcm_token, name')
      .eq('id', record.user_id)
      .single()

    if (profileError || !profile?.fcm_token) {
      return new Response("User has no FCM token", { status: 200 })
    }

    // --- LOGIKA PESAN TOKO AKSESORIS ---
    let notificationTitle = "Update Aksesoris Kamu ✨";
    let notificationBody = `Halo ${profile.name || 'Sobat'}, status pesananmu: ${record.status}`;

    switch (record.status) {
      case 'pending':
        notificationTitle = "Pesanan Dikonfirmasi! 💍";
        notificationBody = "Pesanan aksesoris kamu sudah masuk. Segera kami siapkan untuk mempercantik gayamu!";
        break;
      case 'shipping':
        notificationTitle = "Pesanan Sedang Menuju Kamu! 🚚";
        notificationBody = "Otw! Koleksi barumu sudah diserahkan ke kurir. Gak sabar ya buat unboxing?";
        break;
      case 'completed':
        notificationTitle = "Tampil Makin Kece! ✨";
        notificationBody = "Paket aksesoris sudah sampai. Jangan lupa tag kami saat kamu pakai ya!";
        break;
      default:
        notificationTitle = "Info Pesanan 📦";
        notificationBody = `Status pesananmu saat ini: ${record.status}`;
    }

    // --- 1. SIMPAN LOG KE DATABASE ---
    await supabase.from('notification_logs').insert({
      user_id: record.user_id,
      title: notificationTitle,
      body: notificationBody,
      order_id: record.id,
      type: 'push'
    });

    // --- 2. AUTH GOOGLE ---
    const clientEmail = Deno.env.get('FIREBASE_CLIENT_EMAIL')!
    const privateKeyRaw = Deno.env.get('FIREBASE_PRIVATE_KEY')!.replace(/\\n/g, '\n')
    const projectId = Deno.env.get('FIREBASE_PROJECT_ID')!

    const extractKey = (pem: string) => {
      const pemContents = pem.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\s/g, "");
      const binary = atob(pemContents);
      const buffer = new Uint8Array(binary.length);
      for (let i = 0; i < binary.length; i++) buffer[i] = binary.charCodeAt(i);
      return buffer.buffer;
    };

    const key = await crypto.subtle.importKey(
      "pkcs8",
      extractKey(privateKeyRaw),
      { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
      false,
      ["sign"]
    )

    const now = Math.floor(Date.now() / 1000)
    const jwt = await djwt.create({ alg: "RS256", typ: "JWT" }, {
      iss: clientEmail,
      sub: clientEmail,
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
      scope: "https://www.googleapis.com/auth/cloud-platform",
    }, key)

    const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: jwt,
      }),
    })
    const { access_token } = await tokenRes.json()

    // --- 3. KIRIM KE FCM ---
    const fcmRes = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${access_token}`,
        },
        body: JSON.stringify({
          message: {
            token: profile.fcm_token,
            notification: { 
              title: notificationTitle, 
              body: notificationBody 
            },
            data: {
              order_id: String(record.id),
              status: record.status,
              type: "ORDER_UPDATE"
            },
            android: {
              notification: {
                channel_id: "channel_notification",
                click_action: "FLUTTER_NOTIFICATION_CLICK",
                sound: "blink.mp3" 
              }
            }
          },
        }),
      }
    )

    const result = await fcmRes.json()
    return new Response(JSON.stringify(result), { status: 200 })

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 })
  }
})