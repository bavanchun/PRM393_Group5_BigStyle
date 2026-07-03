import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/voucher_model.dart';

/// Voucher access. Discount validation goes through the `validate_voucher`
/// SECURITY DEFINER RPC (server-authoritative math). Manager CRUD is gated by
/// the `Managers manage vouchers` RLS policy (is_manager()).
class VoucherService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Returns the discount amount for [code] against [subtotal]. Throws a
  /// [PostgrestException] whose message is the Vietnamese reason when the code
  /// is invalid / expired / below the minimum — callers surface it to the user.
  Future<double> validate(String code, double subtotal) async {
    final res = await _client.rpc(
      'validate_voucher',
      params: {'p_code': code, 'p_subtotal': subtotal},
    );
    return (res as num).toDouble();
  }

  /// All vouchers (active + inactive) for the manager list, newest first.
  Future<List<VoucherModel>> getVouchersForManager() async {
    final data = await _client
        .from('vouchers')
        .select('*')
        .order('created_at', ascending: false);
    return data.map((row) => VoucherModel.fromMap(row)).toList();
  }

  Future<VoucherModel?> createVoucher(VoucherModel voucher) async {
    final payload = voucher.toMap();
    // Store codes uppercased so lookup (validate_voucher upper()) is consistent.
    payload['code'] = voucher.code.trim().toUpperCase();
    final inserted =
        await _client.from('vouchers').insert(payload).select().limit(1);
    if (inserted.isEmpty) return null;
    return VoucherModel.fromMap(inserted.first);
  }

  Future<VoucherModel?> updateVoucher(VoucherModel voucher) async {
    final payload = voucher.toMap();
    payload['code'] = voucher.code.trim().toUpperCase();
    final updated = await _client
        .from('vouchers')
        .update(payload)
        .eq('id', voucher.id)
        .select()
        .limit(1);
    if (updated.isEmpty) return null;
    return VoucherModel.fromMap(updated.first);
  }

  Future<void> setActive(String id, bool isActive) async {
    await _client.from('vouchers').update({'is_active': isActive}).eq('id', id);
  }
}
