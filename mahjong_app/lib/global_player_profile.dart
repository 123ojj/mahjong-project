import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'db_helper.dart';

class GlobalPlayerProfileScreen extends StatefulWidget {
  const GlobalPlayerProfileScreen({Key? key}) : super(key: key);

  @override
  _GlobalPlayerProfileScreenState createState() => _GlobalPlayerProfileScreenState();
}

class _GlobalPlayerProfileScreenState extends State<GlobalPlayerProfileScreen> {
  List<String> _allPlayers = [];
  Map<String, Map<String, dynamic>> _playerStats = {};
  Set<String> _expandedPlayers = {};
  bool _isLoading = true;
  String _selectedLeaderboardType = '胡牌王';

  String? _comparePlayer1;
  String? _comparePlayer2;

  String? _synergyTargetPlayer;
  List<Map<String, dynamic>> _synergyStatsList = [];
  bool _isLoadingSynergy = false;

  final List<String> _leaderboardOptions = [
    '得分王',
    '自摸王',
    '自摸率',
    '胡牌王',
    '胡牌率',
    '放槍王',
    '放槍率',
    '最高台數',
    '最多連莊',
  ];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final players = await DatabaseHelper.instance.getAllPlayers();
    Map<String, Map<String, dynamic>> statsMap = {};
    for (String player in players) {
      statsMap[player] = await DatabaseHelper.instance.getPlayerStats(player);
    }
    
    setState(() {
      _allPlayers = players;
      _playerStats = statsMap;
      if (_allPlayers.length >= 2) {
        _comparePlayer1 = _allPlayers[0];
        _comparePlayer2 = _allPlayers[1];
      } else if (_allPlayers.isNotEmpty) {
        _comparePlayer1 = _allPlayers[0];
        _comparePlayer2 = _allPlayers[0];
      }
      
      if (_allPlayers.isNotEmpty) {
        _synergyTargetPlayer = _allPlayers[0];
        _loadSynergyStats(_allPlayers[0]);
      }
      
      _isLoading = false;
    });
  }

  Future<void> _loadSynergyStats(String player) async {
    setState(() => _isLoadingSynergy = true);
    final list = await DatabaseHelper.instance.getSynergyStats(player);
    setState(() {
      _synergyTargetPlayer = player;
      _synergyStatsList = list;
      _isLoadingSynergy = false;
    });
  }

  void _toggleExpand(String player) {
    setState(() {
      if (_expandedPlayers.contains(player)) {
        _expandedPlayers.remove(player);
      } else {
        _expandedPlayers.add(player);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFE8E8E8),
        appBar: AppBar(
          backgroundColor: Colors.green[800],
          title: const Text('玩家總覽', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: '玩家清單'),
              Tab(icon: Icon(Icons.leaderboard)),
              Tab(text: '玩家比較'),
              Tab(text: '相生相剋'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _allPlayers.isEmpty
                ? const Center(child: Text('目前沒有任何玩家紀錄'))
                : TabBarView(
                    children: [
                      // Tab 1: 玩家清單
                      ListView.builder(
                        padding: const EdgeInsets.all(12.0),
                        itemCount: _allPlayers.length,
                        itemBuilder: (context, index) {
                          final player = _allPlayers[index];
                          final stats = _playerStats[player] ?? {};
                          final isExpanded = _expandedPlayers.contains(player);
                          return _buildPlayerCard(player, stats, isExpanded);
                        },
                      ),
                      // Tab 2: 排行榜
                      _buildLeaderboardView(),
                      // Tab 3: 玩家比較
                      _buildComparisonView(),
                      // Tab 4: 相生相剋
                      _buildSynergyView(),
                    ],
                  ),
      ),
    );
  }

  // --- Comparison View Methods ---

  Widget _buildComparisonView() {
    if (_allPlayers.length < 2) {
      return const Center(child: Text('需要至少兩名玩家才能進行比較', style: TextStyle(fontSize: 16)));
    }

    return Column(
      children: [
        // Top Dropdowns
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: _buildCompareDropdown(_comparePlayer1, (val) => setState(() => _comparePlayer1 = val))),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('VS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
              ),
              Expanded(child: _buildCompareDropdown(_comparePlayer2, (val) => setState(() => _comparePlayer2 = val))),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),
        // Comparison List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            children: [
              _buildCompareRow('累積分數', 'totalScore', isPercentage: false),
              _buildCompareRow('遊戲局數', 'gameCount', isPercentage: false),
              _buildCompareRow('胡牌率', 'winRate', isPercentage: true),
              _buildCompareRow('摸魚率', 'slackRate', isPercentage: true),
              _buildCompareRow('自摸率', 'selfDrawnRate', isPercentage: true),
              _buildCompareRow('放槍率', 'chuckRate', isPercentage: true),
              _buildCompareRow('被自摸率', 'gotSelfDrawnRate', isPercentage: true),
              _buildCompareRow('最高連莊數', 'maxCombo', isPercentage: false),
              _buildCompareRow('單局最高台數', 'highestTai', isPercentage: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompareDropdown(String? value, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          dropdownColor: Colors.white,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black87),
          value: value,
          onChanged: onChanged,
          items: _allPlayers.map<DropdownMenuItem<String>>((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Center(child: Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87))),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCompareRow(String label, String statKey, {bool isPercentage = false}) {
    if (_comparePlayer1 == null || _comparePlayer2 == null) return const SizedBox();

    Map<String, dynamic> stats1 = _playerStats[_comparePlayer1!] ?? {};
    Map<String, dynamic> stats2 = _playerStats[_comparePlayer2!] ?? {};

    double val1 = 0;
    double val2 = 0;

    if (statKey == 'slackRate') {
      double w1 = stats1['winRate'] ?? 0;
      double c1 = stats1['chuckRate'] ?? 0;
      val1 = 100.0 - w1 - c1;
      if (val1 < 0) val1 = 0;

      double w2 = stats2['winRate'] ?? 0;
      double c2 = stats2['chuckRate'] ?? 0;
      val2 = 100.0 - w2 - c2;
      if (val2 < 0) val2 = 0;
    } else {
      val1 = (stats1[statKey] ?? 0).toDouble();
      val2 = (stats2[statKey] ?? 0).toDouble();
    }

    String display1 = isPercentage ? '${val1.toStringAsFixed(1)} %' : val1.toInt().toString();
    String display2 = isPercentage ? '${val2.toStringAsFixed(1)} %' : val2.toInt().toString();

    Color color1 = val1 > val2 ? Colors.red.shade700 : Colors.black87;
    Color color2 = val2 > val1 ? Colors.red.shade700 : Colors.black87;
    if (val1 == val2) {
      color1 = Colors.black87;
      color2 = Colors.black87;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Center(child: Text(display1, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color1)))),
          Expanded(child: Center(child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)))),
          Expanded(child: Center(child: Text(display2, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color2)))),
        ],
      ),
    );
  }

  // --- Leaderboard View Methods ---

  Widget _buildLeaderboardView() {
    return Column(
      children: [
        // Dropdown Selector
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              dropdownColor: Colors.white, // FIX: set white background for dropdown
              value: _selectedLeaderboardType,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black87),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedLeaderboardType = newValue;
                  });
                }
              },
              items: _leaderboardOptions.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Center(child: Text(value)),
                );
              }).toList(),
            ),
          ),
        ),
        
        // Rank List
        Expanded(
          child: _buildRankList(),
        )
      ],
    );
  }

  Widget _buildRankList() {
    List<String> sortedPlayers = List.from(_allPlayers);
    sortedPlayers.sort((a, b) {
       double valA = _getSortValue(a, _selectedLeaderboardType);
       double valB = _getSortValue(b, _selectedLeaderboardType);
       return valB.compareTo(valA); // 降冪排序
    });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: sortedPlayers.length,
      itemBuilder: (context, index) {
        String player = sortedPlayers[index];
        String displayValue = _getDisplayValue(player, _selectedLeaderboardType);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              // Rank Icon/Text
              SizedBox(
                width: 70,
                child: index == 0 
                  ? const Icon(Icons.emoji_events, color: Colors.amber, size: 36)
                  : Text('No. ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
              ),
              const SizedBox(width: 8),
              // Player Name
              Expanded(
                child: Text(player, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
              ),
              // Value
              Text(
                displayValue,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
        );
      },
    );
  }

  double _getSortValue(String player, String type) {
    Map<String, dynamic> stats = _playerStats[player] ?? {};
    switch (type) {
      case '得分王': return (stats['totalScore'] ?? 0).toDouble();
      case '自摸王': return (stats['selfDrawnTimes'] ?? 0).toDouble();
      case '自摸率': return (stats['selfDrawnRate'] ?? 0).toDouble();
      case '胡牌王': return (stats['winTimes'] ?? 0).toDouble();
      case '胡牌率': return (stats['winRate'] ?? 0).toDouble();
      case '放槍王': return (stats['chuckTimes'] ?? 0).toDouble();
      case '放槍率': return (stats['chuckRate'] ?? 0).toDouble();
      case '最高台數': return (stats['highestTai'] ?? 0).toDouble();
      case '最多連莊': return (stats['maxCombo'] ?? 0).toDouble();
      default: return 0;
    }
  }

  String _getDisplayValue(String player, String type) {
    Map<String, dynamic> stats = _playerStats[player] ?? {};
    int games = stats['gameCount'] ?? 0;
    
    switch (type) {
      case '得分王': 
        int s = stats['totalScore'] ?? 0;
        return '${s > 0 ? '+' : ''}$s';
      case '自摸王': 
      case '胡牌王': 
      case '放槍王': 
        int count = _getSortValue(player, type).toInt();
        return '$count次 ($games局)';
      case '自摸率': 
      case '胡牌率': 
      case '放槍率': 
        double rate = _getSortValue(player, type);
        return '${rate.toStringAsFixed(1)}%';
      case '最高台數':
        int tai = stats['highestTai'] ?? 0;
        return '$tai 台';
      case '最多連莊':
        int combo = stats['maxCombo'] ?? 0;
        return '連 $combo';
      default: 
        return '';
    }
  }

  // --- Player List View Methods ---

  Widget _buildPlayerCard(String player, Map<String, dynamic> stats, bool isExpanded) {
    int totalScore = stats['totalScore'] ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Header (Always visible)
          InkWell(
            onTap: () => _toggleExpand(player),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  const Icon(Icons.drag_handle, color: Colors.black54),
                  const SizedBox(width: 12),
                  // Avatar placeholder
                  Container(
                    width: 40,
                    height: 55,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.green.shade700, width: 1.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.radio_button_checked, size: 12, color: Colors.red[300]),
                          Icon(Icons.radio_button_checked, size: 12, color: Colors.blue[300]),
                          Icon(Icons.radio_button_checked, size: 12, color: Colors.green[300]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(player, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('累積分數', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text(
                        '${totalScore > 0 ? '+' : ''}$totalScore',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: totalScore >= 0 ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.more_vert, color: Colors.black87),
                  Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.black87),
                ],
              ),
            ),
          ),
          
          // Expanded Details
          if (isExpanded) _buildExpandedDetails(stats),
        ],
      ),
    );
  }

  Widget _buildExpandedDetails(Map<String, dynamic> stats) {
    int gameCount = stats['gameCount'] ?? 0;
    double winRate = stats['winRate'] ?? 0;
    double chuckRate = stats['chuckRate'] ?? 0;
    double slackRate = 100.0 - winRate - chuckRate;
    if (slackRate < 0) slackRate = 0;

    int selfDrawn = stats['selfDrawnTimes'] ?? 0;
    double selfDrawnRate = stats['selfDrawnRate'] ?? 0;
    int winTimes = stats['winTimes'] ?? 0;
    int chuckTimes = stats['chuckTimes'] ?? 0;
    int gotSelfDrawnTimes = stats['gotSelfDrawnTimes'] ?? 0;
    double gotSelfDrawnRate = stats['gotSelfDrawnRate'] ?? 0;

    int highestTai = stats['highestTai'] ?? 0;
    int maxCombo = stats['maxCombo'] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          // 詳細資訊 Divider
          Row(
            children: [
              Expanded(child: Container(height: 1, color: Colors.grey.shade300)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('詳細資訊', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
              ),
              Expanded(child: Container(height: 1, color: Colors.grey.shade300)),
            ],
          ),
          const SizedBox(height: 16),
          
          // Row 1
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDetailItem('遊戲局數', '$gameCount局'),
              _buildDetailItem('勝率', '${winRate.toStringAsFixed(1)}%'),
              _buildDetailItem('摸魚率', '${slackRate.toStringAsFixed(1)}%'),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          
          // Row 2
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDetailItemWithSub('自摸', '$selfDrawn 次', '${selfDrawnRate.toStringAsFixed(1)}%'),
              _buildDetailItemWithSub('胡牌', '$winTimes 次', '${winRate.toStringAsFixed(1)}%'),
              _buildDetailItemWithSub('放槍', '$chuckTimes 次', '${chuckRate.toStringAsFixed(1)}%'),
              _buildDetailItemWithSub('被自摸', '$gotSelfDrawnTimes 次', '${gotSelfDrawnRate.toStringAsFixed(1)}%'),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          
          // Row 3 (Extremes)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDetailItem('單局最高分', '${stats['bestSingleScore'] ?? 0} 分'),
              _buildDetailItem('最高台數', '$highestTai 台'),
              _buildDetailItem('最多連莊', '連 $maxCombo'),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          
          // Radar Chart Title
          const Text('能力雷達圖', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          _buildRadarChart(stats),
        ],
      ),
    );
  }

  Widget _buildRadarChart(Map<String, dynamic> stats) {
    double winRate = stats['winRate'] ?? 0;
    double chuckRate = stats['chuckRate'] ?? 0;
    double slackRate = 100.0 - winRate - chuckRate;
    if (slackRate < 0) slackRate = 0;
    double selfDrawnRate = stats['selfDrawnRate'] ?? 0;
    int highestTai = stats['highestTai'] ?? 0;

    // Normalize to 0-100 (Original version)
    double attack = (winRate / 30.0) * 100;
    if (attack > 100) attack = 100;

    double defense = 100 - ((chuckRate / 25.0) * 100);
    if (defense < 0) defense = 0;
    if (defense > 100) defense = 100;

    double burst = (highestTai / 20.0) * 100;
    if (burst > 100) burst = 100;

    double luck = (selfDrawnRate / 10.0) * 100;
    if (luck > 100) luck = 100;

    double stability = (slackRate / 50.0) * 100;
    if (stability > 100) stability = 100;

    return SizedBox(
      height: 200,
      child: RadarChart(
        RadarChartData(
          dataSets: [
            // Dummy dataset to force the scale from 0 to 100
            RadarDataSet(
              fillColor: Colors.transparent,
              borderColor: Colors.transparent,
              entryRadius: 0,
              dataEntries: const [
                RadarEntry(value: 0),
                RadarEntry(value: 100),
                RadarEntry(value: 100),
                RadarEntry(value: 100),
                RadarEntry(value: 100),
              ],
            ),
            // Actual dataset
            RadarDataSet(
              fillColor: Colors.green.withOpacity(0.3),
              borderColor: Colors.green[700]!,
              entryRadius: 3,
              dataEntries: [
                RadarEntry(value: attack),
                RadarEntry(value: defense),
                RadarEntry(value: burst),
                RadarEntry(value: luck),
                RadarEntry(value: stability),
              ],
            ),
          ],
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          radarBorderData: const BorderSide(color: Colors.transparent),
          titlePositionPercentageOffset: 0.15,
          titleTextStyle: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold),
          getTitle: (index, angle) {
            switch (index) {
              case 0: return const RadarChartTitle(text: '攻擊力');
              case 1: return const RadarChartTitle(text: '防禦力');
              case 2: return const RadarChartTitle(text: '爆發力');
              case 3: return const RadarChartTitle(text: '強運度');
              case 4: return const RadarChartTitle(text: '穩定度');
              default: return const RadarChartTitle(text: '');
            }
          },
          tickCount: 4,
          ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 10),
          tickBorderData: BorderSide(color: Colors.grey.shade300),
          gridBorderData: BorderSide(color: Colors.grey.shade400, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  Widget _buildDetailItemWithSub(String label, String value1, String value2) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        Text(value1, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 4),
        Text(value2, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
      ],
    );
  }

  // --- Synergy View Methods ---

  Widget _buildSynergyView() {
    if (_allPlayers.isEmpty) return const Center(child: Text('無玩家資料'));
    if (_synergyTargetPlayer == null) return const SizedBox();

    return Column(
      children: [
        // Top Dropdown
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          color: Colors.white,
          child: Row(
            children: [
              const Text('分析對象：', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(child: _buildCompareDropdown(_synergyTargetPlayer, (val) {
                if (val != null) _loadSynergyStats(val);
              })),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),
        // List
        Expanded(
          child: _isLoadingSynergy
              ? const Center(child: CircularProgressIndicator())
              : _synergyStatsList.isEmpty
                  ? const Center(child: Text('無同桌紀錄'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _synergyStatsList.length,
                      itemBuilder: (context, index) {
                        final row = _synergyStatsList[index];
                        final coPlayer = row['coPlayer'];
                        final int score = row['score'] ?? 0;
                        final int wins = row['wins'] ?? 0;
                        final int games = row['games'] ?? 0;

                        if (games == 0) return const SizedBox();

                        double coWinRate = (wins / games) * 100;
                        double coAvgScore = (score / games) * 16.0; // 換算成每將(16把)的預期得分

                        // Get baseline stats
                        Map<String, dynamic> baseStats = _playerStats[_synergyTargetPlayer!] ?? {};
                        double baseWinRate = baseStats['winRate'] ?? 0;
                        int baseGames = baseStats['gameCount'] ?? 1;
                        double baseAvgScore = ((baseStats['totalScore'] ?? 0) / baseGames) * 16.0;

                        // Differences
                        double winRateDiff = coWinRate - baseWinRate;
                        double avgScoreDiff = coAvgScore - baseAvgScore;

                        // Tag
                        String tag = '';
                        Color tagColor = Colors.grey;
                        if (winRateDiff >= 2.5 || avgScoreDiff >= 15) {
                          tag = '💰 招財貓';
                          tagColor = Colors.amber.shade800;
                        } else if (winRateDiff <= -2.5 || avgScoreDiff <= -15) {
                          tag = '☠️ 天敵';
                          tagColor = Colors.purple.shade700;
                        } else if (winRateDiff >= 1.0 || avgScoreDiff >= 5) {
                          tag = '😋 大補丸';
                          tagColor = Colors.green.shade700;
                        } else if (winRateDiff <= -1.0 || avgScoreDiff <= -5) {
                          tag = '😈 剋星';
                          tagColor = Colors.red.shade700;
                        } else {
                          tag = '🤝 五五開';
                          tagColor = Colors.blueGrey;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border(left: BorderSide(color: tagColor, width: 4)),
                            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('VS $coPlayer', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: tagColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                    child: Text(tag, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: tagColor)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('共同局數: $games 把', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSynergyStatItem('同桌勝率', coWinRate, baseWinRate, isPercent: true),
                                  ),
                                  Container(width: 1, height: 40, color: Colors.grey.shade300),
                                  Expanded(
                                    child: _buildSynergyStatItem('預期均分(每將)', coAvgScore, baseAvgScore, isPercent: false),
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildSynergyStatItem(String label, double val, double base, {required bool isPercent}) {
    double diff = val - base;
    String diffStr = diff > 0 ? '+${diff.toStringAsFixed(1)}' : diff.toStringAsFixed(1);
    Color diffColor = diff > 0 ? Colors.green.shade700 : (diff < 0 ? Colors.red.shade700 : Colors.black54);
    
    String valStr = isPercent ? '${val.toStringAsFixed(1)}%' : val.toStringAsFixed(1);

    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(valStr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(width: 8),
            Text('($diffStr)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: diffColor)),
          ],
        )
      ],
    );
  }
}
