import 'dart:math';
import 'package:flutter/material.dart';

class EloCalculator {
  static const double initialElo = 1500.0;
  static const double kFactor = 32.0;

  static Map<String, double> calculateEloRankings(List<Map<String, dynamic>> allRecords) {
    Map<String, List<Map<String, dynamic>>> games = _groupAndSortGames(allRecords);
    Map<String, double> eloScores = {};
    Map<String, DateTime> lastPlayedDates = {};

    for (var game in games.values) {
      if (game.length != 4) continue;

      List<Map<String, dynamic>> playersInGame = [];
      for (var playerDoc in game) {
        String name = playerDoc['playerName'];
        eloScores[name] ??= initialElo;
        
        String? createdAtStr = playerDoc['createdAt'] as String?;
        if (createdAtStr != null) {
          DateTime? dt = DateTime.tryParse(createdAtStr.replaceAll('/', '-'));
          if (dt != null) {
            lastPlayedDates[name] = dt;
          }
        }
        
        playersInGame.add({
          'name': name,
          'score': (playerDoc['score'] as num?)?.toDouble() ?? 0.0,
          'elo': eloScores[name]!
        });
      }

      playersInGame.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

      Map<String, double> eloChanges = {};
      for (String name in eloScores.keys) {
        eloChanges[name] = 0.0;
      }

      for (int i = 0; i < playersInGame.length; i++) {
        for (int j = i + 1; j < playersInGame.length; j++) {
          var playerA = playersInGame[i];
          var playerB = playersInGame[j];

          double eloA = playerA['elo'] as double;
          double eloB = playerB['elo'] as double;

          double expectedA = 1 / (1 + pow(10, (eloB - eloA) / 400));
          double expectedB = 1 / (1 + pow(10, (eloA - eloB) / 400));

          double actualA = 1.0;
          double actualB = 0.0;

          if (playerA['score'] == playerB['score']) {
            actualA = 0.5;
            actualB = 0.5;
          }

          double changeA = kFactor * (actualA - expectedA);
          double changeB = kFactor * (actualB - expectedB);

          eloChanges[playerA['name']] = (eloChanges[playerA['name']] ?? 0) + changeA;
          eloChanges[playerB['name']] = (eloChanges[playerB['name']] ?? 0) + changeB;
        }
      }

      for (var player in playersInGame) {
        String name = player['name'];
        eloScores[name] = eloScores[name]! + (eloChanges[name] ?? 0);
      }
    }

    DateTime now = DateTime.now();
    for (String name in eloScores.keys) {
      if (lastPlayedDates.containsKey(name)) {
        DateTime lastPlayed = lastPlayedDates[name]!;
        int daysInactive = now.difference(lastPlayed).inDays;
        
        if (daysInactive >= 30) {
          int penaltyPeriods = daysInactive ~/ 30;
          double penalty = penaltyPeriods * 10.0;
          
          double currentElo = eloScores[name]!;
          if (currentElo > 1500.0) {
            double newElo = currentElo - penalty;
            if (newElo < 1500.0) newElo = 1500.0;
            eloScores[name] = newElo;
          }
        }
      }
    }

    return eloScores;
  }

  static Map<String, List<Map<String, dynamic>>> _groupAndSortGames(List<Map<String, dynamic>> allRecords) {
    Map<String, List<Map<String, dynamic>>> games = {};
    for (var record in allRecords) {
      String gameId = record['gameName']?.toString() ?? ''; // Changed from gameId to gameName as it seems more likely to be the identifier
      if (gameId.isEmpty) continue;
      games.putIfAbsent(gameId, () => []).add(record);
    }
    
    var sortedGameEntries = games.entries.toList()
      ..sort((a, b) {
        String timeA = a.value.first['createdAt'] ?? '';
        String timeB = b.value.first['createdAt'] ?? '';
        return timeA.compareTo(timeB);
      });
      
    Map<String, List<Map<String, dynamic>>> sortedGames = {};
    for (var entry in sortedGameEntries) {
      sortedGames[entry.key] = entry.value;
    }
    
    return sortedGames;
  }
}
