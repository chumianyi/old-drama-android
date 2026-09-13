import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/drama.dart';
import '../services/api_service.dart';
import 'detail_screen.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final _controller = TextEditingController();
  List<Drama> _results = [];
  bool _searching = false;
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _history = prefs.getStringList('search_history') ?? []);
  }

  Future<void> _saveHistory(String kw) async {
    if (kw.isEmpty) return;
    _history.remove(kw);
    _history.insert(0, kw);
    if (_history.length > 10) _history = _history.sublist(0, 10);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', _history);
  }

  Future<void> _doSearch(String kw) async {
    if (kw.isEmpty) return;
    FocusScope.of(context).unfocus();
    await _saveHistory(kw);
    setState(() => _searching = true);
    final results = await ApiService().search(kw, 1);
    if (!mounted) return;
    setState(() {
      _results = results;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: '搜索短剧...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
          onSubmitted: _doSearch,
        ),
        backgroundColor: const Color(0xFFE91E63),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () => _doSearch(_controller.text)),
        ],
      ),
      body: _searching
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? _buildHistory()
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final d = _results[index];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl: d.coverUrl,
                          width: 50,
                          height: 70,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(width: 50, color: Colors.grey[200]),
                          errorWidget: (_, __, ___) =>
                              Container(width: 50, color: Colors.grey[300]),
                        ),
                      ),
                      title: Text(d.title),
                      subtitle: Text('共${d.episodeCount}集'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => DetailScreen(drama: d)),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildHistory() {
    if (_history.isEmpty) {
      return const Center(child: Text('搜索你喜欢的短剧吧'));
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('搜索历史',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _history
                .map((kw) => ActionChip(
                      label: Text(kw),
                      onPressed: () {
                        _controller.text = kw;
                        _doSearch(kw);
                      },
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
