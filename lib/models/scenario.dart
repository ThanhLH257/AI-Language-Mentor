/// Kịch bản nhập vai (Roleplay) cố định.
class Scenario {
  final String id;
  final String title; // Tên kịch bản
  final String aiRole; // Vai của AI
  final String description; // Mô tả ngắn
  final List<String> tasks; // Kho nhiệm vụ (mỗi phiên chat chọn ngẫu nhiên 3)
  final String emoji; // Biểu tượng hiển thị
  final String? imagePath; // Đường dẫn ảnh nền asset
  final String? initialGreeting; // Lời chào mở đầu từ AI (nếu có)

  const Scenario({
    required this.id,
    required this.title,
    required this.aiRole,
    required this.description,
    required this.tasks,
    required this.emoji,
    this.imagePath,
    this.initialGreeting,
  });

  /// Số nhiệm vụ mỗi phiên chat.
  static const int tasksPerSession = 3;

  /// Tạo kịch bản trò chuyện tự do (Free Talk) với AI Mentor
  factory Scenario.freeTalk({
    String topic = 'Cuộc sống thường ngày',
    String persona = 'Người bạn bản xứ thân thiện',
    String? greeting,
    String emoji = '💬',
  }) {
    return Scenario(
      id: 'free_talk_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Free Talk: $topic',
      aiRole: persona,
      description: 'Đàm thoại tự do với AI Mentor về "$topic".',
      emoji: emoji,
      initialGreeting: greeting ??
          'Hi there! I am excited to chat with you today about $topic. How is everything going?',
      tasks: [
        'Chia sẻ suy nghĩ hoặc ý kiến cá nhân',
        'Đặt ít nhất 1 câu hỏi tương tác với bạn chat',
        'Duy trì phản xạ hội thoại trôi chảy',
      ],
    );
  }

  /// Tạo kịch bản tùy chỉnh do AI tạo từ yêu cầu của người dùng
  factory Scenario.custom({
    required String title,
    required String aiRole,
    required String description,
    required List<String> tasks,
    String? greeting,
    String emoji = '✨',
  }) {
    return Scenario(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      aiRole: aiRole,
      description: description,
      emoji: emoji,
      initialGreeting: greeting,
      tasks: tasks.isNotEmpty
          ? tasks
          : [
              'Bắt đầu câu chuyện đúng tình huống',
              'Đặt câu hỏi hoặc phản hồi tự nhiên',
              'Đạt được mục tiêu giao tiếp mong muốn',
            ],
    );
  }

  factory Scenario.fromJson(Map<String, dynamic> json) {
    return Scenario(
      id: json['id'] as String,
      title: json['title'] as String,
      aiRole: json['aiRole'] as String,
      description: json['description'] as String,
      tasks: List<String>.from(json['tasks'] as List),
      emoji: json['emoji'] as String,
      imagePath: json['imagePath'] as String?,
      initialGreeting: json['initialGreeting'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'aiRole': aiRole,
        'description': description,
        'tasks': tasks,
        'emoji': emoji,
        'imagePath': imagePath,
        'initialGreeting': initialGreeting,
      };
}

/// Danh sách 7 kịch bản có sẵn (mock data), mỗi kịch bản có 6 nhiệm vụ.
const List<Scenario> kScenarios = [
  Scenario(
    id: 'coffee_shop',
    title: 'At the Coffee Shop',
    aiRole: 'Barista',
    description: 'Gọi đồ uống tại quán cà phê.',
    emoji: '☕',
    imagePath: 'assets/images/atthecoffeeshop.jpg',
    tasks: [
      'Order a drink or food item',
      'Adjust sugar / ice level',
      'Ask for the price',
      'Ask for a recommendation',
      'Choose the size of your drink',
      'Say whether it is for here or to go',
    ],
  ),
  Scenario(
    id: 'hotel_checkin',
    title: 'Hotel Check-in',
    aiRole: 'Receptionist',
    description: 'Làm thủ tục nhận phòng khách sạn.',
    emoji: '🏨',
    imagePath: 'assets/images/hotelcheckin.jpg',
    tasks: [
      'Give your reservation name',
      'Ask about breakfast time',
      'Ask for the Wi-Fi password',
      'Get your room key',
      'Ask what time check-out is',
      'Ask for a wake-up call or extra towels',
    ],
  ),
  Scenario(
    id: 'directions',
    title: 'Asking for Directions',
    aiRole: 'Local Resident',
    description: 'Hỏi đường đến ga tàu hoặc bến xe.',
    emoji: '🗺️',
    imagePath: 'assets/images/askingfordirection.jpg',
    tasks: [
      'Ask the way to the train station or bus station',
      'Ask how long it takes to walk there',
      'Ask whether it is far from here',
      'Ask which street to turn on',
      'Ask for a landmark to look for',
      'Say thank you',
    ],
  ),
  Scenario(
    id: 'shopping_clothes',
    title: 'Shopping for Clothes',
    aiRole: 'Shop Assistant',
    description: 'Mua sắm quần áo tại cửa hàng.',
    emoji: '👕',
    imagePath: 'assets/images/shoppingforclothes.jpg',
    tasks: [
      'Ask for a size',
      'Ask for a different color',
      'Ask where the fitting room is',
      'Ask about a discount',
      'Ask what material it is made of',
      'Say whether you will buy it or not',
    ],
  ),
  Scenario(
    id: 'job_interview',
    title: 'Job Interview',
    aiRole: 'Interviewer',
    description: 'Luyện phỏng vấn xin việc.',
    emoji: '💼',
    imagePath: 'assets/images/jobinterview.jpg',
    tasks: [
      'Introduce yourself',
      'Mention one of your strengths',
      'Mention one weakness',
      'Explain why you want this job',
      'Describe your previous experience',
      'Ask the interviewer a question',
    ],
  ),
  Scenario(
    id: 'pharmacy',
    title: 'At the Pharmacy',
    aiRole: 'Pharmacist',
    description: 'Mua thuốc tại hiệu thuốc.',
    emoji: '💊',
    imagePath: 'assets/images/atthepharmacy.jpg',
    tasks: [
      'Describe mild symptoms',
      'Say how long you have felt this way',
      'Ask how to take the medicine',
      'Ask about possible side effects',
      'Say whether you have any allergies',
      'Ask for the price',
    ],
  ),
  Scenario(
    id: 'product_return',
    title: 'Product Return',
    aiRole: 'Customer Support',
    description: 'Đổi trả sản phẩm.',
    emoji: '📦',
    imagePath: 'assets/images/productreturn.jpg',
    tasks: [
      'State the reason for the return',
      'Describe the problem with the product',
      'Provide the order or receipt number',
      'Say when you bought it',
      'Choose exchange or refund',
      'Ask how long the refund will take',
    ],
  ),
];
