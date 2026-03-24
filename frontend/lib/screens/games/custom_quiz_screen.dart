import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/socket_service.dart';
import '../../models/room_model.dart';
import '../../core/app_theme.dart';
import '../../widgets/custom_quiz_widgets.dart';
import '../../widgets/shared_game_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum QuizPhase { writing, answering, results }

class CustomQuizScreen extends StatefulWidget {
  final RoomModel room;
  const CustomQuizScreen({super.key, required this.room});

  @override
  State<CustomQuizScreen> createState() => _CustomQuizScreenState();
}

class _CustomQuizScreenState extends State<CustomQuizScreen> with SingleTickerProviderStateMixin {
  final SocketService _socket = SocketService();
  final String _sessionId = UniqueKey().toString();
  late AnimationController _pulseCtrl;
  
  String _myUserId = '';
  String _partnerUserId = '';
  String _myName = '';
  String _partnerName = 'Partner';
  
  QuizPhase _phase = QuizPhase.writing;
  
  bool _myQuestionsLocked = false;
  bool _partnerQuestionsLocked = false;
  bool _myAnswersLocked = false;
  bool _partnerAnswersLocked = false;

  final List<TextEditingController> _qCtrls = List.generate(5, (_) => TextEditingController());
  final List<TextEditingController> _aCtrls = List.generate(5, (_) => TextEditingController());
  
  List<String> _partnerQuestions = [];
  List<String> _partnerAnswers = []; // Used later to grade my guesses
  
  final List<TextEditingController> _guessCtrls = List.generate(5, (_) => TextEditingController());
  List<String> _partnerGuesses = []; // Their guesses to my questions

  int _myScore = 0;
  int _partnerScore = 0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _connectSocket();
  }

  void _connectSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    _myUserId = prefs.getString('userId') ?? '';
    _myName = prefs.getString('name') ?? '';

    _socket.connect(
      roomId: widget.room.roomId,
      token: token,
      onConnected: () {},
      onMessage: (event) {
        if (event['type'] == 'GAME_STATE_UPDATE') {
          final payload = event['payload'];
          
          // Ignore our own broadcasted payloads!
          if (payload['sessionId']?.toString() == _sessionId) return;

          if (payload['action'] == 'QUESTIONS_LOCKED') {
            setState(() {
              _partnerQuestions = List<String>.from(payload['questions'].map((x) => x.toString()));
              _partnerAnswers = List<String>.from(payload['answers'].map((x) => x.toString()));
              final incomingName = payload['userName'];
              if (incomingName != null && incomingName.toString().trim().isNotEmpty) {
                _partnerName = incomingName.toString().trim();
              }
              _partnerQuestionsLocked = true;
              _checkPhaseTransition();
            });
          } else if (payload['action'] == 'ANSWERS_LOCKED') {
            setState(() {
              _partnerGuesses = List<String>.from(payload['guesses'].map((x) => x.toString()));
              _partnerScore = payload['score'];
              _partnerUserId = payload['userId'] ?? '';
              final incomingName = payload['userName'];
              if (incomingName != null && incomingName.toString().trim().isNotEmpty) {
                _partnerName = incomingName.toString().trim();
              }
              _partnerAnswersLocked = true;
              _checkPhaseTransition();
            });
          } else if (payload['action'] == 'BACK_TO_LOBBY') {
            if (mounted) {
              context.go('/lobby', extra: widget.room);
            }
          }
        }
      },
    );
  }

  void _checkPhaseTransition() {
    if (_phase == QuizPhase.writing && _myQuestionsLocked && _partnerQuestionsLocked) {
      setState(() => _phase = QuizPhase.answering);
    } else if (_phase == QuizPhase.answering && _myAnswersLocked && _partnerAnswersLocked) {
      setState(() => _phase = QuizPhase.results);
      if (widget.room.isHost) {
        _sendGameEndEvent();
      }
    }
  }

  void _sendGameEndEvent() {
    String? winnerId;
    if (_myScore > _partnerScore) {
      winnerId = _myUserId;
    } else if (_partnerScore > _myScore) {
      winnerId = _partnerUserId;
    }

    _socket.sendEvent(widget.room.roomId, {
      'type': 'GAME_END',
      'payload': {
        'scoreA': _myScore,
        'scoreB': _partnerScore,
        if (winnerId != null && winnerId.isNotEmpty) 'winnerId': winnerId,
      }
    });
  }

  void _lockQuestions() {
    // Validate
    if (_qCtrls.any((c) => c.text.trim().isEmpty) || _aCtrls.any((c) => c.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields!')));
      return;
    }

    setState(() => _myQuestionsLocked = true);
    final qs = _qCtrls.map((c) => c.text.trim()).toList();
    final as = _aCtrls.map((c) => c.text.trim()).toList();

    _socket.sendEvent(widget.room.roomId, {
      'type': 'GAME_ACTION',
      'payload': {
        'sessionId': _sessionId,
        'action': 'QUESTIONS_LOCKED',
        'questions': qs,
        'answers': as,
        'userName': _myName,
      }
    });
    _checkPhaseTransition();
  }

  void _lockAnswers() {
    if (_guessCtrls.any((c) => c.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please guess all answers!')));
      return;
    }

    setState(() => _myAnswersLocked = true);
    final guesses = _guessCtrls.map((c) => c.text.trim()).toList();
    
    // Calculate my score
    int score = 0;
    for (int i = 0; i < 5; i++) {
      if (guesses[i].trim().toLowerCase() == _partnerAnswers[i].trim().toLowerCase()) {
        score++;
      }
    }
    _myScore = score;

    _socket.sendEvent(widget.room.roomId, {
      'type': 'GAME_ACTION',
      'payload': {
        'sessionId': _sessionId,
        'userId': _myUserId,
        'action': 'ANSWERS_LOCKED',
        'guesses': guesses,
        'score': score,
        'userName': _myName,
      }
    });
    _checkPhaseTransition();
  }

  @override
  void dispose() {
    _socket.disconnect();
    _pulseCtrl.dispose();
    for (var c in _qCtrls) { c.dispose(); }
    for (var c in _aCtrls) { c.dispose(); }
    for (var c in _guessCtrls) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg1,
      appBar: SharedGameAppBar(
        room: widget.room,
        socket: _socket,
        title: 'How Well Do You Know Me?',
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case QuizPhase.writing: return _buildWritingPhase();
      case QuizPhase.answering: return _buildAnsweringPhase();
      case QuizPhase.results: return _buildResultsPhase();
    }
  }

  Widget _buildWritingPhase() {
    if (_myQuestionsLocked) {
      return QuizWaitingCard(
        animation: _pulseCtrl,
        icon: '🎯',
        title: 'Questions Locked!',
        partnerName: _partnerName,
      );
    }

    return Column(
      children: [
        Text('Write 5 Questions about yourself', style: AppTheme.display(22)),
        const SizedBox(height: 8),
        Text('Keep answers short (1-2 words) for easier exact matching!', style: AppTheme.body(14, color: AppTheme.rose)),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.separated(
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(height: 24),
            itemBuilder: (context, i) {
              return QuizQuestionInputCard(
                index: i,
                qCtrl: _qCtrls[i],
                aCtrl: _aCtrls[i],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        AppTheme.roseButton(label: 'Lock Questions', onTap: _lockQuestions),
      ],
    );
  }

  Widget _buildAnsweringPhase() {
    if (_myAnswersLocked) {
      return QuizWaitingCard(
        animation: _pulseCtrl,
        icon: '🤔',
        title: 'Answers Locked!',
        partnerName: _partnerName,
      );
    }

    return Column(
      children: [
        Text('Answer Their Questions', style: AppTheme.display(22)),
        const SizedBox(height: 8),
        Text('Try to guess exactly what they wrote!', style: AppTheme.body(14, color: AppTheme.rose)),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.separated(
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(height: 24),
            itemBuilder: (context, i) {
              return QuizAnswerInputCard(
                index: i,
                question: _partnerQuestions[i],
                guessCtrl: _guessCtrls[i],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        AppTheme.roseButton(label: 'Lock Answers', onTap: _lockAnswers),
      ],
    );
  }

  Widget _buildResultsPhase() {
    final iWon = _myScore > _partnerScore;
    final tie = _myScore == _partnerScore;
    
    return Column(
      children: [
        const Text('🏆', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 12),
        Text(
          tie ? "It's a Tie!" : (iWon ? "You Win!" : "$_partnerName Wins!"),
          style: AppTheme.display(32).copyWith(color: AppTheme.rose),
        ),
        const SizedBox(height: 8),
        Text('You scored $_myScore/5 | $_partnerName scored $_partnerScore/5', style: AppTheme.body(16, color: AppTheme.textPrimary)),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.separated(
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, i) {
              final myQ = _qCtrls[i].text;
              final myA = _aCtrls[i].text;
              final theirGuess = _partnerGuesses[i];
              
              return QuizResultItemCard(
                question: myQ,
                actualAnswer: myA,
                partnerGuess: theirGuess,
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        SharedLeaveGameButton(room: widget.room, socket: _socket),
      ],
    );
  }
}
