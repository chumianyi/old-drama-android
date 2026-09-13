import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/drama.dart';
import '../services/api_service.dart';
import 'detail_screen.dart';

class FollowTab extends StatefulWidget {
  const FollowTab({super.key});

  @override
  State<FollowTab> createState() => _FollowTabState();
}

class _FollowTabState extends State<FollowTab> {
  List<Drama> _favs = [];
  bool _loading = true;

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
    if (mounted) {
      setState(() {
        _favs = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的追番'),
        backgroundColor: const Color(0xFFE91E63),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _favs.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('还没有追番', style: TextStyle(color: Colors.grey)),
                      Text('在短剧详情页点击心形按钮追番',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _favs.length,
                  itemBuilder: (context, index) {
                    final d = _favs[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DetailScreen(drama: d)),
                      ),
                      child: Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4)),
                                child: CachedNetworkImage(
                                  imageUrl: d.coverUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorWidget: (_, __, ___) =>
                                      const Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(d.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12)),
                                  Text('${d.episodeCount}集',
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
