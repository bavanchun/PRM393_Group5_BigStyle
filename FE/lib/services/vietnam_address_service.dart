import 'dart:convert';
import 'package:http/http.dart' as http;

class Province {
  final int code;
  final String name;

  Province({required this.code, required this.name});

  factory Province.fromJson(Map<String, dynamic> json) =>
      Province(code: json['code'], name: json['name']);
}

class District {
  final int code;
  final String name;

  District({required this.code, required this.name});

  factory District.fromJson(Map<String, dynamic> json) =>
      District(code: json['code'], name: json['name']);
}

class Ward {
  final int code;
  final String name;

  Ward({required this.code, required this.name});

  factory Ward.fromJson(Map<String, dynamic> json) =>
      Ward(code: json['code'], name: json['name']);
}

class VietnamAddressService {
  static const _baseUrl = 'https://provinces.open-api.vn/api';
  static const _userAgent = 'BigStyle/1.0 (bigstyle-app)';

  Future<List<Province>> getProvinces() async {
    final res = await http
        .get(Uri.parse('$_baseUrl/p/'), headers: {'User-Agent': _userAgent})
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return [];
    final List data = json.decode(res.body);
    return data.map((e) => Province.fromJson(e)).toList();
  }

  Future<List<District>> getDistricts(int provinceCode) async {
    final res = await http
        .get(Uri.parse('$_baseUrl/p/$provinceCode?depth=2'),
            headers: {'User-Agent': _userAgent})
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return [];
    final data = json.decode(res.body);
    final List districts = data['districts'] ?? [];
    return districts.map((e) => District.fromJson(e)).toList();
  }

  Future<List<Ward>> getWards(int districtCode) async {
    final res = await http
        .get(Uri.parse('$_baseUrl/d/$districtCode?depth=2'),
            headers: {'User-Agent': _userAgent})
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return [];
    final data = json.decode(res.body);
    final List wards = data['wards'] ?? [];
    return wards.map((e) => Ward.fromJson(e)).toList();
  }
}
