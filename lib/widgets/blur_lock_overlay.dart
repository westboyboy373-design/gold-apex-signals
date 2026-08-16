import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Wraps [child] with a frosted blur + lock CTA when [locked] is true.
/// When [locked] is false, renders [child] untouched.
class BlurLockOverlay extends StatelessWidget {
  final bool locked;
  final Widget child;
  final String label;
  final VoidCallback onUnlockTap;

  const BlurLockOverlay({
    super.key,
    required this.locked,
    required this.child,
    required this.onUnlockTap,
    this.label = 'Unlock for 50 coins',
  });

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(child: child),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
              child: Container(color: Colors.black.withValues(alpha: 0.45)),
            ),
          ),
          InkWell(
            onTap: onUnlockTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock, size: 16, color: Colors.black),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
