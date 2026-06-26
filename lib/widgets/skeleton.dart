import 'package:flutter/material.dart';

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 0.7).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _anim, child: widget.child);
}

class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});
  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonBox({super.key, required this.width, required this.height, this.radius = 8});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF2A3A4A),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 100, height: 14),
          const SizedBox(height: 8),
          const SkeletonBox(width: 200, height: 28, radius: 6),
          const SizedBox(height: 24),
          Row(children: const [
            Expanded(child: CardSkeleton(height: 72)),
            SizedBox(width: 12),
            Expanded(child: CardSkeleton(height: 72)),
          ]),
          const SizedBox(height: 12),
          const CardSkeleton(height: 60),
          const SizedBox(height: 20),
          const CardSkeleton(height: 220),
          const SizedBox(height: 16),
          const CardSkeleton(height: 120),
          const SizedBox(height: 16),
          const CardSkeleton(height: 100),
          const SizedBox(height: 16),
          const CardSkeleton(height: 180),
        ],
      ),
    );
  }
}

class CardSkeleton extends StatelessWidget {
  final double height;
  const CardSkeleton({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF1E2A3A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
      ),
    );
  }
}
