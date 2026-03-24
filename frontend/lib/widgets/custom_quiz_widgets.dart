import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class QuizWaitingCard extends StatelessWidget {
  final Animation<double> animation;
  final String icon;
  final String title;
  final String partnerName;

  const QuizWaitingCard({
    super.key,
    required this.animation,
    required this.icon,
    required this.title,
    required this.partnerName,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: AppTheme.velvetCard(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: animation,
              builder: (ctx, child) {
                return Transform.scale(
                  scale: 1.0 + (animation.value * 0.1),
                  child: Text(icon, style: const TextStyle(fontSize: 80)),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(title, style: AppTheme.display(24)),
            const SizedBox(height: 12),
            Text('Waiting for $partnerName...', style: AppTheme.body(16, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class QuizQuestionInputCard extends StatelessWidget {
  final int index;
  final TextEditingController qCtrl;
  final TextEditingController aCtrl;

  const QuizQuestionInputCard({
    super.key,
    required this.index,
    required this.qCtrl,
    required this.aCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.velvetCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Question ${index + 1}', style: AppTheme.label(14)),
          const SizedBox(height: 8),
          TextField(
            controller: qCtrl,
            decoration: AppTheme.inputDeco('e.g. What is my favorite movie?', Icons.help_outline),
          ),
          const SizedBox(height: 16),
          Text('Your Answer', style: AppTheme.label(14)),
          const SizedBox(height: 8),
          TextField(
            controller: aCtrl,
            decoration: AppTheme.inputDeco('e.g. Interstellar', Icons.key),
          ),
        ],
      ),
    );
  }
}

class QuizAnswerInputCard extends StatelessWidget {
  final int index;
  final String question;
  final TextEditingController guessCtrl;

  const QuizAnswerInputCard({
    super.key,
    required this.index,
    required this.question,
    required this.guessCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.velvetCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Question ${index + 1}', style: AppTheme.label(14)),
          const SizedBox(height: 8),
          Text(question, style: AppTheme.display(18).copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Text('Your Guess', style: AppTheme.label(14)),
          const SizedBox(height: 8),
          TextField(
            controller: guessCtrl,
            decoration: AppTheme.inputDeco('Type your guess here', Icons.lightbulb_outline),
          ),
        ],
      ),
    );
  }
}

class QuizResultItemCard extends StatelessWidget {
  final String question;
  final String actualAnswer;
  final String partnerGuess;

  const QuizResultItemCard({
    super.key,
    required this.question,
    required this.actualAnswer,
    required this.partnerGuess,
  });

  @override
  Widget build(BuildContext context) {
    final theyGotIt = actualAnswer.trim().toLowerCase() == partnerGuess.trim().toLowerCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.velvetCard(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: AppTheme.label(16).copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Color(0xFF81C784), size: 16),
              const SizedBox(width: 6),
              Text('Actual: $actualAnswer', style: AppTheme.body(14, color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(theyGotIt ? Icons.check : Icons.close, color: theyGotIt ? const Color(0xFF81C784) : AppTheme.rose, size: 16),
              const SizedBox(width: 6),
              Text('They Guessed: $partnerGuess', style: AppTheme.body(14, color: theyGotIt ? const Color(0xFF81C784) : AppTheme.rose)),
            ],
          )
        ],
      ),
    );
  }
}
