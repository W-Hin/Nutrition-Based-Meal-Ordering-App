import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'service/supabase_conn.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase once here, never anywhere else
  await Supabase.initialize(
    url:     'https://cjsxgpiahswppkyackpk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNqc3hncGlhaHN3cHBreWFja3BrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYwOTE0MDksImV4cCI6MjA5MTY2NzQwOX0.E_2q_i5PqmuY2Csx06e7U0In-DAoLak_n_KC-IgKOkc',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TestPage(),
    );
  }
}

// ── Test Page ──────────────────────────────────────────────────────────────────

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final data = await supabase.from('testing').select();
      setState(() {
        _rows   = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error   = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Connection Test'),
        backgroundColor: const Color(0xFF1E4620),
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Still fetching
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Something went wrong
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text('Connection Failed',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 8),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    // Connected but no rows yet
    if (_rows.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                color: Color(0xFF1E4620), size: 48),
            SizedBox(height: 16),
            Text('Connected to Supabase!',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 18)),
            SizedBox(height: 8),
            Text('Your testing table is empty.\nAdd some rows in the Supabase dashboard.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // Show rows
    return Column(
      children: [
        // Success banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF1E4620),
          child: Text(
            '✓ Connected — ${_rows.length} row(s) found',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
        // Table rows
        Expanded(
          child: ListView.separated(
            itemCount: _rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final row = _rows[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF1E4620),
                  child: Text(
                    '${row['id']}'.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  row['name'] ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(row['created_at'] ?? '-'),
              );
            },
          ),
        ),
      ],
    );
  }
}