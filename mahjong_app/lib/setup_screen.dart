import 'package:flutter/material.dart';
import 'game_table.dart';
import 'db_helper.dart';
import 'firestore_helper.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({Key? key}) : super(key: key);

  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  bool _isLoading = true; 
  List<String> _availablePlayers = [];
  List<String> _selectedPlayers = [];
  
  String _selectedScoreOption = '50 / 20';
  final List<String> _scoreOptions = ['50 / 20', '30 / 10'];

  final List<String> _winds = ['東風', '南風', '西風', '北風'];
  int _dealerIndex = 0; 

  @override
  void initState() {
    super.initState();
    _loadPlayersFromDB();
  }

  void _loadPlayersFromDB() async {
    List<String> dbPlayers = await FirestoreHelper.instance.getAllPlayers();
    List<String> defaultPlayers = ['小竑', '小智', '小翔', '小承'];

    Set<String> combinedPlayers = {...defaultPlayers, ...dbPlayers};
    combinedPlayers.remove('小江'); // 隱藏小江

    _availablePlayers = combinedPlayers.toList();
    _selectedPlayers = ['小竑', '小智', '小翔', '小承'];

    setState(() {
      _isLoading = false;
    });
  }

  void _showAddPlayerDialog() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('新增玩家', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            autofocus: true,
            decoration: InputDecoration(
              hintText: '輸入玩家名稱',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
                foregroundColor: Colors.teal[900],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                String newName = controller.text.trim();
                if (newName.isNotEmpty && !_availablePlayers.contains(newName)) {
                  setState(() {
                    _availablePlayers.add(newName);
                  });
                  Navigator.pop(context);
                } else if (newName.isNotEmpty && _availablePlayers.contains(newName)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('玩家已存在！'), backgroundColor: Colors.orangeAccent),
                  );
                } else {
                  Navigator.pop(context);
                }
              },
              child: const Text('新增', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _startGame() async {

    if (_selectedPlayers.toSet().length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ 玩家不能重複上桌喔！請確認四個座位都是不同人。'), backgroundColor: Colors.orangeAccent),
      );
      return;
    }

    int baseScore = 50;
    int taiScore = 20;
    if (_selectedScoreOption == '30 / 10') {
      baseScore = 30;
      taiScore = 10;
    }

    String gameName = '牌局 ${DateTime.now().month}/${DateTime.now().day} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';

    await FirestoreHelper.instance.saveGameRecord(
      gameName: gameName,
      players: List.from(_selectedPlayers),
      scores: [0, 0, 0, 0],
      winTimes: [0, 0, 0, 0],
      selfDrawnTimes: [0, 0, 0, 0],
      chuckTimes: [0, 0, 0, 0],
      gotSelfDrawnTimes: [0, 0, 0, 0],
      highestTai: [0, 0, 0, 0],
      maxCombo: [0, 0, 0, 0],
      gameCount: 0,
      historyJson: '[]',
      isLocked: false,
      baseScore: baseScore,
      taiScore: taiScore,
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameTableScreen(
          gameName: gameName,
          players: List.from(_selectedPlayers),
          initialDealerIndex: _dealerIndex,
          baseScore: baseScore,
          taiScore: taiScore,
          isLocked: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A), // Slate 900
        body: Center(child: CircularProgressIndicator(color: Colors.tealAccent)),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)], // Slate 900 to Slate 800
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: Text(
                        '開啟新局',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // --- 底台金額設定 ---
                    _buildSectionTitle(Icons.monetization_on_outlined, '底台金額'),
                    const SizedBox(height: 12),
                    _buildGlassContainer(
                      child: DropdownButtonFormField<String>(
                        value: _selectedScoreOption,
                        dropdownColor: const Color(0xFF334155),
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.tealAccent),
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: _scoreOptions.map((String option) {
                          return DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) setState(() => _selectedScoreOption = newValue);
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // --- 玩家與風位 ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle(Icons.group_outlined, '決定風位與玩家'),
                        TextButton.icon(
                          onPressed: _showAddPlayerDialog,
                          icon: const Icon(Icons.person_add_alt_1, color: Colors.tealAccent, size: 20),
                          label: const Text('新增玩家', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.tealAccent.withOpacity(0.1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(4, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildGlassContainer(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  color: index == _dealerIndex ? Colors.amber.withOpacity(0.2) : Colors.transparent,
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                                ),
                                child: Text(
                                  _winds[index],
                                  style: TextStyle(
                                    color: index == _dealerIndex ? Colors.amber : Colors.tealAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedPlayers[index],
                                  dropdownColor: const Color(0xFF334155),
                                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                                  style: const TextStyle(color: Colors.white, fontSize: 16),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  ),
                                  items: _availablePlayers.map((String player) {
                                    return DropdownMenuItem<String>(value: player, child: Text(player));
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) setState(() => _selectedPlayers[index] = newValue);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    
                    const SizedBox(height: 24),
                    
                    // --- 選擇起莊家 ---
                    _buildSectionTitle(Icons.stars_outlined, '選擇起莊家'),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(4, (index) {
                        bool isSelected = _dealerIndex == index;
                        return GestureDetector(
                          onTap: () => setState(() => _dealerIndex = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutBack,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.amber : const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 12, spreadRadius: 2)]
                                  : [const BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                              border: Border.all(color: isSelected ? Colors.amberAccent : Colors.white12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _winds[index].substring(0, 1),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: isSelected ? Colors.brown[900] : Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // --- 開桌按鈕 ---
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.tealAccent.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          backgroundColor: Colors.tealAccent, // Use bright teal for contrast
                          foregroundColor: Colors.teal[900],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                        ),
                        onPressed: _startGame,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.play_arrow_rounded, size: 28),
                            SizedBox(width: 8),
                            Text('正式開桌', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Colors.tealAccent, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ],
    );
  }

  Widget _buildGlassContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: child,
    );
  }
}