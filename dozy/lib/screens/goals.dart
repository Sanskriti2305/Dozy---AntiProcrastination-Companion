import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/usage_insights_service.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen>
    with TickerProviderStateMixin {
  static const String _goalsStorageKey = 'dozy_goals_v1';
  final List<_Goal> _goals = [];

  final List<List<Color>> _gradients = [
    [Color(0xFF7C8BFF), Color(0xFFB07CFF)],
    [Color(0xFFFF6FD8), Color(0xFF3813C2)],
    [Color(0xFF00F5A0), Color(0xFF00D9F5)],
    [Color(0xFFFF9A9E), Color(0xFFFAD0C4)],
    [Color(0xFF6A11CB), Color(0xFF2575FC)],
  ];

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _addGoal(String title, DateTime? deadline) async {
    setState(() {
      _goals.add(
        _Goal(
          title: title,
          deadline: deadline,
          progress: Random().nextDouble(),
          gradient: _gradients[Random().nextInt(_gradients.length)],
        ),
      );
    });
    await _persistGoals();
    UsageInsightsService.notifyUsageChanged();
  }

  Future<void> _persistGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_goals.map((goal) => goal.toJson()).toList());
    await prefs.setString(_goalsStorageKey, encoded);
  }

  Future<void> _loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_goalsStorageKey);
    if (encoded == null || encoded.isEmpty) return;

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return;

      final loadedGoals = decoded
          .map((item) => _Goal.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();

      if (!mounted) return;
      setState(() {
        _goals
          ..clear()
          ..addAll(loadedGoals);
      });
    } catch (_) {
      // Ignore malformed local data and start with empty goals.
    }
  }

  void _showAddGoalDialog() {
    final controller = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) {
        return Center(
          child: Material(
            type: MaterialType.transparency,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: 420,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: StatefulBuilder(
                    builder: (context, setDialogState) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Create New Goal",
                            style: GoogleFonts.sora(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),

                          TextField(
                            controller: controller,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Goal title",
                              hintStyle: const TextStyle(color: Colors.white38),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// DEADLINE BUTTON
                          GestureDetector(
                            onTap: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                              );

                              if (picked != null) {
                                setDialogState(() {
                                  selectedDate = picked;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Colors.white.withOpacity(0.1),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    selectedDate == null
                                        ? "Optional Deadline"
                                        : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.calendar_today,
                                    color: Colors.white70,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C8BFF),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () async {
                              if (controller.text.isNotEmpty) {
                                await _addGoal(controller.text, selectedDate);
                              }
                              if (!context.mounted) return;
                              Navigator.pop(context);
                            },
                            child: const Text("Add Goal"),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// BACKGROUND IMAGE
          Positioned.fill(
            child: Image.asset("assets/goalsBG.jpg", fit: BoxFit.cover),
          ),

          /// DARK OVERLAY
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.7)),
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
                      "Your Goals",
                      style: GoogleFonts.sora(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C8BFF),
                      ),
                      onPressed: _showAddGoalDialog,
                      child: const Text("+ Add Goal"),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                Expanded(
                  child: GridView.builder(
                    itemCount: _goals.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4, // more columns = smaller cards
                          mainAxisSpacing: 25,
                          crossAxisSpacing: 25,
                          childAspectRatio: 1.1,
                        ),

                    itemBuilder: (context, index) {
                      final goal = _goals[index];
                      return _GoalCard(goal: goal);
                    },
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

class _Goal {
  final String title;
  final double progress;
  final List<Color> gradient;
  final DateTime? deadline;

  _Goal({
    required this.title,
    required this.progress,
    required this.gradient,
    this.deadline,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'progress': progress,
      'gradient': gradient.map((color) => color.toARGB32()).toList(),
      'deadline': deadline?.toIso8601String(),
    };
  }

  factory _Goal.fromJson(Map<String, dynamic> json) {
    final gradientValues = (json['gradient'] as List<dynamic>? ?? <dynamic>[])
        .map((value) => Color((value as num).toInt()))
        .toList();

    return _Goal(
      title: (json['title'] ?? '').toString(),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      gradient: gradientValues.length >= 2
          ? gradientValues
          : const [Color(0xFF7C8BFF), Color(0xFFB07CFF)],
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'].toString())
          : null,
    );
  }
}

class _GoalCard extends StatelessWidget {
  final _Goal goal;

  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: goal.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TITLE
          Text(
            goal.title,
            style: GoogleFonts.sora(
              fontSize: 24, // increased
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.2,
            ),
          ),

          const Spacer(),

          /// DEADLINE
          if (goal.deadline != null)
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Text(
                  "${goal.deadline!.day}/${goal.deadline!.month}/${goal.deadline!.year}",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
