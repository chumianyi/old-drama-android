import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/drama.dart';
import '../services/api_service.dart';

class DetailScreen extends StatefulWidget {
  final Drama drama;
  const DetailScreen({super.key, required this.drama});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  DramaDetail? _detail;
  bool _loading = true;
  bool _isFav = false;
  int _currentEpisode = 0;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final detail = await ApiService().fetchDetail(widget.drama.id);
    final favs = await ApiService().getFavorites();
    if (!mounted) return;
    setState(() {
      _detail = detail;
      _isFav = favs.contains(widget.drama.id);
      _loading = false;
    });
    if (detail != null && detail.episodes.isNotEmpty) {
      _playEpisode(0);
    }
  }

  Future<void> _playEpisode(int index) async {
    if (_detail == null || _detail!.episodes.isEmpty) return;
    setState(() => _currentEpisode = index);
    final ep = _detail!.episodes[index];
    _videoController?.dispose();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(ep.videoUrl));
    await _videoController!.initialize();
    await _videoController!.play();
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.drama.title, maxLines: 1),
        actions: [
          IconButton(
            icon: Icon(_isFav ? Icons.favorite : Icons.favorite_border,
                color: _isFav ? Colors.red : null),
            onPressed: () async {
              await ApiService().toggleFavorite(widget.drama.id);
              setState(() => _isFav = !_isFav);
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _detail == null
              ? const Center(child: Text('加载失败'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: _videoController != null &&
                                _videoController!.value.isInitialized
                            ? Container(
                                color: Colors.black,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    VideoPlayer(_videoController!),
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        color: Colors.black54,
                                        child: Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                _videoController!.value.isPlaying
                                                    ? Icons.pause
                                                    : Icons.play_arrow,
                                                color: Colors.white,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _videoController!.value.isPlaying
                                                      ? _videoController!.pause()
                                                      : _videoController!.play();
                                                });
                                              },
                                            ),
                                            Expanded(
                                              child: VideoProgressIndicator(
                                                _videoController!,
                                                allowScrubbing: true,
                                                colors: const VideoProgressColors(
                                                  playedColor: Colors.pink,
                                                  backgroundColor: Colors.white24,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                color: Colors.black,
                                child: const Center(
                                    child: CircularProgressIndicator())),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_detail!.title,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('共${_detail!.episodeCount}集',
                                style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('选集',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 2.5,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _detail!.episodes.length,
                        itemBuilder: (context, index) {
                          final selected = index == _currentEpisode;
                          return GestureDetector(
                            onTap: () => _playEpisode(index),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFFE91E63)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('第${index + 1}集',
                                  style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 13)),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}
