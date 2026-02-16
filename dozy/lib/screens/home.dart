import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class HomeScreen extends StatelessWidget {
  final VoidCallback onStartFocus;

  const HomeScreen({
    super.key,
    required this.onStartFocus,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          /// 🔹 FULLSCREEN BACKGROUND
          Positioned.fill(
            child: Image.asset(
              "assets/bg.jpg",
              fit: BoxFit.cover,
            ),
          ),

          /// 🔹 DARK GRADIENT OVERLAY
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xCC0B0F1C),
                    Color(0x990B0F1C),
                    Colors.transparent,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),

          /// 🔹 TOP RIGHT BRAND NAME
          /// 🔹 TOP RIGHT BRAND NAME WITH GLASS CIRCLE
          Positioned(
            top: 40,
            right: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    "Dozy",
                    style: GoogleFonts.sora(
                      fontSize: 36, // bigger
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: const Color(0xFF8F5CFF),
                          blurRadius: 25,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),


          /// 🔹 HERO CONTENT
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 120),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 650,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// BIG TITLE
                    Text(
                      "Welcome back",
                      style: GoogleFonts.poppins(
                        fontSize: 72,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// SUBTITLE
                    Text(
                      "What would you like to conquer today?",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        height: 1.6,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),

                    const SizedBox(height: 40),

                    /// Focus BUTTON (Professional Touch)
                    GestureDetector(
                      onTap: onStartFocus,   
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF5B7CFF),
                              Color(0xFF8F5CFF),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5B7CFF)
                                  .withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Text(
                          "Start Focus Session",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
