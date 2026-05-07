import 'dart:math';

import '../../../core/services/ai_service.dart';

final _rng = Random();

class AiPlanGenerator {
  AiPlanGenerator._();

  static const _taskTypes = ['matching', 'order_steps', 'fill_blank', 'tap_select', 'spot_error', 'image_select'];

  static Future<Map<String, dynamic>> generatePlan({
    required String subject,
    required String difficulty,
    required String goal,
    required int dailyMinutes,
  }) async {
    final prompt = _buildPrompt(subject: subject, difficulty: difficulty, goal: goal, dailyMinutes: dailyMinutes);

    try {
      final result = await AiService.processText(prompt);
      final data = result.data;
      if (data.containsKey('units')) {
        final units = data['units'] as List?;
        if (units != null && units.isNotEmpty) return data;
      }
    } catch (_) {}

    return fallbackPlan(subject, difficulty);
  }

  static String _buildPrompt({
    required String subject,
    required String difficulty,
    required String goal,
    required int dailyMinutes,
  }) {
    // Rastgelestirme tohumu — her kullanici farkli icerik alsin
    final seed = DateTime.now().millisecondsSinceEpoch;
    final variety = _rng.nextInt(1000);

    // Seviye bazli icerik derinligi ve dil karmasikligi
    final (diffDesc, depthGuide, langGuide) = switch (difficulty) {
      'Başlangıç' || 'Baslangic' => (
        'Bu alani HIC bilmeyen, ilk kez ogrenmeye baslayan biri.',
        'En temel kavramlardan basla. Karmasik formul/teori KULLANMA. Somut ve gunluk hayattan ornekler ver. Her kavram icin basit bir aciklama yap.',
        'Kisa ve anlasilir cumleler kur. Teknik jargon KULLANMA. Her yeni terimi acikla.',
      ),
      'Orta' => (
        'Temel kavramlari bilen, ara duzeyde pekistirmek isteyen biri.',
        'Orta zorlukta konulari isle. Kavramlar arasi iliskileri goster. Uygulamali ornekler ve problem cozmeler ekle. Baslangic seviyesini tekrarlama, derinlestir.',
        'Teknik terimleri aciklamasiz kullanabilirsin. Cumleler daha akademik olabilir.',
      ),
      'İleri' || 'Ileri' => (
        'Guclu temeli olan, ileri ve uzmanlik konularina hazirlanan biri.',
        'Karmasik ve ileri konulari isle. Edge case, optimizasyon, ileri teori, alternatif yaklasimlar ekle. Kritik dusunme gerektiren sorular sor.',
        'Akademik dil kullan. Karmasik cumleler ve derinlemesine analiz yapilabilir.',
      ),
      _ => (
        'Orta duzey bilgiye sahip biri.',
        'Orta zorlukta dengeli icerik olustur.',
        'Standart akademik dil kullan.',
      ),
    };

    return '''
Sen YALNIZCA "$subject" alaninda uzman, yaratici bir egitim planlayicisisin. Turkce yanit ver.
Rastgelestirme tohumu: $seed-$variety (Bu tohumla BENZERSIZ icerik uret. Ayni konuyu farkli acidan, farkli orneklerle, farkli soru kaliplariyla isleyerek her seferinde FARKLI bir ders plani olustur.)

=== ALAN BAGLAMI ===
YALNIZCA "$subject" alanina ozgu kavramlar, terimler, ornekler ve sorular kullan.
BASKA HICBIR ALANDAN ornek, benzetme veya terminoloji KULLANMA.
Her icerik parcasi dogrudan "$subject" konusuyla ilgili, DOGRULANABILIR akademik bilgi olmali.

=== OGRENCI PROFILI ===
Alan: $subject
Seviye: $difficulty — $diffDesc
Hedef: $goal
Gunluk calisma: $dailyMinutes dakika

=== ICERIK DERINLIGI (SEVIYEYE GORE) ===
$depthGuide
$langGuide

=== CESITLILIK KURALLARI (COK ONEMLI) ===
1. Her unite icindeki her ders FARKLI bir alt konu islenmeli. Ayni kavram veya soru TEKRARLAMA.
2. Soru kaliplari CESITLI olsun:
   - "Hangisi dogrudur?" yerine: "Asagidakilerden hangisi X ozelligini tasir?", "Y kavramini en iyi tanimlayan ifade hangisidir?", "Z durumunda ne olur?", "A ve B arasindaki temel fark nedir?"
3. tap_select icin 4 secenek olmali, secenekler birbirine YAKIN ama tek bir dogru cevap olmali. Secenekler mantikli yanlislar olsun (yanlis secenekler rastgele degil, konu ile ilgili yaniltici olsun).
4. spot_error icin hatali kelime ACIKCA yanlis olmali ama cumle icinde dogal durmali. Hata tek kelime olsun.
5. fill_blank icin bosluk cumlede KILIT bir kavrama denk gelmeli.
6. matching icin terimler ve tanımlar birbirine KARISTIRILABILIR olmali (kolay eslestirme olmasin).
7. ASLA ayni soruyu iki kere sorma. ASLA ayni eslestirme ciftlerini tekrarlama.

=== UNITE YAPISI ===
1. 10 unite olustur. Uniteler ONKOSUL sirasiyla: kolay → orta → zor.
   - Unite 1-3: Temel kavramlar ve giris
   - Unite 4-6: Orta duzey uygulamalar
   - Unite 7-9: Ileri konular ve sentez
   - Unite 10: Genel tekrar ve baglanti kurma
2. Her unitenin "$subject" konusuna ozgu GERCEK ve SPESIFIK basligi olsun.
3. Her unitede 8 ders. Her dersin OGRETICI, KONUYA OZGU basligi olsun.

=== ICERIK FORMATI ===
Her unitede sunlar olsun:
- 3 cumlede ozet aciklamasi (gercek bilgi icermeli, genel cumle YAZMA)
- 5 anahtar kavram (description icerisinde virgullerle)
- Dersler asagidaki gorev tiplerini CESITLI sekilde kullansin (art arda ayni tip KULLANMA)

=== HER DERSTE 8 ADIM ===
Her dersin task_content icinde "items" dizisi olmali ve 8 FARKLI soru/etkinlik icermeli.
Hepsi AYNI gorev tipinde olacak ama FARKLI kavramlar/sorular/ornekler kullanacak.
8 adimin hepsi o dersin KONUSUYLA ilgili ama farkli acilardan sorsun.

=== GOREV TIPLERI ===
A) "matching": task_content = {{"items":[{{"pairs":[{{"term":"T1","definition":"D1"}},{{"term":"T2","definition":"D2"}},{{"term":"T3","definition":"D3"}},{{"term":"T4","definition":"D4"}}]}}, ... 7 tane daha]}}
   - Her item 4 cift icermeli, hepsi FARKLI kavramlar
   - Terimler kisa (1-3 kelime), tanimlar aciklayici (5-15 kelime)

B) "order_steps": task_content = {{"items":[{{"instruction":"Aciklama","steps":["a1","a2","a3","a4"],"correct_order":[0,1,2,3]}}, ... 7 tane daha]}}
   - SADECE mantiksal/kronolojik siralama yapilabilen konularda kullan (tarih, islem adimlari, algoritma, bilimsel surec vs.)
   - Matematik formulleri, dil bilgisi kurallari gibi SIRALAMA MANTIGI OLMAYAN alanlarda order_steps KULLANMA, bunun yerine matching veya tap_select kullan

C) "fill_blank": task_content = {{"items":[{{"sentence":"Cumle _____","answer":"cevap","options":["cevap","y1","y2","y3"]}}, ... 7 tane daha]}}
   - Bosluk cumlede KILIT kavram olsun
   - 4 secenek: 1 dogru + 3 mantikli yanlis

D) "tap_select": task_content = {{"items":[{{"question":"Soru?","options":["A","B","C","D"],"correct_index":0}}, ... 7 tane daha]}}
   - Soru acik ve net olsun
   - Secenekler mantikli yanilticilar icersin
   - correct_index dogru cevabi isaret etsin (0-3 arasi)

E) "spot_error": task_content = {{"items":[{{"sentence":"Hatali cumle","error_word":"hata","correction":"dogru"}}, ... 7 tane daha]}}
   - error_word cumle icinde BIREBIR gecmeli (tek kelime, bosluk ICERMESIN)
   - Hata mantikli bir yanlis olsun (typo degil, kavramsal hata)

=== YASAKLAR ===
- ASLA placeholder: "Kavram A", "Secim B", "???", "ornek1" YASAK.
- ASLA baska alandan ornek verme.
- ASLA bos, anlamsiz veya tekrarli cumle yazma.
- ASLA ayni soruyu veya eslestirmeyi iki kere kullanma.
- Sorular O UNITENIN kavramlarini kullansin, rasgele bilgi sorma.
- spot_error icin error_word ASLA iki kelime olmasin, tek kelime olsun.

=== CIKTI ===
SADECE JSON. Aciklama, yorum, markdown, ``` isareti YAZMA.
{{"units":[{{"unit_index":1,"title":"...","description":"3 cumle ozet. Anahtar kavramlar: x, y, z, t, w","lessons":[{{"lesson_index":1,"title":"...","description":"...","task_type":"matching","task_content":{{"items":[...]}}}}]}}]}}
''';
  }

  /// Fallback plan with subject-aware content — her ders 8 adimli items dizisi icerir
  static Map<String, dynamic> fallbackPlan(String subject, String difficulty) {
    final db = _getFallbackUnits(subject);
    final units = <Map<String, dynamic>>[];

    for (int u = 0; u < 10; u++) {
      final unitData = db[u % db.length];
      final topics = unitData['topics'] as List<Map<String, dynamic>>;
      final lessons = <Map<String, dynamic>>[];

      for (int l = 0; l < 8; l++) {
        var taskType = _taskTypes[(u + l) % _taskTypes.length];
        // order_steps icin steps verisi yoksa matching'e don
        if (taskType == 'order_steps') {
          final hasSteps = topics.any((t) => (t['steps'] as List?)?.isNotEmpty == true);
          if (!hasSteps) taskType = 'matching';
        }
        // Her ders icin 8 farkli item olustur — tum topic'lerden rotate ederek
        final items = <Map<String, dynamic>>[];
        for (int step = 0; step < 7; step++) {
          final t = topics[(l + step) % topics.length];
          items.add(_buildSingleItem(taskType, t));
        }
        // Son adim (8.) TUM kavramlari kapsayan kapsamli bir ozet adimi
        items.add(_buildComprehensiveItem(taskType, topics));
        final mainTopic = topics[l % topics.length];
        lessons.add({
          'lesson_index': l + 1,
          'title': mainTopic['title'] as String,
          'description': '${unitData['title']} - ${mainTopic['title']}',
          'task_type': taskType,
          'task_content': {'items': items},
        });
      }

      units.add({
        'unit_index': u + 1,
        'title': '${unitData['title']}${u >= db.length ? ' (${u + 1})' : ''}',
        'description': '$subject - $difficulty seviye',
        'lessons': lessons,
      });
    }

    return {'units': units};
  }

  /// Tek bir task item olustur (matching, fill_blank vs.)
  static Map<String, dynamic> _buildSingleItem(String type, Map<String, dynamic> t) {
    switch (type) {
      case 'matching':
        return {'pairs': t['pairs'] ?? [{'term': 'Terim', 'definition': 'Aciklama'}]};
      case 'order_steps':
        List<String>? steps = (t['steps'] as List?)?.cast<String>();
        String instruction = (t['order_q'] as String?) ?? '';
        if (steps == null || steps.isEmpty) {
          // Siralama verisi yoksa eslestirme gorevine don
          return _buildSingleItem('matching', t);
        }
        return {
          'instruction': instruction.isEmpty ? 'Dogru siraya koy' : instruction,
          'steps': steps,
          'correct_order': List.generate(steps.length, (i) => i),
        };
      case 'fill_blank':
        final f = t['fill'] as Map<String, dynamic>? ?? {};
        final opts = List<String>.from(f['o'] ?? ['cevap', 'yanlis1', 'yanlis2', 'yanlis3']);
        opts.shuffle(_rng);
        return {
          'sentence': f['s'] ?? '_____ bir kavramdir.',
          'answer': f['a'] ?? 'cevap',
          'options': opts,
        };
      case 'tap_select':
        final q = t['quiz'] as Map<String, dynamic>? ?? {};
        final origOpts = List<String>.from(q['o'] ?? ['Dogru', 'Yanlis A', 'Yanlis B', 'Yanlis C']);
        final origIdx = (q['c'] as int?) ?? 0;
        final correctAnswer = origOpts[origIdx];
        origOpts.shuffle(_rng);
        final newIdx = origOpts.indexOf(correctAnswer);
        return {
          'question': q['q'] ?? 'Hangisi dogrudur?',
          'options': origOpts,
          'correct_index': newIdx,
        };
      case 'spot_error':
        final e = t['err'] as Map<String, dynamic>? ?? {};
        return {
          'sentence': e['s'] ?? 'Bu bir cumle.',
          'error_word': e['w'] ?? 'bir',
          'correction': e['f'] ?? 'dogru',
        };
      case 'image_select':
        final img = t['img'] as Map<String, dynamic>? ?? {};
        final origImages = List<String>.from(img['images'] ?? ['img1', 'img2', 'img3', 'img4']);
        final origLabels = List<String>.from(img['labels'] ?? ['Secim A', 'Secim B', 'Secim C', 'Secim D']);
        final origIdx = (img['c'] as int?) ?? 0;
        // Shuffle
        final indices = List.generate(origImages.length, (i) => i)..shuffle(_rng);
        final newImages = indices.map((i) => origImages[i]).toList();
        final newLabels = indices.map((i) => origLabels[i]).toList();
        final newIdx = indices.indexOf(origIdx);
        return {
          'question': img['q'] ?? 'Dogru resmi sec',
          'images': newImages,
          'labels': newLabels,
          'correct_index': newIdx,
        };
      default:
        return {'pairs': t['pairs']};
    }
  }

  /// Son adim: TUM kavramlari kapsayan kapsamli ozet item'i olustur
  static Map<String, dynamic> _buildComprehensiveItem(String type, List<Map<String, dynamic>> allTopics) {
    switch (type) {
      case 'matching':
        // Tum topic'lerden birer pair al, max 4
        final allPairs = <Map<String, String>>[];
        for (final t in allTopics) {
          final pairs = (t['pairs'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          if (pairs.isNotEmpty) {
            final p = pairs[_rng.nextInt(pairs.length)];
            allPairs.add({'term': p['term'] as String? ?? '', 'definition': p['definition'] as String? ?? ''});
          }
        }
        allPairs.shuffle(_rng);
        return {'pairs': allPairs.take(4).toList()};

      case 'order_steps':
        // Sadece steps verisi olan topic'lerden birlesik siralama olustur
        final allSteps = <String>[];
        for (final t in allTopics) {
          final steps = (t['steps'] as List?)?.cast<String>();
          if (steps != null && steps.isNotEmpty) {
            allSteps.add(steps.first);
          }
        }
        if (allSteps.length < 2) {
          // Yeterli siralama verisi yoksa eslestirmeye don
          return _buildComprehensiveItem('matching', allTopics);
        }
        allSteps.shuffle(_rng);
        final taken = allSteps.take(4).toList();
        return {
          'instruction': 'Tum kavramlari dogru siraya koy',
          'steps': taken,
          'correct_order': List.generate(taken.length, (i) => i),
        };

      case 'fill_blank':
        // Rastgele bir topic sec ama soru tum unite hakkinda
        final t = allTopics[_rng.nextInt(allTopics.length)];
        final f = t['fill'] as Map<String, dynamic>? ?? {};
        final opts = List<String>.from(f['o'] ?? ['cevap', 'yanlis1', 'yanlis2', 'yanlis3']);
        opts.shuffle(_rng);
        return {
          'sentence': f['s'] ?? 'Bu unitede ogrenilenlerden biri: _____',
          'answer': f['a'] ?? 'cevap',
          'options': opts,
        };

      case 'tap_select':
        // Rastgele topic quiz'i
        final t = allTopics[_rng.nextInt(allTopics.length)];
        final q = t['quiz'] as Map<String, dynamic>? ?? {};
        final origOpts = List<String>.from(q['o'] ?? ['Dogru', 'Yanlis A', 'Yanlis B', 'Yanlis C']);
        final origIdx = (q['c'] as int?) ?? 0;
        final correctAnswer = origOpts[origIdx.clamp(0, origOpts.length - 1)];
        origOpts.shuffle(_rng);
        return {
          'question': q['q'] ?? 'Bu unitenin kavramlarindan hangisi dogrudur?',
          'options': origOpts,
          'correct_index': origOpts.indexOf(correctAnswer),
        };

      case 'spot_error':
        final t = allTopics[_rng.nextInt(allTopics.length)];
        final e = t['err'] as Map<String, dynamic>? ?? {};
        return {
          'sentence': e['s'] ?? 'Bu cumledeki hatayi bul.',
          'error_word': e['w'] ?? 'hata',
          'correction': e['f'] ?? 'dogru',
        };

      case 'image_select':
        // Tum topic'lerden label olustur
        final labels = <String>[];
        final images = <String>[];
        for (final t in allTopics) {
          final img = t['img'] as Map<String, dynamic>? ?? {};
          final imgLabels = (img['labels'] as List?)?.cast<String>() ?? [];
          if (imgLabels.isNotEmpty) {
            labels.add(imgLabels.first);
            images.add('');
          } else {
            labels.add(t['title'] as String? ?? 'Kavram');
            images.add('');
          }
        }
        final taken = labels.length > 4 ? 4 : labels.length;
        return {
          'question': 'Bu unitenin kavramlarindan dogruyu sec',
          'images': images.take(taken).toList(),
          'labels': labels.take(taken).toList(),
          'correct_index': 0,
        };

      default:
        return allTopics.isNotEmpty ? _buildSingleItem('matching', allTopics.first) : {'pairs': []};
    }
  }

  // ── Subject databases ─────────────────────────────────

  static List<Map<String, dynamic>> _getFallbackUnits(String subject) {
    final s = subject.toLowerCase().replaceAllMapped(RegExp(r'[ıİğĞüÜşŞöÖçÇ]'), (m) {
      const map = {'ı': 'i', 'İ': 'i', 'ğ': 'g', 'Ğ': 'g', 'ü': 'u', 'Ü': 'u', 'ş': 's', 'Ş': 's', 'ö': 'o', 'Ö': 'o', 'ç': 'c', 'Ç': 'c'};
      return map[m.group(0)!] ?? m.group(0)!;
    });
    // Yazilim
    if (s.contains('yazilim') || s.contains('programlama') || s.contains('kod') || s.contains('software') || s.contains('web') || s.contains('mobil')) return _swUnits;
    if (s.contains('python') || s.contains('java') || s.contains('javascript') || s.contains('js') || s.contains('swift') || s.contains('kotlin') || s.contains('c++') || s.contains('sql')) return _swUnits;
    if (s.contains('veri yapi') || s.contains('algoritma') || s.contains('siber') || s.contains('api') || s.contains('git') || s.contains('linux') || s.contains('makine ogrenme')) return _swUnits;
    // Matematik
    if (s.contains('matematik') || s.contains('math') || s.contains('geometri') || s.contains('cebir') || s.contains('trigonometri') || s.contains('kalkulus') || s.contains('istatistik') || s.contains('olasilik') || s.contains('lineer')) return _mathUnits;
    // Fen
    if (s.contains('fizik') || s.contains('physics')) return _physUnits;
    if (s.contains('kimya') || s.contains('chem')) return _chemUnits;
    if (s.contains('biyoloji') || s.contains('bio')) return _bioUnits;
    // Dil
    if (s.contains('ingilizce') || s.contains('english') || s.contains('ielts') || s.contains('toefl') || s.contains('yds') || s.contains('yokdil') || s.contains('is ingilizce')) return _engUnits;
    if (s.contains('alman') || s.contains('german') || s.contains('deutsch')) return _deUnits;
    if (s.contains('frans') || s.contains('french') || s.contains('fran')) return _frUnits;
    // Sinav hazirlik (DGS = Matematik + Turkce)
    if (s.contains('dgs')) return _dgsUnits;
    if (s.contains('yks') && s.contains('mat')) return _mathUnits;
    if (s.contains('yks') && s.contains('fen')) return _physUnits; // fizik agirlikli
    if (s.contains('yks') && (s.contains('turkce') || s.contains('sosyal'))) return _dgsUnits; // turkce+sozel agirlikli
    if (s.contains('kpss') && s.contains('mat')) return _mathUnits;
    if (s.contains('kpss')) return _dgsUnits;
    // Sosyal bilimler
    if (s.contains('tarih')) return _tarihUnits;
    if (s.contains('cografya')) return _tarihUnits;
    if (s.contains('ekonomi') || s.contains('finans') || s.contains('muhasebe') || s.contains('pazarlama') || s.contains('girisimcilik')) return _econUnits;
    if (s.contains('psikoloji') || s.contains('sosyoloji') || s.contains('felsefe')) return _socUnits;
    // Fallback — subject adini direkt alan olarak kullanan genel yapili plan
    return _mathUnits; // en azindan mantikli bir icerik olsun
  }

  static final _swUnits = <Map<String, dynamic>>[
    {
      'title': 'Programlamaya Giris',
      'topics': [
        {'title': 'Degiskenler ve Veri Tipleri', 'pairs': [{'term': 'int', 'definition': 'Tam sayi veri tipi'}, {'term': 'String', 'definition': 'Metin veri tipi'}, {'term': 'bool', 'definition': 'Mantiksal deger (true/false)'}, {'term': 'double', 'definition': 'Ondalikli sayi veri tipi'}], 'steps': ['Degisken tipini belirle', 'Degisken adini yaz', 'Atama operatoru (=) koy', 'Degeri ata'], 'fill': {'s': 'Bir degisken tanimlamak icin once _____ belirtilmelidir.', 'a': 'veri tipi', 'o': ['veri tipi', 'dosya adi', 'sinif adi', 'fonksiyon']}, 'quiz': {'q': 'Hangisi bir veri tipi degildir?', 'o': ['for', 'int', 'String', 'bool'], 'c': 0}, 'err': {'s': 'Degiskenler hafizada gecici veri saklamak icin kullanilmaz.', 'w': 'kullanilmaz', 'f': 'kullanilir'}},
        {'title': 'Kosul Yapilari (if-else)', 'pairs': [{'term': 'if', 'definition': 'Kosul dogru ise calisir'}, {'term': 'else', 'definition': 'Kosul yanlis ise calisir'}, {'term': 'else if', 'definition': 'Ek kosul kontrolu yapar'}], 'fill': {'s': 'Bir kosul saglandiginda calisan kod blogu _____ ile baslar.', 'a': 'if', 'o': ['if', 'for', 'while', 'class']}, 'quiz': {'q': 'if(x > 10) ifadesinde x=5 ise hangi blok calisir?', 'o': ['else blogu', 'if blogu', 'Hata verir', 'Program durur'], 'c': 0}, 'err': {'s': 'if kosulunda parantez icinde mantiksal ifade yazilmamalidir.', 'w': 'yazilmamalidir', 'f': 'yazilmalidir'}},
        {'title': 'Donguler (for, while)', 'pairs': [{'term': 'for', 'definition': 'Belirli sayida tekrar eden dongu'}, {'term': 'while', 'definition': 'Kosul saglandikca tekrar eden dongu'}, {'term': 'break', 'definition': 'Donguyu sonlandirir'}, {'term': 'continue', 'definition': 'Mevcut adimi atlayip sonrakine gecer'}], 'fill': {'s': 'For dongusu _____ kez tekrar edecegini bildigimizde kullanilir.', 'a': 'kac', 'o': ['kac', 'neden', 'nasil', 'nerede']}, 'quiz': {'q': 'for(int i=0; i<5; i++) dongusu kac kez calisir?', 'o': ['5 kez', '4 kez', '6 kez', 'Sonsuz'], 'c': 0}, 'err': {'s': 'While dongusu kosul yanlis oldugu surece calisir.', 'w': 'yanlis', 'f': 'dogru'}},
        {'title': 'Fonksiyonlar', 'pairs': [{'term': 'return', 'definition': 'Fonksiyondan deger dondurur'}, {'term': 'void', 'definition': 'Deger dondurmeyen fonksiyon tipi'}, {'term': 'parametre', 'definition': 'Fonksiyona disaridan verilen deger'}], 'fill': {'s': 'Deger dondurmeyen fonksiyonlarin donus tipi _____ olarak belirtilir.', 'a': 'void', 'o': ['void', 'null', 'int', 'empty']}, 'quiz': {'q': 'Bir fonksiyonun amaci nedir?', 'o': ['Kod tekrarini onlemek', 'Hafizayi silmek', 'Programi yavaslatmak', 'Ekrani kapatmak'], 'c': 0}, 'err': {'s': 'Fonksiyonlar kodun tekrar kullanilamaz parcalaridir.', 'w': 'kullanilamaz', 'f': 'kullanilabilir'}},
        {'title': 'Diziler ve Listeler', 'pairs': [{'term': 'index', 'definition': 'Dizi elemaninin sira numarasi'}, {'term': 'length', 'definition': 'Dizideki eleman sayisi'}, {'term': 'add', 'definition': 'Diziye yeni eleman ekler'}], 'fill': {'s': 'Dizilerde ilk elemanin index numarasi _____ dir.', 'a': '0', 'o': ['0', '1', '-1', '10']}, 'quiz': {'q': '[10, 20, 30] dizisinde index 1 de ne vardir?', 'o': ['20', '10', '30', 'Hata'], 'c': 0}, 'err': {'s': 'Dizilerde index numarasi 1 den baslar.', 'w': '1', 'f': '0'}},
        {'title': 'Hata Yonetimi (try-catch)', 'pairs': [{'term': 'try', 'definition': 'Hata olusabilecek kodu sarar'}, {'term': 'catch', 'definition': 'Olusan hatayi yakalar'}, {'term': 'finally', 'definition': 'Hata olsa da calisir'}], 'fill': {'s': 'Bir hata olusabilecek kod _____ blogu icine yazilir.', 'a': 'try', 'o': ['try', 'main', 'class', 'for']}, 'quiz': {'q': 'try-catch yapisinda hata olmazsa catch blogu calisir mi?', 'o': ['Hayir', 'Evet', 'Bazen', 'Her zaman'], 'c': 0}, 'err': {'s': 'catch blogu hata olmasa bile her zaman calisir.', 'w': 'her zaman', 'f': 'sadece hata olustugunda'}},
      ],
    },
    {
      'title': 'Nesne Yonelimli Programlama',
      'topics': [
        {'title': 'Siniflar ve Nesneler', 'pairs': [{'term': 'class', 'definition': 'Nesne sablonu / tasarim plani'}, {'term': 'object', 'definition': 'Siniftan olusturulan ornek'}, {'term': 'constructor', 'definition': 'Nesne olusturulurken calisan metod'}], 'fill': {'s': 'Bir siniftan nesne olusturmak icin _____ anahtar kelimesi kullanilir.', 'a': 'new', 'o': ['new', 'class', 'void', 'static']}, 'quiz': {'q': 'Sinif ile nesne arasindaki iliski nedir?', 'o': ['Sinif sablon, nesne ornektir', 'Ayni seydir', 'Nesne sablondur', 'Iliskileri yoktur'], 'c': 0}, 'err': {'s': 'Bir siniftan sadece bir tane nesne olusturulabilir.', 'w': 'bir tane', 'f': 'birden fazla'}},
        {'title': 'Kalitim (Inheritance)', 'pairs': [{'term': 'extends', 'definition': 'Sinif kalitimi saglar'}, {'term': 'super', 'definition': 'Ust sinifa erisim saglar'}, {'term': 'override', 'definition': 'Ust sinif metodunu yeniden yazar'}], 'fill': {'s': 'Alt sinif, ust sinifin ozelliklerini _____ ile devralir.', 'a': 'extends', 'o': ['extends', 'implements', 'import', 'return']}, 'quiz': {'q': 'Kalitimda alt sinif ust sinifin nelerini kullanabilir?', 'o': ['Public metod ve alanlari', 'Sadece constructor', 'Hicbirini', 'Private alanlari'], 'c': 0}, 'err': {'s': 'Kalitimda alt sinif ust siniftan bagimsiz calisir.', 'w': 'bagimsiz', 'f': 'ozelliklerini devralarak'}},
        {'title': 'Kapsulleme', 'pairs': [{'term': 'private', 'definition': 'Sadece sinif icinden erisilebilir'}, {'term': 'public', 'definition': 'Her yerden erisilebilir'}, {'term': 'getter/setter', 'definition': 'Kontrollue erisim saglayan metodlar'}], 'fill': {'s': 'Kapsulleme ile sinifin ic detaylari _____ yapilir.', 'a': 'gizli', 'o': ['gizli', 'acik', 'statik', 'sabit']}, 'quiz': {'q': 'Kapsullemenin amaci nedir?', 'o': ['Veriyi korumak', 'Kodu yavaslatmak', 'Sinif silmek', 'Dongu olusturmak'], 'c': 0}, 'err': {'s': 'Private degiskenler sinif disindan dogrudan erisilebilir.', 'w': 'erisilebilir', 'f': 'erisilemez'}},
        {'title': 'Soyutlama (Abstraction)', 'pairs': [{'term': 'abstract', 'definition': 'Dogrudan orneklenemeyen sinif'}, {'term': 'interface', 'definition': 'Metod imzalarini tanimlar'}, {'term': 'implements', 'definition': 'Arayuzu uygular'}], 'fill': {'s': 'Abstract siniflardan dogrudan _____ olusturulamaz.', 'a': 'nesne', 'o': ['nesne', 'dosya', 'dongu', 'dizi']}, 'quiz': {'q': 'Abstract sinif ne ise yarar?', 'o': ['Ortak yapıyı tanimlar', 'Performans saglar', 'Veri siler', 'Gereksizdir'], 'c': 0}, 'err': {'s': 'Soyut siniflar dogrudan new ile olusturulabilir.', 'w': 'olusturulabilir', 'f': 'olusturulamaz'}},
        {'title': 'Polimorfizm', 'pairs': [{'term': 'Polimorfizm', 'definition': 'Ayni metodun farkli davranmasi'}, {'term': 'Override', 'definition': 'Metodu yeniden tanimlama'}, {'term': 'Overload', 'definition': 'Ayni isimli farkli parametreli metod'}], 'fill': {'s': 'Polimorfizm _____ anlamina gelir.', 'a': 'cok bicimlilik', 'o': ['cok bicimlilik', 'tek tiplilik', 'hiz', 'guvenlik']}, 'quiz': {'q': 'Polimorfizmin avantaji nedir?', 'o': ['Esneklik', 'Kod yavaslar', 'Hafiza artar', 'Hata olusur'], 'c': 0}, 'err': {'s': 'Polimorfizm sadece tek bir davranis sekli sunar.', 'w': 'tek bir', 'f': 'birden fazla'}},
        {'title': 'SOLID Prensipleri', 'pairs': [{'term': 'S - Tek Sorumluluk', 'definition': 'Her sinif tek is yapmali'}, {'term': 'O - Acik/Kapali', 'definition': 'Genislemeye acik, degisime kapali'}, {'term': 'D - Bagimlilik Tersleme', 'definition': 'Soyutlamalara bagimli ol'}], 'fill': {'s': 'SOLID in S harfi _____ prensibini temsil eder.', 'a': 'Tek Sorumluluk', 'o': ['Tek Sorumluluk', 'Guvenlik', 'Hiz', 'Depolama']}, 'quiz': {'q': 'Open/Closed prensibi ne der?', 'o': ['Genislemeye acik, degisime kapali', 'Her sey acik', 'Kod degistirilmemeli', 'Sinif silinmeli'], 'c': 0}, 'err': {'s': 'SOLID prensipleri kodun karmasik olmasini saglar.', 'w': 'karmasik', 'f': 'temiz ve suerdueruelebilir'}},
      ],
    },
  ];

  static final _mathUnits = <Map<String, dynamic>>[
    {
      'title': 'Sayi Sistemleri',
      'topics': [
        {'title': 'Dogal Sayilar', 'pairs': [{'term': 'Dogal sayi', 'definition': '0, 1, 2, 3... seklinde devam eden sayilar'}, {'term': 'Asal sayi', 'definition': 'Sadece 1 ve kendisine bolunebilen sayi'}, {'term': 'Cift sayi', 'definition': '2 ye tam bolunebilen sayilar'}], 'fill': {'s': 'En kucuk asal sayi _____ dir.', 'a': '2', 'o': ['2', '0', '1', '3']}, 'quiz': {'q': 'Hangisi asal sayidir?', 'o': ['7', '4', '6', '9'], 'c': 0}, 'err': {'s': '1 bir asal sayidir.', 'w': 'asal', 'f': 'asal olmayan'}},
        {'title': 'Bolunebilme Kurallari', 'pairs': [{'term': '2 ile bolunme', 'definition': 'Son basamagi cift olan sayilar'}, {'term': '3 ile bolunme', 'definition': 'Basamak toplami 3 un kati'}, {'term': '5 ile bolunme', 'definition': 'Son basamagi 0 veya 5'}, {'term': '9 ile bolunme', 'definition': 'Basamak toplami 9 un kati'}], 'fill': {'s': '3 e bolunebilmek icin basamak toplami _____ in kati olmali.', 'a': '3', 'o': ['3', '2', '5', '7']}, 'quiz': {'q': '126 hangi sayilara bolunur?', 'o': ['2, 3, 6, 9', 'Sadece 2', 'Sadece 3', '5 ve 7'], 'c': 0}, 'err': {'s': '15 sayisi 3 e bolunemez.', 'w': 'bolunemez', 'f': 'bolunebilir'}},
        {'title': 'EBOB ve EKOK', 'pairs': [{'term': 'EBOB', 'definition': 'En buyuk ortak bolen'}, {'term': 'EKOK', 'definition': 'En kucuk ortak kat'}, {'term': 'Aralarinda asal', 'definition': 'EBOB degeri 1 olan sayilar'}], 'steps': ['Sayilari asal carpanlarina ayir', 'Ortak carpanlari belirle', 'EBOB: Kucuk usluleri carp', 'EKOK: Buyuk usluleri carp'], 'fill': {'s': '12 ve 18 in EBOB degeri _____ dir.', 'a': '6', 'o': ['6', '3', '12', '36']}, 'quiz': {'q': '12 ve 18 in EKOK degeri kactir?', 'o': ['36', '6', '12', '24'], 'c': 0}, 'err': {'s': 'EBOB her zaman EKOK dan buyuktur.', 'w': 'buyuktur', 'f': 'kucuk veya esittir'}},
        {'title': 'Kesirler', 'pairs': [{'term': 'Pay', 'definition': 'Kesirde ust kisim'}, {'term': 'Payda', 'definition': 'Kesirde alt kisim'}, {'term': 'Bilesik kesir', 'definition': 'Payi paydasindan buyuk kesir'}], 'fill': {'s': 'Kesirlerde toplama yapmak icin _____ esitlenir.', 'a': 'paydalar', 'o': ['paydalar', 'paylar', 'sonuclar', 'sayilar']}, 'quiz': {'q': '1/2 + 1/3 sonucu nedir?', 'o': ['5/6', '2/5', '1/6', '2/6'], 'c': 0}, 'err': {'s': 'Carpma icin paydalar esitlenir.', 'w': 'esitlenir', 'f': 'caprazlama carpilir'}},
        {'title': 'Uslu Sayilar', 'pairs': [{'term': 'Taban', 'definition': 'Carpilan sayi'}, {'term': 'Us', 'definition': 'Carpma tekrar sayisi'}, {'term': '2^3=8', 'definition': '2 x 2 x 2 = 8'}], 'fill': {'s': '5^0 isleminin sonucu _____ dir.', 'a': '1', 'o': ['1', '0', '5', '50']}, 'quiz': {'q': '3^4 kactir?', 'o': ['81', '12', '27', '64'], 'c': 0}, 'err': {'s': 'Sifir uslu her sayi sifira esittir.', 'w': 'sifira', 'f': '1 e'}},
        {'title': 'Kok Alma', 'pairs': [{'term': 'Karekoku', 'definition': 'Kendisi ile carpildiginda o sayiyi veren deger'}, {'term': 'sqrt(9)=3', 'definition': '3x3=9 oldugu icin karekoku 3'}, {'term': 'sqrt(16)=4', 'definition': '4x4=16 oldugu icin karekoku 4'}], 'fill': {'s': 'Karekoku 25 in degeri _____ dir.', 'a': '5', 'o': ['5', '25', '12.5', '10']}, 'quiz': {'q': 'Negatif sayilarin karekoku alinabilir mi?', 'o': ['Reel sayilarda alinamaz', 'Her zaman alinir', '0 olur', '1 olur'], 'c': 0}, 'err': {'s': 'Karekoku 4 degeri 8 dir.', 'w': '8', 'f': '2'}},
      ],
    },
  ];

  static final _physUnits = <Map<String, dynamic>>[
    {
      'title': 'Kuvvet ve Hareket',
      'topics': [
        {'title': 'Newton Hareket Yasalari', 'pairs': [{'term': '1. Yasa (Eylemsizlik)', 'definition': 'Cisim kuvvet uygulanmazsa durumunu korur'}, {'term': '2. Yasa (F=m.a)', 'definition': 'Kuvvet = kutle x ivme'}, {'term': '3. Yasa (Etki-Tepki)', 'definition': 'Her etkiye esit ve zit tepki vardir'}], 'fill': {'s': 'Newton un 2. yasasina gore F = m x _____ dir.', 'a': 'a (ivme)', 'o': ['a (ivme)', 'v (hiz)', 't (zaman)', 's (yol)']}, 'quiz': {'q': '5 kg kutleli cisme 10 N kuvvet uygulanirsa ivme kac m/s²?', 'o': ['2', '50', '0.5', '15'], 'c': 0}, 'err': {'s': 'Newton 3. yasasina gore etki ve tepki esit degildir.', 'w': 'degildir', 'f': 'esittir'}},
        {'title': 'Surtunme Kuvveti', 'pairs': [{'term': 'Statik surtunme', 'definition': 'Hareketten onceki surtunme'}, {'term': 'Kinetik surtunme', 'definition': 'Hareket halindeki surtunme'}, {'term': 'Surtunme katsayisi', 'definition': 'Yuzey puruztulugunu gosteren deger'}], 'fill': {'s': 'Surtunme kuvveti harekete _____ yonde etki eder.', 'a': 'zit', 'o': ['zit', 'ayni', 'dik', 'paralel']}, 'quiz': {'q': 'Hangisi surtunmeyi azaltir?', 'o': ['Yag surme', 'Agirligi artirma', 'Yuzey puruzlugu', 'Hiz azaltma'], 'c': 0}, 'err': {'s': 'Surtunme kuvveti hareketi kolaylastirir.', 'w': 'kolaylastirir', 'f': 'zorlastirir'}},
        {'title': 'Is ve Enerji', 'pairs': [{'term': 'Is (W)', 'definition': 'Kuvvet x yer degistirme (Joule)'}, {'term': 'Kinetik Enerji', 'definition': '1/2 x m x v²'}, {'term': 'Potansiyel Enerji', 'definition': 'm x g x h'}], 'fill': {'s': 'Kinetik enerji formulu Ek = 1/2 x m x _____ dir.', 'a': 'v²', 'o': ['v²', 'a²', 'g²', 't²']}, 'quiz': {'q': '10 N kuvvetle 5 m yol = kac Joule?', 'o': ['50 J', '2 J', '15 J', '500 J'], 'c': 0}, 'err': {'s': 'Potansiyel enerji cismin hizina baglidir.', 'w': 'hizina', 'f': 'yuksekligine'}},
        {'title': 'Duzgun Dogrusal Hareket', 'pairs': [{'term': 'Hiz', 'definition': 'Birim zamandaki yer degistirme'}, {'term': 'Ivme', 'definition': 'Birim zamandaki hiz degisimi'}, {'term': 'DDH', 'definition': 'Sabit hizla yapilan hareket'}], 'fill': {'s': 'DDH de ivme _____ dir.', 'a': 'sifir', 'o': ['sifir', 'sabit', 'artarak', 'degisken']}, 'quiz': {'q': '90 km/h ile 2 saat = kac km?', 'o': ['180 km', '45 km', '90 km', '360 km'], 'c': 0}, 'err': {'s': 'DDH de hiz surekli degisir.', 'w': 'degisir', 'f': 'sabittir'}},
        {'title': 'Ivmeli Hareket', 'pairs': [{'term': 'DDIH', 'definition': 'Sabit ivmeyle hizlanan hareket'}, {'term': 'Serbest dusme', 'definition': 'Yercekimi etkisiyle dusme (g≈10m/s²)'}, {'term': 'v=v₀+a.t', 'definition': 'Hiz-zaman baglantisi'}], 'fill': {'s': 'Serbest dusmede ivme yaklasik _____ m/s² dir.', 'a': '10', 'o': ['10', '5', '20', '100']}, 'quiz': {'q': 'Durgundan 5 m/s² ivmeyle 4 s = hiz?', 'o': ['20 m/s', '9 m/s', '1.25 m/s', '40 m/s'], 'c': 0}, 'err': {'s': 'Serbest dusmede hafif cisimler yavas duser.', 'w': 'yavas', 'f': 'ayni hizda'}},
        {'title': 'Momentum', 'pairs': [{'term': 'Momentum', 'definition': 'Kutle x hiz (p=m.v)'}, {'term': 'Itme', 'definition': 'Kuvvet x zaman (I=F.t)'}, {'term': 'Korunum', 'definition': 'Dis kuvvet yoksa toplam momentum sabittir'}], 'fill': {'s': 'Momentum birimi _____ dir.', 'a': 'kg.m/s', 'o': ['kg.m/s', 'N', 'J', 'W']}, 'quiz': {'q': '2 kg, 3 m/s = momentum?', 'o': ['6 kg.m/s', '5 kg.m/s', '1.5 kg.m/s', '8 kg.m/s'], 'c': 0}, 'err': {'s': 'Capismada toplam momentum korunmaz.', 'w': 'korunmaz', 'f': 'korunur'}},
      ],
    },
  ];

  static final _engUnits = <Map<String, dynamic>>[
    {
      'title': 'Basic Grammar',
      'topics': [
        {'title': 'Simple Present Tense', 'pairs': [{'term': 'I play', 'definition': 'Ben oynarim'}, {'term': 'She goes', 'definition': 'O gider (3.tekil -s/-es)'}, {'term': 'They study', 'definition': 'Onlar calisir'}], 'fill': {'s': 'She _____ to school every day.', 'a': 'goes', 'o': ['goes', 'go', 'going', 'gone']}, 'quiz': {'q': 'Simple Present ne zaman kullanilir?', 'o': ['Aliskanlik ve gercekler', 'Gecmis', 'Gelecek', 'Suanda olan'], 'c': 0}, 'err': {'s': 'He go to work every morning.', 'w': 'go', 'f': 'goes'}},
        {'title': 'Past Simple Tense', 'pairs': [{'term': 'played', 'definition': 'play fiilinin gecmis hali'}, {'term': 'went', 'definition': 'go fiilinin gecmis hali'}, {'term': 'studied', 'definition': 'study fiilinin gecmis hali'}], 'fill': {'s': 'I _____ a good book yesterday.', 'a': 'read', 'o': ['read', 'readed', 'reading', 'reads']}, 'quiz': {'q': 'Hangisi duzenli (regular) fiildir?', 'o': ['played', 'went', 'saw', 'took'], 'c': 0}, 'err': {'s': 'She goed to the market last week.', 'w': 'goed', 'f': 'went'}},
        {'title': 'Present Continuous', 'pairs': [{'term': 'am/is/are + V-ing', 'definition': 'Present Continuous formulu'}, {'term': 'now', 'definition': 'Simdiki zaman belirteci'}, {'term': 'at the moment', 'definition': 'Su anda anlaminda'}], 'fill': {'s': 'They _____ football right now.', 'a': 'are playing', 'o': ['are playing', 'plays', 'played', 'play']}, 'quiz': {'q': 'Present Continuous ne zaman kullanilir?', 'o': ['Su anda olan eylemler', 'Gecmis', 'Aliskanliklar', 'Tahmin'], 'c': 0}, 'err': {'s': 'She is play tennis now.', 'w': 'play', 'f': 'playing'}},
        {'title': 'Articles (a/an/the)', 'pairs': [{'term': 'a', 'definition': 'Unsuz sesle baslayan tekil isimlerden once'}, {'term': 'an', 'definition': 'Unlu sesle baslayan tekil isimlerden once'}, {'term': 'the', 'definition': 'Belirli/bilinen isimlerden once'}], 'fill': {'s': 'She is _____ honest person.', 'a': 'an', 'o': ['an', 'a', 'the', '-']}, 'quiz': {'q': 'Hangisi dogrudur?', 'o': ['an apple', 'a apple', 'an car', 'a umbrella'], 'c': 0}, 'err': {'s': 'I saw a elephant at the zoo.', 'w': 'a', 'f': 'an'}},
        {'title': 'Prepositions (in/on/at)', 'pairs': [{'term': 'in', 'definition': 'Ay, yil, mevsim, sehir'}, {'term': 'on', 'definition': 'Gun, tarih, yuzey'}, {'term': 'at', 'definition': 'Saat, nokta, adres'}], 'fill': {'s': 'The meeting is _____ Monday.', 'a': 'on', 'o': ['on', 'in', 'at', 'to']}, 'quiz': {'q': 'Hangisi dogrudur?', 'o': ['at 5 o\'clock', 'in 5 o\'clock', 'on 5 o\'clock', 'to 5 o\'clock'], 'c': 0}, 'err': {'s': 'I was born at 1995.', 'w': 'at', 'f': 'in'}},
        {'title': 'Basic Vocabulary', 'pairs': [{'term': 'enormous', 'definition': 'Cok buyuk'}, {'term': 'tiny', 'definition': 'Cok kucuk'}, {'term': 'ancient', 'definition': 'Cok eski'}, {'term': 'modern', 'definition': 'Cagdas, yeni'}], 'fill': {'s': 'The opposite of "big" is _____.', 'a': 'small', 'o': ['small', 'tall', 'fast', 'old']}, 'quiz': {'q': '"Delicious" ne demektir?', 'o': ['Lezzetli', 'Tehlikeli', 'Pahali', 'Guzel'], 'c': 0}, 'err': {'s': 'Happy means sad in English.', 'w': 'sad', 'f': 'mutlu'}},
      ],
    },
  ];

  // ── ALMANCA ──────────────────────────────────────────

  static final _deUnits = <Map<String, dynamic>>[
    {
      'title': 'Almanca Temel Gramer',
      'topics': [
        {'title': 'Selamlasma ve Tanisma', 'pairs': [{'term': 'Guten Morgen', 'definition': 'Gunaydin'}, {'term': 'Guten Tag', 'definition': 'Iyi gunler'}, {'term': 'Auf Wiedersehen', 'definition': 'Hosca kal'}, {'term': 'Wie geht es Ihnen?', 'definition': 'Nasilsiniz?'}], 'fill': {'s': 'Almanca\'da "Merhaba" demek icin _____ deriz.', 'a': 'Hallo', 'o': ['Hallo', 'Danke', 'Bitte', 'Tschuss']}, 'quiz': {'q': '"Guten Abend" ne demektir?', 'o': ['Iyi aksamlar', 'Gunaydin', 'Hosca kal', 'Tesekkurler'], 'c': 0}, 'err': {'s': 'Guten Morgen iyi aksamlar demektir.', 'w': 'aksamlar', 'f': 'gunler/gunaydin'}},
        {'title': 'Artikeller (der/die/das)', 'pairs': [{'term': 'der', 'definition': 'Erkek cinsiyet artikeli'}, {'term': 'die', 'definition': 'Disi cinsiyet artikeli'}, {'term': 'das', 'definition': 'Nötr cinsiyet artikeli'}, {'term': 'die (cogul)', 'definition': 'Tum cogul isimler'}], 'fill': {'s': 'Almanca\'da her ismin bir _____ vardir.', 'a': 'artikeli', 'o': ['artikeli', 'rengi', 'sayisi', 'harfi']}, 'quiz': {'q': '"der Hund" ifadesinde "der" ne anlama gelir?', 'o': ['Erkek artikel', 'Disi artikel', 'Notr artikel', 'Cogul artikel'], 'c': 0}, 'err': {'s': 'Almanca\'da artikeller onemli degildir.', 'w': 'degildir', 'f': 'cok onemlidir'}},
        {'title': 'Kisisel Zamirler', 'pairs': [{'term': 'ich', 'definition': 'ben'}, {'term': 'du', 'definition': 'sen'}, {'term': 'er/sie/es', 'definition': 'o (erkek/kadin/notr)'}, {'term': 'wir', 'definition': 'biz'}], 'fill': {'s': 'Almanca\'da "biz" kelimesinin karsiligi _____ dir.', 'a': 'wir', 'o': ['wir', 'ihr', 'sie', 'ich']}, 'quiz': {'q': '"ihr" zamiri ne demektir?', 'o': ['siz', 'ben', 'biz', 'onlar'], 'c': 0}, 'err': {'s': '"ich" zamiri "sen" anlamina gelir.', 'w': 'sen', 'f': 'ben'}},
        {'title': 'sein ve haben Fiilleri', 'pairs': [{'term': 'ich bin', 'definition': 'ben ...im/yim'}, {'term': 'du bist', 'definition': 'sen ...sin'}, {'term': 'ich habe', 'definition': 'benim ...m var'}, {'term': 'er hat', 'definition': 'onun ...si var'}], 'steps': ['Ozneyi belirle (ich/du/er...)', 'Fiili sec (sein veya haben)', 'Fiili ozneye gore cek', 'Cumleyi tamamla'], 'fill': {'s': '"Ben ogrenciyim" cumlesi Almanca\'da "Ich _____ Student" olur.', 'a': 'bin', 'o': ['bin', 'bist', 'ist', 'sind']}, 'quiz': {'q': '"Sie ist Lehrerin" ne demektir?', 'o': ['O (kadin) ogretmendir', 'Sen ogrencisin', 'Biz doktoruz', 'Onlar iscidir'], 'c': 0}, 'err': {'s': '"Du bist" ifadesi "o var" anlamina gelir.', 'w': 'o var', 'f': 'sen ...sin'}},
        {'title': 'Sayilar (1-20)', 'pairs': [{'term': 'eins', 'definition': '1'}, {'term': 'funf', 'definition': '5'}, {'term': 'zehn', 'definition': '10'}, {'term': 'zwanzig', 'definition': '20'}], 'fill': {'s': 'Almanca\'da 3 sayisi _____ olarak soylenir.', 'a': 'drei', 'o': ['drei', 'drai', 'dri', 'tree']}, 'quiz': {'q': '"sieben" kac demektir?', 'o': ['7', '6', '8', '9'], 'c': 0}, 'err': {'s': '"neun" sayisi 6 demektir.', 'w': '6', 'f': '9'}},
        {'title': 'Gunluk Ifadeler', 'pairs': [{'term': 'Danke', 'definition': 'Tesekkurler'}, {'term': 'Bitte', 'definition': 'Lutfen / Rica ederim'}, {'term': 'Entschuldigung', 'definition': 'Afedersiniz'}, {'term': 'Ja / Nein', 'definition': 'Evet / Hayir'}], 'fill': {'s': '"Tesekkur ederim" Almanca\'da _____ dir.', 'a': 'Danke', 'o': ['Danke', 'Bitte', 'Hallo', 'Tschuss']}, 'quiz': {'q': '"Es tut mir leid" ne demektir?', 'o': ['Uzgunum', 'Mutluyum', 'Aciktim', 'Yoruldum'], 'c': 0}, 'err': {'s': '"Bitte" kelimesi "hayir" anlamina gelir.', 'w': 'hayir', 'f': 'lutfen / rica ederim'}},
      ],
    },
    {
      'title': 'Almanca Kelime Hazinesi',
      'topics': [
        {'title': 'Aile Uyeleri', 'pairs': [{'term': 'die Mutter', 'definition': 'anne'}, {'term': 'der Vater', 'definition': 'baba'}, {'term': 'der Bruder', 'definition': 'erkek kardes'}, {'term': 'die Schwester', 'definition': 'kiz kardes'}], 'fill': {'s': '"Buyukanne" Almanca\'da _____ dir.', 'a': 'die Grossmutter', 'o': ['die Grossmutter', 'die Tante', 'die Mutter', 'die Schwester']}, 'quiz': {'q': '"der Onkel" ne demektir?', 'o': ['Amca/dayi', 'Dede', 'Baba', 'Kuzen'], 'c': 0}, 'err': {'s': '"der Vater" anne demektir.', 'w': 'anne', 'f': 'baba'}},
        {'title': 'Yiyecek ve Icecekler', 'pairs': [{'term': 'das Brot', 'definition': 'ekmek'}, {'term': 'die Milch', 'definition': 'sut'}, {'term': 'der Apfel', 'definition': 'elma'}, {'term': 'das Wasser', 'definition': 'su'}], 'fill': {'s': 'Almanca\'da "kahve" kelimesi _____ dir.', 'a': 'der Kaffee', 'o': ['der Kaffee', 'der Tee', 'das Bier', 'der Saft']}, 'quiz': {'q': '"die Kartoffel" ne demektir?', 'o': ['Patates', 'Domates', 'Havuc', 'Sogan'], 'c': 0}, 'err': {'s': '"das Wasser" sut anlamina gelir.', 'w': 'sut', 'f': 'su'}},
        {'title': 'Renkler', 'pairs': [{'term': 'rot', 'definition': 'kirmizi'}, {'term': 'blau', 'definition': 'mavi'}, {'term': 'grun', 'definition': 'yesil'}, {'term': 'gelb', 'definition': 'sari'}], 'fill': {'s': '"Beyaz" Almanca\'da _____ dir.', 'a': 'weiss', 'o': ['weiss', 'schwarz', 'grau', 'braun']}, 'quiz': {'q': '"schwarz" hangi renktir?', 'o': ['Siyah', 'Beyaz', 'Gri', 'Kahverengi'], 'c': 0}, 'err': {'s': '"blau" rengi kirmizi demektir.', 'w': 'kirmizi', 'f': 'mavi'}},
        {'title': 'Haftanin Gunleri', 'pairs': [{'term': 'Montag', 'definition': 'Pazartesi'}, {'term': 'Mittwoch', 'definition': 'Carsamba'}, {'term': 'Freitag', 'definition': 'Cuma'}, {'term': 'Sonntag', 'definition': 'Pazar'}], 'fill': {'s': '"Cumartesi" Almanca\'da _____ dir.', 'a': 'Samstag', 'o': ['Samstag', 'Sonntag', 'Freitag', 'Donnerstag']}, 'quiz': {'q': '"Dienstag" hangi gundur?', 'o': ['Sali', 'Persembe', 'Pazartesi', 'Cuma'], 'c': 0}, 'err': {'s': '"Sonntag" Cumartesi demektir.', 'w': 'Cumartesi', 'f': 'Pazar'}},
        {'title': 'Meslekler', 'pairs': [{'term': 'der Arzt', 'definition': 'doktor (erkek)'}, {'term': 'die Lehrerin', 'definition': 'ogretmen (kadin)'}, {'term': 'der Ingenieur', 'definition': 'muhendis'}, {'term': 'der Koch', 'definition': 'asci'}], 'fill': {'s': '"Ogrenci" Almanca\'da _____ dir.', 'a': 'der Student', 'o': ['der Student', 'der Lehrer', 'der Arzt', 'der Pilot']}, 'quiz': {'q': '"die Krankenschwester" hangi meslektir?', 'o': ['Hemsire', 'Doktor', 'Eczaci', 'Dis hekimi'], 'c': 0}, 'err': {'s': '"der Koch" muhendis demektir.', 'w': 'muhendis', 'f': 'asci'}},
        {'title': 'Soru Kelimeleri', 'pairs': [{'term': 'Wer?', 'definition': 'Kim?'}, {'term': 'Was?', 'definition': 'Ne?'}, {'term': 'Wo?', 'definition': 'Nerede?'}, {'term': 'Wann?', 'definition': 'Ne zaman?'}], 'fill': {'s': '"Nasil?" sorusu Almanca\'da _____ dir.', 'a': 'Wie?', 'o': ['Wie?', 'Wo?', 'Was?', 'Wer?']}, 'quiz': {'q': '"Warum?" ne sorar?', 'o': ['Neden?', 'Nerede?', 'Ne zaman?', 'Nasil?'], 'c': 0}, 'err': {'s': '"Wo?" sorusu "ne zaman" anlamina gelir.', 'w': 'ne zaman', 'f': 'nerede'}},
      ],
    },
  ];

  // ── KIMYA ───────────────────────────────────────────

  static final _chemUnits = <Map<String, dynamic>>[
    {
      'title': 'Genel Kimya Temelleri',
      'topics': [
        {'title': 'Atom Yapisi', 'pairs': [{'term': 'Proton', 'definition': 'Cekirdekte bulunan (+) yuklu parcacik'}, {'term': 'Notron', 'definition': 'Cekirdekte bulunan yuksuz parcacik'}, {'term': 'Elektron', 'definition': 'Cekirdek etrafinda dolanan (-) yuklu parcacik'}, {'term': 'Cekirdek', 'definition': 'Atomun merkezindeki yogun bolge'}], 'fill': {'s': 'Atomun merkezinde _____ bulunur.', 'a': 'cekirdek', 'o': ['cekirdek', 'elektron', 'orbital', 'kabuk']}, 'quiz': {'q': 'Protonun yuku nedir?', 'o': ['Pozitif (+)', 'Negatif (-)', 'Yuksuz', 'Degisken'], 'c': 0}, 'err': {'s': 'Elektronlar atomun cekirdeginde bulunur.', 'w': 'cekirdeginde', 'f': 'yoerungelerinde'}, 'steps': ['Cekirdegi belirle', 'Proton ve notronlari yerlestir', 'Elektron kabuklarini ciz', 'Elektronlari dagilimina gore yerlestir'], 'order_q': 'Atom modelini adim adim olustur'},
        {'title': 'Periyodik Tablo', 'pairs': [{'term': 'Periyot', 'definition': 'Yatay satirlar (enerji seviyesi)'}, {'term': 'Grup', 'definition': 'Dikey sutunlar (degerlik e-)'}, {'term': 'Metal', 'definition': 'Iletken, parlak elementler'}, {'term': 'Ametal', 'definition': 'Iletken olmayan elementler'}], 'fill': {'s': 'Periyodik tabloda ayni gruptaki elementler benzer _____ gosterir.', 'a': 'kimyasal ozellik', 'o': ['kimyasal ozellik', 'kutle', 'renk', 'boyut']}, 'quiz': {'q': 'Periyodik tabloda periyot neyi gosterir?', 'o': ['Enerji seviyesi sayisi', 'Elektron sayisi', 'Notron sayisi', 'Atom agirligi'], 'c': 0}, 'err': {'s': 'Soy gazlar cok reaktif elementlerdir.', 'w': 'reaktif', 'f': 'kararli (tepkimeye girmez)'}},
        {'title': 'Kimyasal Baglar', 'pairs': [{'term': 'Iyonik bag', 'definition': 'Elektron transferi ile olusan bag'}, {'term': 'Kovalent bag', 'definition': 'Elektron paylasimi ile olusan bag'}, {'term': 'Metalik bag', 'definition': 'Serbest elektron denizi modeli'}, {'term': 'H-bagi', 'definition': 'H ile N/O/F arasindaki zayif bag'}], 'fill': {'s': 'NaCl bilesiginde Na ve Cl arasinda _____ bag vardir.', 'a': 'iyonik', 'o': ['iyonik', 'kovalent', 'metalik', 'Van der Waals']}, 'quiz': {'q': 'Kovalent bagda ne olur?', 'o': ['Elektron paylasimi', 'Elektron transferi', 'Proton transferi', 'Notron paylasimi'], 'c': 0}, 'err': {'s': 'Metalik bagda elektronlar sabit konumdadir.', 'w': 'sabit', 'f': 'serbest halde hareket eder'}},
        {'title': 'Mol Kavrami', 'pairs': [{'term': 'Mol', 'definition': '6.02 x 10²³ tane parcacik'}, {'term': 'Avogadro', 'definition': '6.02 x 10²³ sayisi'}, {'term': 'Molar kutle', 'definition': '1 mol maddenin gram cinsinden kutlesi'}, {'term': 'Molalite', 'definition': '1 kg cozucudeki mol sayisi'}], 'fill': {'s': '1 mol suda _____ tane molekul vardir.', 'a': '6.02 x 10²³', 'o': ['6.02 x 10²³', '3.14 x 10⁸', '1.6 x 10⁻¹⁹', '9.8 x 10¹']}, 'quiz': {'q': 'H₂O nun molar kutlesi kac g/mol dur?', 'o': ['18', '16', '2', '20'], 'c': 0}, 'err': {'s': 'Avogadro sayisi 6.02 x 10¹⁰ dur.', 'w': '10¹⁰', 'f': '10²³'}},
        {'title': 'Kimyasal Formuller', 'pairs': [{'term': 'H₂O', 'definition': 'Su'}, {'term': 'NaCl', 'definition': 'Sofra tuzu'}, {'term': 'CO₂', 'definition': 'Karbondioksit'}, {'term': 'H₂SO₄', 'definition': 'Sulfurik asit'}], 'fill': {'s': 'Sofra tuzunun kimyasal formulu _____ dir.', 'a': 'NaCl', 'o': ['NaCl', 'KCl', 'NaOH', 'HCl']}, 'quiz': {'q': 'CO₂ hangi bilesiktir?', 'o': ['Karbondioksit', 'Karbonmonoksit', 'Metan', 'Etan'], 'c': 0}, 'err': {'s': 'H₂O formulu karbondioksiti temsil eder.', 'w': 'karbondioksiti', 'f': 'suyu'}},
        {'title': 'Asit ve Bazlar', 'pairs': [{'term': 'Asit', 'definition': 'H⁺ iyonu veren madde'}, {'term': 'Baz', 'definition': 'OH⁻ iyonu veren madde'}, {'term': 'pH', 'definition': 'Cozeltinin asitlik olcusu'}, {'term': 'Notr', 'definition': 'pH degeri 7 olan cozelti'}], 'fill': {'s': 'pH degeri 7 den kucuk olan cozeltiler _____ dir.', 'a': 'asidik', 'o': ['asidik', 'bazik', 'notr', 'tuzlu']}, 'quiz': {'q': 'Limon suyunun pH degeri yaklasik kactir?', 'o': ['2-3', '7', '10-11', '14'], 'c': 0}, 'err': {'s': 'Bazlar H⁺ iyonu verir.', 'w': 'H⁺', 'f': 'OH⁻'}},
      ],
    },
    {
      'title': 'Kimyasal Tepkimeler',
      'topics': [
        {'title': 'Tepkime Denklemleri', 'pairs': [{'term': 'Girenler', 'definition': 'Tepkimeye giren maddeler (sol taraf)'}, {'term': 'Urunler', 'definition': 'Tepkime sonucu olusan maddeler'}, {'term': 'Denklemek', 'definition': 'Atom sayilarini esitlemek'}, {'term': 'Katsayi', 'definition': 'Formul onundeki sayi'}], 'fill': {'s': 'Kimyasal denklemde ok isaretinin solunda _____ bulunur.', 'a': 'girenler', 'o': ['girenler', 'urunler', 'katalizor', 'cozucu']}, 'quiz': {'q': 'Denklem dengelemede ne korunur?', 'o': ['Atom sayisi', 'Molekul sayisi', 'Hacim', 'Sicaklik'], 'c': 0}, 'err': {'s': 'Kimyasal tepkimede atom sayisi degisir.', 'w': 'degisir', 'f': 'korunur'}},
        {'title': 'Tepkime Tipleri', 'pairs': [{'term': 'Sentez', 'definition': 'A + B → AB (birlesme)'}, {'term': 'Analiz', 'definition': 'AB → A + B (ayrisma)'}, {'term': 'Yer degistirme', 'definition': 'AB + C → AC + B'}, {'term': 'Yanma', 'definition': 'Madde + O₂ → CO₂ + H₂O'}], 'fill': {'s': 'Iki maddenin birlesmesiyle yeni madde olusmasina _____ tepkimesi denir.', 'a': 'sentez', 'o': ['sentez', 'analiz', 'yanma', 'cokme']}, 'quiz': {'q': '2H₂ + O₂ → 2H₂O hangi tepkime turudur?', 'o': ['Sentez', 'Analiz', 'Yer degistirme', 'Notrlesme'], 'c': 0}, 'err': {'s': 'Analiz tepkimesinde maddeler birlesir.', 'w': 'birlesir', 'f': 'ayrisir'}},
        {'title': 'Cozeltiler', 'pairs': [{'term': 'Cozucu', 'definition': 'Cozen madde (genelde su)'}, {'term': 'Cozunen', 'definition': 'Cozulen madde'}, {'term': 'Deriik', 'definition': 'Cok cozunen iceren cozelti'}, {'term': 'Seyreltik', 'definition': 'Az cozunen iceren cozelti'}], 'fill': {'s': 'Tuzlu suda, su _____ dir.', 'a': 'cozucu', 'o': ['cozucu', 'cozunen', 'urun', 'katalizor']}, 'quiz': {'q': 'Derişik çözelti ne demektir?', 'o': ['Cok cozunen iceren', 'Az cozunen iceren', 'Cozucusu fazla olan', 'Soguk cozelti'], 'c': 0}, 'err': {'s': 'Cozucu, cozelti icinde cozunen maddedir.', 'w': 'cozunen', 'f': 'cozen'}},
        {'title': 'Gaz Yasalari', 'pairs': [{'term': 'Boyle', 'definition': 'P₁V₁ = P₂V₂ (sabit T)'}, {'term': 'Charles', 'definition': 'V₁/T₁ = V₂/T₂ (sabit P)'}, {'term': 'Ideal gaz', 'definition': 'PV = nRT'}, {'term': 'Avogadro', 'definition': 'Esit V, esit T → esit mol'}], 'fill': {'s': 'Ideal gaz denkleminde PV = _____ dir.', 'a': 'nRT', 'o': ['nRT', 'mRT', 'kT', 'PnR']}, 'quiz': {'q': 'Boyle yasasinda sabit tutulan nedir?', 'o': ['Sicaklik', 'Basinc', 'Hacim', 'Mol sayisi'], 'c': 0}, 'err': {'s': 'Charles yasasinda basinc degiskendir.', 'w': 'degiskendir', 'f': 'sabittir'}},
        {'title': 'Oksidasyon-Reduksiyon', 'pairs': [{'term': 'Oksidasyon', 'definition': 'Elektron kaybetme'}, {'term': 'Reduksiyon', 'definition': 'Elektron kazanma'}, {'term': 'Oksitleyici', 'definition': 'Elektron alan madde'}, {'term': 'Indirgen', 'definition': 'Elektron veren madde'}], 'fill': {'s': 'Elektron kaybeden madde _____ olur.', 'a': 'oksitlenir', 'o': ['oksitlenir', 'indirgenir', 'notrlesir', 'cozunur']}, 'quiz': {'q': 'Reduksiyon nedir?', 'o': ['Elektron kazanma', 'Elektron kaybetme', 'Proton kazanma', 'Notron kaybetme'], 'c': 0}, 'err': {'s': 'Indirgen madde elektron alir.', 'w': 'alir', 'f': 'verir'}},
        {'title': 'Termokimya', 'pairs': [{'term': 'Ekzotermik', 'definition': 'Isi veren tepkime'}, {'term': 'Endotermik', 'definition': 'Isi alan tepkime'}, {'term': 'Entalpi', 'definition': 'Tepkimenin isi degisimi (ΔH)'}, {'term': 'Katalizor', 'definition': 'Tepkimeyi hizlandiran madde'}], 'fill': {'s': 'Yanma tepkimeleri _____ tepkimelerdir.', 'a': 'ekzotermik', 'o': ['ekzotermik', 'endotermik', 'notr', 'tersinir']}, 'quiz': {'q': 'Katalizor tepkimede ne yapar?', 'o': ['Hizlandirir', 'Yavaslatir', 'Durdurur', 'Urun degistirir'], 'c': 0}, 'err': {'s': 'Endotermik tepkimelerde isi aciga cikar.', 'w': 'aciga cikar', 'f': 'absorbe edilir'}},
      ],
    },
  ];

  // ── BIYOLOJI ──────────────────────────────────────────

  static final _bioUnits = <Map<String, dynamic>>[
    {
      'title': 'Hucre Biyolojisi',
      'topics': [
        {'title': 'Hucre Yapisi', 'pairs': [{'term': 'Mitokondri', 'definition': 'Enerji ureten organel'}, {'term': 'Ribozom', 'definition': 'Protein sentezleyen organel'}, {'term': 'Golgi', 'definition': 'Maddeleri paketleyen organel'}, {'term': 'Lizozom', 'definition': 'Sindirim enzimi iceren organel'}], 'fill': {'s': 'Hucrenin enerji santrali _____ dir.', 'a': 'mitokondri', 'o': ['mitokondri', 'ribozom', 'golgi', 'lizozom']}, 'quiz': {'q': 'Protein sentezi nerede gerceklesir?', 'o': ['Ribozom', 'Mitokondri', 'Cekirdek', 'Golgi'], 'c': 0}, 'err': {'s': 'Lizozom enerji uretir.', 'w': 'enerji uretir', 'f': 'sindirim yapar'}, 'steps': ['Hucre zarindan gecis', 'Sitoplazmaya ulasim', 'Organele yonelim', 'Islevin gerceklesmesi'], 'order_q': 'Madde hucre icinde nasil islenir?'},
        {'title': 'DNA ve Genetik', 'pairs': [{'term': 'DNA', 'definition': 'Genetik bilgiyi tasiyan molekul'}, {'term': 'Gen', 'definition': 'Protein kodlayan DNA parcasi'}, {'term': 'Kromozom', 'definition': 'DNA nin yogunlasmis hali'}, {'term': 'RNA', 'definition': 'DNA dan bilgi tasiyan molekul'}], 'fill': {'s': 'Genetik bilgi _____ molekulunde saklanir.', 'a': 'DNA', 'o': ['DNA', 'RNA', 'protein', 'lipid']}, 'quiz': {'q': 'Insanda kac cift kromozom vardir?', 'o': ['23', '22', '46', '24'], 'c': 0}, 'err': {'s': 'RNA cift sarmal yapisinddair.', 'w': 'cift', 'f': 'tek'}},
        {'title': 'Fotosentez', 'pairs': [{'term': 'Kloroplast', 'definition': 'Fotosentezin gerceklestigi organel'}, {'term': 'Klorofil', 'definition': 'Isik soguran yesil pigment'}, {'term': 'CO₂', 'definition': 'Fotosentezde kullanilan gaz'}, {'term': 'O₂', 'definition': 'Fotosentezde aciga cikan gaz'}], 'fill': {'s': 'Fotosentez _____ organelinde gerceklesir.', 'a': 'kloroplast', 'o': ['kloroplast', 'mitokondri', 'ribozom', 'golgi']}, 'quiz': {'q': 'Fotosentezde hammadde nedir?', 'o': ['CO₂ ve H₂O', 'O₂ ve glikoz', 'Protein ve yag', 'ATP ve NADP'], 'c': 0}, 'err': {'s': 'Fotosentezde oksijen tuketilir.', 'w': 'tuketilir', 'f': 'uretilir'}},
        {'title': 'Hucre Bolunmesi', 'pairs': [{'term': 'Mitoz', 'definition': '2 esit hucre olusturan bolunme'}, {'term': 'Mayoz', 'definition': '4 haploid hucre olusturan bolunme'}, {'term': 'Interfaz', 'definition': 'Bolunme oncesi hazirlik evresi'}, {'term': 'Krossing over', 'definition': 'Homolog kromozomlarda gen degisimi'}], 'fill': {'s': 'Vucut hucrelerinin cogalmasi _____ bolunme ile olur.', 'a': 'mitoz', 'o': ['mitoz', 'mayoz', 'amitoz', 'biner']}, 'quiz': {'q': 'Mayoz bolunme sonucunda kac hucre olusur?', 'o': ['4', '2', '1', '8'], 'c': 0}, 'err': {'s': 'Mitoz bolunmede kromozom sayisi yarilir.', 'w': 'yarilir', 'f': 'ayni kalir'}},
        {'title': 'Sindirim Sistemi', 'pairs': [{'term': 'Agiz', 'definition': 'Mekanik ve kimyasal sindirimin basladigi yer'}, {'term': 'Mide', 'definition': 'Protein sindiriminin basladigi organ'}, {'term': 'Ince bagirsak', 'definition': 'Besin emiliminin yapildigi organ'}, {'term': 'Karaciger', 'definition': 'Safra ureten organ'}], 'fill': {'s': 'Protein sindirimi _____ de baslar.', 'a': 'midede', 'o': ['midede', 'agizda', 'karacigerde', 'ince bagirsak']}, 'quiz': {'q': 'Besin emilimi nerede gerceklesir?', 'o': ['Ince bagirsak', 'Mide', 'Kalin bagirsak', 'Yemek borusu'], 'c': 0}, 'err': {'s': 'Safra midede uretilir.', 'w': 'midede', 'f': 'karacigerde'}},
        {'title': 'Dolasim Sistemi', 'pairs': [{'term': 'Kalp', 'definition': 'Kani pompalayan organ'}, {'term': 'Atardamar', 'definition': 'Kalpten organlara kan tasiyan damar'}, {'term': 'Toplardamar', 'definition': 'Organlardan kalbe kan getiren damar'}, {'term': 'Kilcal damar', 'definition': 'Madde degisiminin yapildigi ince damar'}], 'fill': {'s': 'Kalpten temiz kani organlara tasiyan damarlara _____ denir.', 'a': 'atardamar', 'o': ['atardamar', 'toplardamar', 'kilcal damar', 'lenf damari']}, 'quiz': {'q': 'Kilcal damarlarin gorevi nedir?', 'o': ['Madde degisimi', 'Kan pompalama', 'Kan depolama', 'Kan filtreleme'], 'c': 0}, 'err': {'s': 'Toplardamarlar kalpten organlara kan tasir.', 'w': 'kalpten organlara', 'f': 'organlardan kalbe'}},
      ],
    },
  ];

  // ── DGS (Matematik + Turkce) ──────────────────────────

  static final _dgsUnits = <Map<String, dynamic>>[
    {
      'title': 'DGS Matematik — Sayi Problemleri',
      'topics': [
        {'title': 'Dogal Sayilar ve Islemler', 'pairs': [{'term': 'Bolunebilme', 'definition': 'Bir sayinin baska bir sayiya kalansiz bolunmesi'}, {'term': 'EBOB', 'definition': 'En buyuk ortak bolen'}, {'term': 'EKOK', 'definition': 'En kucuk ortak kat'}, {'term': 'Asal sayi', 'definition': 'Sadece 1 ve kendisine bolunen sayi'}], 'steps': ['Sayilari asal carpanlarina ayir', 'Ortak carpanlari belirle', 'EBOB icin kucuk usluleri carp', 'EKOK icin buyuk usluleri carp'], 'order_q': 'EBOB/EKOK bulma adimlarini sirala', 'fill': {'s': 'En kucuk asal sayi _____ dir.', 'a': '2', 'o': ['2', '0', '1', '3']}, 'quiz': {'q': '12 ve 18 in EBOB u kactir?', 'o': ['6', '3', '12', '36'], 'c': 0}, 'err': {'s': '1 bir asal sayidir.', 'w': 'asal', 'f': 'asal olmayan'}},
        {'title': 'Oran-Oranti', 'pairs': [{'term': 'Oran', 'definition': 'Iki niceliğin bolumu'}, {'term': 'Oranti', 'definition': 'Iki oranin esitligi'}, {'term': 'Doğru oranti', 'definition': 'Biri artarken digeri de artar'}, {'term': 'Ters oranti', 'definition': 'Biri artarken digeri azalir'}], 'fill': {'s': 'Bir isci 5 gunde bitirirse, 2 isci _____ gunde bitirir.', 'a': '2.5', 'o': ['2.5', '10', '3', '7']}, 'quiz': {'q': 'Hiz ile sure arasindaki iliski nedir?', 'o': ['Ters oranti', 'Dogru oranti', 'Oransiz', 'Esit'], 'c': 0}, 'err': {'s': 'Isci sayisi artarsa sure de artar.', 'w': 'artar', 'f': 'azalir'}},
        {'title': 'Yuzde Problemleri', 'pairs': [{'term': '%25', 'definition': '1/4 (dortte bir)'}, {'term': '%50', 'definition': '1/2 (yarim)'}, {'term': '%10', 'definition': 'Onda bir'}, {'term': 'Kar/Zarar', 'definition': 'Satis - Alis farki'}], 'fill': {'s': '200 TL nin %15 i _____ TL dir.', 'a': '30', 'o': ['30', '15', '50', '20']}, 'quiz': {'q': 'Bir urun 100 TL ye alinip 120 TL ye satilirsa kar yuzdesi nedir?', 'o': ['%20', '%12', '%120', '%80'], 'c': 0}, 'err': {'s': 'Kar yuzdesi satis fiyati uzerinden hesaplanir.', 'w': 'satis', 'f': 'alis'}},
        {'title': 'Denklem Cozme', 'pairs': [{'term': 'Bilinmeyen', 'definition': 'Degeri aranan degisken (x)'}, {'term': '1. derece', 'definition': 'ax + b = 0 seklindeki denklem'}, {'term': 'Cozum', 'definition': 'Denklemi saglayan deger'}, {'term': 'Esitsizlik', 'definition': 'Iki ifade arasindaki buyukluk iliskisi'}], 'fill': {'s': '3x + 6 = 15 denkleminde x = _____ dir.', 'a': '3', 'o': ['3', '5', '9', '7']}, 'quiz': {'q': '2(x-1) = 8 denkleminde x kactir?', 'o': ['5', '4', '3', '6'], 'c': 0}, 'err': {'s': 'Denklemde bir tarafa gecerken isaret degismez.', 'w': 'degismez', 'f': 'degisir'}},
        {'title': 'Problem Turleri', 'pairs': [{'term': 'Isci problemi', 'definition': 'Toplam is = hiz x sure'}, {'term': 'Hareket problemi', 'definition': 'Yol = Hiz x Zaman'}, {'term': 'Havuz problemi', 'definition': 'Doldurma/bosaltma hizi problemi'}, {'term': 'Yas problemi', 'definition': 'Yas farki sabit kalir'}], 'fill': {'s': 'Saatte 60 km hizla 3 saat gidilirse yol _____ km dir.', 'a': '180', 'o': ['180', '20', '63', '120']}, 'quiz': {'q': 'Ali 12 yasinda, babasi 36 yasinda. Yas farki kactir?', 'o': ['24', '48', '12', '36'], 'c': 0}, 'err': {'s': 'Yas farki zamanla degisir.', 'w': 'degisir', 'f': 'ayni kalir'}},
        {'title': 'Kume Problemleri', 'pairs': [{'term': 'Birlesim', 'definition': 'A veya B nin elemanlari'}, {'term': 'Kesisim', 'definition': 'A ve B nin ortak elemanlari'}, {'term': 'Fark', 'definition': 'A da olup B de olmayan'}, {'term': 'Tum eleman', 'definition': 'n(AUB) = n(A)+n(B)-n(AnB)'}], 'fill': {'s': '30 kisiden 20 si futbol, 15 i basketbol seviyor, 10 u her ikisini seviyorsa toplam _____ kisi en az birini sever.', 'a': '25', 'o': ['25', '30', '45', '35']}, 'quiz': {'q': 'Kesisim kumesi ne gosterir?', 'o': ['Ortak elemanlari', 'Tum elemanlari', 'Fark elemanlari', 'Bos kumeyi'], 'c': 0}, 'err': {'s': 'Birlesim kumesi iki kumenin sadece ortak elemanlarindan olusur.', 'w': 'ortak', 'f': 'tum'}},
      ],
    },
    {
      'title': 'DGS Turkce — Soz Bilgisi',
      'topics': [
        {'title': 'Es Anlamli Kelimeler', 'pairs': [{'term': 'Yoksul', 'definition': 'Fakir'}, {'term': 'Sakin', 'definition': 'Durgun'}, {'term': 'Cesur', 'definition': 'Yigit'}, {'term': 'Hizli', 'definition': 'Seri'}], 'fill': {'s': '"Genis" kelimesinin es anlamlisi _____ dir.', 'a': 'ferah', 'o': ['ferah', 'dar', 'uzun', 'kisa']}, 'quiz': {'q': '"Ozlem" kelimesinin es anlamlisi hangisidir?', 'o': ['Hasret', 'Sevinc', 'Keder', 'Ofke'], 'c': 0}, 'err': {'s': '"Buyuk" ve "kucuk" es anlamlidir.', 'w': 'es anlamlidir', 'f': 'zit anlamlidir'}},
        {'title': 'Zit Anlamli Kelimeler', 'pairs': [{'term': 'Sicak', 'definition': 'Soguk'}, {'term': 'Guzel', 'definition': 'Cirkin'}, {'term': 'Hizli', 'definition': 'Yavas'}, {'term': 'Uzun', 'definition': 'Kisa'}], 'fill': {'s': '"Karanlik" kelimesinin zit anlamlisi _____ dir.', 'a': 'aydinlik', 'o': ['aydinlik', 'koyuluk', 'gece', 'sisli']}, 'quiz': {'q': '"Genis" in zit anlamlisi hangisidir?', 'o': ['Dar', 'Buyuk', 'Ferah', 'Uzun'], 'c': 0}, 'err': {'s': '"Mutlu" ve "mesut" zit anlamlidir.', 'w': 'zit', 'f': 'es'}},
        {'title': 'Deyimler', 'pairs': [{'term': 'Goz boyamak', 'definition': 'Gercegi saklamak, aldatmak'}, {'term': 'El ustunde tutmak', 'definition': 'Cok deger vermek'}, {'term': 'Agzinda bakla islanmamak', 'definition': 'Sir saklayamamak'}, {'term': 'Burnundan kil aldirmamak', 'definition': 'Cok kibirli olmak'}], 'fill': {'s': '"Cok sevinmekten ucarcasina olmak" anlamina gelen deyim _____ dir.', 'a': 'havaya girmek', 'o': ['havaya girmek', 'goz boyamak', 'yere basmak', 'ayagi yere degmemek']}, 'quiz': {'q': '"Kulak misafiri olmak" ne demektir?', 'o': ['Baskalarinin konusmasini isitmek', 'Cok iyi duymak', 'Ses cikarmamak', 'Dinlememek'], 'c': 0}, 'err': {'s': '"Goz boyamak" gozleri guzellesirmek demektir.', 'w': 'guzellesirmek', 'f': 'aldatmak/kandirmak'}},
        {'title': 'Cumle Turleri', 'pairs': [{'term': 'Olumlu', 'definition': 'Eylemin yapildigini bildirir'}, {'term': 'Olumsuz', 'definition': 'Eylemin yapilmadigini bildirir'}, {'term': 'Soru', 'definition': 'Soru eki icerir'}, {'term': 'Sart', 'definition': '-se/-sa eki icerir'}], 'fill': {'s': '"Hava guzel olursa piknik yapariz" cumlesinde sart eki _____ dir.', 'a': '-sa/-se', 'o': ['-sa/-se', '-di/-di', '-mis/-mus', '-r/-ir']}, 'quiz': {'q': '"Dun okula gitmedim" cumlesi hangi turdedir?', 'o': ['Olumsuz', 'Olumlu', 'Soru', 'Sart'], 'c': 0}, 'err': {'s': 'Soru cumleleri her zaman soru isareti ile biter.', 'w': 'her zaman', 'f': 'genellikle ama icerik olarak da soru olabilir'}},
        {'title': 'Paragraf Analizi', 'pairs': [{'term': 'Ana dusunce', 'definition': 'Paragrafin temel mesaji'}, {'term': 'Yardimci dusunce', 'definition': 'Ana dusunceyi destekleyen fikirler'}, {'term': 'Konu', 'definition': 'Paragrafin ne hakkinda oldugu'}, {'term': 'Baslik', 'definition': 'Konuyu en iyi ozetleyen ifade'}], 'fill': {'s': 'Paragrafta yazar en cok _____ vurgulamak ister.', 'a': 'ana dusunceyi', 'o': ['ana dusunceyi', 'detaylari', 'ornekleri', 'tarihleri']}, 'quiz': {'q': 'Paragrafin konusu nasil bulunur?', 'o': ['Ne hakkinda oldugu sorulur', 'Son cumleye bakilir', 'Sayilar incelenir', 'Baslik okunur'], 'c': 0}, 'err': {'s': 'Ana dusunce her zaman ilk cumlede yer alir.', 'w': 'her zaman', 'f': 'her yerde olabilir'}},
        {'title': 'Anlatim Bozukluklari', 'pairs': [{'term': 'Gereksiz kelime', 'definition': 'Anlami tekrar eden fazla soz'}, {'term': 'Ozne-yuklem uyumsuzlugu', 'definition': 'Kisi/sayi uyusmazligi'}, {'term': 'Mantik hatasi', 'definition': 'Anlam bakimindan celiskili ifade'}, {'term': 'Anlam belirsizligi', 'definition': 'Birden fazla anlama gelen cumle'}], 'fill': {'s': '"Karsiliksiz bos yere ugrastim" cumlesindeki hata _____ dir.', 'a': 'gereksiz kelime', 'o': ['gereksiz kelime', 'devrik cumle', 'kisa cumle', 'ed-at hatasi']}, 'quiz': {'q': '"Ben ve arkadaslarim okula gittiler" cumlesindeki hata nedir?', 'o': ['Yuklem kisi uyumsuzlugu', 'Gereksiz kelime', 'Mantik hatasi', 'Hata yok'], 'c': 0}, 'err': {'s': '"Herkes kendi gorevlerini yapsin" cumlesi doğrudur.', 'w': 'gorevlerini', 'f': 'gorevini (tekil olmali)'}},
      ],
    },
  ];

  // ── TARIH ──────────────────────────────────────────

  static final _tarihUnits = <Map<String, dynamic>>[
    {
      'title': 'Tarih — Ilk Caglar ve Uygarliklar',
      'topics': [
        {'title': 'Tarih Oncesi Donemler', 'pairs': [{'term': 'Paleolitik', 'definition': 'Eski Tas Devri (avcilik-toplayicilik)'}, {'term': 'Neolitik', 'definition': 'Yeni Tas Devri (tarimci yerleskici)'}, {'term': 'Kalkolitik', 'definition': 'Bakir-Tas Devri (maden kullanimi)'}, {'term': 'Demir Cagi', 'definition': 'Demiris isleminin basladigi donem'}], 'steps': ['Paleolitik (Eski Tas)', 'Mezolitik (Orta Tas)', 'Neolitik (Yeni Tas)', 'Kalkolitik (Bakir Cagi)'], 'order_q': 'Tarih oncesi donemleri kronolojik sirala', 'fill': {'s': 'Insanlarin yerleskik hayata gectigi donem _____ dir.', 'a': 'Neolitik', 'o': ['Neolitik', 'Paleolitik', 'Demir Cagi', 'Kalkolitik']}, 'quiz': {'q': 'Ilk yazili belge hangi uygarliga aittir?', 'o': ['Sumerler', 'Misir', 'Roma', 'Yunan'], 'c': 0}, 'err': {'s': 'Paleolitik donemde insanlar tarimla ugrasirdi.', 'w': 'tarimla', 'f': 'avcilik-toplayicilikla'}},
        {'title': 'Ilk Uygarliklar', 'pairs': [{'term': 'Sumer', 'definition': 'Yazıyı icat eden uygarlik'}, {'term': 'Misir', 'definition': 'Nil Nehri kenarinda kurulan'}, {'term': 'Hitit', 'definition': 'Anadoluda kurulan ilk buyuk devlet'}, {'term': 'Lidya', 'definition': 'Parayi icat eden uygarlik'}], 'fill': {'s': 'Tarihteki ilk yazili kanun olan Ur-Nammu Kanunlarini _____ yapti.', 'a': 'Sumerler', 'o': ['Sumerler', 'Romalılar', 'Hititler', 'Persliler']}, 'quiz': {'q': 'Anadolunun ilk buyuk devleti hangisidir?', 'o': ['Hititler', 'Lidyalilar', 'Urartular', 'Frigyalilar'], 'c': 0}, 'err': {'s': 'Parayi Romalılar icat etmistir.', 'w': 'Romalılar', 'f': 'Lidyalilar'}},
        {'title': 'Islam Oncesi Turk Devletleri', 'pairs': [{'term': 'Hun Devleti', 'definition': 'Bilinen ilk Turk devleti (Teoman)'}, {'term': 'Gokturk', 'definition': 'Turk adini kullanan ilk devlet'}, {'term': 'Uygur', 'definition': 'Yerleskik hayata gecen ilk Turk toplulugu'}, {'term': 'Mete Han', 'definition': 'Buyuk Hun Devletinin kurucusu'}], 'fill': {'s': 'Turk tarihinde bilinen ilk devlet _____ dir.', 'a': 'Buyuk Hun Devleti', 'o': ['Buyuk Hun Devleti', 'Gokturk', 'Uygur', 'Selcuklu']}, 'quiz': {'q': '"Turk" adini resmi olarak kullanan ilk devlet hangisidir?', 'o': ['Gokturk Devleti', 'Hun Devleti', 'Uygur Devleti', 'Osmanli'], 'c': 0}, 'err': {'s': 'Uygarlar gocebe bir yasam surmuslurdir.', 'w': 'gocebe', 'f': 'yerleskik'}},
        {'title': 'Osmanli Kurulusu', 'pairs': [{'term': 'Osman Gazi', 'definition': 'Osmanli Devletinin kurucusu'}, {'term': '1299', 'definition': 'Osmanli Devletinin kurulus yili'}, {'term': 'Bursa', 'definition': 'Osmanlinin ilk baskenti'}, {'term': 'Orhan Gazi', 'definition': 'Ilk Osmanli padisahi'}], 'fill': {'s': 'Osmanli Devleti _____ yilinda kurulmustur.', 'a': '1299', 'o': ['1299', '1453', '1071', '1923']}, 'quiz': {'q': 'Osmanlinin ilk baskenti neresidir?', 'o': ['Bursa', 'Istanbul', 'Edirne', 'Sogut'], 'c': 0}, 'err': {'s': 'Osmanli Devletinin ilk baskenti Istanbuldur.', 'w': 'Istanbul', 'f': 'Bursa'}},
        {'title': 'Istanbulun Fethi', 'pairs': [{'term': '1453', 'definition': 'Istanbulun fetih yili'}, {'term': 'Fatih Sultan Mehmet', 'definition': 'Istanbulu fetheden padisah'}, {'term': 'Ortacag sonu', 'definition': 'Fetihle sona eren cag'}, {'term': 'Yeni Cag', 'definition': 'Fetihle baslayan donem'}], 'fill': {'s': 'Istanbul _____ yilinda fethedilmistir.', 'a': '1453', 'o': ['1453', '1299', '1071', '1923']}, 'quiz': {'q': 'Istanbul fethi hangi cagi baslatmistir?', 'o': ['Yeni Cag', 'Yakin Cag', 'Ortacag', 'Ilkcag'], 'c': 0}, 'err': {'s': 'Istanbulun fethi Ilkcagi baslatmistir.', 'w': 'Ilkcagi', 'f': 'Yeni Cagi'}},
        {'title': 'Ataturk ve Cumhuriyet', 'pairs': [{'term': '1923', 'definition': 'Cumhuriyetin ilan yili'}, {'term': 'Ankara', 'definition': 'Cumhuriyet baskenti'}, {'term': 'TBMM', 'definition': '1920 de acilan meclis'}, {'term': 'Lozanx', 'definition': 'Bagimsizligi taniyan antlasma'}], 'fill': {'s': 'Turkiye Cumhuriyeti _____ Ekim 1923 te ilan edildi.', 'a': '29', 'o': ['29', '23', '30', '19']}, 'quiz': {'q': 'TBMM hangi yil acilmistir?', 'o': ['1920', '1919', '1923', '1922'], 'c': 0}, 'err': {'s': 'Cumhuriyet Istanbul da ilan edilmistir.', 'w': 'Istanbul', 'f': 'Ankara'}},
      ],
    },
  ];

  // ── EKONOMI ──────────────────────────────────────────

  static final _econUnits = <Map<String, dynamic>>[
    {
      'title': 'Ekonomi Temelleri',
      'topics': [
        {'title': 'Arz ve Talep', 'pairs': [{'term': 'Arz', 'definition': 'Uretici tarafindan sunulan miktar'}, {'term': 'Talep', 'definition': 'Tuketici tarafindan istenen miktar'}, {'term': 'Denge fiyat', 'definition': 'Arz ve talebin esitlendi̇gi fiyat'}, {'term': 'Kıtlik', 'definition': 'Kaynaklarin ihtiyactan az olmasi'}], 'fill': {'s': 'Bir urunun fiyati artarsa talebi _____.', 'a': 'azalir', 'o': ['azalir', 'artar', 'degismez', 'sifirlanir']}, 'quiz': {'q': 'Arz artarsa fiyat ne olur?', 'o': ['Duser', 'Artar', 'Degismez', 'Ikiye katlanir'], 'c': 0}, 'err': {'s': 'Fiyat artarsa talep artar.', 'w': 'artar', 'f': 'azalir'}},
        {'title': 'Para ve Enflasyon', 'pairs': [{'term': 'Enflasyon', 'definition': 'Genel fiyat duzeyinin artmasi'}, {'term': 'Deflasyon', 'definition': 'Genel fiyat duzeyinin dusmesi'}, {'term': 'Faiz', 'definition': 'Paranin kullanma bedeli'}, {'term': 'TCMB', 'definition': 'Turkiye Cumhuriyet Merkez Bankasi'}], 'fill': {'s': 'Fiyatlarin genel olarak artmasina _____ denir.', 'a': 'enflasyon', 'o': ['enflasyon', 'deflasyon', 'devaluasyon', 'revaluas']}, 'quiz': {'q': 'Merkez bankasi faiz artirirsa ne olur?', 'o': ['Tuketim azalir', 'Tuketim artar', 'Hicbir etkisi olmaz', 'Ihracat duser'], 'c': 0}, 'err': {'s': 'Enflasyon paranin deger kazanmasidir.', 'w': 'kazanmasi', 'f': 'kaybetmesi'}},
        {'title': 'GSYH ve Buyume', 'pairs': [{'term': 'GSYH', 'definition': 'Bir ulkede uretilen tum mal/hizmet degeri'}, {'term': 'Buyume', 'definition': 'GSYH nin artis orani'}, {'term': 'Kisi basi gelir', 'definition': 'GSYH / nufus'}, {'term': 'Resesyon', 'definition': 'Ust uste iki ceyrek daralma'}], 'fill': {'s': 'Ulke ekonomisinin buyuklugu _____ ile olculur.', 'a': 'GSYH', 'o': ['GSYH', 'Enflasyon', 'Issizlik', 'Faiz']}, 'quiz': {'q': 'Resesyon ne demektir?', 'o': ['Ekonomik daralma', 'Hizli buyume', 'Yuksek enflasyon', 'Doviz artisi'], 'c': 0}, 'err': {'s': 'GSYH sadece tarim uretimini olcer.', 'w': 'tarim', 'f': 'tum sektorlerin'}},
        {'title': 'Vergi Cesitleri', 'pairs': [{'term': 'KDV', 'definition': 'Katma deger vergisi (tuketim)'}, {'term': 'Gelir vergisi', 'definition': 'Kazanc uzerinden alinan vergi'}, {'term': 'Kurumlar vergisi', 'definition': 'Sirketlerden alinan vergi'}, {'term': 'OTV', 'definition': 'Ozel tuketim vergisi'}], 'fill': {'s': 'Satilan her urun uzerinden alinan vergiye _____ denir.', 'a': 'KDV', 'o': ['KDV', 'OTV', 'MTV', 'Gelir vergisi']}, 'quiz': {'q': 'Dolayni vergi nedir?', 'o': ['Fiyata eklenen vergi (KDV)', 'Maas uzerinden kesilen', 'Miras vergisi', 'Emlak vergisi'], 'c': 0}, 'err': {'s': 'KDV sadece lüks urunlere uygulanir.', 'w': 'lüks', 'f': 'neredeyse tum'}},
        {'title': 'Dis Ticaret', 'pairs': [{'term': 'Ihracat', 'definition': 'Yurt disina mal satmak'}, {'term': 'Ithalat', 'definition': 'Yurt disindan mal almak'}, {'term': 'Dis ticaret acigi', 'definition': 'Ithalat > ihracat farki'}, {'term': 'Doviz kuru', 'definition': 'Bir para biriminin digeri karsisinda degeri'}], 'fill': {'s': 'Yurt disina yapilan mal satisina _____ denir.', 'a': 'ihracat', 'o': ['ihracat', 'ithalat', 'transfer', 'yatirim']}, 'quiz': {'q': 'TL deger kaybederse ihracat ne olur?', 'o': ['Artar (ucuzlar)', 'Azalir', 'Degismez', 'Durur'], 'c': 0}, 'err': {'s': 'Ithalat yurt disina mal satmaktir.', 'w': 'satmak', 'f': 'almak'}},
        {'title': 'Issizlik', 'pairs': [{'term': 'Issizlik orani', 'definition': 'Issiz / isgucü x 100'}, {'term': 'Mevsimsel issizlik', 'definition': 'Mevsime bagli gecici issizlik'}, {'term': 'Yapisal issizlik', 'definition': 'Sektorel degisimden kaynaklanan'}, {'term': 'Isgucue', 'definition': 'Calisan + is arayan toplam kisi'}], 'fill': {'s': 'Is arayan ama bulamayan kisilerin calismak isteyen nufusa oranina _____ denir.', 'a': 'issizlik orani', 'o': ['issizlik orani', 'enflasyon', 'buyume', 'verimlilik']}, 'quiz': {'q': 'Tarim iscilerinin kis aylinda isssiz kalmasi ne tur issizlik?', 'o': ['Mevsimsel', 'Yapisal', 'Devirsel', 'Friksiyonel'], 'c': 0}, 'err': {'s': 'Issizlik oraninda emekliler de sayilir.', 'w': 'sayilir', 'f': 'sayilmaz (isgucunde degillerdir)'}},
      ],
    },
  ];

  // ── SOSYAL BİLİMLER (Psikoloji/Sosyoloji/Felsefe) ──

  static final _socUnits = <Map<String, dynamic>>[
    {
      'title': 'Psikoloji Temelleri',
      'topics': [
        {'title': 'Psikoloji Nedir?', 'pairs': [{'term': 'Psikoloji', 'definition': 'Davranis ve zihinsel surecleri inceler'}, {'term': 'Davranis', 'definition': 'Gozlemlenebilir eylemler'}, {'term': 'Bilis', 'definition': 'Dusunme, algilama, hafiza surecleri'}, {'term': 'Bilinc', 'definition': 'Farkindalik durumu'}], 'fill': {'s': 'Psikoloji _____ ve zihinsel surecleri inceleyen bilim dalidir.', 'a': 'davranis', 'o': ['davranis', 'toplum', 'ekonomi', 'tarih']}, 'quiz': {'q': 'Psikolojinin temel konusu nedir?', 'o': ['Insan davranisi ve zihni', 'Toplumsal yapi', 'Ekonomik sistem', 'Tarihsel olaylar'], 'c': 0}, 'err': {'s': 'Psikoloji sadece ruhsal hastaliklari inceler.', 'w': 'sadece ruhsal hastaliklari', 'f': 'tum davranis ve zihinsel surecleri'}},
        {'title': 'Ogrenme Kuramlari', 'pairs': [{'term': 'Klasik kosullanma', 'definition': 'Pavlov — uyarana tepki baglama'}, {'term': 'Edimsel kosullanma', 'definition': 'Skinner — odul ve ceza'}, {'term': 'Gozlem yoluyla', 'definition': 'Bandura — model alarak ogrenme'}, {'term': 'Bilissel ogrenme', 'definition': 'Icerik ve anlam uzerinden ogrenme'}], 'fill': {'s': 'Pavlov un kopek deneyinde zil sesiyle salya salgilanmasi _____ ornegedir.', 'a': 'klasik kosullanma', 'o': ['klasik kosullanma', 'edimsel', 'gozlem', 'bilissel']}, 'quiz': {'q': 'Odul ve ceza ile ogrenme hangi kuramdir?', 'o': ['Edimsel kosullanma', 'Klasik kosullanma', 'Bilissel', 'Insancil'], 'c': 0}, 'err': {'s': 'Gozlem yoluyla ogrenmeyi Pavlov one surmustur.', 'w': 'Pavlov', 'f': 'Bandura'}},
        {'title': 'Motivasyon', 'pairs': [{'term': 'Ic motivasyon', 'definition': 'Kendi istegi ile yapma'}, {'term': 'Dis motivasyon', 'definition': 'Odul/ceza etkisiyle yapma'}, {'term': 'Maslow', 'definition': 'Ihtiyaclar hiyerarsisi kurami'}, {'term': 'Temel ihtiyaclar', 'definition': 'Yeme, icme, uyuma gibi'}], 'fill': {'s': 'Maslow a gore ilk karsilanmasi gereken ihtiyaclar _____ ihtiyaclaridir.', 'a': 'fizyolojik', 'o': ['fizyolojik', 'sosyal', 'saygi', 'kendini gerceklestirme']}, 'quiz': {'q': 'Bir isi sevdiği icin yapan kisi hangi motivasyona sahiptir?', 'o': ['Ic motivasyon', 'Dis motivasyon', 'Zorunlu motivasyon', 'Motivasyonsuz'], 'c': 0}, 'err': {'s': 'Maslow a gore en ust ihtiyac fizyolojik ihtiyaclardir.', 'w': 'fizyolojik', 'f': 'kendini gerceklestirme'}},
        {'title': 'Duygular', 'pairs': [{'term': 'Temel duygular', 'definition': 'Sevinc, uzuntu, korku, ofke, igrenme, saskinlik'}, {'term': 'Empati', 'definition': 'Baskasinin duygusunu anlama'}, {'term': 'Duygusal zeka', 'definition': 'Duyguları tanima ve yonetme'}, {'term': 'Stres', 'definition': 'Baskiya karsi bedensel/ruhsal tepki'}], 'fill': {'s': 'Baskasinin duygularını anlayabilme becerisine _____ denir.', 'a': 'empati', 'o': ['empati', 'sempati', 'antipati', 'apati']}, 'quiz': {'q': 'Hangisi temel duygulardan biridir?', 'o': ['Korku', 'Hayal kirikligi', 'Nostalji', 'Huzur'], 'c': 0}, 'err': {'s': 'Stres her zaman zararlidir.', 'w': 'her zaman', 'f': 'belirli duzeyde faydali olabilir'}},
        {'title': 'Kisilik Kuramlari', 'pairs': [{'term': 'Freud', 'definition': 'Id, ego, superego modeli'}, {'term': 'Id', 'definition': 'Ilkel arzular ve durtuluer'}, {'term': 'Ego', 'definition': 'Gerceklik ilkesiyle calisan'}, {'term': 'Superego', 'definition': 'Ahlaki kurallar ve vicdan'}], 'fill': {'s': 'Freud un kisilik yapisinda ilkel durtuleri temsil eden _____ dir.', 'a': 'id', 'o': ['id', 'ego', 'superego', 'bilis']}, 'quiz': {'q': 'Ego hangi ilkeyle calisir?', 'o': ['Gerceklik', 'Haz', 'Ahlak', 'Korku'], 'c': 0}, 'err': {'s': 'Superego haz ilkesiyle calisir.', 'w': 'haz', 'f': 'ahlak'}},
        {'title': 'Bellek Turleri', 'pairs': [{'term': 'Kisa sureli', 'definition': '15-30 sn bilgi tutar'}, {'term': 'Uzun sureli', 'definition': 'Kalici bilgi depolama'}, {'term': 'Duyusal bellek', 'definition': 'Anlık duyusal kayit (<1 sn)'}, {'term': 'Islem bellegi', 'definition': 'Bilgiyi aktif olarak isleme'}], 'fill': {'s': 'Bir telefon numarasini birka saniye hatirlamak _____ bellek ornegedir.', 'a': 'kisa sureli', 'o': ['kisa sureli', 'uzun sureli', 'duyusal', 'islemsel']}, 'quiz': {'q': 'Cocukluk anilari hangi bellekte saklanir?', 'o': ['Uzun sureli', 'Kisa sureli', 'Duyusal', 'Islem'], 'c': 0}, 'err': {'s': 'Duyusal bellek bilgiyi dakikalarca saklar.', 'w': 'dakikalarca', 'f': 'bir saniyeden kisa sure'}},
      ],
    },
  ];

  // ── FRANSIZCA ────────────────────────────────────────

  static final _frUnits = <Map<String, dynamic>>[
    {
      'title': 'Fransizca Temel Gramer',
      'topics': [
        {'title': 'Selamlasma', 'pairs': [{'term': 'Bonjour', 'definition': 'Merhaba / Gunaydin'}, {'term': 'Bonsoir', 'definition': 'Iyi aksamlar'}, {'term': 'Au revoir', 'definition': 'Hosca kal'}, {'term': 'Merci', 'definition': 'Tesekkurler'}], 'fill': {'s': 'Fransizca\'da "Hosca kal" demek icin _____ deriz.', 'a': 'Au revoir', 'o': ['Au revoir', 'Bonjour', 'Merci', 'Pardon']}, 'quiz': {'q': '"S\'il vous plait" ne demektir?', 'o': ['Lutfen', 'Tesekkurler', 'Afedersiniz', 'Merhaba'], 'c': 0}, 'err': {'s': '"Bonsoir" gunaydin demektir.', 'w': 'gunaydin', 'f': 'iyi aksamlar'}},
        {'title': 'Artikeller (le/la/les)', 'pairs': [{'term': 'le', 'definition': 'Erkek tekil artikel'}, {'term': 'la', 'definition': 'Disi tekil artikel'}, {'term': 'les', 'definition': 'Cogul artikel'}, {'term': "l'", 'definition': 'Unlu harf oncesi artikel'}], 'fill': {'s': '"Kitap" Fransizca\'da _____ livre olarak soylenir.', 'a': 'le', 'o': ['le', 'la', 'les', 'un']}, 'quiz': {'q': '"la maison" ifadesinde "la" ne gosterir?', 'o': ['Disi cinsiyet', 'Erkek cinsiyet', 'Cogul', 'Belirsiz'], 'c': 0}, 'err': {'s': '"les" artikeli tekil isimler icin kullanilir.', 'w': 'tekil', 'f': 'cogul'}},
        {'title': 'Kisisel Zamirler', 'pairs': [{'term': 'je', 'definition': 'ben'}, {'term': 'tu', 'definition': 'sen'}, {'term': 'il/elle', 'definition': 'o (erkek/kadin)'}, {'term': 'nous', 'definition': 'biz'}], 'fill': {'s': '"Onlar" Fransizca\'da _____ olarak soylenir.', 'a': 'ils/elles', 'o': ['ils/elles', 'nous', 'vous', 'je']}, 'quiz': {'q': '"vous" ne anlama gelir?', 'o': ['siz / sen (resmi)', 'ben', 'biz', 'onlar'], 'c': 0}, 'err': {'s': '"je" zamiri "sen" demektir.', 'w': 'sen', 'f': 'ben'}},
        {'title': 'Etre ve Avoir Fiilleri', 'pairs': [{'term': 'je suis', 'definition': 'ben ...im/yim'}, {'term': 'tu es', 'definition': 'sen ...sin'}, {'term': "j'ai", 'definition': 'benim ...m var'}, {'term': 'il a', 'definition': 'onun ...si var'}], 'fill': {'s': '"Ben mutluyum" Fransizca\'da "Je _____ content" olur.', 'a': 'suis', 'o': ['suis', 'es', 'est', 'ai']}, 'quiz': {'q': '"Nous avons" ne demektir?', 'o': ['Bizim var', 'Biz gidiyoruz', 'Onlar istiyor', 'Siz biliyorsunuz'], 'c': 0}, 'err': {'s': '"tu es" ifadesi "o var" anlamina gelir.', 'w': 'o var', 'f': 'sen ...sin'}},
        {'title': 'Sayilar (1-20)', 'pairs': [{'term': 'un', 'definition': '1'}, {'term': 'cinq', 'definition': '5'}, {'term': 'dix', 'definition': '10'}, {'term': 'vingt', 'definition': '20'}], 'fill': {'s': 'Fransizca\'da 3 sayisi _____ olarak soylenir.', 'a': 'trois', 'o': ['trois', 'tree', 'tri', 'tris']}, 'quiz': {'q': '"sept" kac demektir?', 'o': ['7', '6', '8', '9'], 'c': 0}, 'err': {'s': '"neuf" sayisi 6 demektir.', 'w': '6', 'f': '9'}},
        {'title': 'Gunluk Ifadeler', 'pairs': [{'term': 'Oui / Non', 'definition': 'Evet / Hayir'}, {'term': 'Excusez-moi', 'definition': 'Afedersiniz'}, {'term': 'Je ne comprends pas', 'definition': 'Anlamiyorum'}, {'term': "Je m'appelle...", 'definition': 'Benim adim...'}], 'fill': {'s': '"Anlamiyorum" Fransizca\'da _____ dir.', 'a': 'Je ne comprends pas', 'o': ['Je ne comprends pas', 'Je suis content', 'Merci beaucoup', 'Au revoir']}, 'quiz': {'q': '"Comment allez-vous?" ne sorar?', 'o': ['Nasilsiniz?', 'Kac yasinda?', 'Nerelisiniz?', 'Ne istiyorsunuz?'], 'c': 0}, 'err': {'s': '"Oui" hayir demektir.', 'w': 'hayir', 'f': 'evet'}},
      ],
    },
    {
      'title': 'Fransizca Kelime Hazinesi',
      'topics': [
        {'title': 'Aile Uyeleri', 'pairs': [{'term': 'la mere', 'definition': 'anne'}, {'term': 'le pere', 'definition': 'baba'}, {'term': 'le frere', 'definition': 'erkek kardes'}, {'term': 'la soeur', 'definition': 'kiz kardes'}], 'fill': {'s': '"Buyukbaba" Fransizca\'da _____ dir.', 'a': 'le grand-pere', 'o': ['le grand-pere', 'le pere', 'le frere', 'l\'oncle']}, 'quiz': {'q': '"la tante" ne demektir?', 'o': ['Teyze/Hala', 'Anne', 'Kiz kardes', 'Buyukanne'], 'c': 0}, 'err': {'s': '"le pere" anne demektir.', 'w': 'anne', 'f': 'baba'}},
        {'title': 'Yiyecekler', 'pairs': [{'term': 'le pain', 'definition': 'ekmek'}, {'term': 'le fromage', 'definition': 'peynir'}, {'term': 'la pomme', 'definition': 'elma'}, {'term': "l'eau", 'definition': 'su'}], 'fill': {'s': '"Sut" Fransizca\'da _____ dir.', 'a': 'le lait', 'o': ['le lait', 'le vin', 'le jus', 'le cafe']}, 'quiz': {'q': '"le poulet" ne demektir?', 'o': ['Tavuk', 'Balik', 'Et', 'Sebze'], 'c': 0}, 'err': {'s': '"le fromage" ekmek demektir.', 'w': 'ekmek', 'f': 'peynir'}},
        {'title': 'Renkler', 'pairs': [{'term': 'rouge', 'definition': 'kirmizi'}, {'term': 'bleu', 'definition': 'mavi'}, {'term': 'vert', 'definition': 'yesil'}, {'term': 'jaune', 'definition': 'sari'}], 'fill': {'s': '"Beyaz" Fransizca\'da _____ dir.', 'a': 'blanc', 'o': ['blanc', 'noir', 'gris', 'brun']}, 'quiz': {'q': '"noir" hangi renktir?', 'o': ['Siyah', 'Beyaz', 'Gri', 'Mor'], 'c': 0}, 'err': {'s': '"bleu" rengi kirmizi demektir.', 'w': 'kirmizi', 'f': 'mavi'}},
        {'title': 'Haftanin Gunleri', 'pairs': [{'term': 'lundi', 'definition': 'Pazartesi'}, {'term': 'mercredi', 'definition': 'Carsamba'}, {'term': 'vendredi', 'definition': 'Cuma'}, {'term': 'dimanche', 'definition': 'Pazar'}], 'fill': {'s': '"Cumartesi" Fransizca\'da _____ dir.', 'a': 'samedi', 'o': ['samedi', 'dimanche', 'vendredi', 'jeudi']}, 'quiz': {'q': '"mardi" hangi gundur?', 'o': ['Sali', 'Persembe', 'Pazartesi', 'Cuma'], 'c': 0}, 'err': {'s': '"dimanche" Cumartesi demektir.', 'w': 'Cumartesi', 'f': 'Pazar'}},
        {'title': 'Mekanlar', 'pairs': [{'term': "l'ecole", 'definition': 'okul'}, {'term': 'la maison', 'definition': 'ev'}, {'term': "l'hopital", 'definition': 'hastane'}, {'term': 'le restaurant', 'definition': 'restoran'}], 'fill': {'s': '"Kutuphane" Fransizca\'da _____ dir.', 'a': 'la bibliotheque', 'o': ['la bibliotheque', 'la librairie', 'le musee', 'le cinema']}, 'quiz': {'q': '"la gare" ne demektir?', 'o': ['Tren istasyonu', 'Okul', 'Hastane', 'Park'], 'c': 0}, 'err': {'s': '"la maison" okul demektir.', 'w': 'okul', 'f': 'ev'}},
        {'title': 'Soru Kelimeleri', 'pairs': [{'term': 'Qui?', 'definition': 'Kim?'}, {'term': 'Quoi?', 'definition': 'Ne?'}, {'term': 'Ou?', 'definition': 'Nerede?'}, {'term': 'Quand?', 'definition': 'Ne zaman?'}], 'fill': {'s': '"Nasil?" sorusu Fransizca\'da _____ dir.', 'a': 'Comment?', 'o': ['Comment?', 'Combien?', 'Pourquoi?', 'Ou?']}, 'quiz': {'q': '"Pourquoi?" ne sorar?', 'o': ['Neden?', 'Nerede?', 'Ne zaman?', 'Nasil?'], 'c': 0}, 'err': {'s': '"Ou?" sorusu "ne zaman" anlamina gelir.', 'w': 'ne zaman', 'f': 'nerede'}},
      ],
    },
  ];
}
