import 'package:flutter/material.dart';
import 'dart:convert';
import 'db_helper.dart';
import 'firestore_helper.dart';
import 'game_table.dart';
import 'home_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Map<String, dynamic>>> _historyFuture;

  void _showRenameDialog(String oldName) {
    TextEditingController controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('重新命名牌局'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: '新牌局名稱'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
              onPressed: () async {
                String newName = controller.text.trim();
                if (newName.isNotEmpty && newName != oldName) {
                  await FirestoreHelper.instance.renameGameRecord(oldName, newName);
                  setState(() {
                    _historyFuture = FirestoreHelper.instance.getHistoryRecords();
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('確認', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(String gameName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('刪除牌局'),
          content: Text('確定要刪除「$gameName」嗎？\n刪除後與此牌局相關的所有數據都會被移除，且無法復原。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
              onPressed: () async {
                await FirestoreHelper.instance.deleteGameRecord(gameName);
                setState(() {
                  _historyFuture = FirestoreHelper.instance.getHistoryRecords();
                });
                Navigator.pop(context);
              },
              child: const Text('確定刪除', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _historyFuture = FirestoreHelper.instance.getHistoryRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B684B),
        title: const Text('歷史紀錄', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload, color: Colors.white),
            tooltip: '上傳本地資料到雲端',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('開始上傳資料到雲端...')));
              await FirestoreHelper.instance.migrateLocalDataToFirestore();
              setState(() {
                _historyFuture = FirestoreHelper.instance.getHistoryRecords();
              });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('資料上傳完成！網頁版現在可以看到歷史紀錄了！')));
            }
          ),
          IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('載入失敗：${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('目前沒有歷史紀錄喔！'));
          }

          // 群組資料
          final records = snapshot.data!;
          final Map<String, List<Map<String, dynamic>>> groupedData = {};
          for (var record in records) {
            final gameName = record['gameName'] as String;
            if (!groupedData.containsKey(gameName)) {
              groupedData[gameName] = [];
            }
            groupedData[gameName]!.add(record);
          }

          final gameNames = groupedData.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: gameNames.length,
            itemBuilder: (context, index) {
              final gameName = gameNames[index];
              var playersData = groupedData[gameName]!.reversed.toList();
              
              // 1. Sort by playerIndex if available
              playersData.sort((a, b) {
                int indexA = a['playerIndex'] as int? ?? 99;
                int indexB = b['playerIndex'] as int? ?? 99;
                return indexA.compareTo(indexB);
              });
              
              // 2. Fallback to recover original order from historyJson for old games
              if ((playersData.first['playerIndex'] as int?) == null) {
                String? rawHistory = playersData.first['historyJson'] as String?;
                if (rawHistory != null && rawHistory.isNotEmpty && rawHistory != '[]') {
                  try {
                    List<dynamic> parsed = jsonDecode(rawHistory);
                    if (parsed.isNotEmpty) {
                      List<int> lastState = List<int>.from(parsed.last);
                      List<int> hScores = lastState.sublist(0, 4);
                      List<int> hSelfDrawn = lastState.sublist(4, 8);
                      List<int> hWin = lastState.sublist(8, 12);
                      List<int> hChuck = lastState.sublist(12, 16);
                      List<int> hGotSelf = lastState.sublist(16, 20);
                      
                      List<Map<String, dynamic>> sorted = List.filled(4, {});
                      List<bool> matched = [false, false, false, false];
                      
                      for (int i = 0; i < 4; i++) {
                         var pd = playersData[i];
                         int score = (pd['score'] as num?)?.toInt() ?? 0;
                         int win = (pd['winTimes'] as num?)?.toInt() ?? 0;
                         int self = (pd['selfDrawnTimes'] as num?)?.toInt() ?? 0;
                         int chuck = (pd['chuckTimes'] as num?)?.toInt() ?? 0;
                         int gotSelf = (pd['gotSelfDrawnTimes'] as num?)?.toInt() ?? 0;
                         
                         int matchIdx = -1;
                         for (int j = 0; j < 4; j++) {
                           if (!matched[j] &&
                               hScores[j] == score &&
                               hWin[j] == win &&
                               hSelfDrawn[j] == self &&
                               hChuck[j] == chuck &&
                               hGotSelf[j] == gotSelf) {
                             matchIdx = j;
                             break;
                           }
                         }
                         if (matchIdx != -1) {
                           sorted[matchIdx] = pd;
                           matched[matchIdx] = true;
                         } else {
                           throw Exception('Mismatch');
                         }
                      }
                      playersData = sorted;
                    }
                  } catch (e) {
                    print("Recovery failed: $e");
                  }
                }
              }

              String dateStr = playersData.first['createdAt'] as String? ?? '時間未定';
              bool isLocked = (playersData.first['isLocked'] as int? ?? 1) == 1;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 2,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    List<String> players = playersData.map((d) => d['playerName'] as String).toList();
                    String? historyJson = playersData.first['historyJson'] as String?;
                    List<int> scores = playersData.map((d) => (d['score'] as int)).toList();
                    List<int> winTimes = playersData.map((d) => (d['winTimes'] as int)).toList();
                    List<int> selfDrawnTimes = playersData.map((d) => (d['selfDrawnTimes'] as int)).toList();
                    List<int> chuckTimes = playersData.map((d) => (d['chuckTimes'] as int)).toList();

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GameTableScreen(
                          gameName: gameName,
                          players: players,
                          initialDealerIndex: 0,
                          baseScore: 50,
                          taiScore: 20,
                          initialHistoryJson: historyJson,
                          initialScores: scores,
                          initialWinCount: winTimes,
                          initialSelfDrawnCount: selfDrawnTimes,
                          initialChuckCount: chuckTimes,
                          isLocked: isLocked,
                        ),
                      ),
                    );
                    
                    setState(() {
                      _historyFuture = FirestoreHelper.instance.getHistoryRecords();
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                    child: Row(
                      children: [
                        Icon(isLocked ? Icons.lock : Icons.play_circle_fill, size: 32, color: isLocked ? Colors.black87 : Colors.green[700]),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      gameName, 
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (!isLocked) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.green)),
                                      child: const Text('進行中', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.history, size: 16, color: Colors.black87),
                                  const SizedBox(width: 4),
                                  Text(dateStr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.black87),
                          onSelected: (value) {
                            if (value == 'rename') {
                              _showRenameDialog(gameName);
                            } else if (value == 'delete') {
                              _showDeleteDialog(gameName);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'rename', child: Text('重新命名')),
                            const PopupMenuItem(value: 'delete', child: Text('刪除', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                        const Icon(Icons.keyboard_arrow_down, color: Colors.black87),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
