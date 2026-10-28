import 'package:flutter/material.dart';
import '../models.dart';
import '../nav_menu.dart';
import '../theme.dart';
import 'seat_screen.dart';

class PosterCard extends StatelessWidget {
  final Movie movie;
  final double w, h, gap;
  final VoidCallback? onTap;
  const PosterCard(
      {super.key,
      required this.movie,
      this.w = 100,
      this.h = 146,
      this.gap = 20,
      this.onTap});

  Widget _fallback() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: movie.colors,
          ),
        ),
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.all(8),
        child: Text(movie.title,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, height: 1.15)),
      );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: w,
        height: h,
        margin: EdgeInsets.only(right: gap),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              movie.posterAsset == null
                  ? _fallback()
                  : Image.asset(movie.posterAsset!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallback()),
              if (movie.rating > 0 && !movie.isComingSoon)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.yellow.withValues(alpha: 0.4),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 11, color: AppColors.yellow),
                        const SizedBox(width: 2),
                        Text(
                          movie.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _ctrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Semua film tanpa judul ganda.
  List<Movie> get _all {
    final seen = <String>{};
    return [...nowPlaying, ...comingSoon, ...topMovies]
        .where((m) => seen.add(m.title))
        .toList();
  }

  List<Movie> get _results {
    final q = _q.trim().toLowerCase();
    return _all
        .where((m) =>
            m.title.toLowerCase().contains(q) || m.genre.toLowerCase().contains(q))
        .toList();
  }

  void _open(Movie m) {
    FocusScope.of(context).unfocus();
    if (m.isComingSoon || comingSoon.any((c) => c.title == m.title)) {
      _showComingSoonDetail(m);
      return;
    }
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => SeatScreen(movie: m)));
  }

  void _showComingSoonDetail(Movie m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1824),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PosterCard(movie: m, w: 90, h: 132, gap: 0),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.yellow.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.yellow.withValues(alpha: 0.6)),
                            ),
                            child: const Text(
                              'COMING SOON',
                              style: TextStyle(
                                color: AppColors.yellow,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            m.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${m.genre}  •  ${m.minutes ~/ 60}j ${m.minutes % 60}m',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Sinopsis Film',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  m.description.isNotEmpty
                      ? m.description
                      : 'Film spektakuler ini segera tayang di TikTap XXI. Nantikan petualangan serunya dan pantau tanggal rilis resminya!',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppColors.lightBlue, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pemesanan tiket untuk film ini belum dibuka. Anda akan diberi tahu saat tiket mulai dijual.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white38),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.notifications_active_outlined,
                            size: 18, color: AppColors.yellow),
                        label: const Text('Ingatkan Saya',
                            style: TextStyle(color: Colors.white)),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Pengingat untuk film ${m.title} telah diaktifkan!'),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GradientButton(
                        text: 'Tutup',
                        onTap: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<Movie> list) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      SizedBox(
        height: 146,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 20),
          itemCount: list.length,
          itemBuilder: (_, i) =>
              PosterCard(movie: list[i], onTap: () => _open(list[i])),
        ),
      ),
    ]);
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          const Icon(Icons.search, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _ctrl,
              onChanged: (v) => setState(() => _q = v),
              textInputAction: TextInputAction.search,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              cursorColor: AppColors.lightBlue,
              decoration: const InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(color: Colors.white70, fontSize: 15),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_q.isNotEmpty)
            GestureDetector(
              onTap: () {
                _ctrl.clear();
                setState(() => _q = '');
              },
              child: const Icon(Icons.close, color: Colors.white70, size: 20),
            ),
        ]),
      ),
    );
  }

  Widget _searchResults() {
    final res = _results;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${res.length} hasil untuk "${_q.trim()}"',
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 14),
        if (res.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 50),
            child: Center(
              child: Column(children: [
                Icon(Icons.search_off, size: 52, color: Colors.white54),
                SizedBox(height: 10),
                Text('Film tidak ditemukan',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text('Coba kata kunci lain, misalnya judul atau genre.',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
            ),
          )
        else
          Wrap(
            spacing: 16,
            runSpacing: 18,
            children: [
              for (final m in res)
                GestureDetector(
                  onTap: () => _open(m),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 100,
                    child: Column(children: [
                      PosterCard(movie: m, gap: 0),
                      const SizedBox(height: 6),
                      Text(m.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12)),
                    ]),
                  ),
                ),
            ],
          ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searching = _q.trim().isNotEmpty;
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(bottom: 96 + MediaQuery.paddingOf(context).bottom),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(children: [
            SizedBox(width: 44),
            Expanded(
              child: Center(
                child: Text('Choose Movie',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              ),
            ),
            NavMenuButton(),
          ]),
        ),
        _searchBar(),
        if (searching)
          _searchResults()
        else ...[
          _section('Now Playing', nowPlaying),
          _section('Coming Soon', comingSoon),
          _section('Top movies', topMovies),
        ],
      ],
    );
  }
}
