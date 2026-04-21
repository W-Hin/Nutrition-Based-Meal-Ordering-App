import 'supabase_conn.dart';

class AddressService {
  String get _uid => supabase.auth.currentUser?.id ?? '';

  // Fetch all addresses for current user
  Future<List<Map<String, dynamic>>> fetchAddresses() async {
    return await supabase
        .from('addresses')
        .select()
        .eq('user_id', _uid)
        .order('is_default', ascending: false) // default first
        .order('created_at', ascending: false);
  }

  // Delete address
  Future<void> deleteAddress(String addressId) async {
    await supabase.from('addresses').delete().eq('address_id', addressId);
  }

  // Set default address
  Future<void> setDefault(String addressId) async {
    // Remove default from all user addresses first
    await supabase.from('addresses').update({'is_default': false}).eq('user_id', _uid);
    // Set the chosen one as default
    await supabase.from('addresses').update({'is_default': true}).eq('address_id', addressId);
  }
}
