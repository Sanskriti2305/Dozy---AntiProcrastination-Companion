import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../services/api_service.dart';
import '../services/usage_insights_service.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen>
    with SingleTickerProviderStateMixin {

  VideoPlayerController? _videoController;
  bool _videoReady = false;

  Timer? _timer;

  int _totalSeconds = 1500;
  int _remainingSeconds = 1500;

  bool _isRunning = false;
  bool _hasStartedOnce = false; // NEW

  double? _riskScore;

  final TextEditingController _h = TextEditingController();
  final TextEditingController _m = TextEditingController();
  final TextEditingController _s = TextEditingController();

  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();

    _videoController =
        VideoPlayerController.asset("assets/focusVideo.mp4")
          ..initialize().then((_) {
            _videoController!.setLooping(true);
            _videoController!.setVolume(0);
            _videoController!.play();
            setState(() => _videoReady = true);
          });

    _glowController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
  }

  // ---------------- START / RESUME ----------------
  void _start() async {
    if (_isRunning) return;

    // Only call ML the first time session starts
    if (!_hasStartedOnce) {
      try {
        final result = await ApiService.predict(
          startDelay: 120,
          lastMinuteRush: 1,
          focusRating: 6,
          distractions: 3,
          coffee: 200,
          qualityScore: 7,
          stressLevel: 8,
          complexityLow: 0,
          complexityMedium: 1,
        );

        _riskScore = result["risk_score"];
        print("Procrastination Risk: $_riskScore");

      } catch (e) {
        print("Prediction error: $e");
      }

      _hasStartedOnce = true;
    }

    _isRunning = true;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async{
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        _isRunning = false;

        if (_riskScore != null) {
          await UsageInsightsService.logFocusSession(
            durationSeconds: _totalSeconds,
            remainingSeconds: _remainingSeconds,
            riskScore: _riskScore!,
          );
          final completed = _remainingSeconds == 0;

        if (completed) {
          _showSuccessFeedback();
        } else {
          _showDozyFeedback();
        }
        }
      }

    });
  }

  // ---------------- PAUSE ----------------
  void _pause() {
    _timer?.cancel();
    _isRunning = false;
  }

  // ---------------- STOP ----------------
  void _stop() async {
    _timer?.cancel();
    _isRunning = false;

    if (_riskScore != null) {
      await UsageInsightsService.logFocusSession(
        durationSeconds: _totalSeconds,
        remainingSeconds: _remainingSeconds,
        riskScore: _riskScore!,
      );
      _showDozyFeedback();
    }

    setState(() {
      _remainingSeconds = _totalSeconds;
    });

    _hasStartedOnce = false;
  }

  // ---------------- FEEDBACK ----------------
  void _showDozyFeedback() {
    String message;

    if (_riskScore! > 0.85) {
      message =
          "High procrastination risk detected.\n\nTry:\n• Remove distractions\n• Use 5-minute micro start\n• Reduce stress before restarting.";
    } else if (_riskScore! > 0.6) {
      message =
          "Moderate risk.\n\nTry:\n• Set smaller goals\n• Work in 25 min sprints\n• Lower coffee intake.";
    } else {
      message =
          "Great focus discipline.\n\nKeep going. You’re in control.";
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Dozy Says",
                      style: GoogleFonts.sora(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      message,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 25),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Got it"),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSuccessFeedback() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Dozy Says",
                      style: GoogleFonts.sora(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Excellent discipline. You completed your focus session successfully. Keep stacking wins.",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 25),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Nice"),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  // ---------------- TIME FORMAT ----------------
  String get time {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  double get progress => 1 - (_remainingSeconds / _totalSeconds);

  // ---------------- SET TIME DIALOG (UNCHANGED) ----------------
  void _showSetTimeDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        return Center(
          child: Material(
            type: MaterialType.transparency,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: 500,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 35),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Set Focus Time",
                        style: GoogleFonts.sora(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 35),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          _timeField(_h, "HH"),
                          const Text(" : ",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24)),
                          _timeField(_m, "MM"),
                          const Text(" : ",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24)),
                          _timeField(_s, "SS"),
                        ],
                      ),
                      const SizedBox(height: 35),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C8BFF),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          int hours =
                              int.tryParse(_h.text) ?? 0;
                          int mins =
                              int.tryParse(_m.text) ?? 0;
                          int secs =
                              int.tryParse(_s.text) ?? 0;

                          int total =
                              hours * 3600 +
                                  mins * 60 +
                                  secs;

                          if (total > 0) {
                            setState(() {
                              _totalSeconds = total;
                              _remainingSeconds = total;
                            });
                          }

                          Navigator.pop(context);
                        },
                        child: Text(
                          "Apply",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.white,
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
      },
    );
  }

  Widget _timeField(TextEditingController c, String hint) {
    return SizedBox(
      width: 90,
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 20),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _timer?.cancel();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          Positioned.fill(
            child: _videoReady
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController!.value.size.width,
                      height: _videoController!.value.size.height,
                      child: VideoPlayer(_videoController!),
                    ),
                  )
                : Container(color: Colors.black),
          ),

          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xCC0E1324),
                    Color(0x990E1324),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Text(
                    "Deep Focus",
                    style: GoogleFonts.sora(
                      fontSize: 64,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 50),

                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) {
                      return Container(
                        width: 360,
                        height: 360,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: _isRunning
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF7C8BFF)
                                        .withOpacity(
                                            0.3 + _glowController.value * 0.3),
                                    blurRadius: 60,
                                    spreadRadius: 5,
                                  )
                                ]
                              : [],
                        ),
                        child: child,
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(200),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(320, 320),
                                painter: _ProgressPainter(progress),
                              ),
                              Text(
                                time,
                                style: GoogleFonts.sora(
                                  fontSize: 72,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _controlButton(
                          _isRunning ? "Resume" : "Start",
                          _start),
                      const SizedBox(width: 20),
                      _controlButton("Pause", _pause),
                      const SizedBox(width: 20),
                      _controlButton("Stop", _stop),
                      const SizedBox(width: 20),
                      _controlButton("Set Time",
                          _showSetTimeDialog),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlButton(String text, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.15),
        padding: const EdgeInsets.symmetric(
            horizontal: 28, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      onPressed: onTap,
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  final double progress;
  _ProgressPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final bg = Paint()
      ..color = Colors.white24
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    final fg = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF7C8BFF), Color(0xFFB07CFF)],
      ).createShader(rect)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -pi / 2, 2 * pi, false, bg);
    canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, fg);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
