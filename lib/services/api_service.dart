import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/drama.dart';

class ApiService {
  static const String contentBase = 'https://video.999381.xyz';
  static const String userBase = 'https://www.88ipa.com';
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;
  SharedPreferences? _prefs;
  String? _token;
  int? _userId;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      responseType: ResponseType.plain,
      validateStatus: (s) => s != null && s < 500,
      headers: {'User-Agent': 'OldVideo/1.0 (Android)'},
    ));
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _token = _prefs?.getString('user_token');
    _userId = _prefs?.getInt('user_id');
  }

  bool get isLoggedIn => _token != null;
  String? get savedEmail => _prefs?.getString('user_email') ?? '';

  Map<String, dynamic>? _parse(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ============ Feed推荐 ============
  Future<List<Drama>> fetchFeed(int page, {int limit = 6}) async {
    try {
      final res = await _dio.get('$contentBase/api/drama/feed',
          queryParameters: {'page': page, 'limit': limit});
      final data = _parse(res.data.toString());
      if (data != null && data['data'] is List) {
        return (data['data'] as List).map((e) => Drama.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ============ 搜索 ============
  Future<List<Drama>> search(String keyword, int page) async {
    try {
      final res = await _dio.get('$contentBase/api/drama/search',
          queryParameters: {'keyword': keyword, 'page': page, 'limit': 6});
      final data = _parse(res.data.toString());
      if (data != null && data['data'] is List) {
        return (data['data'] as List).map((e) => Drama.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ============ 详情 ============
  Future<DramaDetail?> fetchDetail(int id) async {
    try {
      final res = await _dio.get('$contentBase/api/drama/$id');
      final data = _parse(res.data.toString());
      if (data != null && data['data'] is Map) {
        return DramaDetail.fromJson(data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ============ 登录 ============
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await _dio.post(
        '$userBase/app_api/v2/get_user_login_token',
        data: {'email': email, 'password': password},
        options: Options(
          headers: {'X-Requested-With': 'XMLHttpRequest'},
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      final data = _parse(res.data.toString());
      if (data == null) return {'success': false, 'message': '响应异常'};
      if (data['status'] == 'success') {
        _token = data['token']?.toString() ?? data['data']?['token']?.toString();
        _userId = data['user_id'] ?? data['data']?['user_id'];
        await _prefs?.setString('user_token', _token ?? '');
        await _prefs?.setInt('user_id', _userId ?? 0);
        await _prefs?.setString('user_email', email);
        return {'success': true, 'message': '登录成功'};
      }
      return {'success': false, 'message': data['message'] ?? '登录失败'};
    } catch (e) {
      return {'success': false, 'message': '网络错误: $e'};
    }
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    await _prefs?.remove('user_token');
    await _prefs?.remove('user_id');
    await _prefs?.remove('user_email');
  }

  // ============ 收藏 ============
  Future<Set<int>> getFavorites() async {
    final list = _prefs?.getStringList('favorites') ?? [];
    return list.map((e) => int.tryParse(e) ?? 0).toSet();
  }

  Future<void> toggleFavorite(int id) async {
    final favs = await getFavorites();
    if (favs.contains(id)) {
      favs.remove(id);
    } else {
      favs.add(id);
    }
    await _prefs?.setStringList(
        'favorites', favs.map((e) => e.toString()).toList());
  }
}
