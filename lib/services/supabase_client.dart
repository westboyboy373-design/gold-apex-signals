import 'package:supabase_flutter/supabase_flutter.dart';

/// Your Supabase project credentials.
/// The publishable/anon key is safe to ship in a client app by design —
/// Row Level Security policies (see supabase/schema.sql) are what actually
/// protect your data, not secrecy of this key.
const String kSupabaseUrl = 'https://esktjaivgfgzlvtofzdw.supabase.co';
const String kSupabaseAnonKey = 'sb_publishable_KOimVrLak_ubdL-yygOFbQ_Hvmea_Si';

/// Shorthand accessor used throughout the app.
SupabaseClient get supabase => Supabase.instance.client;
