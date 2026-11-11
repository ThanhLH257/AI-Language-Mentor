# AI Language Mentor

Ứng dụng học tiếng Anh trên thiết bị di động được xây dựng bằng
**Flutter**, tích hợp **Google Gemini AI** để hỗ trợ luyện hội thoại,
viết nhật ký và luyện đặt câu. Ứng dụng kết hợp lưu trữ cục bộ với
**Supabase** để quản lý tài khoản và đồng bộ dữ liệu học tập.

## Tổng quan

AI Language Mentor hỗ trợ người học rèn luyện tiếng Anh thông qua: 
- **Roleplay:** luyện giao tiếp theo tình huống với nhân vật AI. 
- **Nhậtký tiếng Anh:** viết nhật ký, nhận điểm số, bản chỉnh sửa và nhận xét.
- **Sổ từ vựng:** lưu từ mới, phiên âm IPA, nghĩa, ví dụ và ngữ cảnh.
- **Ôn tập:** học từ bằng flashcard có hiệu ứng lật.
- **Luyện đặt câu:** tự đặt câu với từ đã lưu và nhận đánh giá từ AI.
- **Phát âm:** nghe cách đọc bằng Google TTS hoặc TTS trên thiết bị.
- **Lịch sử và hồ sơ:** xem lại hoạt động học tập và tiến độ.
- **Cá nhân hóa:** chọn giao diện sáng/tối, bảng màu, giọng đọc và tốc độ phát âm.

## Kiến trúc dự án

Dự án được tổ chức theo hướng MVC kết hợp GetX:

``` text
lib/
├── controllers/       # Quản lý trạng thái và nghiệp vụ
├── models/            # Các lớp dữ liệu
├── services/          # AI, Supabase, lưu trữ, TTS...
├── theme/             # Chủ đề và phong cách giao diện
├── views/             # Các màn hình
├── widgets/           # Widget dùng chung
└── main.dart          # Điểm khởi chạy ứng dụng
```

## Cơ chế lưu trữ và đồng bộ

Ứng dụng sử dụng mô hình kết hợp: 
1. Ghi dữ liệu vào **SharedPreferences** trên thiết bị trước.
2. Thực hiện đồng bộ dữ liệu lên **Supabase PostgreSQL**.
3. Khi đăng nhập thành công, ứng dụng gọi chức năng đồng bộ dữ liệu cục bộ lên Supabase.

## Cài đặt và chạy dự án

``` bash
flutter pub get
flutter run
```
