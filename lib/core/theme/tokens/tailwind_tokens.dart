import 'package:flutter/material.dart';

/// Tailwind CSS & Bootstrap design tokens for Flutter.
///
/// Implements authentic Tailwind utility color scales (Zinc, Slate, Emerald, Blue, etc.)
/// and Bootstrap semantic patterns (Card, Badge, ListGroup) to give the application
/// a clean, disciplined, professional developer-grade aesthetic without AI slop.
abstract final class TailwindColors {
  // ── Zinc Neutral Scale (Default Dark Theme Foundation) ─────────────────────
  static const Color zinc50 = Color(0xFFFAFAFA);
  static const Color zinc100 = Color(0xFFF4F4F5);
  static const Color zinc200 = Color(0xFFE4E4E7);
  static const Color zinc300 = Color(0xFFD4D4D8);
  static const Color zinc400 = Color(0xFFA1A1AA);
  static const Color zinc500 = Color(0xFF71717A);
  static const Color zinc600 = Color(0xFF52525B);
  static const Color zinc700 = Color(0xFF3F3F46);
  static const Color zinc800 = Color(0xFF27272A);
  static const Color zinc900 = Color(0xFF18181B);
  static const Color zinc950 = Color(0xFF09090B);

  // ── Slate Neutral Scale ────────────────────────────────────────────────────
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF020617);

  // ── Semantic Accents ───────────────────────────────────────────────────────
  // Emerald (Success / Optimal / Active)
  static const Color emerald400 = Color(0xFF34D399);
  static const Color emerald500 = Color(0xFF10B981);
  static const Color emerald600 = Color(0xFF059669);
  static const Color emerald950 = Color(0xFF022C22);

  // Blue (Primary / Focus / Information)
  static const Color blue400 = Color(0xFF60A5FA);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue600 = Color(0xFF2563EB);
  static const Color blue950 = Color(0xFF172554);

  // Amber (Warning / Pending / Cache)
  static const Color amber400 = Color(0xFFFBBF24);
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber600 = Color(0xFFD97706);
  static const Color amber950 = Color(0xFF451A03);

  // Rose (Danger / High Performance / Throttle)
  static const Color rose400 = Color(0xFFFB7185);
  static const Color rose500 = Color(0xFFF43F5E);
  static const Color rose600 = Color(0xFFE11D48);
  static const Color rose950 = Color(0xFF4C0519);

  // Indigo / Violet (Privileged / Shizuku)
  static const Color indigo400 = Color(0xFF818CF8);
  static const Color indigo500 = Color(0xFF6366F1);
  static const Color indigo600 = Color(0xFF4F46E5);
  static const Color indigo950 = Color(0xFF1E1B4B);
}

/// Bootstrap semantic color tokens
abstract final class BootstrapColors {
  static const Color primary = Color(0xFF0D6EFD);
  static const Color secondary = Color(0xFF6C757D);
  static const Color success = Color(0xFF198754);
  static const Color danger = Color(0xFFDC3545);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF0DCAF0);
  static const Color light = Color(0xFFF8F9FA);
  static const Color dark = Color(0xFF212529);
}
