import 'package:flutter/material.dart';
import 'game_table.dart';

class GameLedgerScreen extends StatelessWidget {
  final GlobalKey<GameTableScreenState> tableKey;
  final List<String> players;

  const GameLedgerScreen({Key? key, required this.tableKey, required this.players}) : super(key: key);

  final List<String> _windNames = const ['東', '南', '西', '北'];

  @override
  Widget build(BuildContext context) {
    final state = tableKey.currentState;
    if (state == null) {
      return const Center(child: Text('載入中...'));
    }

    List<List<int>> allStates = List.from(state.history);
    allStates.add(state.currentStateSnapshot);

    List<Map<String, dynamic>> hands = [];

    for (int i = 0; i < allStates.length - 1; i++) {
      var meta = allStates[i];
      var after = allStates[i + 1];

      int dPass = meta[35];
      int hNum = meta[36];
      int jiang = (dPass ~/ 16) + 1;
      String circleName = '${_windNames[(dPass ~/ 4) % 4]}風圈';
      String windName = '${_windNames[dPass % 4]}風';
      
      String groupKey = '第 $jiang 將 $circleName';

      List<int> deltas = [];
      List<int> cumScores = [];
      for (int p = 0; p < 4; p++) {
        deltas.add(after[p] - meta[p]);
        cumScores.add(after[p]);
      }

      hands.add({
        'groupKey': groupKey,
        'handNum': hNum,
        'windName': windName,
        'deltas': deltas,
        'cumScores': cumScores,
      });
    }

    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var h in hands.reversed) {
      grouped.putIfAbsent(h['groupKey'], () => []).add(h);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      appBar: AppBar(
        title: const Text('當局逐把明細', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.green[800],
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                const SizedBox(
                  width: 60,
                  child: Center(child: Text('局數', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87))),
                ),
                ...List.generate(4, (index) {
                  return Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 32,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            border: Border.all(color: Colors.green),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.casino, color: Colors.green, size: 20),
                        ),
                        const SizedBox(height: 4),
                        Text(players[index], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: grouped.isEmpty
                ? const Center(child: Text('尚未有任何計分紀錄', style: TextStyle(color: Colors.black54, fontSize: 16)))
                : ListView.builder(
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      String groupKey = grouped.keys.elementAt(index);
                      List<Map<String, dynamic>> groupHands = grouped[groupKey]!;
                      
                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            color: Colors.grey[200],
                            alignment: Alignment.center,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(groupKey, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12)),
                            ),
                          ),
                          ...groupHands.map((h) {
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 60,
                                    child: Column(
                                      children: [
                                        Text('${h['handNum']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                                        Text(h['windName'], style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                      ],
                                    ),
                                  ),
                                  ...List.generate(4, (pIndex) {
                                    int delta = h['deltas'][pIndex];
                                    int cum = h['cumScores'][pIndex];
                                    return Expanded(
                                      child: Column(
                                        children: [
                                          if (delta != 0)
                                            Text(
                                              '(${delta > 0 ? '+' : ''}$delta)',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: delta > 0 ? Colors.green[700] : Colors.red[700]),
                                            )
                                          else
                                            const SizedBox(height: 16),
                                          const SizedBox(height: 4),
                                          Text('$cum', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
