import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';
import 'dart:async';
import 'sign_in_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<FootballMatch> _matchList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Icon(
                        Icons.sports_soccer,
                        size: 200,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 24, bottom: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.sports_soccer, color: Colors.white, size: 32),
                          const SizedBox(height: 8),
                          const Text(
                            "Live Scores",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Real-time match updates",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () => setState(() {}),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () => _showLogoutDialog(),
              ),
            ],
          ),
          StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('football')
                .orderBy('is_running', descending: true)
                .snapshots(),
            builder: (context, snapshots) {
              if (snapshots.connectionState == ConnectionState.waiting) {
                return SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
                  ),
                );
              } else if (snapshots.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text(snapshots.error.toString())),
                );
              } else if (snapshots.hasData) {
                _matchList.clear();
                for (var doc in snapshots.data!.docs) {
                  final data = doc.data();
                  _matchList.add(
                    FootballMatch(
                      id: doc.id,
                      team1: data["team1_name"] ?? "Unknown",
                      team1Score: data["team1_score"] ?? 0,
                      team2: data["team2_name"] ?? "Unknown",
                      team2Score: data["team2_score"] ?? 0,
                      isRunning: data["is_running"] ?? false,
                      winner: data["winner_team"] ?? "TBD",
                      team1CountryCode: (data["team1_country_code"] ?? "br").toString().toLowerCase(),
                      team2CountryCode: (data["team2_country_code"] ?? "ar").toString().toLowerCase(),
                    ),
                  );
                }

                if (_matchList.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text("No matches available")),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _MatchCard(match: _matchList[index]),
                      childCount: _matchList.length,
                    ),
                  ),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox());
            },
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          FilledButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const SignInScreen()),
                  (route) => false,
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatefulWidget {
  final FootballMatch match;
  const _MatchCard({required this.match});

  @override
  State<_MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<_MatchCard> {
  Timer? _timer;
  int _minutes = 0;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    if (widget.match.isRunning) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds++;
          if (_seconds >= 60) {
            _seconds = 0;
            _minutes++;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime() => '${_minutes.toString().padLeft(2, '0')}:${_seconds.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isLive = widget.match.isRunning;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isLive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.red[600]!, Colors.red[400]!]),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  const Text("LIVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatTime(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTeamInfo(widget.match.team1, widget.match.team1CountryCode),
                    _buildScoreBox("${widget.match.team1Score} - ${widget.match.team2Score}"),
                    _buildTeamInfo(widget.match.team2, widget.match.team2CountryCode),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isLive ? Colors.green.withOpacity(0.1) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isLive ? Colors.green.withOpacity(0.3) : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isLive ? Icons.play_circle : Icons.emoji_events,
                        size: 20,
                        color: isLive ? Colors.green[700] : Colors.amber[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isLive ? "Match in Progress" : "Winner: ${widget.match.winner}",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isLive ? Colors.green[700] : Colors.grey[700],
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

  Widget _buildTeamInfo(String name, String code) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[300]!, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: CountryFlag.fromCountryCode(
              code,
              height: 60,
              width: 60,
              shape: const Circle(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBox(String score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        score,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class FootballMatch {
  final String id;
  final String team1;
  final int team1Score;
  final String team2;
  final int team2Score;
  final bool isRunning;
  final String winner;
  final String team1CountryCode;
  final String team2CountryCode;

  FootballMatch({
    required this.id,
    required this.team1,
    required this.team1Score,
    required this.team2,
    required this.team2Score,
    required this.isRunning,
    required this.winner,
    required this.team1CountryCode,
    required this.team2CountryCode,
  });
}