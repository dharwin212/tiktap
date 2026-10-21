import 'dart:math' as math;
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import '../models.dart';
import '../nav_menu.dart';
import '../theme.dart';

/// Langkah 3: Mobile Ticket dengan barcode, muncul setelah pembayaran.
class TicketScreen extends StatelessWidget {
  const TicketScreen({super.key});

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Row(children: [
          RoundIconButton(icon: Icons.arrow_back, onTap: () => AppState.I.goTo(0)),
          const Expanded(
            child: Center(
              child: Text('Mobile Ticket',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            ),
          ),
          const NavMenuButton(),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final list = AppState.I.active;

    if (list.isEmpty) {
      return Column(children: [
        _header(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.confirmation_number_outlined,
                    size: 56, color: Colors.white54),
                const SizedBox(height: 12),
                const Text('Belum ada tiket',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                const Text('Barcode tiket muncul di sini setelah kamu membayar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 20),
                SizedBox(
                    width: 180,
                    child: GradientButton(
                        text: 'Pesan tiket', onTap: () => AppState.I.goTo(0))),
              ]),
            ),
          ),
        ),
        SizedBox(height: 80 + MediaQuery.paddingOf(context).bottom),
      ]);
    }

    return Column(children: [
      _header(),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 8),
        child: Text(
          'Once you buy a movie ticket simply scan the barcode to access your movie.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, height: 1.35),
        ),
      ),
      Expanded(child: _TicketCarousel(tickets: list)),
      SizedBox(height: 80 + MediaQuery.paddingOf(context).bottom),
    ]);
  }
}

/// Tiket bertumpuk: yang aktif di tengah, tiket lain mengintip di kiri/kanan
/// (lebih kecil dan redup). Bisa digeser atau diketuk untuk dipindah ke tengah.
class _TicketCarousel extends StatefulWidget {
  final List<Ticket> tickets;
  const _TicketCarousel({required this.tickets});

  @override
  State<_TicketCarousel> createState() => _TicketCarouselState();
}

class _TicketCarouselState extends State<_TicketCarousel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim =
      AnimationController.unbounded(vsync: this, value: 0);
  double _step = 75; // jarak geser antar tiket (px)

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _TicketCarousel old) {
    super.didUpdateWidget(old);
    final n = widget.tickets.length;
    if (n > old.tickets.length) {
      // Tiket baru dibeli (ada di urutan pertama) -> tampilkan di tengah.
      _anim.animateTo(0,
          duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    } else if (_anim.value > n - 1) {
      _anim.value = (n - 1).toDouble();
    }
  }

  void _go(int i) => _anim.animateTo(i.toDouble(),
      duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);

  Widget _slot(int i, double pos, double s) {
    final delta = i - pos;
    final d = delta.abs().clamp(0.0, 1.0);
    final opacity = delta.abs() <= 1
        ? 1 - 0.3 * d
        : (2 - delta.abs()).clamp(0.0, 1.0) * 0.7;
    return Transform.translate(
      offset: Offset(delta * _step, 0),
      child: GestureDetector(
        onTap: () => _go(i),
        child: Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: s * (1 - 0.12 * d),
            child: _TicketCard(t: widget.tickets[i], glow: 1 - d),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.tickets.length;
    return LayoutBuilder(builder: (context, c) {
      final s = math.min(
          1.0,
          math.min((c.maxHeight - 56) / _TicketCard._h,
              (c.maxWidth * 0.66) / _TicketCard._w));
      _step = _TicketCard._w * s * 0.30;
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (d) {
          _anim.stop();
          _anim.value =
              (_anim.value - d.delta.dx / _step).clamp(0.0, (n - 1).toDouble());
        },
        onHorizontalDragEnd: (d) {
          final v = -(d.primaryVelocity ?? 0) / _step;
          _go((_anim.value + v * 0.2).round().clamp(0, n - 1));
        },
        child: SizedBox(
          width: c.maxWidth,
          height: c.maxHeight,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) {
              final pos = _anim.value;
              // Yang terjauh digambar lebih dulu, yang paling dekat paling atas.
              final order = List<int>.generate(n, (i) => i)
                ..sort((a, b) => (b - pos).abs().compareTo((a - pos).abs()));
              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  for (final i in order)
                    if ((i - pos).abs() < 2.2) _slot(i, pos, s),
                ],
              );
            },
          ),
        ),
      );
    });
  }
}

class _NotchClipper extends CustomClipper<Path> {
  final double notchY;
  const _NotchClipper(this.notchY);

  @override
  Path getClip(Size s) {
    final card = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(22)));
    final notch = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, notchY), radius: 14))
      ..addOval(Rect.fromCircle(center: Offset(s.width, notchY), radius: 14));
    return Path.combine(PathOperation.difference, card, notch);
  }

  @override
  bool shouldReclip(covariant _NotchClipper old) => old.notchY != notchY;
}

/// Bayangan jatuh + cahaya tosca di sekeliling tiket (mengikuti bentuk bertakik).
class _GlowPainter extends CustomPainter {
  final double notchY;
  final double glow; // 0..1, kuat saat tiket di tengah
  const _GlowPainter(this.notchY, this.glow);

  static const _teal = Color(0xFF6CB8FF);

  @override
  void paint(Canvas canvas, Size size) {
    final path = _NotchClipper(notchY).getClip(size);
    canvas.drawPath(
      path.shift(const Offset(0, 16)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
    if (glow > 0.01) {
      canvas.drawPath(
        path,
        Paint()
          ..color = _teal.withValues(alpha: 0.55 * glow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = _teal.withValues(alpha: 0.9 * glow),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GlowPainter old) =>
      old.glow != glow || old.notchY != notchY;
}

class _TicketCard extends StatelessWidget {
  final Ticket t;
  final double glow;
  const _TicketCard({required this.t, this.glow = 0});

  static const _w = 250.0;
  static const _posterH = 290.0;
  static const _h = 440.0;

  Widget _info(String label, String value, {int flex = 1}) => Expanded(
        flex: flex,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF5B2A86),
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Color(0xFF14202B),
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final m = t.movie;
    return SizedBox(
      width: _w,
      height: _h,
      child: CustomPaint(
        painter: _GlowPainter(_posterH, glow),
        child: ClipPath(
        clipper: const _NotchClipper(_posterH),
        child: Column(children: [
          // Poster
          Container(
            height: _posterH,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: m.colors,
              ),
            ),
            child: Stack(fit: StackFit.expand, children: [
              if (m.posterAsset != null)
                Image.asset(m.posterAsset!,
                    fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 22),
                  child: Text(m.title.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: const TextStyle(
                          fontSize: 22,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ),
          // Bagian detail + barcode
          Container(
            height: _h - _posterH,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            color: const Color(0xFFE9EEF4),
            child: Column(children: [
              const SizedBox(
                  height: 14,
                  child: Center(child: DashedLine(color: Colors.black45))),
              Row(children: [
                _info('Date', t.date, flex: 3),
                _info('Time', t.time, flex: 2),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                _info('Row', seatRows(t.seats)),
                _info('Seats', seatNumbers(t.seats)),
              ]),
              const SizedBox(height: 10),
              Expanded(
                child: BarcodeWidget(
                  barcode: Barcode.code128(),
                  data: t.id,
                  drawText: false,
                  color: Colors.black,
                  errorBuilder: (_, __) => const SizedBox(),
                ),
              ),
              const SizedBox(height: 4),
              Text(t.id,
                  style: const TextStyle(
                      color: Colors.black54, fontSize: 10, letterSpacing: 2)),
            ]),
          ),
        ]),
      ),
      ),
    );
  }
}
