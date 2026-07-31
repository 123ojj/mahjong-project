import 'package:flutter/material.dart';
import 'dart:convert';
import 'setup_screen.dart';
import 'db_helper.dart';
import 'firestore_helper.dart';
import 'score_trend_chart.dart';

class GameTableScreen extends StatefulWidget {
  final String? gameName;
  final List<String> players;
  final int initialDealerIndex;
  final int baseScore;
  final int taiScore;
  final String? initialHistoryJson; // Pass if reopening past game
  final List<int>? initialScores;
  final List<int>? initialWinCount;
  final List<int>? initialSelfDrawnCount;
  final List<int>? initialChuckCount;
  final bool isLocked;

  const GameTableScreen({
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
  GameTableScreenState createState() => GameTableScreenState();
}

class GameTableScreenState extends State<GameTableScreen> {
  List<List<int>> _history = [];
  List<int> _currentScores = [0, 0, 0, 0];
  
  // 記錄各玩家的 摸、胡、槍 次數
  List<int> _selfDrawnCount = [0, 0, 0, 0];
  List<int> _winCount = [0, 0, 0, 0];
  List<int> _chuckCount = [0, 0, 0, 0];
  
  List<int> _gotSelfDrawnCount = [0, 0, 0, 0]; // 被自摸次數
  List<int> _maxTaiCount = [0, 0, 0, 0]; // 單局最高台數
  List<int> _maxComboCount = [0, 0, 0, 0]; // 最多連莊數
  
  late int _currentDealerIndex;
  int _comboCount = 0; // 莊家連莊次數

  int _viewOffset = 0;
  List<int> _uiPositions = [0, 1, 2, 3]; // Logical slots: 0=Bottom, 1=Right, 2=Top, 3=Left
  
  bool _isGameLocked = false; // 是否已結算鎖死
  bool _showCumulativeScore = true; // 顯示累計分數或單將分數
  
  List<int> get _jiangStartScores {
    int currentJiang = _dealerPassCount ~/ 16;
    int targetPassCount = currentJiang * 16;

    for (int i = 0; i < _history.length; i++) {
      int histPassCount = 0;
      if (_history[i].length >= 36) {
        histPassCount = _history[i][35];
      } else if (_history[i].length > 23) {
        histPassCount = _history[i][23];
      }
      if (histPassCount >= targetPassCount) {
        return _history[i].sublist(0, 4);
      }
    }
    return _currentScores;
  }

  // 圈數與局數追蹤
  int _dealerPassCount = 0;
  int _totalHandsPlayed = 1;
  final List<String> _windNames = ['東', '南', '西', '北'];

  // Public Getters for Ledger
  List<List<int>> get history => _history;
  List<int> get currentScores => _currentScores;
  int get dealerPassCount => _dealerPassCount;
  int get totalHandsPlayed => _totalHandsPlayed;
  int get currentDealerIndex => _currentDealerIndex;

  List<int> get currentStateSnapshot => [
      ..._currentScores,
      ..._selfDrawnCount,
      ..._winCount,
      ..._chuckCount,
      ..._gotSelfDrawnCount,
      ..._maxTaiCount,
      ..._maxComboCount,
      _currentDealerIndex,
      _comboCount,
      ..._uiPositions,
      _viewOffset,
      _dealerPassCount,
      _totalHandsPlayed,
  ];

  @override
  void initState() {
    super.initState();
    _isGameLocked = widget.isLocked;
    
    if (widget.initialHistoryJson != null && widget.initialHistoryJson != '[]' && widget.initialHistoryJson!.isNotEmpty) {
      // Re-hydrate past game state
      List<dynamic> parsed = jsonDecode(widget.initialHistoryJson!);
      List<List<int>> allStates = parsed.map((e) => List<int>.from(e)).toList();
      if (allStates.isNotEmpty) {
        _history = allStates.sublist(0, allStates.length - 1);
        final lastState = allStates.last;
        _currentScores = lastState.sublist(0, 4);
        _selfDrawnCount = lastState.sublist(4, 8);
        _winCount = lastState.sublist(8, 12);
        _chuckCount = lastState.sublist(12, 16);
        _gotSelfDrawnCount = lastState.sublist(16, 20);
        _maxTaiCount = lastState.sublist(20, 24);
        _maxComboCount = lastState.sublist(24, 28);
        _currentDealerIndex = lastState[28];
        _comboCount = lastState[29];
        _uiPositions = lastState.sublist(30, 34);
        _viewOffset = lastState[34];
        _dealerPassCount = lastState[35];
        _totalHandsPlayed = lastState[36];
      } else if (widget.initialScores != null) {
        _currentScores = List.from(widget.initialScores!);
        _winCount = List.from(widget.initialWinCount!);
        _selfDrawnCount = List.from(widget.initialSelfDrawnCount!);
        _chuckCount = List.from(widget.initialChuckCount!);
        _currentDealerIndex = widget.initialDealerIndex;
      } else {
        _currentDealerIndex = widget.initialDealerIndex;
      }
    } else if (widget.initialScores != null) {
      _currentScores = List.from(widget.initialScores!);
      _winCount = List.from(widget.initialWinCount!);
      _selfDrawnCount = List.from(widget.initialSelfDrawnCount!);
      _chuckCount = List.from(widget.initialChuckCount!);
      _currentDealerIndex = widget.initialDealerIndex;
    } else {
      _currentDealerIndex = widget.initialDealerIndex;
    }
  }

  void _autoSaveGame() {
    if (_isGameLocked || widget.gameName == null) return;
    
    List<List<int>> allStates = List.from(_history);
    allStates.add(currentStateSnapshot);
    String historyJson = jsonEncode(allStates);

    FirestoreHelper.instance.saveGameRecord(
      gameName: widget.gameName!,
      players: widget.players,
      scores: _currentScores,
      winTimes: _winCount,
      selfDrawnTimes: _selfDrawnCount,
      chuckTimes: _chuckCount,
      gotSelfDrawnTimes: _gotSelfDrawnCount,
      highestTai: _maxTaiCount,
      maxCombo: _maxComboCount,
      gameCount: _totalHandsPlayed,
      historyJson: historyJson,
      isLocked: false,
    );
  }

  void _saveSnapshot() {
    if (_isGameLocked) return;
    _history.add([
      ..._currentScores,
      ..._selfDrawnCount,
      ..._winCount,
      ..._chuckCount,
      ..._gotSelfDrawnCount,
      ..._maxTaiCount,
      ..._maxComboCount,
      _currentDealerIndex, // 28
      _comboCount,         // 29
      ..._uiPositions,     // 30, 31, 32, 33
      _viewOffset,         // 34
      _dealerPassCount,    // 35
      _totalHandsPlayed,   // 36
    ]);
  }

  void _undo() {
    if (_isGameLocked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('牌局已結束，無法再更改！')));
      return;
    }
    if (_history.isNotEmpty) {
      setState(() {
        final lastState = _history.removeLast();
        _currentScores = lastState.sublist(0, 4);
        _selfDrawnCount = lastState.sublist(4, 8);
        _winCount = lastState.sublist(8, 12);
        _chuckCount = lastState.sublist(12, 16);
        
        bool isNewFormat = lastState.length >= 36; // includes new stats
        _gotSelfDrawnCount = isNewFormat ? lastState.sublist(16, 20) : _gotSelfDrawnCount;
        _maxTaiCount = isNewFormat ? lastState.sublist(20, 24) : _maxTaiCount;
        _maxComboCount = isNewFormat ? lastState.sublist(24, 28) : _maxComboCount;
        
        _currentDealerIndex = isNewFormat ? lastState[28] : (lastState.length > 16 ? lastState[16] : _currentDealerIndex);
        _comboCount = isNewFormat ? lastState[29] : (lastState.length > 17 ? lastState[17] : _comboCount);
        _uiPositions = isNewFormat ? lastState.sublist(30, 34) : (lastState.length > 21 ? lastState.sublist(18, 22) : _uiPositions);
        _viewOffset = isNewFormat ? lastState[34] : (lastState.length > 22 ? lastState[22] : _viewOffset);
        _dealerPassCount = isNewFormat ? lastState[35] : (lastState.length > 23 ? lastState[23] : _dealerPassCount);
        _totalHandsPlayed = isNewFormat ? lastState[36] : (lastState.length > 24 ? lastState[24] : _totalHandsPlayed);
      });
      _autoSaveGame();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已復原上一步！'), duration: Duration(seconds: 1)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已經是最原始狀態，無法再還原囉！')),
      );
    }
  }

  void _handleScoreUpdate(int winnerIndex, int loserIndex, List<int> finalTaiPays, bool isSelfDrawn, int baseTai) {
    _saveSnapshot();
    
    setState(() {
      int totalWinScore = 0;

      if (isSelfDrawn) {
        _selfDrawnCount[winnerIndex]++;
        for (int i = 0; i < 4; i++) {
          if (i != winnerIndex) {
            int scoreToPay = widget.baseScore + (widget.taiScore * finalTaiPays[i]);
            _currentScores[i] -= scoreToPay;
            totalWinScore += scoreToPay;
            _gotSelfDrawnCount[i]++; // 新增：被自摸次數
          }
        }
        _currentScores[winnerIndex] += totalWinScore;
      } else {
        _winCount[winnerIndex]++;
        _chuckCount[loserIndex]++;
        int scoreToPay = widget.baseScore + (widget.taiScore * finalTaiPays[loserIndex]);
        _currentScores[loserIndex] -= scoreToPay;
        _currentScores[winnerIndex] += scoreToPay;
      }
      
      // 更新最高台數 (取最大支付台數或 baseTai 作為代表)
      int maxPaidTai = finalTaiPays.reduce((curr, next) => curr > next ? curr : next);
      int recordTai = maxPaidTai > baseTai ? maxPaidTai : baseTai;
      if (recordTai > _maxTaiCount[winnerIndex]) {
        _maxTaiCount[winnerIndex] = recordTai;
      }

      // 莊家異動與連莊計算
      _totalHandsPlayed++;
      if (winnerIndex == _currentDealerIndex) {
        _comboCount++; // 莊家胡牌/自摸，連莊次數 + 1
        if (_comboCount > _maxComboCount[_currentDealerIndex]) {
          _maxComboCount[_currentDealerIndex] = _comboCount;
        }
      } else {
        _comboCount = 0; // 閒家胡牌，連莊中斷
        int currentSlot = _uiPositions.indexOf(_currentDealerIndex);
        _currentDealerIndex = _uiPositions[(currentSlot + 1) % 4]; // 換下家作莊
        _dealerPassCount++; // 風圈推進
      }
    });
    _autoSaveGame();

    // 檢查是否打完一將 (風圈推進了16次)
    if (_dealerPassCount > 0 && _dealerPassCount % 16 == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showNextJiangDialog();
        }
      });
    }
  }

  void _showScoreDialog() {
    if (_isGameLocked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('牌局已結束，無法再更改！')));
      return;
    }
    int selectedWinner = 0;
    int selectedLoser = 1;
    bool isSelfDrawn = false;
    TextEditingController taiController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('新增計分'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text('自摸？'),
                      Switch(
                        value: isSelfDrawn,
                        activeColor: Colors.green,
                        onChanged: (val) {
                          setDialogState(() {
                            isSelfDrawn = val;
                          });
                        },
                      ),
                    ],
                  ),
                  DropdownButtonFormField<int>(
                    value: selectedWinner,
                    decoration: const InputDecoration(labelText: '贏家'),
                    items: List.generate(4, (index) => DropdownMenuItem(value: index, child: Text(widget.players[index]))),
                    onChanged: (val) => setDialogState(() {
                      selectedWinner = val!;
                      if (!isSelfDrawn && selectedWinner == selectedLoser) {
                        selectedLoser = (selectedWinner + 1) % 4;
                      }
                    }),
                  ),
                  if (!isSelfDrawn)
                    DropdownButtonFormField<int>(
                      value: selectedLoser,
                      decoration: const InputDecoration(labelText: '放槍者'),
                      items: List.generate(4, (index) => DropdownMenuItem(value: index, child: Text(widget.players[index]))),
                      onChanged: (val) => setDialogState(() {
                        selectedLoser = val!;
                        if (selectedWinner == selectedLoser) {
                          selectedWinner = (selectedLoser + 1) % 4;
                        }
                      }),
                    ),
                  TextField(
                    controller: taiController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '台數'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                  onPressed: () {
                    int tai = int.tryParse(taiController.text) ?? 0;
                    if (!isSelfDrawn && selectedWinner == selectedLoser) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('贏家和放槍者不能是同一人！')));
                      return;
                    }
                    Navigator.pop(context);
                    _showScoreConfirmationDialog(selectedWinner, selectedLoser, tai, isSelfDrawn);
                  },
                  child: const Text('確認', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      }
    );
  }

  void _showScoreConfirmationDialog(int winnerIndex, int loserIndex, int baseTai, bool isSelfDrawn) {
    // 預先計算各家應該付的台數
    // 莊家台 = 1, 連莊 = 2 * _comboCount
    int dealerExtraTai = 1 + (_comboCount * 2);
    List<int> defaultPays = [0, 0, 0, 0];
    
    if (isSelfDrawn) {
      for (int i = 0; i < 4; i++) {
        if (i == winnerIndex) continue;
        if (winnerIndex == _currentDealerIndex || i == _currentDealerIndex) {
          defaultPays[i] = baseTai + dealerExtraTai;
        } else {
          defaultPays[i] = baseTai;
        }
      }
    } else {
      if (winnerIndex == _currentDealerIndex || loserIndex == _currentDealerIndex) {
        defaultPays[loserIndex] = baseTai + dealerExtraTai;
      } else {
        defaultPays[loserIndex] = baseTai;
      }
    }

    List<TextEditingController> taiControllers = List.generate(4, (i) => TextEditingController(text: defaultPays[i].toString()));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('確認結算台數'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isSelfDrawn ? '贏家 (自摸): ${widget.players[winnerIndex]}' : '贏家: ${widget.players[winnerIndex]}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (!isSelfDrawn) Text('放槍: ${widget.players[loserIndex]}'),
                const SizedBox(height: 12),
                const Text('應付台數 (已自動加上莊家/連莊台，可手動修改)：', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                ...List.generate(4, (i) {
                  if (i == winnerIndex) return const SizedBox.shrink();
                  if (!isSelfDrawn && i != loserIndex) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        SizedBox(width: 80, child: Text('${widget.players[i]} 付:')),
                        Expanded(
                          child: TextField(
                            controller: taiControllers[i],
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(isDense: true, suffixText: '台'),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
              onPressed: () {
                List<int> finalTaiPays = [0, 0, 0, 0];
                for (int i = 0; i < 4; i++) {
                  finalTaiPays[i] = int.tryParse(taiControllers[i].text) ?? 0;
                }
                _handleScoreUpdate(winnerIndex, loserIndex, finalTaiPays, isSelfDrawn, baseTai);
                Navigator.pop(context);
              },
              child: const Text('確認', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showAdjustScoreDialog() {
    if (_isGameLocked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('牌局已結束，無法再更改！')));
      return;
    }
    List<TextEditingController> controllers = List.generate(4, (index) => TextEditingController());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('調整分數 (微調)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(4, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: TextField(
                    controller: controllers[index],
                    keyboardType: const TextInputType.numberWithOptions(signed: true),
                    decoration: InputDecoration(
                      labelText: '${widget.players[index]} 的加減分 (例: 50, -50)',
                    ),
                  ),
                );
              }),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
              onPressed: () {
                _saveSnapshot();
                setState(() {
                  for (int i = 0; i < 4; i++) {
                    int delta = int.tryParse(controllers[i].text) ?? 0;
                    _currentScores[i] += delta;
                  }
                });
                _autoSaveGame();
                Navigator.pop(context);
              },
              child: const Text('確認', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showSwapPositionsDialog() {
    if (_isGameLocked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('牌局已結束，無法再更改！')));
      return;
    }
    int playerA = 0;
    int playerB = 1;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('互換座位'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: playerA,
                    decoration: const InputDecoration(labelText: '玩家 A'),
                    items: List.generate(4, (index) => DropdownMenuItem(value: index, child: Text(widget.players[index]))),
                    onChanged: (val) => setDialogState(() {
                      playerA = val!;
                      if (playerA == playerB) playerB = (playerA + 1) % 4;
                    }),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Icon(Icons.swap_vert),
                  ),
                  DropdownButtonFormField<int>(
                    value: playerB,
                    decoration: const InputDecoration(labelText: '玩家 B'),
                    items: List.generate(4, (index) => DropdownMenuItem(value: index, child: Text(widget.players[index]))),
                    onChanged: (val) => setDialogState(() {
                      playerB = val!;
                      if (playerA == playerB) playerA = (playerB + 1) % 4;
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                  onPressed: () {
                    _saveSnapshot();
                    setState(() {
                      int slotA = _uiPositions.indexOf(playerA);
                      int slotB = _uiPositions.indexOf(playerB);
                      if (slotA != -1 && slotB != -1) {
                        _uiPositions[slotA] = playerB;
                        _uiPositions[slotB] = playerA;
                      }
                    });
                    _autoSaveGame();
                    Navigator.pop(context);
                  },
                  child: const Text('互換', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTrendChart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: ScoreTrendChart(
            history: _history,
            currentScores: _currentScores,
            players: widget.players,
          ),
        );
      },
    );
  }

  void _rotateView() {
    if (_isGameLocked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('牌局已結束，無法再更改！')));
      return;
    }
    _saveSnapshot(); // 旋轉視角也可以支援復原
    setState(() {
      // 順時針轉動：原本在下(0)的變到右(1)，所以 offset + 1
      _viewOffset = (_viewOffset + 1) % 4;
    });
    _autoSaveGame();
  }

  void _showEndGameDialog() {
    if (_isGameLocked) return;
    
    String defaultGameName = '牌局 ${DateTime.now().month}/${DateTime.now().day} ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}';
    TextEditingController nameController = TextEditingController(text: defaultGameName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('結束牌局'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('確定要結束這局牌嗎？結束後分數與戰績將被鎖死，無法再進行修改。'),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '牌局名稱',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
              onPressed: () async {
                String gameName = nameController.text.trim();
                if (gameName.isEmpty) gameName = defaultGameName;
                
                if (widget.gameName != null && widget.gameName != gameName) {
                  await FirestoreHelper.instance.renameGameRecord(widget.gameName!, gameName);
                }
                
                List<List<int>> allStates = List.from(_history);
                allStates.add(currentStateSnapshot);
                String historyJson = jsonEncode(allStates);

                await FirestoreHelper.instance.saveGameRecord(
                  gameName: gameName,
                  players: widget.players,
                  scores: _currentScores,
                  winTimes: _winCount,
                  selfDrawnTimes: _selfDrawnCount,
                  chuckTimes: _chuckCount,
                  gotSelfDrawnTimes: _gotSelfDrawnCount,
                  highestTai: _maxTaiCount,
                  maxCombo: _maxComboCount,
                  gameCount: _totalHandsPlayed,
                  historyJson: historyJson,
                  isLocked: true,
                );

                setState(() {
                  _isGameLocked = true;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('牌局已結束並寫入資料庫！')));
              },
              child: const Text('確定結束', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showTransferDealerDialog() {
    if (_isGameLocked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('牌局已結束，無法再更改！')));
      return;
    }
    int newDealer = _currentDealerIndex;
    TextEditingController comboController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('轉移莊家'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: newDealer,
                    decoration: const InputDecoration(labelText: '新莊家'),
                    items: List.generate(4, (index) => DropdownMenuItem(value: index, child: Text(widget.players[index]))),
                    onChanged: (val) => setDialogState(() => newDealer = val!),
                  ),
                  TextField(
                    controller: comboController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '連莊次數'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                  onPressed: () {
                    _saveSnapshot();
                    setState(() {
                      _currentDealerIndex = newDealer;
                      _comboCount = int.tryParse(comboController.text) ?? 0;
                      _dealerPassCount++;
                    });
                    _autoSaveGame();
                    Navigator.pop(context);
                  },
                  child: const Text('確認移轉', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleDraw() {
    if (_isGameLocked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('牌局已結束，無法再更改！')));
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('流局確認'),
          content: const Text('確定要流局嗎？莊家將繼續連莊。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
              onPressed: () {
                _saveSnapshot();
                setState(() {
                  _comboCount++;
                  _totalHandsPlayed++;
                });
                _autoSaveGame();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已記錄流局，莊家連莊！')));
              },
              child: const Text('確認', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showNextJiangDialog() {
    if (_isGameLocked) return;
    
    List<int> tempPositions = List.from(_uiPositions);
    int tempDealer = _currentDealerIndex;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('下一將重新搬風'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('請重新安排座位與新起莊家：'),
                    const SizedBox(height: 16),
                    ...List.generate(4, (index) {
                      return Row(
                        children: [
                          Text('${_windNames[index]}位:'),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: tempPositions[index],
                              items: List.generate(4, (pIdx) => DropdownMenuItem(value: pIdx, child: Text(widget.players[pIdx]))),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() {
                                    int oldIndex = tempPositions.indexOf(val);
                                    if (oldIndex != -1) {
                                      tempPositions[oldIndex] = tempPositions[index];
                                    }
                                    tempPositions[index] = val;
                                  });
                                }
                              },
                            ),
                          ),
                          Radio<int>(
                            value: tempPositions[index],
                            groupValue: tempDealer,
                            onChanged: (val) {
                              if (val != null) setDialogState(() => tempDealer = val);
                            },
                          ),
                          const Text('起莊'),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                  onPressed: () {
                    _saveSnapshot();
                    setState(() {
                      _uiPositions = tempPositions;
                      _currentDealerIndex = tempDealer;
                      _comboCount = 0;
                      // Advance _dealerPassCount to next Jiang only if in the middle of one
                      if (_dealerPassCount % 16 != 0) {
                        _dealerPassCount = ((_dealerPassCount ~/ 16) + 1) * 16;
                      }
                    });
                    _autoSaveGame();
                    Navigator.pop(context);
                  },
                  child: const Text('確認換位', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPlayerCard(int index) {
    bool isDealer = index == _currentDealerIndex;
    int displayScore = _currentScores[index];
    if (!_showCumulativeScore) {
      displayScore = _currentScores[index] - _jiangStartScores[index];
    }
    
    // Placeholder tile icon logic (just for visual matching)
    IconData tileIcon = Icons.dashboard_customize_outlined;
    Color tileColor = Colors.green[700]!;
    
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (isDealer)
            Positioned(
              right: -5,
              top: -20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.red[800], borderRadius: BorderRadius.circular(4)),
                child: Text(
                  _comboCount > 0 ? '莊 連 $_comboCount' : '莊', 
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(tileIcon, color: tileColor, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(widget.players[index], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${displayScore > 0 && !_showCumulativeScore ? '+' : ''}$displayScore',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: displayScore >= 0 ? Colors.green[700] : Colors.red[700]),
              ),
              const SizedBox(height: 12),
              Text(
                '摸 ${_selfDrawnCount[index]}  胡 ${_winCount[index]}  槍 ${_chuckCount[index]}',
                style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPositionedPlayer(int logicalSlot) {
    // 根據 _viewOffset 計算出實際在畫面上的位置 (0=下, 1=右, 2=上, 3=左)
    int effectiveSlot = (logicalSlot + _viewOffset) % 4;
    int playerIndex = _uiPositions[logicalSlot];

    switch (effectiveSlot) {
      case 0: // 下
        return Positioned(bottom: 0, child: _buildPlayerCard(playerIndex));
      case 1: // 右
        return Positioned(right: 0, child: _buildPlayerCard(playerIndex));
      case 2: // 上
        return Positioned(top: 0, child: _buildPlayerCard(playerIndex));
      case 3: // 左
        return Positioned(left: 0, child: _buildPlayerCard(playerIndex));
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B684B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(widget.gameName?.isNotEmpty == true ? widget.gameName! : '新牌局', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
            Text(
            _isGameLocked 
            ? '已結算' 
            : '第 ${_dealerPassCount ~/ 16 + 1} 將 ${_windNames[(_dealerPassCount ~/ 4) % 4]}圈${_windNames[_dealerPassCount % 4]}局 ($_totalHandsPlayed把)',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.mobile_off_outlined, color: Colors.white), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Toolbar
          Container(
            color: const Color(0xFFF5F5F5),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const SizedBox(width: 16),
                  _buildToolButton(Icons.undo, '復原操作', _undo),
                  const SizedBox(width: 24),
                  _buildToolButton(Icons.handshake_outlined, '流局', _handleDraw),
                  const SizedBox(width: 24),
                  _buildToolButton(Icons.edit_note, '調整分數', _showAdjustScoreDialog),
                  const SizedBox(width: 24),
                  _buildToolButton(Icons.show_chart, '走勢圖', _showTrendChart),
                  const SizedBox(width: 24),
                  _buildToolButton(Icons.calculate_outlined, '統計/結算', _showEndGameDialog),
                  const SizedBox(width: 24),
                  _buildToolButton(Icons.screen_rotation, '旋轉視角', _rotateView),
                  const SizedBox(width: 24),
                  _buildToolButton(Icons.swap_horiz, '調整位置', _showSwapPositionsDialog),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          const SizedBox(height: 10),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              decoration: BoxDecoration(border: Border.all(color: Colors.green.shade300), borderRadius: BorderRadius.circular(4), color: Colors.transparent),
              child: const Text('已連線', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: Center(
              child: SizedBox(
                width: 380,
                height: 520,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildPositionedPlayer(0), // Logical East
                    _buildPositionedPlayer(1), // Logical South
                    _buildPositionedPlayer(2), // Logical West
                    _buildPositionedPlayer(3), // Logical North
                    
                    // Center action button
                    GestureDetector(
                      onTap: _showNextJiangDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('繼\n續\n下\n一\n將', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                      ),
                    ),
                    
                    // Bottom left mode indicator
                    Positioned(
                      left: 16,
                      bottom: 40,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showCumulativeScore = !_showCumulativeScore;
                          });
                        },
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade400, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _showCumulativeScore ? '顯示模式\n累計' : '顯示模式\n單將',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isGameLocked ? null : _showScoreDialog,
        backgroundColor: _isGameLocked ? Colors.grey : Colors.green[700],
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildToolButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.black87, size: 28),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}