import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../provider/practice_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final practice = ref.watch(practiceProvider);
    final history = practice.history;

    final totalPractices = history.length;
    final avgScore = history.isEmpty 
        ? 0 
        : history.map((s) => s.score).reduce((a, b) => a + b) ~/ history.length;
    final bestScore = history.isEmpty 
        ? 0 
        : history.map((s) => s.score).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('성과 대시보드'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryGrid(totalPractices, avgScore, bestScore),
            const SizedBox(height: 32),
            _buildSectionTitle('최근 7일 연습 활동'),
            const SizedBox(height: 16),
            _buildWeeklyChart(history),
            const SizedBox(height: 32),
            _buildSectionTitle('발음 점수 분포'),
            const SizedBox(height: 16),
            _buildScoreDistribution(history),
            const SizedBox(height: 32),
            _buildRecentSessions(history),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSummaryGrid(int total, int avg, int best) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      childAspectRatio: 0.8,
      children: [
        _buildStatCard('연습 횟수', total.toString(), Colors.blueAccent),
        _buildStatCard('평균 점수', '$avg점', Colors.greenAccent),
        _buildStatCard('최고 점수', '$best점', Colors.orangeAccent),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(List<dynamic> history) {
    final now = DateTime.now();
    final last7Days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    
    final countsPerDay = last7Days.map((date) {
      return history.where((s) => 
        s.timestamp.year == date.year && 
        s.timestamp.month == date.month && 
        s.timestamp.day == date.day
      ).length;
    }).toList();

    final maxCount = countsPerDay.isEmpty ? 1 : countsPerDay.reduce((a, b) => a > b ? a : b);
    final displayMax = maxCount == 0 ? 5 : maxCount + 1;

    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final count = countsPerDay[i];
          final heightFactor = count / displayMax;
          final date = last7Days[i];
          final isToday = i == 6;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 30,
                height: 100 * heightFactor + 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isToday 
                        ? [Colors.blueAccent, Colors.blueAccent.withValues(alpha: 0.3)]
                        : [Colors.white24, Colors.white10],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: count > 0 ? Text(
                    count.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ) : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('E').format(date),
                style: TextStyle(
                  color: isToday ? Colors.blueAccent : Colors.white24,
                  fontSize: 12,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildScoreDistribution(List<dynamic> history) {
    final excellent = history.where((s) => s.score >= 90).length;
    final good = history.where((s) => s.score >= 70 && s.score < 90).length;
    final poor = history.where((s) => s.score < 70).length;
    final total = history.isEmpty ? 1 : history.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _buildDistRow('매우 좋음 (90+)', excellent, total, Colors.greenAccent),
          const SizedBox(height: 12),
          _buildDistRow('좋음 (70-89)', good, total, Colors.orangeAccent),
          const SizedBox(height: 12),
          _buildDistRow('연습 필요 (<70)', poor, total, Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildDistRow(String label, int count, int total, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text('$count회', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: count / total,
          backgroundColor: Colors.white10,
          color: color,
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildRecentSessions(List<dynamic> history) {
    final recent = history.take(3).toList();
    if (recent.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('최근 실력 변화'),
        const SizedBox(height: 16),
        ...recent.map((s) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic, color: Colors.blueAccent, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.targetText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    Text(
                      DateFormat('MM.dd HH:mm').format(s.timestamp),
                      style: const TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                '${s.score}점',
                style: TextStyle(
                  color: s.score >= 90 ? Colors.greenAccent : Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
