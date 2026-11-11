import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/chat_message.dart';
import '../models/scenario.dart';
import '../models/vocabulary.dart';

/// Kết quả AI trả về cho mỗi lượt chat.
class RoleplayResult {
  final int rating; // 1 - 5
  final String suggestion;
  final String explanation;
  final bool onTopic; // false nếu user trả lời lạc đề
  final String offTopicNote; // Lời nhắc khi lạc đề (tiếng Việt)
  final List<int> completedTaskNumbers; // Số thứ tự nhiệm vụ vừa hoàn thành
  final String aiReply;
  final List<Vocabulary> recommendedVocab; // 1 - 2 từ đáng chú ý

  RoleplayResult({
    required this.rating,
    required this.suggestion,
    required this.explanation,
    required this.aiReply,
    this.onTopic = true,
    this.offTopicNote = '',
    this.completedTaskNumbers = const [],
    this.recommendedVocab = const [],
  });

  /// Parse JSON do AI trả về (xem prompt trong [AiService]).
  factory RoleplayResult.fromJson(Map<String, dynamic> json) {
    final eval = json['user_evaluation'] as Map<String, dynamic>;
    final rawRating = (eval['rating'] as num).toInt();
    final vocabList = ((json['recommended_vocab'] as List?) ?? [])
        .map((e) => Vocabulary.fromJson(e as Map<String, dynamic>))
        .where((v) => v.word.trim().isNotEmpty)
        .take(2)
        .toList();
    final done = ((json['completed_tasks'] as List?) ?? [])
        .whereType<num>()
        .map((e) => e.toInt())
        .toList();
    return RoleplayResult(
      rating: rawRating.clamp(1, 5), // Đảm bảo nằm trong 1 - 5
      suggestion: (eval['suggestion'] ?? '') as String,
      explanation: (eval['explanation'] ?? '') as String,
      onTopic: (eval['on_topic'] ?? true) as bool,
      offTopicNote: (eval['off_topic_note'] ?? '') as String,
      completedTaskNumbers: done,
      aiReply: json['ai_reply'] as String,
      recommendedVocab: vocabList,
    );
  }
}

/// Kết quả AI kiểm tra câu đặt với từ vựng.
class SentenceCheckResult {
  final int rating; // 1 - 5 sao
  final bool isCorrect;
  final String correctedSentence;
  final String feedback; // Nhận xét (tiếng Việt)
  final String sentenceUsage; // Câu này dùng ở đâu, khi nào (tiếng Việt)
  final List<Vocabulary> recommendedVocab; // Từ vựng gợi ý thêm

  SentenceCheckResult({
    this.rating = 5,
    required this.isCorrect,
    required this.correctedSentence,
    required this.feedback,
    required this.sentenceUsage,
    this.recommendedVocab = const [],
  });

  factory SentenceCheckResult.fromJson(Map<String, dynamic> json) {
    final vocabList = ((json['recommended_vocab'] as List?) ?? [])
        .map((e) => Vocabulary.fromJson(e as Map<String, dynamic>))
        .where((v) => v.word.trim().isNotEmpty)
        .take(1)
        .toList();
    final rawRating = ((json['rating'] as num?) ?? (json['is_correct'] == true ? 5 : 3)).toInt();
    return SentenceCheckResult(
      rating: rawRating.clamp(1, 5),
      isCorrect: (json['is_correct'] ?? false) as bool,
      correctedSentence: (json['corrected_sentence'] ?? '') as String,
      feedback: (json['feedback'] ?? '') as String,
      sentenceUsage: (json['sentence_usage'] ?? '') as String,
      recommendedVocab: vocabList,
    );
  }
}

/// Gọi REST API Gemini.
class AiService {
  /// Lấy Gemini API key từ biến môi trường (.env)
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _model = 'gemini-3.1-flash-lite';
  static const Duration _timeout = Duration(seconds: 25); // Thời gian chờ tối đa
  static const int _maxHistory = 6; // Giảm xuống 6 tin nhắn gần nhất để phản hồi nhanh nhất

  /// Tạo prompt hệ thống linh hoạt theo từng kịch bản đời thực hoặc đàm thoại tự do.
  String _buildSystemPrompt(
    Scenario scenario,
    List<String> tasks,
    List<String> completedTasks,
  ) {
    final isFreeTalk = scenario.id.startsWith('free_talk');
    final taskLines = [
      for (int i = 0; i < tasks.length; i++)
        '${i + 1}. ${tasks[i]}${completedTasks.contains(tasks[i]) ? ' [DONE]' : ''}',
    ].join('\n');

    if (isFreeTalk) {
      return '''
You are a warm, encouraging Native English conversation mentor and partner named "${scenario.aiRole}".
You are having an open, engaging conversation with the learner about "${scenario.title}" (${scenario.description}).

Conversation Goals:
$taskLines

Evaluation & Response Guidelines:
1. Real-life conversational evaluation:
   - Assess user's LAST message based on natural English and communicative fluency.
   - Do NOT be pedantic or overly harsh. If user's input is understandable, rate fairly (3-5 stars).
2. "suggestion":
   - A natural, authentic phrasing that a native speaker would say in a friendly chat.
3. "explanation":
   - Concise explanation in Vietnamese explaining grammar, word choice, or conversational nuances.
4. "on_topic":
   - Always set to true unless the input is complete gibberish or spam.
5. "ai_reply":
   - A warm, friendly, in-character response (1-2 sentences), sharing thoughts and ALWAYS ending with a natural open-ended question to keep the chat going.

Respond strictly in valid JSON:
{
  "user_evaluation": {
    "rating": 1-5,
    "suggestion": "natural native expression",
    "explanation": "concise Vietnamese explanation",
    "on_topic": true,
    "off_topic_note": ""
  },
  "completed_tasks": [numbers of newly completed goals from 1-${tasks.length}, or []],
  "recommended_vocab": [{"word": "...", "phonetic": "/.../", "meaning": "VN meaning", "example": "...", "usage": "VN situation without 'Dùng khi:' prefix"}],
  "ai_reply": "Friendly response with an engaging follow-up question (1-2 sentences)"
}''';
    }

    return '''
You are roleplaying as "${scenario.aiRole}" in "${scenario.title}" (${scenario.description}).
Scenario Goals:
$taskLines

Evaluation & Response Guidelines:
1. Real-life contextual evaluation:
   - Assess user's LAST message based on natural English and real-world communication etiquette tailored to "${scenario.title}".
   - In informal situations (e.g. café, casual shopping), quick greetings or direct requests are fine.
   - In professional/formal situations (e.g. job interview, hotel check-in, customs, clinic), greetings accompanied by necessary context or polite introductions are more natural.
   - Do NOT be pedantic or overly harsh. If user's input is natural and acceptable in reality, rate fairly (3-5 stars).
2. "suggestion":
   - A natural, authentic phrasing that a native speaker would actually say in THIS specific situation. Avoid robotic or redundant filler words.
3. "explanation":
   - Concise explanation in Vietnamese tailored to "${scenario.title}". Explain whether the sentence is natural in this context, and suggest what information or tone is commonly used in real life for this situation.
4. "on_topic":
   - Set to true if the message is relevant to the scenario or natural small talk/greetings for it. Set to false ONLY if completely irrelevant to the situation. If false, provide a gentle "off_topic_note" in Vietnamese.
5. "ai_reply":
   - Realistic, in-character response as "${scenario.aiRole}" (1-2 sentences), responding naturally to the user and keeping the conversation flowing for this situation.

Respond strictly in valid JSON:
{
  "user_evaluation": {
    "rating": 1-5,
    "suggestion": "natural native expression for this situation",
    "explanation": "concise, context-specific Vietnamese explanation",
    "on_topic": true,
    "off_topic_note": ""
  },
  "completed_tasks": [numbers of newly completed goals from 1-${tasks.length}, or []],
  "recommended_vocab": [{"word": "...", "phonetic": "/.../", "meaning": "VN meaning", "example": "...", "usage": "Vietnamese situation description (e.g. 'bạn muốn thanh toán tiền mặt') without repeating 'Dùng khi:' prefix"}],
  "ai_reply": "In-character reply (1-2 sentences)"
}''';
  }

  /// Gửi toàn bộ lịch sử (kèm tin nhắn mới nhất ở cuối) và nhận kết quả.
  /// [history] đã bao gồm tin nhắn user vừa gửi.
  Future<RoleplayResult> sendRoleplay({
    required Scenario scenario,
    required List<ChatMessage> history,
    required List<String> tasks,
    required List<String> completedTasks,
  }) async {
    // Chỉ gửi các tin nhắn gần nhất để request nhẹ và nhanh hơn
    var recent = history.length > _maxHistory
        ? history.sublist(history.length - _maxHistory)
        : history;
    // Lượt đầu gửi lên phải là của user
    while (recent.isNotEmpty && !recent.first.isUser) {
      recent = recent.sublist(1);
    }

    // Gemini dùng role 'user' và 'model'
    final contents = recent
        .map((m) => {
              'role': m.isUser ? 'user' : 'model',
              'parts': [
                {'text': m.text}
              ],
            })
        .toList();

    final body = {
      'systemInstruction': {
        'parts': [
          {'text': _buildSystemPrompt(scenario, tasks, completedTasks)}
        ]
      },
      'contents': contents,
      'generationConfig': {'responseMimeType': 'application/json'},
    };

    final text = await _generate(body);
    return RoleplayResult.fromJson(jsonDecode(text) as Map<String, dynamic>);
  }

  /// Tự động sinh kịch bản hội thoại tùy chỉnh dựa trên ý tưởng của người dùng.
  Future<Scenario> generateCustomScenario(String userIdea) async {
    const systemPrompt = '''
You are an expert English conversation curriculum designer.
Analyze the user's desired conversation topic or situation, and generate a structured roleplay scenario.
Return ONLY valid JSON in this exact structure:
{
  "title": "Short catchy English title (e.g. Booking a Dental Appointment)",
  "aiRole": "Specific English character to roleplay (e.g. Dentist, Airline Agent, Movie Theater Clerk)",
  "description": "Short Vietnamese description of the scenario (1 sentence)",
  "tasks": [
    "English goal 1 (e.g. Describe your symptoms)",
    "English goal 2 (e.g. Ask for available appointment slots)",
    "English goal 3 (e.g. Confirm the booking and ask about payment)"
  ],
  "emoji": "1 relevant emoji",
  "openingReply": "A warm, natural English opening message from your role to start the conversation"
}
''';

    final body = {
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt}
        ]
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': 'User topic: $userIdea'}
          ]
        }
      ],
      'generationConfig': {'responseMimeType': 'application/json'},
    };

    final text = await _generate(body);
    final data = jsonDecode(text) as Map<String, dynamic>;
    final tasks = ((data['tasks'] as List<dynamic>?) ?? [])
        .map((e) => e.toString())
        .take(3)
        .toList();

    return Scenario.custom(
      title: (data['title'] ?? userIdea) as String,
      aiRole: (data['aiRole'] ?? 'Speaking Partner') as String,
      description:
          (data['description'] ?? 'Luyện tập hội thoại tùy chỉnh.') as String,
      tasks: tasks.isNotEmpty
          ? tasks
          : [
              'Bắt đầu câu chuyện theo tình huống',
              'Đặt câu hỏi hoặc phản hồi tự nhiên',
              'Đạt được mục tiêu giao tiếp',
            ],
      greeting: data['openingReply'] as String?,
      emoji: (data['emoji'] ?? '✨') as String,
    );
  }

  /// Kiểm tra câu người dùng tự đặt với một từ vựng và gợi ý từ liên quan.
  Future<SentenceCheckResult> checkSentence({
    required Vocabulary vocab,
    required String sentence,
  }) async {
    final systemPrompt = '''
Check learner's English sentence using target word "${vocab.word}".
Evaluate sentence grammar, naturalness, and real-life applicability.
Return JSON:
{
  "rating": 1-5,
  "is_correct": true/false,
  "corrected_sentence": "natural version",
  "feedback": "short Vietnamese feedback explaining grammar/usage",
  "sentence_usage": "Vietnamese: describe real-life situation without repeating 'Dùng khi' (e.g. 'chào hỏi đồng nghiệp khi mới đến công ty')",
  "recommended_vocab": [{"word": "advanced/related word", "phonetic": "/.../", "meaning": "VN meaning", "example": "short example", "usage": "VN situation without 'Dùng khi' prefix"}]
}''';

    final body = {
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt}
        ]
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'text':
                  'Target word: "${vocab.word}" (meaning: ${vocab.meaning})\nLearner sentence: $sentence'
            }
          ]
        }
      ],
      'generationConfig': {'responseMimeType': 'application/json'},
    };

    final text = await _generate(body);
    return SentenceCheckResult.fromJson(
      jsonDecode(text) as Map<String, dynamic>,
    );
  }

  /// Chấm điểm bài nhật ký tiếng Anh (thang 1 - 10).
  Future<DiaryResult> evaluateDiary(String content) async {
    const systemPrompt = '''
You are an English writing teacher. The user writes a short diary entry in English.
Give a score from 1 to 10, rewrite the entry so it is correct and more natural,
and give short feedback in Vietnamese.
Respond ONLY with valid JSON in exactly this format:
{"score": 1-10, "corrected_text": "...", "feedback": "..."}''';

    final body = {
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt}
        ]
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': content}
          ]
        }
      ],
      'generationConfig': {'responseMimeType': 'application/json'},
    };

    final text = await _generate(body);
    return DiaryResult.fromJson(jsonDecode(text) as Map<String, dynamic>);
  }

  /// Gọi API có timeout và tự thử lại 1 lần khi lỗi mạng/timeout.
  /// Trả về chuỗi JSON do AI sinh ra.
  Future<String> _generate(Map<String, dynamic> body) async {
    final key = _apiKey.trim();
    if (key.isEmpty) {
      throw Exception('Chưa cấu hình GEMINI_API_KEY trong file .env');
    }

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent',
    );
    Object? lastError;
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': key,
              },
              body: jsonEncode(body),
            )
            .timeout(_timeout);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return data['candidates'][0]['content']['parts'][0]['text']
              as String;
        }
        // Lỗi 5xx/429 thì thử lại, lỗi khác báo ngay
        lastError = 'Lỗi API (${response.statusCode}): ${response.body}';
        if (response.statusCode < 500 && response.statusCode != 429) break;
      } on TimeoutException catch (e) {
        lastError = 'Hết thời gian chờ, hãy thử lại ($e)';
      } on SocketException catch (e) {
        lastError = 'Không có kết nối mạng ($e)';
      }
    }
    throw Exception(lastError);
  }
}

/// Kết quả chấm nhật ký.
class DiaryResult {
  final int score; // 1 - 10
  final String correctedText;
  final String feedback;

  DiaryResult({
    required this.score,
    required this.correctedText,
    required this.feedback,
  });

  factory DiaryResult.fromJson(Map<String, dynamic> json) {
    return DiaryResult(
      score: (json['score'] as num).toInt().clamp(1, 10),
      correctedText: (json['corrected_text'] ?? '') as String,
      feedback: (json['feedback'] ?? '') as String,
    );
  }
}

