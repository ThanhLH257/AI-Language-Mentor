/// Model từ vựng trong khóa học.
class CourseVocab {
  final String word;
  final String phonetic;
  final String meaning;
  final String exampleSentence;

  const CourseVocab({
    required this.word,
    required this.phonetic,
    required this.meaning,
    required this.exampleSentence,
  });

  factory CourseVocab.fromJson(Map<String, dynamic> json) {
    return CourseVocab(
      word: json['word'] as String? ?? '',
      phonetic: json['phonetic'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      exampleSentence: json['exampleSentence'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'word': word,
        'phonetic': phonetic,
        'meaning': meaning,
        'exampleSentence': exampleSentence,
      };
}

/// Mẫu câu hội thoại đối đáp mẫu.
class CourseDialogue {
  final String speaker;
  final String text;
  final String translation;

  const CourseDialogue({
    required this.speaker,
    required this.text,
    required this.translation,
  });

  factory CourseDialogue.fromJson(Map<String, dynamic> json) {
    return CourseDialogue(
      speaker: json['speaker'] as String? ?? '',
      text: json['text'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'speaker': speaker,
        'text': text,
        'translation': translation,
      };
}

/// Câu hỏi ôn tập trắc nghiệm nhanh cho khóa học.
class CourseQuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const CourseQuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory CourseQuizQuestion.fromJson(Map<String, dynamic> json) {
    return CourseQuizQuestion(
      question: json['question'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      correctIndex: json['correctIndex'] as int? ?? 0,
      explanation: json['explanation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'correctIndex': correctIndex,
        'explanation': explanation,
      };
}

/// Khóa học nhỏ (Mini-Course) gắn liền với từng đề tài kịch bản (Scenario).
class CourseModel {
  final String id; // Trùng với Scenario.id (ví dụ 'coffee_shop')
  final String scenarioId;
  final String title;
  final String description;
  final String level;
  final int estimatedMinutes;
  final List<CourseVocab> vocabularies;
  final List<String> conversationTips;
  final List<CourseDialogue> sampleDialogues;
  final List<CourseQuizQuestion> quizzes;

  const CourseModel({
    required this.id,
    required this.scenarioId,
    required this.title,
    required this.description,
    required this.level,
    this.estimatedMinutes = 5,
    required this.vocabularies,
    required this.conversationTips,
    required this.sampleDialogues,
    required this.quizzes,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] as String? ?? '',
      scenarioId: json['scenarioId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      level: json['level'] as String? ?? 'Cơ bản',
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 5,
      vocabularies: (json['vocabularies'] as List<dynamic>?)
              ?.map((e) => CourseVocab.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      conversationTips: (json['conversationTips'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      sampleDialogues: (json['sampleDialogues'] as List<dynamic>?)
              ?.map((e) => CourseDialogue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      quizzes: (json['quizzes'] as List<dynamic>?)
              ?.map(
                  (e) => CourseQuizQuestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'scenarioId': scenarioId,
        'title': title,
        'description': description,
        'level': level,
        'estimatedMinutes': estimatedMinutes,
        'vocabularies': vocabularies.map((v) => v.toJson()).toList(),
        'conversationTips': conversationTips,
        'sampleDialogues': sampleDialogues.map((d) => d.toJson()).toList(),
        'quizzes': quizzes.map((q) => q.toJson()).toList(),
      };
}

/// Dữ liệu khóa học chuẩn hóa cho 7 đề tài trong ứng dụng
const List<CourseModel> kTopicCourses = [
  // 1. Quán cà phê
  CourseModel(
    id: 'coffee_shop',
    scenarioId: 'coffee_shop',
    title: 'Khóa học: Giao tiếp tại Quán Cà Phê',
    description: 'Nắm vững từ vựng gọi đồ uống, tùy chỉnh đường đá và thanh toán.',
    level: 'Cơ bản',
    estimatedMinutes: 5,
    vocabularies: [
      CourseVocab(
        word: 'Iced Latte',
        phonetic: '/aɪst ˈlɑːteɪ/',
        meaning: 'Cà phê latte đá',
        exampleSentence: 'Could I get a medium iced latte with oat milk?',
      ),
      CourseVocab(
        word: 'Less ice / Half sweet',
        phonetic: '/lɛs aɪs / hæf swiːt/',
        meaning: 'Ít đá / 50% độ ngọt',
        exampleSentence: 'Please make it with less ice and half sweet.',
      ),
      CourseVocab(
        word: 'For here or to go?',
        phonetic: '/fɔːr hɪər ɔːr tuː ɡoʊ/',
        meaning: 'Dùng tại quán hay mang đi?',
        exampleSentence: 'It will be to go, please.',
      ),
      CourseVocab(
        word: 'Pastry',
        phonetic: '/ˈpeɪstri/',
        meaning: 'Bánh ngọt ăn kèm',
        exampleSentence: 'Do you have any fresh pastries today?',
      ),
    ],
    conversationTips: [
      'Bắt đầu lịch sự bằng "Can I get..." hoặc "Could I have..." thay vì "I want...".',
      'Luôn nói rõ dung tích cốc: Small (nhỏ), Medium (vừa), Large (lớn).',
      'Khi thu ngân hỏi "For here or to go?", trả lời ngắn gọn "To go, please" nếu mang đi.',
    ],
    sampleDialogues: [
      CourseDialogue(
        speaker: 'Barista',
        text: 'Hi there! What can I get started for you today?',
        translation: 'Xin chào! Hôm nay bạn muốn dùng gì ạ?',
      ),
      CourseDialogue(
        speaker: 'You',
        text: 'Hi! Could I get an iced Americano with less sugar, please?',
        translation: 'Chào bạn! Cho mình một Americano đá ít đường nhé.',
      ),
      CourseDialogue(
        speaker: 'Barista',
        text: 'Sure thing. For here or to go?',
        translation: 'Dạ được. Bạn dùng ở đây hay mang đi ạ?',
      ),
      CourseDialogue(
        speaker: 'You',
        text: 'To go, please. And how much is that?',
        translation: 'Mang đi giúp mình nhé. Hết bao nhiêu tiền vậy bạn?',
      ),
    ],
    quizzes: [
      CourseQuizQuestion(
        question: 'Khi muốn mang đồ uống đi, bạn nên trả lời thế nào?',
        options: ['For here, please', 'To go, please', 'I sit down', 'Eat inside'],
        correctIndex: 1,
        explanation: '"To go" là cụm từ chuẩn bản xứ dùng khi mua đồ uống mang đi.',
      ),
      CourseQuizQuestion(
        question: 'Câu nào gọi món lịch sự nhất trong quán cà phê?',
        options: [
          'Give me coffee now.',
          'I want an iced latte.',
          'Could I get a medium iced latte, please?',
          'Coffee is needed.'
        ],
        correctIndex: 2,
        explanation: 'Dùng "Could I get..." kết hợp với "please" là cách gọi món rất tự nhiên và lịch sự.',
      ),
    ],
  ),

  // 2. Nhận phòng khách sạn
  CourseModel(
    id: 'hotel_checkin',
    scenarioId: 'hotel_checkin',
    title: 'Khóa học: Thủ tục Nhận Phòng Khách Sạn',
    description: 'Cách cung cấp thông tin đặt phòng, hỏi giờ ăn sáng và mật khẩu Wi-Fi.',
    level: 'Cơ bản',
    estimatedMinutes: 5,
    vocabularies: [
      CourseVocab(
        word: 'Reservation',
        phonetic: '/ˌrɛzərˈveɪʃən/',
        meaning: 'Phiếu đặt phòng trước',
        exampleSentence: 'I have a reservation under the name John Doe.',
      ),
      CourseVocab(
        word: 'Key card',
        phonetic: '/kiː kɑːrd/',
        meaning: 'Thẻ từ mở phòng',
        exampleSentence: 'Here is your key card for room 402.',
      ),
      CourseVocab(
        word: 'Complimentary breakfast',
        phonetic: '/ˌkɑːmplɪˈmɛntri ˈbrɛkfəst/',
        meaning: 'Bữa sáng miễn phí theo phòng',
        exampleSentence: 'Is breakfast complimentary with this room?',
      ),
      CourseVocab(
        word: 'Check-out time',
        phonetic: '/tʃɛk aʊt taɪm/',
        meaning: 'Giờ trả phòng',
        exampleSentence: 'What time is check-out tomorrow morning?',
      ),
    ],
    conversationTips: [
      'Nói tên đặt phòng bằng cấu trúc: "I have a reservation under the name [Tên của bạn]".',
      'Đừng quên hỏi về tiện ích miễn phí: "Is Wi-Fi free?" và "Where is breakfast served?".',
    ],
    sampleDialogues: [
      CourseDialogue(
        speaker: 'Receptionist',
        text: 'Welcome to Grand Hotel! How can I help you today?',
        translation: 'Chào mừng quý khách đến với Grand Hotel! Tôi có thể giúp gì cho quý khách?',
      ),
      CourseDialogue(
        speaker: 'You',
        text: 'Hi, I have a reservation under John. Here is my passport.',
        translation: 'Chào bạn, tôi có đặt phòng tên là John. Đây là hộ chiếu của tôi.',
      ),
      CourseDialogue(
        speaker: 'Receptionist',
        text: 'Thank you! Your room is 501. Breakfast is served from 6:30 to 9:30 AM.',
        translation: 'Cảm ơn quý khách! Phòng của bạn là 501. Bữa sáng phục vụ từ 6:30 đến 9:30 sáng.',
      ),
    ],
    quizzes: [
      CourseQuizQuestion(
        question: 'Câu nào dùng để thông báo bạn đã đặt phòng trước?',
        options: [
          'I live here.',
          'I have a reservation under my name.',
          'Give me room.',
          'Where is hotel?'
        ],
        correctIndex: 1,
        explanation: '"I have a reservation under..." là câu chuẩn khi check-in khách sạn.',
      ),
    ],
  ),

  // 3. Hỏi đường
  CourseModel(
    id: 'directions',
    scenarioId: 'directions',
    title: 'Khóa học: Hỏi Đường & Chỉ Hướng',
    description: 'Cách hỏi đường đến các địa điểm công cộng và hiểu các chỉ dẫn rẽ trái, phải.',
    level: 'Cơ bản',
    estimatedMinutes: 5,
    vocabularies: [
      CourseVocab(
        word: 'Excuse me',
        phonetic: '/ɪkˈskjuːz miː/',
        meaning: 'Xin lỗi (dùng khi bắt đầu hỏi người lạ)',
        exampleSentence: 'Excuse me, could you tell me how to get to the subway?',
      ),
      CourseVocab(
        word: 'Turn left / Turn right',
        phonetic: '/tɜːrn lɛft / raɪt/',
        meaning: 'Rẽ trái / Rẽ phải',
        exampleSentence: 'Turn right at the traffic lights.',
      ),
      CourseVocab(
        word: 'Go straight ahead',
        phonetic: '/ɡoʊ streɪt əˈhɛd/',
        meaning: 'Đi thẳng về phía trước',
        exampleSentence: 'Go straight ahead for two blocks.',
      ),
      CourseVocab(
        word: 'Landmark',
        phonetic: '/ˈlændmɑːrk/',
        meaning: 'Địa danh / Tòa nhà mốc dễ nhận biết',
        exampleSentence: 'Is there any notable landmark nearby?',
      ),
    ],
    conversationTips: [
      'Luôn mở đầu bằng "Excuse me," để tạo sự thân thiện và tôn trọng.',
      'Hỏi thời gian đi bộ: "How long does it take to walk there?".',
    ],
    sampleDialogues: [
      CourseDialogue(
        speaker: 'You',
        text: 'Excuse me, could you tell me how to get to the central train station?',
        translation: 'Xin lỗi, bạn có thể chỉ giúp tôi đường đến ga tàu trung tâm không?',
      ),
      CourseDialogue(
        speaker: 'Local',
        text: 'Sure! Go straight for two blocks, then turn left. It will be on your right.',
        translation: 'Được chứ! Bạn đi thẳng hai dãy nhà, rồi rẽ trái. Ga tàu sẽ ở bên tay phải bạn.',
      ),
    ],
    quizzes: [
      CourseQuizQuestion(
        question: 'Cụm từ "Go straight ahead" có nghĩa là gì?',
        options: ['Rẽ trái ngay', 'Đi lùi lại', 'Đi thẳng về phía trước', 'Dừng lại'],
        correctIndex: 2,
        explanation: '"Go straight ahead" nghĩa là tiếp tục đi thẳng.',
      ),
    ],
  ),

  // 4. Mua sắm quần áo
  CourseModel(
    id: 'shopping_clothes',
    scenarioId: 'shopping_clothes',
    title: 'Khóa học: Mua Sắm Quần Áo',
    description: 'Hỏi kích cỡ (size), màu sắc, phòng thử đồ và hỏi về giảm giá.',
    level: 'Cơ bản',
    estimatedMinutes: 5,
    vocabularies: [
      CourseVocab(
        word: 'Fitting room',
        phonetic: '/ˈfɪtɪŋ ruːm/',
        meaning: 'Phòng thử đồ',
        exampleSentence: 'Where is the fitting room, please?',
      ),
      CourseVocab(
        word: 'Size medium / large',
        phonetic: '/saɪz ˈmiːdiəm/',
        meaning: 'Kích cỡ vừa / lớn',
        exampleSentence: 'Do you have this shirt in a size medium?',
      ),
      CourseVocab(
        word: 'Discount',
        phonetic: '/ˈdɪskaʊnt/',
        meaning: 'Giảm giá / Ưu đãi',
        exampleSentence: 'Is there any discount on this jacket?',
      ),
      CourseVocab(
        word: 'Try on',
        phonetic: '/traɪ ɑːn/',
        meaning: 'Mặc thử',
        exampleSentence: 'Can I try this on?',
      ),
    ],
    conversationTips: [
      'Dùng "Can I try this on?" khi muốn mặc thử đồ trong phòng thử đồ.',
      'Hỏi màu sắc khác: "Does this come in another color?".',
    ],
    sampleDialogues: [
      CourseDialogue(
        speaker: 'Assistant',
        text: 'Hello! Are you looking for anything in particular?',
        translation: 'Xin chào! Bạn đang tìm mẫu đồ nào đặc biệt không?',
      ),
      CourseDialogue(
        speaker: 'You',
        text: 'Yes, I like this jacket. Do you have it in black and size L?',
        translation: 'Vâng, tôi thích chiếc áo khoác này. Shop có màu đen cỡ L không ạ?',
      ),
    ],
    quizzes: [
      CourseQuizQuestion(
        question: 'Bạn muốn thử một chiếc áo, bạn sẽ nói:',
        options: ['Can I buy this now?', 'Can I try this on?', 'Can you wear this?', 'No clothes here.'],
        correctIndex: 1,
        explanation: '"Try on" nghĩa là thử đồ lên người.',
      ),
    ],
  ),

  // 5. Phỏng vấn xin việc
  CourseModel(
    id: 'job_interview',
    scenarioId: 'job_interview',
    title: 'Khóa học: Phỏng Vấn Xin Việc Cơ Bản',
    description: 'Tự giới thiệu bản thân, nêu điểm mạnh, điểm yếu và lý do ứng tuyển.',
    level: 'Trung cấp',
    estimatedMinutes: 6,
    vocabularies: [
      CourseVocab(
        word: 'Strength',
        phonetic: '/strɛŋkθ/',
        meaning: 'Thế mạnh / Điểm mạnh',
        exampleSentence: 'One of my greatest strengths is problem-solving under pressure.',
      ),
      CourseVocab(
        word: 'Work experience',
        phonetic: '/wɜːrk ɪkˈspɪriəns/',
        meaning: 'Kinh nghiệm làm việc',
        exampleSentence: 'I have over three years of experience in mobile development.',
      ),
      CourseVocab(
        word: 'Team player',
        phonetic: '/tiːm ˈpleɪər/',
        meaning: 'Người có tinh thần làm việc nhóm tốt',
        exampleSentence: 'I consider myself a strong team player and active learner.',
      ),
      CourseVocab(
        word: 'Career goal',
        phonetic: '/kəˈrɪər ɡoʊl/',
        meaning: 'Mục tiêu nghề nghiệp',
        exampleSentence: 'My goal is to grow into a lead mobile software engineer.',
      ),
    ],
    conversationTips: [
      'Trả lời theo cấu trúc STAR: Situation (Tình huống) - Task (Nhiệm vụ) - Action (Hành động) - Result (Kết quả).',
      'Khi nói về điểm yếu, luôn nêu kèm hành động bạn đang thực hiện để khắc phục.',
    ],
    sampleDialogues: [
      CourseDialogue(
        speaker: 'Interviewer',
        text: 'Could you please introduce yourself and your background?',
        translation: 'Bạn có thể giới thiệu sơ lược về bản thân và kinh nghiệm của mình được không?',
      ),
      CourseDialogue(
        speaker: 'You',
        text: 'Certainly! I am a passionate developer with a strong focus on Flutter and mobile UX.',
        translation: 'Dạ được ạ! Tôi là một lập trình viên nhiệt huyết, chuyên sâu về Flutter và trải nghiệm người dùng di động.',
      ),
    ],
    quizzes: [
      CourseQuizQuestion(
        question: 'Từ nào dùng để chỉ "điểm mạnh" trong buổi phỏng vấn?',
        options: ['Weakness', 'Strength', 'Mistake', 'Hobby'],
        correctIndex: 1,
        explanation: '"Strength" nghĩa là thế mạnh / điểm mạnh.',
      ),
    ],
  ),

  // 6. Hiệu thuốc
  CourseModel(
    id: 'pharmacy',
    scenarioId: 'pharmacy',
    title: 'Khóa học: Mua Thuốc Tại Hiệu Thuốc',
    description: 'Cách miêu tả các triệu chứng nhẹ (đau đầu, sốt, ho) và hỏi liều dùng thuốc.',
    level: 'Cơ bản',
    estimatedMinutes: 5,
    vocabularies: [
      CourseVocab(
        word: 'Symptom',
        phonetic: '/ˈsɪmptəm/',
        meaning: 'Triệu chứng bệnh',
        exampleSentence: 'What symptoms have you been experiencing?',
      ),
      CourseVocab(
        word: 'Headache / Sore throat',
        phonetic: '/ˈhɛdeɪk / sɔːr θroʊt/',
        meaning: 'Đau đầu / Đau họng',
        exampleSentence: 'I have had a mild fever and a sore throat for two days.',
      ),
      CourseVocab(
        word: 'Dosage',
        phonetic: '/ˈdoʊsɪdʒ/',
        meaning: 'Liều lượng dùng thuốc',
        exampleSentence: 'What is the recommended dosage for this syrup?',
      ),
      CourseVocab(
        word: 'Allergic',
        phonetic: '/əˈlɜːrdʒɪk/',
        meaning: 'Dị ứng với thuốc',
        exampleSentence: 'I am allergic to penicillin.',
      ),
    ],
    conversationTips: [
      'Nói rõ thời gian bị triệu chứng: "I have had a headache for 2 days".',
      'Hỏi cách uống: "Should I take this before or after meals?".',
    ],
    sampleDialogues: [
      CourseDialogue(
        speaker: 'Pharmacist',
        text: 'Hello. How can I help you today?',
        translation: 'Xin chào. Tôi có thể giúp gì cho bạn hôm nay?',
      ),
      CourseDialogue(
        speaker: 'You',
        text: 'I have a sore throat and a slight fever. Do you have something for this?',
        translation: 'Tôi bị đau họng và sốt nhẹ. Bạn có thuốc gì uống đỡ không?',
      ),
    ],
    quizzes: [
      CourseQuizQuestion(
        question: 'Khi muốn hỏi nên uống thuốc trước hay sau bữa ăn, bạn hỏi:',
        options: [
          'Is this food?',
          'Should I take this before or after meals?',
          'Where is food?',
          'Can I eat the pill?'
        ],
        correctIndex: 1,
        explanation: '"Should I take this before or after meals?" là câu chuẩn hỏi về thời điểm uống thuốc.',
      ),
    ],
  ),

  // 7. Đổi trả sản phẩm
  CourseModel(
    id: 'product_return',
    scenarioId: 'product_return',
    title: 'Khóa học: Đổi Trả Sản Phẩm',
    description: 'Trình bày lý do đổi trả hàng lỗi, xuất trình hóa đơn và chọn hoàn tiền.',
    level: 'Trung cấp',
    estimatedMinutes: 5,
    vocabularies: [
      CourseVocab(
        word: 'Refund',
        phonetic: '/ˈriːfʌnd/',
        meaning: 'Hoàn tiền lại',
        exampleSentence: 'Would you prefer a replacement or a full refund?',
      ),
      CourseVocab(
        word: 'Receipt',
        phonetic: '/rɪˈsiːt/',
        meaning: 'Hóa đơn mua hàng',
        exampleSentence: 'I still have the original receipt and packaging.',
      ),
      CourseVocab(
        word: 'Defective',
        phonetic: '/dɪˈfɛktɪv/',
        meaning: 'Bị lỗi, hư hỏng do nhà sản xuất',
        exampleSentence: 'The headphone is defective and only works on one side.',
      ),
      CourseVocab(
        word: 'Exchange',
        phonetic: '/ɪksˈtʃeɪndʒ/',
        meaning: 'Đổi sang sản phẩm khác',
        exampleSentence: 'Can I exchange this for a different model?',
      ),
    ],
    conversationTips: [
      'Bắt đầu bằng: "I would like to return/exchange this item because...".',
      'Luôn mang theo receipt (hóa đơn) để quy trình hoàn tiền diễn ra thuận lợi.',
    ],
    sampleDialogues: [
      CourseDialogue(
        speaker: 'Support',
        text: 'Hi there, how can I assist you with your purchase today?',
        translation: 'Chào bạn, tôi có thể hỗ trợ gì về đơn hàng của bạn hôm nay?',
      ),
      CourseDialogue(
        speaker: 'You',
        text: 'Hello. I bought this yesterday, but it seems defective. I would like a refund, please.',
        translation: 'Chào bạn. Tôi mua món này hôm qua nhưng nó bị lỗi. Tôi muốn yêu cầu hoàn tiền.',
      ),
    ],
    quizzes: [
      CourseQuizQuestion(
        question: 'Từ "Receipt" có nghĩa là gì?',
        options: ['Hộp đựng', 'Hóa đơn mua hàng', 'Mã giảm giá', 'Nhân viên bán hàng'],
        correctIndex: 1,
        explanation: '"Receipt" là hóa đơn mua hàng.',
      ),
    ],
  ),
];
