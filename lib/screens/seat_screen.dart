import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';
import 'home_screen.dart';

/// Langkah 1: pilih tanggal, jam, dan kursi. Setelah "Lanjut" -> Order Confirmation.
class SeatScreen extends StatefulWidget {
  final Movie movie;
  const SeatScreen({super.key, required this.movie});
  @override
  State<SeatScreen> createState() => _SeatScreenState();
}

class _SeatScreenState extends State<SeatScreen> {
  static const _times = ['13:00', '15:30', '18:00', '19:30', '21:15'];
  static const _dates = ['Hari ini', 'Besok', 'Lusa'];
  static const _rows = ['A', 'B', 'C', 'D', 'E'];
  static const _taken = {'A3', 'A4', 'B2', 'C5', 'C6', 'D1', 'E4'};

  int _time = 0;
  int _date = 0;

  DateTime _showAt(int d, int t) {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day).add(Duration(days: d));
    final p = _times[t].split(':');
    return DateTime(day.year, day.month, day.day, int.parse(p[0]), int.parse(p[1]));
  }

  bool _past(int d, int t) => !_showAt(d, t).isAfter(DateTime.now());

  int _firstValid(int d) {
    for (var t = 0; t < _times.length; t++) {
      if (!_past(d, t)) return t;
    }
    return -1;
  }

  @override
  void initState() {
    super.initState();
    // Pilih tanggal & jam terdekat yang belum lewat.
    for (var d = 0; d < _dates.length; d++) {
      final t = _firstValid(d);
      if (t != -1) {
        _date = d;
        _time = t;
        break;
      }
    }
    if (_firstValid(_date) == -1) {
      _time = 0;
    }
  }
  final Set<String> _seats = {};

  String _dateLabel() {
    final d = DateTime.now().add(Duration(days: _date));
    const bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    const hari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return '${hari[d.weekday - 1]}, ${d.day} ${bulan[d.month - 1]} ${d.year}';
  }

  void _next() {
    final list = _seats.toList()..sort();
    AppState.I.setOrder(Order(
      movie: widget.movie,
      cinema: 'TikTap XXI',
      date: _dateLabel(),
      time: _times[_time],
      seats: list,
      showAt: _showAt(_date, _time),
    ));
    Navigator.of(context).pop();
  }

  void _showMovieInfo(Movie m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1824),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PosterCard(movie: m, w: 70, h: 100),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.title,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text('Genre: ${m.genre}',
                              style: const TextStyle(color: Colors.white70)),
                          Text('Durasi: ${m.minutes ~/ 60}j ${m.minutes % 60}m',
                              style: const TextStyle(color: Colors.white70)),
                          Text('Rating: ⭐ ${m.rating > 0 ? m.rating.toStringAsFixed(1) : "8.0"} / 10',
                              style: const TextStyle(color: AppColors.yellow, fontWeight: FontWeight.w600)),
                          Text('Harga: ${rupiah(m.price)} / kursi',
                              style: const TextStyle(
                                  color: AppColors.lightBlue,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (m.description.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Sinopsis',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    m.description,
                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                ],
                const SizedBox(height: 14),
                const Text(
                  'Silakan pilih tanggal tayang, jam penayangan, dan nomor kursi yang kamu inginkan, lalu tekan "Lanjut" untuk melakukan pembayaran.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                GradientButton(
                  text: 'Tutup',
                  onTap: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String t, bool on, VoidCallback f) => GestureDetector(
        onTap: f,
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: on ? AppColors.lightBlue : Colors.white.withValues(alpha: 0.1),
            border: Border.all(color: on ? AppColors.lightBlue : AppColors.border),
          ),
          child: Text(t,
              style: TextStyle(
                  color: on ? const Color(0xFF0B2A48) : Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 13)),
        ),
      );

  Widget _seat(String id) {
    final taken = _taken.contains(id);
    final on = _seats.contains(id);
    return GestureDetector(
      onTap: taken
          ? null
          : () => setState(() => on ? _seats.remove(id) : _seats.add(id)),
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.all(4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: taken
              ? Colors.white12
              : on
                  ? AppColors.yellow
                  : Colors.white.withValues(alpha: 0.22),
        ),
        child: Text(id,
            style: TextStyle(
                fontSize: 10,
                color: taken
                    ? Colors.white30
                    : on
                        ? const Color(0xFF0B2A48)
                        : Colors.white,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.movie;
    final total = _seats.length * m.price;
    final sorted = _seats.toList()..sort();
    return Scaffold(
      body: GradientBg(
        blue: true,
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(children: [
                RoundIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.of(context).pop()),
                const Expanded(
                  child: Center(
                    child: Text('Pilih Kursi',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 44),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    PosterCard(
                      movie: m,
                      w: 80,
                      h: 116,
                      onTap: () => _showMovieInfo(m),
                    ),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.title,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text('${m.genre}  |  ${m.minutes ~/ 60}j ${m.minutes % 60}m',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 6),
                            Text('${rupiah(m.price)} / kursi',
                                style: const TextStyle(color: AppColors.lightBlue)),
                          ]),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  const Text('Tanggal',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Row(children: [
                    for (var i = 0; i < _dates.length; i++)
                      _chip(_dates[i], _date == i, () {
                        final t = _firstValid(i);
                        if (t == -1) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Semua jam tayang untuk hari ini sudah lewat. Silakan pilih hari Besok atau Lusa.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        setState(() {
                          _date = i;
                          if (_past(_date, _time)) _time = t;
                        });
                      }),
                  ]),
                  const SizedBox(height: 16),
                  const Text('Jam tayang',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      for (var i = 0; i < _times.length; i++)
                        Opacity(
                          opacity: _past(_date, i) ? 0.35 : 1,
                          child: _chip(_times[i], _time == i, () {
                            if (!_past(_date, i)) setState(() => _time = i);
                          }),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: const LinearGradient(colors: [
                        Colors.transparent,
                        AppColors.lightBlue,
                        Colors.transparent
                      ]),
                    ),
                  ),
                  const Center(
                      child: Padding(
                    padding: EdgeInsets.only(top: 6, bottom: 14),
                    child: Text('Layar',
                        style: TextStyle(color: Colors.white54, fontSize: 12)),
                  )),
                  Center(
                    child: Column(children: [
                      for (final r in _rows)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          for (var c = 1; c <= 6; c++) ...[
                            _seat('$r$c'),
                            if (c == 3) const SizedBox(width: 14),
                          ],
                        ]),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _Legend(color: Color(0x38FFFFFF), text: 'Tersedia'),
                    _Legend(color: AppColors.yellow, text: 'Dipilih'),
                    _Legend(color: Colors.white12, text: 'Terisi'),
                  ]),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: GlassBox(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_seats.isEmpty ? 'Pilih kursi' : sorted.join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(rupiah(total),
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 130,
                        child: Opacity(
                          opacity: _seats.isEmpty ? 0.4 : 1,
                          child: GradientButton(
                            text: 'Lanjut',
                            onTap: () {
                              if (_seats.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Silakan pilih minimal 1 kursi terlebih dahulu untuk melanjutkan ke pembayaran.'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                              if (_past(_date, _time)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Jam tayang yang dipilih sudah lewat. Silakan pilih jam lain.'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                              _next();
                            },
                          ),
                        ),
                      ),
                    ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;
  const _Legend({required this.color, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(children: [
          Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
      );
}
