import '../model/address_model.dart';
import 'supabase_conn.dart';

class AddressService {
  // ── Save address ─────────────────────────────────────────────
  Future<void> saveAddress(AddressModel address) async {
    await supabase.from('address').insert({
      'user_id':    supabase.auth.currentUser?.id ?? 'test_user_ui_mode',
      'name':       address.name,
      'phone':      address.phone,
      'address':    address.address,
      'label':      address.label?.name,
      'label_name': address.customLabelName,
    });
  }

  // ── Fetch all addresses for current user ─────────────────────
  Future<List<Map<String, dynamic>>> fetchAddresses() async {
    return await supabase
        .from('address')
        .select()
        .eq('user_id', supabase.auth.currentUser?.id ?? 'test_user_ui_mode')
        .order('created_at', ascending: false);
  }

  // ── Update existing address ───────────────────────────────────
  Future<void> updateAddress(String id, AddressModel address) async {
    await supabase.from('address').update({
      'name':       address.name,
      'phone':      address.phone,
      'address':    address.address,
      'label':      address.label?.name,
      'label_name': address.customLabelName,
    }).eq('id', id);
  }

  // ── Delete address ────────────────────────────────────────────
  Future<void> deleteAddress(String id) async {
    await supabase.from('address').delete().eq('user_id', id);
  }
}