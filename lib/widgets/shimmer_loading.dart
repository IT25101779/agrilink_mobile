import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A shimmering placeholder box used while content loads, instead of a
/// bare spinner — makes loading states feel intentional rather than broken.
class ShimmerBox extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const ShimmerBox({super.key, required this.height, this.width, this.borderRadius});

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(10),
            gradient: LinearGradient(
              begin: Alignment(-1 + _controller.value * 2, 0),
              end: Alignment(1 + _controller.value * 2, 0),
              colors: const [AppColors.border, Color(0xFFF0F4F0), AppColors.border],
              stops: const [0.35, 0.5, 0.65],
            ),
          ),
        );
      },
    );
  }
}

/// A card-shaped shimmer, matching the app's standard list-item card size.
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const ShimmerBox(height: 44, width: 44, borderRadius: BorderRadius.all(Radius.circular(12))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(height: 14, width: MediaQuery.of(context).size.width * 0.4),
                const SizedBox(height: 8),
                ShimmerBox(height: 12, width: MediaQuery.of(context).size.width * 0.25),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
