import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;

  late final AnimationController _barController;
  late final Animation<double> _barWidth;

  late final AnimationController _taglineController;
  late final Animation<int> _letterCount;

  late final AnimationController _dotsController;
  late final Animation<double> _dotsFade;

  late final AnimationController _trianglesController;
  late final Animation<double> _trianglesFade;

  static const String _tagline = 'EQUIPPING EDUCATORS TO CHANGE THE WORLD';

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    );
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _barWidth = Tween<double>(begin: 0, end: 220).animate(
      CurvedAnimation(parent: _barController, curve: Curves.easeOut),
    );

    _taglineController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _tagline.length * 60),
    );
    _letterCount = IntTween(begin: 0, end: _tagline.length).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.linear),
    );

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _dotsFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _dotsController, curve: Curves.easeIn),
    );

    _trianglesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );
    _trianglesFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _trianglesController, curve: Curves.easeIn),
    );

    _startSequence();
  }

  void _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 1650));
    if (!mounted) return;
    _barController.forward();

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    _taglineController.forward();

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    _trianglesController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _dotsController.forward();
    // loop the dots pulse
    _dotsController.addStatusListener((status) {
      if (!mounted) return;
      if (status == AnimationStatus.completed) {
        _dotsController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _dotsController.forward();
      }
    });

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    context.go('/login');
  }

  @override
  void dispose() {
    _logoController.dispose();
    _barController.dispose();
    _taglineController.dispose();
    _dotsController.dispose();
    _trianglesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffffffff),
      body: Stack(
        children: [
          // Corner triangles
          AnimatedBuilder(
            animation: _trianglesFade,
            builder: (context, _) => Opacity(
              opacity: _trianglesFade.value,
              child: const _CornerTriangles(),
            ),
          ),
          // Main centered content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) => FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: child,
                    ),
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 260,
                  ),
                ),
                const SizedBox(height: 20),
                // Gold bar
                AnimatedBuilder(
                  animation: _barWidth,
                  builder: (context, _) => Container(
                    width: _barWidth.value,
                    height: 3,
                    color: const Color(0xfff9b625),
                  ),
                ),
                const SizedBox(height: 16),
                // Tagline
                AnimatedBuilder(
                  animation: _letterCount,
                  builder: (context, _) => Text(
                    _tagline.substring(0, _letterCount.value),
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.5,
                      color: Color(0xff555555),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Pulsing dots
                AnimatedBuilder(
                  animation: _dotsFade,
                  builder: (context, _) => Opacity(
                    opacity: _dotsFade.value,
                    child: const _PulsingDots(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDots extends StatelessWidget {
  const _PulsingDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Padding(
          padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xff007398),
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}

class _CornerTriangles extends StatelessWidget {
  const _CornerTriangles();

  static const _gold = Color(0xfff9b625);
  static const _orange = Color(0xffdd7d1b);
  static const _blue = Color(0xff3eb1c8);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Top-right corner
        Positioned(
          top: 0,
          right: 0,
          child: CustomPaint(
            size: const Size(90, 90),
            painter: _TrianglePainter(
              colors: [_gold, _orange, _blue],
              corner: _Corner.topRight,
            ),
          ),
        ),
        // Bottom-left corner
        Positioned(
          bottom: 0,
          left: 0,
          child: CustomPaint(
            size: const Size(90, 90),
            painter: _TrianglePainter(
              colors: [_gold, _orange, _blue],
              corner: _Corner.bottomLeft,
            ),
          ),
        ),
      ],
    );
  }
}

enum _Corner { topRight, bottomLeft }

class _TrianglePainter extends CustomPainter {
  const _TrianglePainter({
    required this.colors,
    required this.corner,
  });

  final List<Color> colors;
  final _Corner corner;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (corner == _Corner.topRight) {
      // Three layered triangles from largest to smallest, top-right corner
      _drawTriangle(
        canvas,
        [Offset(0, 0), Offset(w, 0), Offset(w, h)],
        colors[0],
      );
      _drawTriangle(
        canvas,
        [Offset(w * 0.35, 0), Offset(w, 0), Offset(w, h * 0.65)],
        colors[1],
      );
      _drawTriangle(
        canvas,
        [Offset(w * 0.65, 0), Offset(w, 0), Offset(w, h * 0.35)],
        colors[2],
      );
    } else {
      // Mirrored — bottom-left corner
      _drawTriangle(
        canvas,
        [Offset(0, 0), Offset(w, h), Offset(0, h)],
        colors[0],
      );
      _drawTriangle(
        canvas,
        [Offset(0, h * 0.35), Offset(w * 0.65, h), Offset(0, h)],
        colors[1],
      );
      _drawTriangle(
        canvas,
        [Offset(0, h * 0.65), Offset(w * 0.35, h), Offset(0, h)],
        colors[2],
      );
    }
  }

  void _drawTriangle(Canvas canvas, List<Offset> pts, Color color) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(pts[0].dx, pts[0].dy)
      ..lineTo(pts[1].dx, pts[1].dy)
      ..lineTo(pts[2].dx, pts[2].dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => false;
}
