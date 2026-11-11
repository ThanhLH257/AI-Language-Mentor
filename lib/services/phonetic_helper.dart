/// Từ điển phiên âm IPA cho các từ vựng phổ biến trong giao tiếp và kịch bản Roleplay
class PhoneticHelper {
  static const Map<String, String> _ipaDictionary = {
    // Kịch bản Cà phê & Ăn uống
    'coffee': '/ˈkɒf.i/',
    'latte': '/ˈlɑː.teɪ/',
    'cappuccino': '/ˌkæp.əˈtʃiː.nəʊ/',
    'espresso': '/eˈspres.əʊ/',
    'beverage': '/ˈbev.ər.ɪdʒ/',
    'americano': '/əˌmer.ɪˈkɑː.nəʊ/',
    'mocha': '/ˈmɒk.ə/',
    'syrup': '/ˈsɪr.əp/',
    'receipt': '/rɪˈsiːt/',
    'bill': '/bɪl/',
    'cash': '/kæʃ/',
    'takeaway': '/ˈteɪk.ə.weɪ/',
    'dine-in': '/daɪn ɪn/',
    'sugar': '/ˈʃʊɡ.ər/',
    'ice': '/aɪs/',
    'order': '/ˈɔː.dər/',
    'menu': '/ˈmen.juː/',
    'pastry': '/ˈpeɪ.stri/',
    'croissant': '/ˈkrwɑː.sɒ̃/',

    // Kịch bản Phỏng vấn xin việc
    'interview': '/ˈɪn.tə.vjuː/',
    'interviewer': '/ˈɪn.tə.vjuː.ər/',
    'candidate': '/ˈkæn.dɪ.dət/',
    'qualification': '/ˌkwɒl.ɪ.fɪˈkeɪ.ʃən/',
    'experience': '/ɪkˈspɪə.ri.əns/',
    'strength': '/streŋθ/',
    'weakness': '/ˈwiːk.nəs/',
    'salary': '/ˈsæl.ər.i/',
    'position': '/pəˈzɪʃ.ən/',
    'resume': '/ˈrez.juː.meɪ/',
    'responsibilities': '/rɪˌspɒn.sɪˈbɪl.ə.tiz/',
    'teamwork': '/ˈtiːm.wɜːk/',
    'achievement': '/əˈtʃiːv.mənt/',
    'deadline': '/ˈded.laɪn/',
    'skill': '/skɪl/',
    'promotion': '/prəˈməʊ.ʃən/',

    // Kịch bản Khách sạn & Du lịch
    'reservation': '/ˌrez.əˈveɪ.ʃən/',
    'reception': '/rɪˈsep.ʃən/',
    'check-in': '/ˈtʃek.ɪn/',
    'check-out': '/ˈtʃek.aʊt/',
    'luggage': '/ˈlʌɡ.ɪdʒ/',
    'baggage': '/ˈbæɡ.ɪdʒ/',
    'amenity': '/əˈmen.ə.ti/',
    'amenities': '/əˈmen.ə.tiz/',
    'suite': '/swiːt/',
    'complimentary': '/ˌkɒm.plɪˈmen.tər.i/',
    'bellhop': '/ˈbel.hɒp/',
    'passport': '/ˈpɑːs.pɔːt/',
    'keycard': '/ˈkiː.kɑːd/',
    'shuttle': '/ˈʃʌt.əl/',

    // Kịch bản Hỏi đường
    'direction': '/daɪˈrek.ʃən/',
    'intersection': '/ˌɪn.təˈsek.ʃən/',
    'crossroad': '/ˈkrɒs.rəʊd/',
    'roundabout': '/ˈraʊnd.ə.baʊt/',
    'straight': '/streɪt/',
    'avenue': '/ˈæv.ə.njuː/',
    'boulevard': '/ˈbuː.lə.vɑːd/',
    'pedestrian': '/pəˈdes.tri.ən/',
    'pavement': '/ˈpeɪv.mənt/',
    'subway': '/ˈsʌb.weɪ/',
    'landmark': '/ˈlænd.mɑːk/',
    'corner': '/ˈkɔː.nər/',

    // Kịch bản Mua sắm
    'discount': '/ˈdɪs.kaʊnt/',
    'fitting room': '/ˈfɪt.ɪŋ ˌruːm/',
    'cashier': '/kæˈʃɪər/',
    'bargain': '/ˈbɑː.ɡɪn/',
    'refund': '/ˈriː.fʌnd/',
    'exchange': '/ɪksˈtʃeɪndʒ/',
    'warranty': '/ˈwɒr.ən.ti/',
    'size': '/saɪz/',
    'voucher': '/ˈvaʊ.tʃər/',
    'coupon': '/ˈkuː.pɒn/',
    'aisle': '/aɪl/',
    'trolley': '/ˈtrɒl.i/',

    // Từ vựng thông dụng khác
    'recommend': '/ˌrek.əˈmend/',
    'suggest': '/səˈdʒest/',
    'available': '/əˈveɪ.lə.bəl/',
    'convenient': '/kənˈviː.ni.ənt/',
    'appreciate': '/əˈpriː.ʃi.eɪt/',
    'apologize': '/əˈpɒl.ə.dʒaɪz/',
    'assistance': '/əˈsɪs.təns/',
    'schedule': '/ˈʃedʒ.uːl/',
    'appointment': '/əˈpɔɪnt.mənt/',
    'confirm': '/kənˈfɜːm/',
    'cancel': '/ˈkæn.səl/',
    'urgent': '/ˈɜː.dʒənt/',
    'opportunity': '/ˌɒp.əˈtʃuː.nə.ti/',
    'challenge': '/ˈtʃæl.ɪndʒ/',
    'delicious': '/dɪˈlɪʃ.əs/',
    'comfortable': '/ˈkʌm.fə.tə.bəl/',
    'fantastic': '/fænˈtæs.tɪk/',
    'wonderful': '/ˈwʌn.də.fəl/',
    'excellent': '/ˈek.səl.ənt/',
    'fluent': '/ˈfluː.ənt/',
    'vocabulary': '/vəˈkæb.jə.lər.i/',
    'pronunciation': '/prəˌnʌn.siˈeɪ.ʃən/',
    'conversation': '/ˌkɒn.vəˈseɪ.ʃən/',
    'practice': '/ˈpræk.tɪs/',
    'feedback': '/ˈfiːd.bæk/',
    'improvement': '/ɪmˈpruːv.mənt/',
    'confidence': '/ˈkɒn.fɪ.dəns/',
    'communication': '/kəˌmjuː.nɪˈkeɪ.ʃən/',
  };

  /// Tra cứu phiên âm IPA cho từ tiếng Anh.
  /// Nếu tìm thấy trả về phiên âm chuẩn `/.../`, nếu không trả về chuỗi rỗng.
  static String getPhonetic(String word) {
    final clean = word.trim().toLowerCase();
    if (_ipaDictionary.containsKey(clean)) {
      return _ipaDictionary[clean]!;
    }

    // Tra từ không dấu hoặc ký tự phụ
    final simple = clean.replaceAll(RegExp(r'[^a-zA-Z\s\-]'), '');
    if (_ipaDictionary.containsKey(simple)) {
      return _ipaDictionary[simple]!;
    }

    return '';
  }
}

