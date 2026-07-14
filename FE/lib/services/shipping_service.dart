import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../models/shipping_rate_model.dart';

class ShippingService {
  final SupabaseClient _client;

  ShippingService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Lookup shipping fee from [fromProvince] → [toProvince].
  /// Returns 0 if subtotal >= free_threshold, otherwise baseFee.
  /// Falls back to [AppConfig.flatShippingFee] if no rate found.
  Future<double> calculateShippingFee({
    required String fromProvince,
    required String toProvince,
    required double subtotal,
  }) async {
    if (fromProvince == toProvince) {
      final data = await _client
          .from('shipping_rates')
          .select()
          .eq('from_province', fromProvince)
          .eq('to_province', toProvince)
          .eq('is_active', true)
          .maybeSingle();
      if (data != null) {
        final rate = ShippingRateModel.fromMap(data);
        if (subtotal >= rate.freeThreshold && rate.freeThreshold > 0) {
          return 0;
        }
        return rate.baseFee;
      }
      return 15000; // Default intra-city
    }

    final data = await _client
        .from('shipping_rates')
        .select()
        .eq('from_province', fromProvince)
        .eq('to_province', toProvince)
        .eq('is_active', true)
        .maybeSingle();

    if (data != null) {
      final rate = ShippingRateModel.fromMap(data);
      if (subtotal >= rate.freeThreshold && rate.freeThreshold > 0) {
        return 0;
      }
      return rate.baseFee;
    }

    return AppConfig.flatShippingFee;
  }

  /// Admin: get all shipping rates
  Future<List<ShippingRateModel>> getAllRates() async {
    final data = await _client
        .from('shipping_rates')
        .select()
        .order('from_province')
        .order('to_province');
    return data
        .map((e) => ShippingRateModel.fromMap(e))
        .toList();
  }

  /// Admin: create or update a shipping rate
  Future<ShippingRateModel> upsertRate(ShippingRateModel rate) async {
    final data = await _client
        .from('shipping_rates')
        .upsert(rate.toMap(), onConflict: 'from_province,to_province')
        .select()
        .single();
    return ShippingRateModel.fromMap(data);
  }

  /// Admin: toggle active status
  Future<void> toggleRate(String rateId, bool isActive) async {
    await _client
        .from('shipping_rates')
        .update({'is_active': isActive}).eq('id', rateId);
  }

  /// Admin: delete a rate
  Future<void> deleteRate(String rateId) async {
    await _client.from('shipping_rates').delete().eq('id', rateId);
  }
}
