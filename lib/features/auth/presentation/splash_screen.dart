import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgBase,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: kMint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: kMint.withValues(alpha: 0.3)),
              ),
              alignment: Alignment.center,
              child: const Text(
                'S',
                style: TextStyle(
                  color: kMint,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Settle', style: amountStyle(size: 32, color: kTextPrimary)),
            const SizedBox(height: 48),
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: kMint),
            ),
          ],
        ),
      ),
    );
  }
}
