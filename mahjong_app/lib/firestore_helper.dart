import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'db_helper.dart';

class FirestoreHelper {
  static final FirestoreHelper instance = FirestoreHelper._init();
  FirestoreHelper._init();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveGameRecord({
    required String gameName,
    required List<String> players,
    required List<int> scores,
    required List<int> winTimes,
    required List<int> selfDrawnTimes,
    required List<int> chuckTimes,
    required List<int> gotSelfDrawnTimes,
    required List<int> highestTai,
    required List<int> maxCombo,
    required int gameCount,
    required String historyJson,
    required bool isLocked,
    String? createdAt,
  }) async {
    final snapshot = await _firestore.collection('game_records').where('gameName', isEqualTo: gameName).get();
    
    if (snapshot.docs.isEmpty) {
      String currentTime = createdAt ?? DateTime.now().toString().substring(0, 16).replaceAll('-', '/');
      for (int i = 0; i < 4; i++) {
        await _firestore.collection('game_records').add({
          'gameName': gameName,
          'playerName': players[i],
          'score': scores[i],
          'winTimes': winTimes[i],
          'selfDrawnTimes': selfDrawnTimes[i],
          'chuckTimes': chuckTimes[i],
          'gotSelfDrawnTimes': gotSelfDrawnTimes[i],
          'highestTai': highestTai[i],
          'maxCombo': maxCombo[i],
          'gameCount': gameCount,
          'historyJson': historyJson,
          'createdAt': currentTime,
          'isLocked': isLocked ? 1 : 0,
        });
      }
    } else {
      for (int i = 0; i < 4; i++) {
        var docs = snapshot.docs.where((d) => d.data()['playerName'] == players[i]).toList();
        if (docs.isNotEmpty) {
          await docs.first.reference.update({
            'score': scores[i],
            'winTimes': winTimes[i],
            'selfDrawnTimes': selfDrawnTimes[i],
            'chuckTimes': chuckTimes[i],
            'gotSelfDrawnTimes': gotSelfDrawnTimes[i],
            'highestTai': highestTai[i],
            'maxCombo': maxCombo[i],
            'gameCount': gameCount,
            'historyJson': historyJson,
            'isLocked': isLocked ? 1 : 0,
            if (createdAt != null) 'createdAt': createdAt,
          });
        }
      }
    }
  }

  Future<List<Map<String, dynamic>>> getHistoryRecords() async {
    final snapshot = await _firestore.collection('game_records').orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<void> renameGameRecord(String oldName, String newName) async {
    final snapshot = await _firestore.collection('game_records').where('gameName', isEqualTo: oldName).get();
    for (var doc in snapshot.docs) {
      await doc.reference.update({'gameName': newName});
    }
  }

  Future<void> deleteGameRecord(String gameName) async {
    final snapshot = await _firestore.collection('game_records').where('gameName', isEqualTo: gameName).get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<List<String>> getAllPlayers() async {
    final snapshot = await _firestore.collection('game_records').get();
    final players = snapshot.docs.map((doc) => doc.data()['playerName'] as String).toSet().toList();
    return players;
  }

  Future<Map<String, dynamic>> getPlayerStats(String playerName) async {
    final snapshot = await _firestore.collection('game_records').where('playerName', isEqualTo: playerName).get();
    
    int totalScore = 0;
    int totalWin = 0;
    int totalSelfDrawn = 0;
    int totalChuck = 0;
    int trueGotSelfDrawn = 0;
    int bestTai = 0;
    int bestCombo = 0;
    int totalGames = 0;
    int bestSingleScore = 0;

    if (snapshot.docs.isEmpty) return {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      totalScore += (data['score'] as int? ?? 0);
      totalWin += (data['winTimes'] as int? ?? 0);
      totalSelfDrawn += (data['selfDrawnTimes'] as int? ?? 0);
      totalChuck += (data['chuckTimes'] as int? ?? 0);
      trueGotSelfDrawn += (data['gotSelfDrawnTimes'] as int? ?? 0);
      totalGames += (data['gameCount'] as int? ?? 0);
      
      int tai = (data['highestTai'] as int? ?? 0);
      if (tai > bestTai) bestTai = tai;
      
      int combo = (data['maxCombo'] as int? ?? 0);
      if (combo > bestCombo) bestCombo = combo;
      
      int score = (data['score'] as int? ?? 0);
      if (score > bestSingleScore) bestSingleScore = score;
    }

    if (totalGames == 0) return {};
    
    double games = totalGames.toDouble();
    return {
      'totalScore': totalScore,
      'gameCount': totalGames,
      'winTimes': totalWin,
      'selfDrawnTimes': totalSelfDrawn,
      'chuckTimes': totalChuck,
      'gotSelfDrawnTimes': trueGotSelfDrawn,
      'highestTai': bestTai,
      'maxCombo': bestCombo,
      'bestSingleScore': bestSingleScore,
      'winRate': totalWin / games * 100,
      'selfDrawnRate': totalSelfDrawn / games * 100,
      'chuckRate': totalChuck / games * 100,
      'gotSelfDrawnRate': trueGotSelfDrawn / games * 100,
    };
  }

  Future<List<Map<String, dynamic>>> getSynergyStats(String targetPlayer) async {
    // Firebase doesn't support complex joins, doing it in memory
    final snapshot = await _firestore.collection('game_records').get();
    
    // Group records by gameName
    Map<String, List<Map<String, dynamic>>> games = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      String gameName = data['gameName'];
      if (!games.containsKey(gameName)) {
        games[gameName] = [];
      }
      games[gameName]!.add(data);
    }
    
    Map<String, Map<String, dynamic>> synergy = {};
    
    for (var game in games.values) {
      var targetData = game.firstWhere((p) => p['playerName'] == targetPlayer, orElse: () => {});
      if (targetData.isEmpty) continue;
      
      for (var player in game) {
        String coPlayer = player['playerName'];
        if (coPlayer != targetPlayer) {
          if (!synergy.containsKey(coPlayer)) {
            synergy[coPlayer] = {'coPlayer': coPlayer, 'score': 0, 'wins': 0, 'games': 0};
          }
          synergy[coPlayer]!['score'] += (targetData['score'] as int? ?? 0);
          synergy[coPlayer]!['wins'] += (targetData['winTimes'] as int? ?? 0);
          synergy[coPlayer]!['games'] += (targetData['gameCount'] as int? ?? 0);
        }
      }
    }
    
    var resultList = synergy.values.toList();
    resultList.sort((a, b) => (b['games'] as int).compareTo(a['games'] as int));
    return resultList;
  }

  // ==== ?詨?鞈?頧宏? ====
  Future<void> migrateLocalDataToFirestore() async {
    if (kIsWeb) return; // ?芣??典蝡?(??/?餉) ?? SQLite ?臭誑頧宏
    
    final localRecords = await DatabaseHelper.instance.getHistoryRecords();
    if (localRecords.isEmpty) return;

    // 皜征?暹? Firebase 隞亙???
    final snapshot = await _firestore.collection('game_records').get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }

    // 撠?SQLite 鞈??券撖怠 Firebase
    for (var record in localRecords) {
      await _firestore.collection('game_records').add({
        'gameName': record['gameName'],
        'playerName': record['playerName'],
        'score': record['score'],
        'winTimes': record['winTimes'],
        'selfDrawnTimes': record['selfDrawnTimes'],
        'chuckTimes': record['chuckTimes'],
        'gotSelfDrawnTimes': record['gotSelfDrawnTimes'],
        'highestTai': record['highestTai'],
        'maxCombo': record['maxCombo'],
        'gameCount': record['gameCount'],
        'historyJson': record['historyJson'],
        'createdAt': record['createdAt'],
        'isLocked': record['isLocked'],
      });
    }
  }
}
