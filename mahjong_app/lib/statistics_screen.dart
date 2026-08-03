import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'firestore_helper.dart';
import 'elo_calculator.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _playerStats = [];

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final records = await FirestoreHelper.instance.getHistoryRecords();
      
      // 計算 Elo
      Map<String, double> eloScores = EloCalculator.calculateEloRankings(records);

      // 同時計算每個玩家的總局數與總得分，用於額外資訊
      Map<String, Map<String, dynamic>> baseStats = {};
      for (var record in records) {
        String name = record['playerName'];
        if (!baseStats.containsKey(name)) {
          baseStats[name] = {'totalScore': 0, 'gameCount': 0, 'winTimes': 0};
        }
        baseStats[name]!['totalScore'] += ((record['score'] ?? 0) as num).toInt();
        baseStats[name]!['gameCount'] += (record['gameCount'] as int? ?? 1);
        baseStats[name]!['winTimes'] += (record['winTimes'] as int? ?? 0);
      }

      List<Map<String, dynamic>> statsList = [];
      eloScores.forEach((name, elo) {
        statsList.add({
          'name': name,
          'elo': elo,
          'totalScore': baseStats[name]?['totalScore'] ?? 0,
          'gameCount': baseStats[name]?['gameCount'] ?? 0,
          'winTimes': baseStats[name]?['winTimes'] ?? 0,
        });
      });

      // 依分數降序排序
      statsList.sort((a, b) => (b['elo'] as double).compareTo(a['elo'] as double));

      setState(() {
        _playerStats = statsList;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading statistics: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getRankImage(double elo) {
    if (elo < 1550) return 'assets/new_rank_0.png';
    if (elo < 1600) return 'assets/new_rank_1.png';
    if (elo < 1650) return 'assets/new_rank_2.png';
    if (elo < 1700) return 'assets/new_rank_3.png';
    if (elo < 1750) return 'assets/new_rank_4.png';
    return 'assets/new_rank_5.png';
  }
  
  String _getRankName(double elo) {
    if (elo < 1550) return '初心';
    if (elo < 1600) return '雀士';
    if (elo < 1650) return '雀傑';
    if (elo < 1700) return '雀豪';
    if (elo < 1750) return '雀聖';
    return '魂天';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
        color: Colors.grey[100],
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _playerStats.length,
          itemBuilder: (context, index) {
            final stat = _playerStats[index];
            final elo = stat['elo'] as double;
            final rankImage = _getRankImage(elo);
            final rankName = _getRankName(elo);
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text('#${index + 1}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(width: 16),
                    Image.asset(rankImage, width: 60, height: 60, errorBuilder: (context, error, stackTrace) {
                      return Container(width: 60, height: 60, color: Colors.grey[300], child: const Icon(Icons.image_not_supported));
                    }),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(stat['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(rankName, style: TextStyle(color: Colors.green[800], fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Elo 分數: ${elo.toStringAsFixed(1)}', style: const TextStyle(fontSize: 16, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('總得分: ${stat['totalScore']} | 局數: ${stat['gameCount']} | 勝場: ${stat['winTimes']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
  }
}
