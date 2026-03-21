import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'backend_config.dart';

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String name;
  final int totalXp;
  final String? profilePictureBase64;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    required this.totalXp,
    this.profilePictureBase64,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: (json['rank'] as num).toInt(),
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed',
      totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
      profilePictureBase64: json['profile_picture_base64'] as String?,
    );
  }
}

class LeaderboardResult {
  final List<LeaderboardEntry> entries;
  final int? myRank;
  final int myXp;

  const LeaderboardResult({
    required this.entries,
    this.myRank,
    this.myXp = 0,
  });
}

class LeaderboardService {
  /// Fetches the global leaderboard plus the current user's rank & XP.
  Future<LeaderboardResult?> fetchLeaderboard(String userId) async {
    try {
      final uri = Uri.parse(
        '${BackendConfig.baseUrl}/users/leaderboard/me?user_id=${Uri.encodeComponent(userId)}&limit=50',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final List<dynamic> raw = data['leaderboard'] as List<dynamic>? ?? [];
        final entries = raw
            .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        return LeaderboardResult(
          entries: entries,
          myRank: data['my_rank'] as int?,
          myXp: (data['my_xp'] as num?)?.toInt() ?? 0,
        );
      }
    } catch (e) {
      debugPrint('LeaderboardService error: $e');
    }
    return null;
  }
}
