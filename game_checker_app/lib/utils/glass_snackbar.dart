import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GlassSnackBar {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isWarning = false,
  }) {
    // Menentukan warna aksen: Merah (Error), Kuning (Warning), atau Hijau Tosca Figma (Sukses)
    final Color accentColor = isError
        ? Colors.redAccent
        : (isWarning ? Colors.amberAccent : const Color(0xFF4EE2C0));

    final IconData iconData = isError
        ? Icons.error_outline_rounded
        : (isWarning
              ? Icons.warning_amber_rounded
              : Icons.check_circle_outline_rounded);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor:
            Colors.transparent, // Wajib transparan agar efek kaca terlihat
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 24, left: 20, right: 20),
        duration: const Duration(seconds: 3),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            // Efek Blur Kaca (Frosted Glass)
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                // Warna gelap semi-transparan (70% opacity)
                color: const Color(0xFF181C27).withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(16),
                // Garis batas bercahaya halus sesuai warna status
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(iconData, color: accentColor, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: GoogleFonts.figtree(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
