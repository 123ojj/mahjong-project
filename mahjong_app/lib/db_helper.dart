import 'dart:io' show File, Directory; 
import 'package:flutter/foundation.dart'; 
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  static final List<Map<String, dynamic>> _webMemoryDb = [
    {'playerName': '小智', 'score': 260, 'winTimes': 9, 'selfDrawnTimes': 8, 'chuckTimes': 10, 'gameCount': 75, 'gotSelfDrawnTimes': 20, 'highestTai': 15, 'maxCombo': 5},
    {'playerName': '小承', 'score': 740, 'winTimes': 12, 'selfDrawnTimes': 10, 'chuckTimes': 12, 'gameCount': 75, 'gotSelfDrawnTimes': 18, 'highestTai': 22, 'maxCombo': 9},
    {'playerName': '小江', 'score': -700, 'winTimes': 5, 'selfDrawnTimes': 6, 'chuckTimes': 12, 'gameCount': 75, 'gotSelfDrawnTimes': 22, 'highestTai': 8, 'maxCombo': 2},
    {'playerName': '小竑', 'score': -300, 'winTimes': 15, 'selfDrawnTimes': 4, 'chuckTimes': 7, 'gameCount': 75, 'gotSelfDrawnTimes': 24, 'highestTai': 12, 'maxCombo': 3},
  ];

  static final List<Map<String, dynamic>> _webMemoryHistory = [
    {'gameName': '測試局 1', 'playerName': '小智', 'score': 260, 'winTimes': 9, 'selfDrawnTimes': 8, 'chuckTimes': 10, 'gotSelfDrawnTimes': 20, 'highestTai': 15, 'maxCombo': 5, 'gameCount': 75, 'historyJson': '[]', 'isLocked': 1},
    {'gameName': '測試局 1', 'playerName': '小承', 'score': 740, 'winTimes': 12, 'selfDrawnTimes': 10, 'chuckTimes': 12, 'gotSelfDrawnTimes': 18, 'highestTai': 22, 'maxCombo': 9, 'gameCount': 75, 'historyJson': '[]', 'isLocked': 1},
    {'gameName': '測試局 1', 'playerName': '小江', 'score': -700, 'winTimes': 5, 'selfDrawnTimes': 6, 'chuckTimes': 12, 'gotSelfDrawnTimes': 22, 'highestTai': 8, 'maxCombo': 2, 'gameCount': 75, 'historyJson': '[]', 'isLocked': 1},
    {'gameName': '測試局 1', 'playerName': '小竑', 'score': -300, 'winTimes': 15, 'selfDrawnTimes': 4, 'chuckTimes': 7, 'gotSelfDrawnTimes': 24, 'highestTai': 12, 'maxCombo': 3, 'gameCount': 75, 'historyJson': '[]', 'isLocked': 1},
  ];

  Future<Database?> get database async {
    if (kIsWeb) return null; 
    if (_database != null) return _database!;
    _database = await _initDB('mahjong.db');
    return _database!;
  }

  Future<Database?> _initDB(String fileName) async {
    if (kIsWeb) return null;
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, fileName);
    bool dbExists = await File(path).exists();

    if (!dbExists) {
      try {
        ByteData data = await rootBundle.load(join("assets", fileName));
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);
      } catch (e) {
        print("載入資料庫失敗：$e");
      }
    }
    return await openDatabase(
      path,
      version: 5,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute('ALTER TABLE game_records ADD COLUMN gotSelfDrawnTimes INTEGER DEFAULT 0');
            await db.execute('ALTER TABLE game_records ADD COLUMN highestTai INTEGER DEFAULT 0');
            await db.execute('ALTER TABLE game_records ADD COLUMN maxCombo INTEGER DEFAULT 0');
          } catch (_) {}
        }
        if (oldVersion < 3) {
          try {
            await db.execute('ALTER TABLE game_records ADD COLUMN historyJson TEXT DEFAULT "[]"');
          } catch (_) {}
        }
        if (oldVersion < 4) {
          try {
            await db.execute('ALTER TABLE game_records ADD COLUMN createdAt TEXT');
          } catch (_) {}
        }
        if (oldVersion < 5) {
          try {
            await db.execute('ALTER TABLE game_records ADD COLUMN isLocked INTEGER DEFAULT 1');
          } catch (_) {}
        }
      },
    );
  }

  Future<Map<String, dynamic>> getPlayerStats(String playerName) async {
    if (kIsWeb) {
      var matches = _webMemoryDb.where((row) => row['playerName'] == playerName);
      if (matches.isEmpty) return {'winRate': 0.0, 'selfDrawnRate': 0.0, 'chuckRate': 0.0, 'gotSelfDrawnRate': 0.0, 'totalScore': 0, 'gameCount': 0, 'winTimes': 0, 'selfDrawnTimes': 0, 'chuckTimes': 0, 'gotSelfDrawnTimes': 0, 'highestTai': 0, 'maxCombo': 0};
      var row = matches.first;
      double games = (row['gameCount'] as int).toDouble();
      return {
        'totalScore': row['score'],
        'gameCount': row['gameCount'],
        'winTimes': row['winTimes'],
        'selfDrawnTimes': row['selfDrawnTimes'],
        'chuckTimes': row['chuckTimes'],
        'gotSelfDrawnTimes': row['gotSelfDrawnTimes'],
        'highestTai': row['highestTai'],
        'maxCombo': row['maxCombo'],
        'winRate': (row['winTimes'] as int) / games * 100,
        'selfDrawnRate': (row['selfDrawnTimes'] as int) / games * 100,
        'chuckRate': (row['chuckTimes'] as int) / games * 100,
        'gotSelfDrawnRate': (row['gotSelfDrawnTimes'] as int) / games * 100,
      };
    }

    final db = (await instance.database)!;
    final result = await db.rawQuery('''
      SELECT SUM(score) as totalScore, SUM(winTimes) as totalWin,
             SUM(selfDrawnTimes) as totalSelfDrawn, SUM(chuckTimes) as totalChuck,
             SUM(gotSelfDrawnTimes) as trueGotSelfDrawn,
             MAX(highestTai) as bestTai, MAX(maxCombo) as bestCombo,
             SUM(gameCount) as totalGames, MAX(score) as bestSingleScore
      FROM game_records WHERE playerName = ?
    ''', [playerName]);

    if (result.isEmpty || result.first['totalGames'] == null) return {};
    var row = result.first;
    double games = (row['totalGames'] as int).toDouble();
    if (games == 0) return {};

    return {
      'totalScore': row['totalScore'],
      'gameCount': row['totalGames'],
      'winTimes': row['totalWin'],
      'selfDrawnTimes': row['totalSelfDrawn'],
      'chuckTimes': row['totalChuck'],
      'gotSelfDrawnTimes': row['trueGotSelfDrawn'] ?? 0,
      'highestTai': row['bestTai'] ?? 0,
      'maxCombo': row['bestCombo'] ?? 0,
      'bestSingleScore': row['bestSingleScore'] ?? 0,
      'winRate': (row['totalWin'] as int) / games * 100,
      'selfDrawnRate': (row['totalSelfDrawn'] as int) / games * 100,
      'chuckRate': (row['totalChuck'] as int) / games * 100,
      'gotSelfDrawnRate': ((row['trueGotSelfDrawn'] as int?) ?? 0) / games * 100,
    };
  }

  Future<List<Map<String, dynamic>>> getSynergyStats(String targetPlayer) async {
    if (kIsWeb) {
      return []; // Return empty for mock web
    }
    final db = (await instance.database)!;
    final result = await db.rawQuery('''
      SELECT 
        B.playerName as coPlayer,
        SUM(A.score) as score,
        SUM(A.winTimes) as wins,
        SUM(A.gameCount) as games
      FROM game_records A
      JOIN game_records B ON A.gameName = B.gameName
      WHERE A.playerName = ? AND A.playerName != B.playerName
      GROUP BY B.playerName
      ORDER BY games DESC
    ''', [targetPlayer]);

    return result;
  }

  Future<List<String>> getAllPlayers() async {
    if (kIsWeb) {
      return _webMemoryDb.map((row) => row['playerName'] as String).toList();
    }
    // 💡 修正 2：同樣加上驚嘆號
    final db = (await instance.database)!;
    final result = await db.rawQuery('SELECT DISTINCT playerName FROM game_records WHERE playerName IS NOT NULL');
    return result.map((row) => row['playerName'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> getHistoryRecords() async {
    if (kIsWeb) {
      // Mock for web
      return List.from(_webMemoryHistory);
    }
    final db = (await instance.database)!;
    final result = await db.rawQuery('SELECT rowid as id, * FROM game_records ORDER BY createdAt DESC, rowid DESC');
    return result;
  }

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
    if (kIsWeb) {
      _webMemoryHistory.removeWhere((row) => row['gameName'] == gameName);
      for (int i = 0; i < 4; i++) {
        _webMemoryHistory.insert(0, {
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
          'isLocked': isLocked ? 1 : 0,
        });
        
        var pIdx = _webMemoryDb.indexWhere((row) => row['playerName'] == players[i]);
        if (pIdx != -1) {
          _webMemoryDb[pIdx]['score'] += scores[i];
          _webMemoryDb[pIdx]['winTimes'] += winTimes[i];
          _webMemoryDb[pIdx]['selfDrawnTimes'] += selfDrawnTimes[i];
          _webMemoryDb[pIdx]['chuckTimes'] += chuckTimes[i];
          _webMemoryDb[pIdx]['gotSelfDrawnTimes'] += gotSelfDrawnTimes[i];
          if (highestTai[i] > _webMemoryDb[pIdx]['highestTai']) _webMemoryDb[pIdx]['highestTai'] = highestTai[i];
          if (maxCombo[i] > _webMemoryDb[pIdx]['maxCombo']) _webMemoryDb[pIdx]['maxCombo'] = maxCombo[i];
          _webMemoryDb[pIdx]['gameCount'] += gameCount;
        } else {
          _webMemoryDb.add({
             'playerName': players[i], 'score': scores[i], 'winTimes': winTimes[i],
             'selfDrawnTimes': selfDrawnTimes[i], 'chuckTimes': chuckTimes[i],
             'gotSelfDrawnTimes': gotSelfDrawnTimes[i], 'highestTai': highestTai[i],
             'maxCombo': maxCombo[i], 'gameCount': gameCount
          });
        }
      }
      print('Web 模式：假裝存入資料庫 $gameName');
      return;
    }
    
    final db = (await instance.database)!;
    
    // 使用 transaction 確保四筆資料同時成功寫入
    String currentTime = createdAt ?? DateTime.now().toString().substring(0, 16).replaceAll('-', '/');
    int lockedValue = isLocked ? 1 : 0;
    
    await db.transaction((txn) async {
      await txn.delete('game_records', where: 'gameName = ?', whereArgs: [gameName]);
      for (int i = 0; i < 4; i++) {
        await txn.insert('game_records', {
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
          'isLocked': lockedValue,
        });
      }
    });
  }

  Future<void> renameGameRecord(String oldName, String newName) async {
    if (kIsWeb) {
      for (var row in _webMemoryHistory) {
        if (row['gameName'] == oldName) {
          row['gameName'] = newName;
        }
      }
      return;
    }
    final db = (await instance.database)!;
    await db.update('game_records', {'gameName': newName}, where: 'gameName = ?', whereArgs: [oldName]);
  }

  Future<void> deleteGameRecord(String gameName) async {
    if (kIsWeb) {
      _webMemoryHistory.removeWhere((row) => row['gameName'] == gameName);
      // Not re-calculating web memory DB here for simplicity since it's just a mock
      return;
    }
    final db = (await instance.database)!;
    await db.delete('game_records', where: 'gameName = ?', whereArgs: [gameName]);
  }

  Future<void> fixChangSheng46() async {
    if (kIsWeb) return;
    final db = (await instance.database)!;
    await db.transaction((txn) async {
      final records = await txn.query('game_records', where: 'gameName LIKE ?', whereArgs: ['%長勝46%']);
      
      // Determine current players in the game to see if it was messed up by the previous script
      List<String> currentPlayers = records.map((r) => r['playerName'] as String).toList();
      bool wasModifiedByBuggyScript = currentPlayers.contains('小翔');

      for (var record in records) {
        String playerName = record['playerName'] as String;
        String newPlayerName = playerName;
        
        if (wasModifiedByBuggyScript) {
          // If the buggy script ran:
          // Original 小竑 became 小翔 -> Needs to become 小著
          // Original 小著 stayed 小著 -> Needs to become 小竑
          // Original 小智 became 小承 -> Needs to become 小承 (Wait! User wants Zhi<->Cheng, buggy script already did Zhi<->Cheng! So leave them alone!)
          // Original 小承 became 小智 -> Needs to become 小智 (Already swapped, leave alone!)
          
          if (playerName == '小翔') newPlayerName = '小著_TEMP';
          else if (playerName == '小著') newPlayerName = '小竑_TEMP';
          else if (playerName == '小承') newPlayerName = '小承_TEMP';
          else if (playerName == '小智') newPlayerName = '小智_TEMP';
        } else {
          // If the buggy script did NOT run, just do the swaps the user wants:
          if (playerName == '小竑') newPlayerName = '小著_TEMP';
          else if (playerName == '小著') newPlayerName = '小竑_TEMP';
          else if (playerName == '小智') newPlayerName = '小承_TEMP';
          else if (playerName == '小承') newPlayerName = '小智_TEMP';
        }

        if (newPlayerName != playerName) {
          await txn.update(
            'game_records',
            {'playerName': newPlayerName},
            where: 'gameName = ? AND playerName = ?',
            whereArgs: [record['gameName'], playerName],
          );
        }
      }
      
      await txn.rawUpdate("UPDATE game_records SET playerName = REPLACE(playerName, '_TEMP', '') WHERE gameName LIKE '%長勝46%'");
    });
  }
}