import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/colors.dart';

class FloatingNav extends StatelessWidget {
  const FloatingNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onAddTap,
  });

  final int currentIndex;
  final void Function(int) onTap;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: kBgSurface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: kDivider, width: 1),
            ),
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  index: 0,
                  current: currentIndex,
                  onTap: onTap,
                ),
                _NavItem(
                  icon: Icons.group_rounded,
                  index: 1,
                  current: currentIndex,
                  onTap: onTap,
                ),
                // Center FAB slot
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        onAddTap();
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: kMint,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: kMint.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add_rounded,
                            color: kBgBase, size: 26),
                      ),
                    ),
                  ),
                ),
                _NavItem(
                  icon: Icons.receipt_long_rounded,
                  index: 3,
                  current: currentIndex,
                  onTap: onTap,
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  index: 4,
                  current: currentIndex,
                  onTap: onTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.index,
    required this.current,
    required this.onTap,
  });

  final IconData icon;
  final int index;
  final int current;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final selected = current == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap(index);
        },
        child: Center(
          child: Icon(
            icon,
            size: 24,
            color: selected ? kMint : kTextMuted,
          ),
        ),
      ),
    );
  }
}
