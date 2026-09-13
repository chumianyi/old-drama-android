import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/drama.dart';
import 'detail_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _loggedIn = false;
  String _email = '';
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() {
    final api = ApiService();
    setState(() {
      _loggedIn = api.isLoggedIn;
      _email = api.savedEmail ?? '';
      _emailController.text = _email;
    });
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请输入邮箱和密码')));
      return;
    }
    setState(() => _loading = true);
    final result = await ApiService()
        .login(_emailController.text.trim(), _passController.text);
    setState(() => _loading = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(result['message'])));
    if (result['success']) {
      setState(() {
        _loggedIn = true;
        _email = _emailController.text.trim();
      });
    }
  }

  Future<void> _logout() async {
    await ApiService().logout();
    setState(() {
      _loggedIn = false;
      _passController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        backgroundColor: const Color(0xFFE91E63),
        foregroundColor: Colors.white,
      ),
      body: _loggedIn ? _buildProfile() : _buildLogin(),
    );
  }

  Widget _buildLogin() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.movie_filter, size: 80, color: Color(0xFFE91E63)),
          const SizedBox(height: 20),
          const Text('登录老短剧',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: '邮箱',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passController,
            decoration: const InputDecoration(
              labelText: '密码',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                foregroundColor: Colors.white,
              ),
              onPressed: _loading ? null : _login,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('登 录', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    return ListView(
      children: [
        const SizedBox(height: 20),
        const CircleAvatar(
          radius: 40,
          backgroundColor: Color(0xFFE91E63),
          child: Icon(Icons.person, size: 40, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Center(child: Text(_email, style: const TextStyle(fontSize: 18))),
        const SizedBox(height: 20),
        ListTile(
          leading: const Icon(Icons.favorite, color: Colors.red),
          title: const Text('我的收藏'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FavoritesScreen()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('关于'),
          onTap: () => showAboutDialog(
            context: context,
            applicationName: '老短剧',
            applicationVersion: '1.0.0',
            applicationLegalese: 'API: video.999381.xyz',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.grey),
          title: const Text('退出登录'),
          onTap: _logout,
        ),
      ],
    );
  }
}

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Drama> _favs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ids = await ApiService().getFavorites();
    final list = <Drama>[];
    for (final id in ids) {
      final d = await ApiService().fetchDetail(id);
      if (d != null) {
        list.add(Drama(
          id: d.id,
          title: d.title,
          coverUrl: d.coverUrl,
          episodeCount: d.episodeCount,
        ));
      }
    }
    if (mounted) setState(() => _favs = list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的收藏')),
      body: _favs.isEmpty
          ? const Center(child: Text('暂无收藏'))
          : ListView.builder(
              itemCount: _favs.length,
              itemBuilder: (context, index) {
                final d = _favs[index];
                return ListTile(
                  leading: const Icon(Icons.movie),
                  title: Text(d.title),
                  subtitle: Text('共${d.episodeCount}集'),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => DetailScreen(drama: d))),
                );
              },
            ),
    );
  }
}
