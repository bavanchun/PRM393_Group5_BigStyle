import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer_address_model.dart';

class AddressService {
  final SupabaseClient _client;

  AddressService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<List<CustomerAddressModel>> getAddresses(String userId) async {
    final data = await _client
        .from('customer_addresses')
        .select()
        .eq('user_id', userId)
        .order('is_default', ascending: false)
        .order('created_at', ascending: false);
    return data
        .map((e) => CustomerAddressModel.fromMap(e))
        .toList();
  }

  Future<CustomerAddressModel?> getDefaultAddress(String userId) async {
    final data = await _client
        .from('customer_addresses')
        .select()
        .eq('user_id', userId)
        .eq('is_default', true)
        .maybeSingle();
    return data != null ? CustomerAddressModel.fromMap(data) : null;
  }

  Future<CustomerAddressModel> createAddress(
      CustomerAddressModel address) async {
    // If marking as default, clear other defaults first
    if (address.isDefault) {
      await _client
          .from('customer_addresses')
          .update({'is_default': false})
          .eq('user_id', address.userId);
    }

    final map = address.toMap()..remove('id');
    final data = await _client
        .from('customer_addresses')
        .insert(map)
        .select()
        .single();
    return CustomerAddressModel.fromMap(data);
  }

  Future<CustomerAddressModel> updateAddress(
      CustomerAddressModel address) async {
    // If marking as default, clear other defaults first
    if (address.isDefault) {
      await _client
          .from('customer_addresses')
          .update({'is_default': false})
          .eq('user_id', address.userId)
          .neq('id', address.id);
    }

    final data = await _client
        .from('customer_addresses')
        .update(address.toMap())
        .eq('id', address.id)
        .select()
        .single();
    return CustomerAddressModel.fromMap(data);
  }

  Future<void> deleteAddress(String addressId) async {
    await _client.from('customer_addresses').delete().eq('id', addressId);
  }

  Future<void> setDefault(String addressId, String userId) async {
    // Clear all defaults for this user
    await _client
        .from('customer_addresses')
        .update({'is_default': false})
        .eq('user_id', userId);
    // Set new default
    await _client
        .from('customer_addresses')
        .update({'is_default': true})
        .eq('id', addressId);
  }
}
