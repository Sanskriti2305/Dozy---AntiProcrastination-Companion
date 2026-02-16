import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/usage_insights_service.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  UsageInsightsSummary _summary = const UsageInsightsSummary.empty();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInsights();
    UsageInsightsService.usageVersion.addListener(_onUsageChanged);
  }

  @override
  void dispose() {
    UsageInsightsService.usageVersion.removeListener(_onUsageChanged);
    super.dispose();
  }

  void _onUsageChanged() {
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    final summary = await UsageInsightsService.getSummary();
    if (!mounted) return;

    setState(() {
      _summary = summary;
      _isLoading = false;
    });
  }

  String _formatSessionDuration(int seconds) {
    if (seconds >= 3600) {
      final hours = seconds ~/ 3600;
      final mins = (seconds % 3600) ~/ 60;
      if (mins == 0) return "${hours}h";
      return "${hours}h ${mins}m";
    }

    if (seconds >= 60) {
      final mins = seconds ~/ 60;
      final secs = seconds % 60;
      if (secs == 0) return "${mins}m";
      return "${mins}m ${secs}s";
    }

    return "${seconds}s";
  }

  String _formatTotalFocusTime(int totalSeconds) {
    if (totalSeconds <= 0) {
      return "0s";
    }

    if (totalSeconds < 60) {
      return "${totalSeconds}s";
    }

    if (totalSeconds < 3600) {
      final mins = totalSeconds ~/ 60;
      final secs = totalSeconds % 60;
      if (secs == 0) return "${mins}m";
      return "${mins}m ${secs}s";
    }

    if (totalSeconds < 86400) {
      final hours = totalSeconds ~/ 3600;
      final mins = (totalSeconds % 3600) ~/ 60;
      if (mins == 0) return "${hours}h";
      return "${hours}h ${mins}m";
    }

    final days = totalSeconds ~/ 86400;
    final hours = (totalSeconds % 86400) ~/ 3600;
    if (hours == 0) return "${days}d";
    return "${days}d ${hours}h";
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/insightsBG.jpg", fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.75)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Insights",
                      style: GoogleFonts.sora(
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: _loadInsights,
                      icon: const Icon(Icons.refresh, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 50),
                Expanded(
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: _GlassCard(
                          width: 520,
                          height: 320,
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Productivity Intelligence",
                                      style: GoogleFonts.sora(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      _summary.headline,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      "${_summary.weeklyTrendLabel} • Avg risk ${_summary.averageRiskPercent.toStringAsFixed(1)}%",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.white60,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Total focused time: ${ _formatTotalFocusTime(_summary.totalFocusedSeconds)}",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.white60,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        child: _SmallStatCard(
                          title: "Focus Sessions",
                          value: "${_summary.totalSessions}",
                          accent: Colors.purpleAccent,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _SmallStatCard(
                          title: "Avg Session",
                          value: _formatSessionDuration(
                            _summary.averageSessionSeconds,
                          ),
                          accent: Colors.blueAccent,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: _SmallStatCard(
                          title: "Completion Rate",
                          value: "${_summary.completionRatePercent}%",
                          accent: Colors.greenAccent,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: _SmallStatCard(
                          title: "Goals Added",
                          value: "${_summary.goalsAdded}",
                          accent: Colors.pinkAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final double width;
  final double height;
  final Widget child;

  const _GlassCard({
    required this.width,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SmallStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color accent;

  const _SmallStatCard({
    required this.title,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: 260,
          height: 150,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
              ),
              const Spacer(),
              Text(
                value,
                style: GoogleFonts.sora(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
