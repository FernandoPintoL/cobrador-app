import 'package:flutter/material.dart';
import 'dart:math' as math;

class ModernStatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final double? progress; // 0.0 to 1.0
  final String? trend; // '+5%', '-3%', etc.
  final bool isIncreasing;
  final VoidCallback? onTap;

  const ModernStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.progress,
    this.trend,
    this.isIncreasing = true,
    this.onTap,
  });

  @override
  State<ModernStatCard> createState() => _ModernStatCardState();
}

class _ModernStatCardState extends State<ModernStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _progressAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      widget.color.withValues(alpha: 0.15),
                      widget.color.withValues(alpha: 0.05),
                    ]
                  : [
                      widget.color.withValues(alpha: 0.1),
                      widget.color.withValues(alpha: 0.05),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Background pattern
                Positioned(
                  right: -20,
                  top: -20,
                  child: Opacity(
                    opacity: 0.05,
                    child: Icon(widget.icon, size: 100, color: widget.color),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Adaptar tamaños según el espacio disponible
                      final isCompact = constraints.maxHeight < 140;
                      final iconSize = isCompact ? 20.0 : 24.0;
                      final iconPadding = isCompact ? 8.0 : 10.0;
                      final valueSize = isCompact ? 18.0 : 24.0;
                      final titleSize = isCompact ? 10.0 : 12.0;
                      final spacing = isCompact ? 6.0 : 10.0;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon and trend
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: EdgeInsets.all(iconPadding),
                                decoration: BoxDecoration(
                                  color: widget.color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  widget.icon,
                                  color: widget.color,
                                  size: iconSize,
                                ),
                              ),
                              if (widget.trend != null)
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: widget.isIncreasing
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          widget.isIncreasing
                                              ? Icons.trending_up
                                              : Icons.trending_down,
                                          size: 12,
                                          color: widget.isIncreasing
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                        const SizedBox(width: 2),
                                        Flexible(
                                          child: Text(
                                            widget.trend!,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: widget.isIncreasing
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          SizedBox(height: spacing),

                          // Value - con FittedBox para adaptarse
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                widget.value,
                                style: TextStyle(
                                  fontSize: valueSize,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ),

                          SizedBox(height: spacing * 0.4),

                          // Title
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: titleSize,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: isCompact ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // Progress bar
                          if (widget.progress != null && !isCompact) ...[
                            SizedBox(height: spacing),
                            AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, child) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value:
                                        widget.progress! *
                                        _progressAnimation.value,
                                    backgroundColor: isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      widget.color,
                                    ),
                                    minHeight: 5,
                                  ),
                                );
                              },
                            ),
                          ],

                          // Subtitle
                          if (widget.subtitle != null && !isCompact) ...[
                            SizedBox(height: spacing * 0.6),
                            Text(
                              widget.subtitle!,
                              style: TextStyle(
                                fontSize: 9,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[500],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Shimmer loading card for skeleton loading effect
class ModernStatCardSkeleton extends StatefulWidget {
  const ModernStatCardSkeleton({super.key});

  @override
  State<ModernStatCardSkeleton> createState() => _ModernStatCardSkeletonState();
}

class _ModernStatCardSkeletonState extends State<ModernStatCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment(-1.0 - _shimmerController.value * 2, 0),
              end: Alignment(1.0 - _shimmerController.value * 2, 0),
              colors: isDark
                  ? [Colors.grey[800]!, Colors.grey[700]!, Colors.grey[800]!]
                  : [Colors.grey[300]!, Colors.grey[200]!, Colors.grey[300]!],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableHeight = constraints.maxHeight;
                final isVeryCompact = availableHeight < 80;
                final isCompact = availableHeight < 100;

                final iconSize = isVeryCompact ? 24.0 : (isCompact ? 32.0 : 40.0);
                final valueHeight = isVeryCompact ? 14.0 : (isCompact ? 18.0 : 24.0);
                final titleHeight = isVeryCompact ? 6.0 : (isCompact ? 8.0 : 12.0);
                final spacing1 = isVeryCompact ? 4.0 : (isCompact ? 8.0 : 12.0);
                final spacing2 = isVeryCompact ? 2.0 : (isCompact ? 4.0 : 8.0);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[700] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(isVeryCompact ? 8 : 12),
                      ),
                    ),
                    SizedBox(height: spacing1),
                    Container(
                      width: isCompact ? 60 : 80,
                      height: valueHeight,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[700] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    SizedBox(height: spacing2),
                    Container(
                      width: isCompact ? 90 : 120,
                      height: titleHeight,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[700] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
