import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'game_table.dart';

class PlayerStatsScreen extends StatelessWidget {
  final GlobalKey<GameTableScreenState> tableKey;
  final List<String> players;
  final GlobalKey _boundaryKey = GlobalKey();

  PlayerStatsScreen({Key? key, required this.tableKey, required this.players}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = tableKey.currentState;
    if (state == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('當局玩家數據', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Colors.green[800],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final snap = state.currentStateSnapshot;
    // totalHandsPlayed is at index 36. Since it starts at 1 and represents the "current" hand, 
    // the completed hands is (snap[36] - 1). If 0, we avoid division by zero.
    int games = snap[36] - 1;
    if (games <= 0) games = 1; 

    List<Map<String, dynamic>> fourPlayerStats = [];
    for (int i = 0; i < 4; i++) {
      fourPlayerStats.add({
        'totalScore': snap[i],
        'selfDrawnTimes': snap[4 + i],
        'winTimes': snap[8 + i],
        'chuckTimes': snap[12 + i],
        'gotSelfDrawnTimes': snap[16 + i],
        'highestTai': snap[20 + i],
        'maxCombo': snap[24 + i],
        'winRate': (snap[8 + i] / games) * 100,
        'selfDrawnRate': (snap[4 + i] / games) * 100,
        'chuckRate': (snap[12 + i] / games) * 100,
        'gotSelfDrawnRate': (snap[16 + i] / games) * 100,
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('當局玩家數據', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.green[800],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => _captureAndShare(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: RepaintBoundary(
          key: _boundaryKey,
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
            _buildHeaderRow(),
            const Divider(height: 1, thickness: 1),
            _buildStatRow('分數', fourPlayerStats, (stats) {
              int score = stats['totalScore'] ?? 0;
              return Text(
                '${score > 0 ? '+' : ''}$score',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: score >= 0 ? Colors.green[700] : Colors.red[700]),
              );
            }),
            const Divider(height: 1),
            _buildStatRow('勝率', fourPlayerStats, (stats) {
              double rate = stats['winRate'] ?? 0.0;
              return Text('${rate.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87));
            }),
            const Divider(height: 1),
            _buildStatRow('摸魚率', fourPlayerStats, (stats) {
              double win = stats['winRate'] ?? 0.0;
              double chuck = stats['chuckRate'] ?? 0.0;
              double slack = 100.0 - win - chuck;
              if (slack < 0) slack = 0;
              return Text('${slack.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87));
            }),
            const Divider(height: 1),
            _buildStatRowDual('自摸', '自摸率', 'selfDrawnTimes', 'selfDrawnRate', fourPlayerStats),
            const Divider(height: 1),
            _buildStatRowDual('胡牌', '胡牌率', 'winTimes', 'winRate', fourPlayerStats),
            const Divider(height: 1),
            _buildStatRowDual('放槍', '放槍率', 'chuckTimes', 'chuckRate', fourPlayerStats),
            const Divider(height: 1),
            _buildStatRowDual('被自摸', '被自摸率', 'gotSelfDrawnTimes', 'gotSelfDrawnRate', fourPlayerStats),
            const Divider(height: 1),
            _buildStatRowDual('最高台數', '單局', 'highestTai', null, fourPlayerStats, isRate: false),
            const Divider(height: 1),
            _buildStatRowDual('最多連莊', '次數', 'maxCombo', null, fourPlayerStats, isRate: false),
            const Divider(height: 1),
          ],
        ),
      ),
      ),
      ),
    );
  }

  Future<void> _captureAndShare(BuildContext context) async {
    try {
      RenderRepaintBoundary? boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        Uint8List pngBytes = byteData.buffer.asUint8List();
        
        final directory = await getTemporaryDirectory();
        final imagePath = File('${directory.path}/mahjong_stats.png');
        await imagePath.writeAsBytes(pngBytes);
        
        await Share.shareXFiles([XFile(imagePath.path)], text: '今晚的麻將戰績出爐囉！');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('分享失敗：$e')));
      }
    }
  }

  Widget _buildHeaderRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Container(
            width: 80,
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_list, size: 16, color: Colors.black87),
                  SizedBox(width: 4),
                  Text('項目', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
            ),
          ),
          ...List.generate(4, (index) {
            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.casino, color: Colors.green),
                  ),
                  const SizedBox(height: 8),
                  Text(players[index], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatRow(String title, List<Map<String, dynamic>> fourPlayerStats, Widget Function(Map<String, dynamic> stats) builder) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
          ),
          ...List.generate(4, (index) {
            return Expanded(
              child: Center(
                child: builder(fourPlayerStats[index]),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatRowDual(String title, String subTitle, String countKey, String? rateKey, List<Map<String, dynamic>> fourPlayerStats, {bool isRate = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Column(
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                Text('($subTitle)', style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          ...List.generate(4, (index) {
            var stats = fourPlayerStats[index];
            int count = stats[countKey] ?? 0;
            return Expanded(
              child: Column(
                children: [
                  Text('$count', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  if (isRate && rateKey != null) const SizedBox(height: 4),
                  if (isRate && rateKey != null) Text('(${(stats[rateKey] ?? 0.0).toStringAsFixed(1)}%)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
