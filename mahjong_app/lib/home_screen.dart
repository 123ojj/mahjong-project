import 'package:flutter/material.dart';
import 'game_table.dart';
import 'game_ledger_screen.dart';
import 'player_stats_screen.dart';

class GameSessionScreen extends StatefulWidget {
  final String? gameName;
  final List<String> players;
  final int initialDealerIndex;
  final int baseScore;
  final int taiScore;
  final String? initialHistoryJson;
  final List<int>? initialScores;
  final List<int>? initialWinCount;
  final List<int>? initialSelfDrawnCount;
  final List<int>? initialChuckCount;
  final bool isLocked;

  const GameSessionScreen({
    Key? key,
    this.gameName,
    required this.players,
    required this.initialDealerIndex,
    required this.baseScore,
    required this.taiScore,
    this.initialHistoryJson,
    this.initialScores,
    this.initialWinCount,
    this.initialSelfDrawnCount,
    this.initialChuckCount,
    this.isLocked = true,
  }) : super(key: key);

  @override
  _GameSessionScreenState createState() => _GameSessionScreenState();
}

class _GameSessionScreenState extends State<GameSessionScreen> {
  int _currentIndex = 0;
  final GlobalKey<GameTableScreenState> _tableKey = GlobalKey<GameTableScreenState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Offstage(
            offstage: _currentIndex != 0,
            child: GameTableScreen(
              key: _tableKey,
              gameName: widget.gameName,
              players: widget.players,
              initialDealerIndex: widget.initialDealerIndex,
              baseScore: widget.baseScore,
              taiScore: widget.taiScore,
              initialHistoryJson: widget.initialHistoryJson,
              initialScores: widget.initialScores,
              initialWinCount: widget.initialWinCount,
              initialSelfDrawnCount: widget.initialSelfDrawnCount,
              initialChuckCount: widget.initialChuckCount,
              isLocked: widget.isLocked,
            ),
          ),
          if (_currentIndex == 1) GameLedgerScreen(tableKey: _tableKey, players: widget.players),
          if (_currentIndex == 2) PlayerStatsScreen(tableKey: _tableKey, players: widget.players),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFE8E8E8), // Light color based on screenshot
        selectedItemColor: Colors.green[800],
        unselectedItemColor: Colors.grey[600],
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.casino), label: '目前牌局'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: '牌局紀錄'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '數據統計'),
        ],
      ),
    );
  }
}
