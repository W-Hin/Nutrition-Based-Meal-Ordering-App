import 'package:supabase_flutter/supabase_flutter.dart';

// Single global client — import this file wherever you need Supabase
// Never initialize Supabase anywhere else
final supabase = Supabase.instance.client;