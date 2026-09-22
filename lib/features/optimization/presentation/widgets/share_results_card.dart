import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/tokens/app_radius.dart';

/// Renders a shareable Moha Lab performance certificate card
/// and captures it as a PNG image for sharing.
class ShareResultsHelper {
  static final ScreenshotController _screenshotController =
      ScreenshotController();

  static Future<void> captureAndShare({
    required BuildContext context,
    required String profileName,
    required int toolsCount,
    required String deviceModel,
  }) async {
    try {
      final imageBytes = await _screenshotController.captureFromWidget(
        Material(
          color: Colors.transparent,
          child: _ShareCardGraphic(
            profileName: profileName,
            toolsCount: toolsCount,
            deviceModel: deviceModel,
          ),
        ),
        delay: const Duration(milliseconds: 50),
        pixelRatio: 2.5,
      );

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/moha_lab_optimization.png');
      await file.writeAsBytes(imageBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Just tuned my $deviceModel with Moha Lab Optimization! Applied $toolsCount safe tools using the $profileName profile.',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate share image: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _ShareCardGraphic extends StatelessWidget {
  const _ShareCardGraphic({
    required this.profileName,
    required this.toolsCount,
    required this.deviceModel,
  });

  final String profileName;
  final int toolsCount;
  final String deviceModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F17),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: const Color(0xFF1E56DE), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x331E56DE),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Moha Lab Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E56DE),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'MOHA LAB',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'OPTIMIZATION',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 12, color: Color(0xFF10B981)),
                    SizedBox(width: 4),
                    Text(
                      'VERIFIED SAFE',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Title
          const Text(
            'Performance\nSweep Certified',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // Stats Container
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF111724),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF243247)),
            ),
            child: Column(
              children: [
                _StatRow(
                  label: 'Target Device',
                  value: deviceModel,
                  color: Colors.white,
                ),
                const Divider(color: Color(0xFF243247), height: 16),
                _StatRow(
                  label: 'Profile Deployed',
                  value: profileName,
                  color: const Color(0xFF5B93FF),
                ),
                const Divider(color: Color(0xFF243247), height: 16),
                _StatRow(
                  label: 'Applied Kernel / System Tools',
                  value: '$toolsCount Active Modules',
                  color: const Color(0xFF10B981),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Footer
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hardware Grounded • Non-Root Tuning',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                't.me/mohalab',
                style: TextStyle(
                  color: Color(0xFF5B93FF),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
