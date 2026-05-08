import 'dart:math';

import '../../../core/services/ai_service.dart';

final _rng = Random(DateTime.now().millisecondsSinceEpoch);

class AiPlanGenerator {
  AiPlanGenerator._();

  static const _taskTypes = ['matching', 'order_steps', 'fill_blank', 'tap_select', 'spot_error', 'image_select'];
  static const _langTaskTypes = ['translate_sentence', 'matching', 'fill_blank', 'image_select', 'tap_select', 'speak_word', 'spot_error', 'translate_sentence'];

  static Future<Map<String, dynamic>> generatePlan({
    required String subject,
    required String difficulty,
    required String goal,
    required int dailyMinutes,
  }) async {
    final prompt = _buildPrompt(subject: subject, difficulty: difficulty, goal: goal, dailyMinutes: dailyMinutes);

    try {
      final result = await AiService.generatePlan(prompt);
      final data = result.data;
      if (data.containsKey('units')) {
        final units = data['units'] as List?;
        if (units != null && units.isNotEmpty) {
          _postProcessShuffleOptions(data);

          // AI bir miktar unite üretti — eksikleri fallback ile tamamla
          if (units.length < 10) {
            final fb = fallbackPlan(subject, difficulty);
            final fbUnits = (fb['units'] as List?) ?? [];
            for (int i = units.length; i < 10 && i < fbUnits.length; i++) {
              units.add(fbUnits[i]);
            }
            // ignore: avoid_print
            print('[AiPlanGenerator] AI returned ${units.length - (10 - fbUnits.length)} units, padded to ${units.length} with fallback');
          }
          return data;
        }
      }
      // ignore: avoid_print
      print('[AiPlanGenerator] AI responded but no valid units found. Keys: ${data.keys}');
    } catch (e) {
      // ignore: avoid_print
      print('[AiPlanGenerator] AI plan generation failed: $e — using fallback');
    }

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
3. Her unitede 5 ders. Her dersin OGRETICI, KONUYA OZGU basligi olsun.

=== ICERIK FORMATI ===
Her unitede sunlar olsun:
- 1 cumlede KISA ozet aciklamasi
- 3 anahtar kavram (description icerisinde virgullerle)
- Dersler asagidaki gorev tiplerini CESITLI sekilde kullansin (art arda ayni tip KULLANMA)

=== HER DERSTE 4 ADIM ===
Her dersin task_content icinde "items" dizisi olmali ve 4 FARKLI soru/etkinlik icermeli.
Hepsi AYNI gorev tipinde olacak ama FARKLI kavramlar/sorular/ornekler kullanacak.
4 adimin hepsi o dersin KONUSUYLA ilgili ama farkli acilardan sorsun.

=== GOREV TIPLERI (SADECE BUNLARI KULLAN) ===
A) "matching": task_content = {{"items":[{{"pairs":[{{"term":"T1","definition":"D1"}},{{"term":"T2","definition":"D2"}},{{"term":"T3","definition":"D3"}}]}}, ... 3 tane daha]}}
   - Her item 3 cift icermeli, hepsi FARKLI kavramlar

B) "fill_blank": task_content = {{"items":[{{"sentence":"Cumle _____","answer":"cevap","options":["cevap","y1","y2","y3"]}}, ... 3 tane daha]}}
   - Bosluk cumlede KILIT kavram olsun
   - 4 secenek: 1 dogru + 3 mantikli yanlis

C) "tap_select": task_content = {{"items":[{{"question":"Soru?","options":["A","B","C","D"],"correct_index":2}}, ... 3 tane daha]}}
   - correct_index RASTGELE olmali! (0-3 arasi dagit)

D) "spot_error": task_content = {{"items":[{{"sentence":"Hatali cumle","error_word":"hata","correction":"dogru","choices":["kelime1","kelime2","hata","kelime3"]}}, ... 3 tane daha]}}
   - error_word cumle icinde BIREBIR gecmeli (tek kelime)
   - choices: 4 kelime icermeli (1 hatali + 3 dogru kelime cumlden)

E) "speak_word" (SADECE dil dersleri icin): task_content = {{"items":[{{"native_word":"merhaba","target_word":"hello","lang_code":"en-US"}}, ... 3 tane daha]}}
   - native_word = Turkce anlami, target_word = hedef dilde kelime
   - lang_code: "en-US", "de-DE", "fr-FR", "es-ES" vs.

F) "image_select": task_content = {{"items":[{{"question":"Hangisi X?","images":["🐶","🐱","🐭","🐰"],"labels":["Kopek","Kedi","Fare","Tavsan"],"correct_index":0}}, ... 3 tane daha]}}
   - images SADECE emoji kullan (URL degil)
   - 4 secenek olmali, correct_index dogru emojinin indexi

G) "translate_sentence" (SADECE dil dersleri icin): task_content = {{"items":[{{"source_sentence":"Merhaba, nasilsin?","correct_translation":"Hello, how are you?","word_chips":["Hello,","how","are","you?","is","the","my"],"lang_code":"en-US"}}, ... 3 tane daha]}}
   - source_sentence = Turkce cumle, correct_translation = hedef dilde ceviri
   - word_chips: dogru kelimeleri + 2-3 fazladan yaniltici kelime icermeli (karisik sirada)

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
  /// [difficulty] : 'kolay', 'orta', 'zor'
  static Map<String, dynamic> fallbackPlan(String subject, String difficulty) {
    final db = _getFallbackUnits(subject);
    final isLang = _isLanguageSubject(subject);
    final types = isLang ? _langTaskTypes : _taskTypes;
    final units = <Map<String, dynamic>>[];

    // Her uniteye FARKLI bir topic seti ata
    // Tum topic'leri topla ve unit basina dagit
    final allTopicSets = <List<Map<String, dynamic>>>[];
    for (final unitData in db) {
      final topics = (unitData['topics'] as List).cast<Map<String, dynamic>>();
      allTopicSets.add(topics);
    }

    for (int u = 0; u < 10; u++) {
      final topicSetIdx = u % allTopicSets.length;
      final unitTopics = List<Map<String, dynamic>>.from(allTopicSets[topicSetIdx]);
      final unitTitle = (db[topicSetIdx]['title'] as String?) ?? 'Unite ${u + 1}';

      // Topic sirasini bu unite icin karistir
      final shuffledTopics = List<Map<String, dynamic>>.from(unitTopics)..shuffle(_rng);
      final lessons = <Map<String, dynamic>>[];

      for (int l = 0; l < 8; l++) {
        // Her ders FARKLI bir task type kullansin
        var taskType = types[l % types.length];

        // Uyumsuz task type'lari fallback'le
        if (taskType == 'order_steps' && !unitTopics.any((t) => (t['steps'] as List?)?.isNotEmpty == true)) {
          taskType = 'matching';
        }
        if (taskType == 'translate_sentence' && !unitTopics.any((t) => (t['trans'] as Map?)?.isNotEmpty == true)) {
          taskType = 'fill_blank';
        }
        if (taskType == 'speak_word' && !isLang) taskType = 'tap_select';

        // Bu ders icin kullanilacak topic — her ders farkli topic
        final lessonTopic = shuffledTopics[l % shuffledTopics.length];

        // translate_sentence icin trans verisi olan topic sec
        final topicForTask = (taskType == 'translate_sentence')
            ? (unitTopics.where((t) => (t['trans'] as Map?)?.isNotEmpty == true).toList()..shuffle(_rng)).firstOrNull ?? lessonTopic
            : lessonTopic;

        // Zorluk bazli item sayisi ve cesitlilik
        // kolay: 6 kolay + 2 orta, orta: 3 kolay + 3 orta + 2 zor, zor: 2 orta + 4 zor + 2 cok zor
        final items = <Map<String, dynamic>>[];
        for (int step = 0; step < 7; step++) {
          // Her step farkli bir topic'ten gelsin (rotate)
          final stepTopic = (taskType == 'translate_sentence')
              ? (unitTopics.where((t) => (t['trans'] as Map?)?.isNotEmpty == true).toList())
                  .elementAtOrNull(step % unitTopics.length) ?? topicForTask
              : unitTopics[step % unitTopics.length];
          // variant: unite*100 + ders*10 + step — global unique
          final variant = u * 100 + l * 10 + step;
          items.add(_buildSingleItem(taskType, stepTopic, variant: variant));
        }
        // Son adim: ozet
        items.add(_buildComprehensiveItem(taskType, unitTopics));

        lessons.add({
          'lesson_index': l + 1,
          'title': lessonTopic['title'] as String,
          'description': '$unitTitle - ${lessonTopic['title']}',
          'task_type': taskType,
          'task_content': {'items': items},
          'difficulty': _lessonDifficulty(difficulty, l),
        });
      }

      units.add({
        'unit_index': u + 1,
        'title': '$unitTitle${u >= db.length ? ' (${u ~/ db.length + 1})' : ''}',
        'description': '$subject - $difficulty seviye',
        'lessons': lessons,
      });
    }

    return {'units': units};
  }

  /// Ders sirasina gore zorluk belirle
  static String _lessonDifficulty(String userDiff, int lessonIdx) {
    // kolay kullanici: ilk 5 kolay, son 3 orta
    // orta kullanici: ilk 3 kolay, 3 orta, 2 zor
    // zor kullanici: ilk 2 orta, 4 zor, 2 cok zor
    switch (userDiff.toLowerCase()) {
      case 'kolay':
        return lessonIdx < 5 ? 'kolay' : 'orta';
      case 'orta':
        if (lessonIdx < 3) return 'kolay';
        if (lessonIdx < 6) return 'orta';
        return 'zor';
      case 'zor':
        if (lessonIdx < 2) return 'orta';
        if (lessonIdx < 6) return 'zor';
        return 'cok_zor';
      default:
        return lessonIdx < 4 ? 'kolay' : 'orta';
    }
  }

  /// Tek bir task item olustur (matching, fill_blank vs.)
  /// [variant] farkli dersler icin ayni topic'ten farkli sorular uretmeyi saglar
  static Map<String, dynamic> _buildSingleItem(String type, Map<String, dynamic> t, {int variant = 0}) {
    switch (type) {
      case 'matching':
        final rawPairs = (t['pairs'] as List?)?.cast<Map<String, dynamic>>() ?? [{'term': 'Terim', 'definition': 'Aciklama'}];
        // Parantez icindeki ipuclarini kaldir (3.tekil -s/-es) vs.
        final allPairs = rawPairs.map((p) {
          final def = (p['definition'] as String? ?? '').replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
          return {'term': p['term'] as String? ?? '', 'definition': def};
        }).toList();
        // variant'a gore farkli pair subset'leri dondur
        if (allPairs.length > 2) {
          final shifted = <Map<String, dynamic>>[];
          for (int i = 0; i < allPairs.length; i++) {
            shifted.add(allPairs[(i + variant) % allPairs.length]);
          }
          return {'pairs': shifted};
        }
        return {'pairs': allPairs};
      case 'order_steps':
        List<String>? steps = (t['steps'] as List?)?.cast<String>();
        String instruction = (t['order_q'] as String?) ?? '';
        if (steps == null || steps.isEmpty) {
          // steps yoksa, pairs verisinden siralama olustur
          final pairs = (t['pairs'] as List?)?.cast<Map<String, dynamic>>();
          if (pairs != null && pairs.length >= 3) {
            final titles = pairs.map((p) => '${p['term']}: ${p['definition']}').toList();
            final taken = titles.take(4).toList();
            return {
              'instruction': instruction.isNotEmpty ? instruction : '${t['title']} kavramlarini mantikli siraya koy',
              'steps': taken,
              'correct_order': List.generate(taken.length, (i) => i),
            };
          }
          // Pairs de yoksa quiz verisinden olustur
          final quiz = t['quiz'] as Map<String, dynamic>?;
          final fill = t['fill'] as Map<String, dynamic>?;
          if (quiz != null && fill != null) {
            final items = [
              fill['s']?.toString().replaceAll('_____', fill['a'] ?? '') ?? '',
              quiz['q']?.toString() ?? '',
              'Cevap: ${fill['a'] ?? ''}',
              'Cevap: ${(quiz['o'] as List?)?[(quiz['c'] as int?) ?? 0] ?? ''}',
            ].where((s) => s.isNotEmpty).take(4).toList();
            if (items.length >= 3) {
              return {
                'instruction': '${t['title']} bilgilerini dogru siraya koy',
                'steps': items,
                'correct_order': List.generate(items.length, (i) => i),
              };
            }
          }
          // Hicbir veri yoksa matching'e don
          return _buildSingleItem('matching', t);
        }
        return {
          'instruction': instruction.isEmpty ? 'Dogru siraya koy' : instruction,
          'steps': steps,
          'correct_order': List.generate(steps.length, (i) => i),
        };
      case 'fill_blank':
        // Her zaman fill verisini kullan — variant'a gore farkli topic'lerden
        final f = t['fill'] as Map<String, dynamic>? ?? {};
        final fSentence = f['s'] as String?;
        final fAnswer = f['a'] as String?;
        final fOpts = f['o'] as List?;
        if (fSentence != null && fSentence.contains('_____') && fAnswer != null && fOpts != null) {
          final opts = List<String>.from(fOpts);
          opts.shuffle(_rng);
          return {
            'sentence': fSentence,
            'answer': fAnswer,
            'options': opts,
          };
        }
        // fill verisi yoksa quiz'den coktan secmeli olustur
        final q2 = t['quiz'] as Map<String, dynamic>?;
        if (q2 != null) {
          final qOpts = List<String>.from(q2['o'] ?? []);
          final idx = (q2['c'] as int?) ?? 0;
          if (qOpts.isNotEmpty && idx < qOpts.length) {
            final answer = qOpts[idx];
            final sentence = '${q2['q'] ?? 'Soru'}: _____';
            qOpts.shuffle(_rng);
            return {'sentence': sentence, 'answer': answer, 'options': qOpts};
          }
        }
        return {
          'sentence': '_____ bir kavramdir.',
          'answer': 'cevap',
          'options': ['cevap', 'yanlis1', 'yanlis2', 'yanlis3'],
        };
      case 'tap_select':
        // quiz verisini kullan, variant'a gore farkli topic'lerden
        final q = t['quiz'] as Map<String, dynamic>? ?? {};
        final origOpts = List<String>.from(q['o'] ?? ['Dogru', 'Yanlis A', 'Yanlis B', 'Yanlis C']);
        final origIdx = (q['c'] as int?) ?? 0;
        final correctAnswer = origIdx < origOpts.length ? origOpts[origIdx] : origOpts.first;
        origOpts.shuffle(_rng);
        final newIdx = origOpts.indexOf(correctAnswer);
        return {
          'question': q['q'] ?? 'Hangisi dogrudur?',
          'options': origOpts,
          'correct_index': newIdx,
        };
      case 'spot_error':
        // Her zaman err verisini kullan
        final e = t['err'] as Map<String, dynamic>? ?? {};
        final eSentence = e['s'] as String?;
        if (eSentence != null && eSentence.isNotEmpty) {
          return {
            'sentence': eSentence,
            'error_word': e['w'] ?? 'hata',
            'correction': e['f'] ?? 'dogru',
          };
        }
        return {
          'sentence': 'Bu cumlede bir hata var.',
          'error_word': 'hata',
          'correction': 'dogru',
        };
      case 'image_select':
        final img = t['img'] as Map<String, dynamic>? ?? {};
        final origImages = List<String>.from(img['images'] ?? ['🔵', '🟢', '🟣', '🟠']);
        final origLabels = List<String>.from(img['labels'] ?? ['Secim A', 'Secim B', 'Secim C', 'Secim D']);
        final origIdx = (img['c'] as int?) ?? 0;
        // Shuffle
        final indices = List.generate(origImages.length, (i) => i)..shuffle(_rng);
        final newImages = indices.map((i) => origImages[i]).toList();
        final newLabels = indices.map((i) => origLabels[i]).toList();
        final newIdx = indices.indexOf(origIdx);
        return {
          'question': img['q'] ?? 'Dogru gorseli sec',
          'images': newImages,
          'labels': newLabels,
          'correct_index': newIdx,
        };
      case 'speak_word':
        final pairs = (t['pairs'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        if (pairs.isEmpty) return _buildSingleItem('tap_select', t, variant: variant);
        final p = pairs[variant % pairs.length];
        final trans2 = t['trans'] as Map<String, dynamic>?;
        final lang = (trans2?['lang'] as String?) ?? 'en-US';
        return {
          'native_word': p['definition'] as String? ?? '',
          'target_word': p['term'] as String? ?? '',
          'lang_code': lang,
        };
      case 'translate_sentence':
        // HER ZAMAN trans verisini kullan — tam Ingilizce cumle -> tam Turkce cevap
        final trans = t['trans'] as Map<String, dynamic>? ?? {};
        final source = trans['s'] as String? ?? '';
        final answer = trans['a'] as String? ?? '';
        final chips = List<String>.from(trans['chips'] ?? []);
        final lang = trans['lang'] as String? ?? 'en-US';
        if (source.isEmpty || answer.isEmpty || chips.isEmpty) {
          // trans verisi yoksa bos donme — fill_blank olarak goster
          final f = t['fill'] as Map<String, dynamic>?;
          if (f != null && (f['s'] as String?)?.contains('_____') == true) {
            final opts = List<String>.from(f['o'] ?? []);
            opts.shuffle(_rng);
            return {
              'source_sentence': (f['s'] as String).replaceAll('_____', '______'),
              'correct_translation': f['a'] as String? ?? '',
              'word_chips': opts,
              'lang_code': lang.isNotEmpty ? lang : 'en-US',
              'instruction': 'Boslugu dolduracak kelimeyi sec',
            };
          }
          // Hicbir sey yoksa basit bir eslestirme dondur
          return {'pairs': t['pairs'] ?? []};
        }
        // Variant'a gore chip'lere ekstra yaniltici kelimeler ekle
        final allChips = List<String>.from(chips);
        final distractorSets = [
          ['ama', 'sonra', 'once', 'cunku', 'belki', 'hic', 'zaten', 'bile'],
          ['yine', 'sadece', 'hep', 'asla', 'gerci', 'sanki', 'hala', 'artik'],
          ['tabii', 'iste', 'demek', 'nasil', 'neden', 'oysa', 'kendi', 'gibi'],
        ];
        final dSet = distractorSets[variant % distractorSets.length];
        dSet.shuffle(_rng);
        allChips.addAll(dSet.take(2 + (variant % 2)));
        allChips.shuffle(_rng);
        return {
          'source_sentence': source,
          'correct_translation': answer,
          'word_chips': allChips,
          'lang_code': lang,
          'instruction': trans['q'] as String? ?? 'Asagidaki cumleyi cevir',
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
        // Rastgele bir topic'in img verisini kullan — duzgun bir soru sor
        final imgTopics = allTopics.where((t) {
          final img = t['img'] as Map<String, dynamic>?;
          return img != null && (img['q'] as String?)?.isNotEmpty == true;
        }).toList();
        if (imgTopics.isNotEmpty) {
          final t = imgTopics[_rng.nextInt(imgTopics.length)];
          return _buildSingleItem('image_select', t);
        }
        // img verisi yoksa tap_select'e don
        return _buildComprehensiveItem('tap_select', allTopics);

      case 'translate_sentence':
        // Random topic'ten translate item olustur
        final t = allTopics[_rng.nextInt(allTopics.length)];
        return _buildSingleItem('translate_sentence', t);

      case 'speak_word':
        final t2 = allTopics[_rng.nextInt(allTopics.length)];
        return _buildSingleItem('speak_word', t2);

      default:
        return allTopics.isNotEmpty ? _buildSingleItem('matching', allTopics.first) : {'pairs': []};
    }
  }

  // ── Helpers ─────────────────────────────────────────────

  static bool _isLanguageSubject(String subject) {
    final s = subject.toLowerCase();
    return s.contains('ingilizce') || s.contains('english') || s.contains('alman') ||
           s.contains('german') || s.contains('deutsch') || s.contains('frans') ||
           s.contains('french') || s.contains('japon') || s.contains('japanese') ||
           s.contains('ispanyol') || s.contains('spanish') || s.contains('italyan') ||
           s.contains('italian') || s.contains('kore') || s.contains('korean') ||
           s.contains('cin') || s.contains('chinese') || s.contains('arap') ||
           s.contains('arabic') || s.contains('rus') || s.contains('russian');
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
    // Dil ogretimi
    if (s.contains('japon') || s.contains('japan')) return _jaUnits;
    if (s.contains('ispan') || s.contains('spanish') || s.contains('espanol')) return _esUnits;
    if (s.contains('cinc') || s.contains('mandarin') || s.contains('chinese')) return _zhUnits;
    if (s.contains('kore') || s.contains('korean')) return _koUnits;
    if (s.contains('ital') || s.contains('italian')) return _itUnits;
    if (s.contains('arap') || s.contains('arabic')) return _arUnits;
    if (s.contains('rus') || s.contains('russian')) return _ruUnits;
    // Fallback — genel ogrenme plani (matematik degil!)
    return _genericSubjectUnits(subject);
  }

  static final _swUnits = <Map<String, dynamic>>[
    {
      'title': 'Programlamaya Giris',
      'topics': [
        {'title': 'Degiskenler ve Veri Tipleri', 'pairs': [{'term': 'int', 'definition': 'Tam sayi veri tipi'}, {'term': 'String', 'definition': 'Metin veri tipi'}, {'term': 'bool', 'definition': 'Mantiksal deger (true/false)'}, {'term': 'double', 'definition': 'Ondalikli sayi veri tipi'}], 'steps': ['Degisken tipini belirle', 'Degisken adini yaz', 'Atama operatoru (=) koy', 'Degeri ata'], 'fill': {'s': 'Bir degisken tanimlamak icin once _____ belirtilmelidir.', 'a': 'veri tipi', 'o': ['veri tipi', 'dosya adi', 'sinif adi', 'fonksiyon']}, 'quiz': {'q': 'Hangisi bir veri tipi degildir?', 'o': ['for', 'int', 'String', 'bool'], 'c': 0}, 'err': {'s': 'Degiskenler hafizada gecici veri saklamak icin kullanilmaz.', 'w': 'kullanilmaz', 'f': 'kullanilir'}},
        {'title': 'Kosul Yapilari (if-else)', 'pairs': [{'term': 'if', 'definition': 'Kosul dogru ise calisir'}, {'term': 'else', 'definition': 'Kosul yanlis ise calisir'}, {'term': 'else if', 'definition': 'Ek kosul kontrolu yapar'}], 'steps': ['Kosulu belirle', 'if blogu ile kosulu yaz', 'else if ile alternatif kosullari ekle', 'else ile varsayilan durumu tanimla'], 'order_q': 'if-else yapisi olusturma adimlarini sirala', 'fill': {'s': 'Bir kosul saglandiginda calisan kod blogu _____ ile baslar.', 'a': 'if', 'o': ['if', 'for', 'while', 'class']}, 'quiz': {'q': 'if(x > 10) ifadesinde x=5 ise hangi blok calisir?', 'o': ['else blogu', 'if blogu', 'Hata verir', 'Program durur'], 'c': 0}, 'err': {'s': 'if kosulunda parantez icinde mantiksal ifade yazilmamalidir.', 'w': 'yazilmamalidir', 'f': 'yazilmalidir'}},
        {'title': 'Donguler (for, while)', 'pairs': [{'term': 'for', 'definition': 'Belirli sayida tekrar eden dongu'}, {'term': 'while', 'definition': 'Kosul saglandikca tekrar eden dongu'}, {'term': 'break', 'definition': 'Donguyu sonlandirir'}, {'term': 'continue', 'definition': 'Mevcut adimi atlayip sonrakine gecer'}], 'steps': ['Dongu turunu sec (for/while)', 'Baslangic degerini ata', 'Kosul ifadesini yaz', 'Artis/azalis adimini belirle'], 'order_q': 'Dongu olusturma adimlarini sirala', 'fill': {'s': 'For dongusu _____ kez tekrar edecegini bildigimizde kullanilir.', 'a': 'kac', 'o': ['kac', 'neden', 'nasil', 'nerede']}, 'quiz': {'q': 'for(int i=0; i<5; i++) dongusu kac kez calisir?', 'o': ['5 kez', '4 kez', '6 kez', 'Sonsuz'], 'c': 0}, 'err': {'s': 'While dongusu kosul yanlis oldugu surece calisir.', 'w': 'yanlis', 'f': 'dogru'}},
        {'title': 'Fonksiyonlar', 'pairs': [{'term': 'return', 'definition': 'Fonksiyondan deger dondurur'}, {'term': 'void', 'definition': 'Deger dondurmeyen fonksiyon tipi'}, {'term': 'parametre', 'definition': 'Fonksiyona disaridan verilen deger'}], 'steps': ['Donus tipini belirle (void/int/String)', 'Fonksiyon adini yaz', 'Parametreleri tanimla', 'Fonksiyon govdesini ve return ifadesini yaz'], 'order_q': 'Fonksiyon tanimlama adimlarini sirala', 'fill': {'s': 'Deger dondurmeyen fonksiyonlarin donus tipi _____ olarak belirtilir.', 'a': 'void', 'o': ['void', 'null', 'int', 'empty']}, 'quiz': {'q': 'Bir fonksiyonun amaci nedir?', 'o': ['Kod tekrarini onlemek', 'Hafizayi silmek', 'Programi yavaslatmak', 'Ekrani kapatmak'], 'c': 0}, 'err': {'s': 'Fonksiyonlar kodun tekrar kullanilamaz parcalaridir.', 'w': 'kullanilamaz', 'f': 'kullanilabilir'}},
        {'title': 'Diziler ve Listeler', 'pairs': [{'term': 'index', 'definition': 'Dizi elemaninin sira numarasi'}, {'term': 'length', 'definition': 'Dizideki eleman sayisi'}, {'term': 'add', 'definition': 'Diziye yeni eleman ekler'}], 'steps': ['Dizi tipini belirle', 'Diziyi olustur ve ilk degerleri ver', 'Index ile elemanlara eris', 'Eleman ekle/sil/guncelle'], 'order_q': 'Dizi kullanim adimlarini sirala', 'fill': {'s': 'Dizilerde ilk elemanin index numarasi _____ dir.', 'a': '0', 'o': ['0', '1', '-1', '10']}, 'quiz': {'q': '[10, 20, 30] dizisinde index 1 de ne vardir?', 'o': ['20', '10', '30', 'Hata'], 'c': 0}, 'err': {'s': 'Dizilerde index numarasi 1 den baslar.', 'w': '1', 'f': '0'}},
        {'title': 'Hata Yonetimi (try-catch)', 'pairs': [{'term': 'try', 'definition': 'Hata olusabilecek kodu sarar'}, {'term': 'catch', 'definition': 'Olusan hatayi yakalar'}, {'term': 'finally', 'definition': 'Hata olsa da calisir'}], 'steps': ['Riskli kodu try blogu icine al', 'catch ile hata turunu yakala', 'Hata mesajini kullaniciya goster', 'finally ile temizlik islemlerini yap'], 'order_q': 'Hata yonetimi adimlarini sirala', 'fill': {'s': 'Bir hata olusabilecek kod _____ blogu icine yazilir.', 'a': 'try', 'o': ['try', 'main', 'class', 'for']}, 'quiz': {'q': 'try-catch yapisinda hata olmazsa catch blogu calisir mi?', 'o': ['Hayir', 'Evet', 'Bazen', 'Her zaman'], 'c': 0}, 'err': {'s': 'catch blogu hata olmasa bile her zaman calisir.', 'w': 'her zaman', 'f': 'sadece hata olustugunda'}},
      ],
    },
    {
      'title': 'Nesne Yonelimli Programlama',
      'topics': [
        {'title': 'Siniflar ve Nesneler', 'pairs': [{'term': 'class', 'definition': 'Nesne sablonu / tasarim plani'}, {'term': 'object', 'definition': 'Siniftan olusturulan ornek'}, {'term': 'constructor', 'definition': 'Nesne olusturulurken calisan metod'}], 'steps': ['Sinif adi ve govdesini tanimla', 'Alanlari (fields) ekle', 'Constructor metodu yaz', 'new ile nesne olustur'], 'order_q': 'Siniftan nesne olusturma adimlarini sirala', 'fill': {'s': 'Bir siniftan nesne olusturmak icin _____ anahtar kelimesi kullanilir.', 'a': 'new', 'o': ['new', 'class', 'void', 'static']}, 'quiz': {'q': 'Sinif ile nesne arasindaki iliski nedir?', 'o': ['Sinif sablon, nesne ornektir', 'Ayni seydir', 'Nesne sablondur', 'Iliskileri yoktur'], 'c': 0}, 'err': {'s': 'Bir siniftan sadece bir tane nesne olusturulabilir.', 'w': 'bir tane', 'f': 'birden fazla'}},
        {'title': 'Kalitim (Inheritance)', 'pairs': [{'term': 'extends', 'definition': 'Sinif kalitimi saglar'}, {'term': 'super', 'definition': 'Ust sinifa erisim saglar'}, {'term': 'override', 'definition': 'Ust sinif metodunu yeniden yazar'}], 'steps': ['Ust sinifi (parent) tanimla', 'Alt sinifi extends ile turet', 'super ile ust constructor i cagir', 'Gerekli metodlari override et'], 'order_q': 'Kalitim uygulama adimlarini sirala', 'fill': {'s': 'Alt sinif, ust sinifin ozelliklerini _____ ile devralir.', 'a': 'extends', 'o': ['extends', 'implements', 'import', 'return']}, 'quiz': {'q': 'Kalitimda alt sinif ust sinifin nelerini kullanabilir?', 'o': ['Public metod ve alanlari', 'Sadece constructor', 'Hicbirini', 'Private alanlari'], 'c': 0}, 'err': {'s': 'Kalitimda alt sinif ust siniftan bagimsiz calisir.', 'w': 'bagimsiz', 'f': 'ozelliklerini devralarak'}},
        {'title': 'Kapsulleme', 'pairs': [{'term': 'private', 'definition': 'Sadece sinif icinden erisilebilir'}, {'term': 'public', 'definition': 'Her yerden erisilebilir'}, {'term': 'getter/setter', 'definition': 'Kontrollue erisim saglayan metodlar'}], 'steps': ['Alanlari private yap', 'Getter metodu ile okuma sagla', 'Setter metodu ile kontrollü yazma ekle', 'Disaridan sadece metodlarla erisimi zorla'], 'order_q': 'Kapsulleme uygulama adimlarini sirala', 'fill': {'s': 'Kapsulleme ile sinifin ic detaylari _____ yapilir.', 'a': 'gizli', 'o': ['gizli', 'acik', 'statik', 'sabit']}, 'quiz': {'q': 'Kapsullemenin amaci nedir?', 'o': ['Veriyi korumak', 'Kodu yavaslatmak', 'Sinif silmek', 'Dongu olusturmak'], 'c': 0}, 'err': {'s': 'Private degiskenler sinif disindan dogrudan erisilebilir.', 'w': 'erisilebilir', 'f': 'erisilemez'}},
        {'title': 'Soyutlama (Abstraction)', 'pairs': [{'term': 'abstract', 'definition': 'Dogrudan orneklenemeyen sinif'}, {'term': 'interface', 'definition': 'Metod imzalarini tanimlar'}, {'term': 'implements', 'definition': 'Arayuzu uygular'}], 'steps': ['Abstract sinif veya interface tanimla', 'Metod imzalarini (signature) yaz', 'Concrete sinif ile implements/extends yap', 'Tum soyut metodlari gercekle (implement)'], 'order_q': 'Soyutlama uygulama adimlarini sirala', 'fill': {'s': 'Abstract siniflardan dogrudan _____ olusturulamaz.', 'a': 'nesne', 'o': ['nesne', 'dosya', 'dongu', 'dizi']}, 'quiz': {'q': 'Abstract sinif ne ise yarar?', 'o': ['Ortak yapıyı tanimlar', 'Performans saglar', 'Veri siler', 'Gereksizdir'], 'c': 0}, 'err': {'s': 'Soyut siniflar dogrudan new ile olusturulabilir.', 'w': 'olusturulabilir', 'f': 'olusturulamaz'}},
        {'title': 'Polimorfizm', 'pairs': [{'term': 'Polimorfizm', 'definition': 'Ayni metodun farkli davranmasi'}, {'term': 'Override', 'definition': 'Metodu yeniden tanimlama'}, {'term': 'Overload', 'definition': 'Ayni isimli farkli parametreli metod'}], 'steps': ['Ust sinifta ortak metodu tanimla', 'Alt siniflarda override ile farkli davranis yaz', 'Ust sinif referansi ile alt sinif nesnesini tut', 'Calisma zamaninda dogru metod otomatik cagirilir'], 'order_q': 'Polimorfizm uygulama adimlarini sirala', 'fill': {'s': 'Polimorfizm _____ anlamina gelir.', 'a': 'cok bicimlilik', 'o': ['cok bicimlilik', 'tek tiplilik', 'hiz', 'guvenlik']}, 'quiz': {'q': 'Polimorfizmin avantaji nedir?', 'o': ['Esneklik', 'Kod yavaslar', 'Hafiza artar', 'Hata olusur'], 'c': 0}, 'err': {'s': 'Polimorfizm sadece tek bir davranis sekli sunar.', 'w': 'tek bir', 'f': 'birden fazla'}},
        {'title': 'SOLID Prensipleri', 'pairs': [{'term': 'S - Tek Sorumluluk', 'definition': 'Her sinif tek is yapmali'}, {'term': 'O - Acik/Kapali', 'definition': 'Genislemeye acik, degisime kapali'}, {'term': 'D - Bagimlilik Tersleme', 'definition': 'Soyutlamalara bagimli ol'}], 'steps': ['S: Her sinifa tek sorumluluk ver', 'O: Yeni ozellik icin mevcut kodu degistirme, genislet', 'L: Alt sinif, ust sinifin yerine gecebilmeli', 'D: Somut siniflara degil soyutlamalara baglan'], 'order_q': 'SOLID prensiplerini uygulama onceligi ile sirala', 'fill': {'s': 'SOLID in S harfi _____ prensibini temsil eder.', 'a': 'Tek Sorumluluk', 'o': ['Tek Sorumluluk', 'Guvenlik', 'Hiz', 'Depolama']}, 'quiz': {'q': 'Open/Closed prensibi ne der?', 'o': ['Genislemeye acik, degisime kapali', 'Her sey acik', 'Kod degistirilmemeli', 'Sinif silinmeli'], 'c': 0}, 'err': {'s': 'SOLID prensipleri kodun karmasik olmasini saglar.', 'w': 'karmasik', 'f': 'temiz ve suerdueruelebilir'}},
      ],
    },
  ];

  static final _mathUnits = <Map<String, dynamic>>[
    {
      'title': 'Sayi Sistemleri',
      'topics': [
        {'title': 'Dogal Sayilar', 'pairs': [{'term': 'Dogal sayi', 'definition': '0, 1, 2, 3... seklinde devam eden sayilar'}, {'term': 'Asal sayi', 'definition': 'Sadece 1 ve kendisine bolunebilen sayi'}, {'term': 'Cift sayi', 'definition': '2 ye tam bolunebilen sayilar'}], 'steps': ['Sayiyi yaz', 'Bolenleri sirala (1 den baslayarak)', 'Sadece 1 ve kendisi mi kontrol et', 'Asal ise isaretle, degilse bilesik yaz'], 'order_q': 'Asal sayi kontrol adimlarini sirala', 'fill': {'s': 'En kucuk asal sayi _____ dir.', 'a': '2', 'o': ['2', '0', '1', '3']}, 'quiz': {'q': 'Hangisi asal sayidir?', 'o': ['7', '4', '6', '9'], 'c': 0}, 'err': {'s': '1 bir asal sayidir.', 'w': 'asal', 'f': 'asal olmayan'}},
        {'title': 'Bolunebilme Kurallari', 'pairs': [{'term': '2 ile bolunme', 'definition': 'Son basamagi cift olan sayilar'}, {'term': '3 ile bolunme', 'definition': 'Basamak toplami 3 un kati'}, {'term': '5 ile bolunme', 'definition': 'Son basamagi 0 veya 5'}, {'term': '9 ile bolunme', 'definition': 'Basamak toplami 9 un kati'}], 'steps': ['Sayinin son basamagina bak', '2 ye bolunme: Cift mi?', 'Basamak toplamini hesapla', '3 ve 9 a bolunme icin toplami kontrol et'], 'order_q': 'Bolunebilme kontrol adimlarini sirala', 'fill': {'s': '3 e bolunebilmek icin basamak toplami _____ in kati olmali.', 'a': '3', 'o': ['3', '2', '5', '7']}, 'quiz': {'q': '126 hangi sayilara bolunur?', 'o': ['2, 3, 6, 9', 'Sadece 2', 'Sadece 3', '5 ve 7'], 'c': 0}, 'err': {'s': '15 sayisi 3 e bolunemez.', 'w': 'bolunemez', 'f': 'bolunebilir'}},
        {'title': 'EBOB ve EKOK', 'pairs': [{'term': 'EBOB', 'definition': 'En buyuk ortak bolen'}, {'term': 'EKOK', 'definition': 'En kucuk ortak kat'}, {'term': 'Aralarinda asal', 'definition': 'EBOB degeri 1 olan sayilar'}], 'steps': ['Sayilari asal carpanlarina ayir', 'Ortak carpanlari belirle', 'EBOB: Kucuk usluleri carp', 'EKOK: Buyuk usluleri carp'], 'order_q': 'EBOB/EKOK bulma adimlarini sirala', 'fill': {'s': '12 ve 18 in EBOB degeri _____ dir.', 'a': '6', 'o': ['6', '3', '12', '36']}, 'quiz': {'q': '12 ve 18 in EKOK degeri kactir?', 'o': ['36', '6', '12', '24'], 'c': 0}, 'err': {'s': 'EBOB her zaman EKOK dan buyuktur.', 'w': 'buyuktur', 'f': 'kucuk veya esittir'}},
        {'title': 'Kesirler', 'pairs': [{'term': 'Pay', 'definition': 'Kesirde ust kisim'}, {'term': 'Payda', 'definition': 'Kesirde alt kisim'}, {'term': 'Bilesik kesir', 'definition': 'Payi paydasindan buyuk kesir'}], 'steps': ['Paydalari kontrol et', 'Farkli ise EKOK ile payda esitle', 'Paylari topla/cikar', 'Sonucu sadeslestir'], 'order_q': 'Kesir toplama adimlarini sirala', 'fill': {'s': 'Kesirlerde toplama yapmak icin _____ esitlenir.', 'a': 'paydalar', 'o': ['paydalar', 'paylar', 'sonuclar', 'sayilar']}, 'quiz': {'q': '1/2 + 1/3 sonucu nedir?', 'o': ['5/6', '2/5', '1/6', '2/6'], 'c': 0}, 'err': {'s': 'Carpma icin paydalar esitlenir.', 'w': 'esitlenir', 'f': 'caprazlama carpilir'}},
        {'title': 'Uslu Sayilar', 'pairs': [{'term': 'Taban', 'definition': 'Carpilan sayi'}, {'term': 'Us', 'definition': 'Carpma tekrar sayisi'}, {'term': '2^3=8', 'definition': '2 x 2 x 2 = 8'}], 'steps': ['Tabani belirle', 'Us degerini oku', 'Tabani us kadar kendi ile carp', 'Sonucu yaz'], 'order_q': 'Us hesaplama adimlarini sirala', 'fill': {'s': '5^0 isleminin sonucu _____ dir.', 'a': '1', 'o': ['1', '0', '5', '50']}, 'quiz': {'q': '3^4 kactir?', 'o': ['81', '12', '27', '64'], 'c': 0}, 'err': {'s': 'Sifir uslu her sayi sifira esittir.', 'w': 'sifira', 'f': '1 e'}},
        {'title': 'Kok Alma', 'pairs': [{'term': 'Karekoku', 'definition': 'Kendisi ile carpildiginda o sayiyi veren deger'}, {'term': 'sqrt(9)=3', 'definition': '3x3=9 oldugu icin karekoku 3'}, {'term': 'sqrt(16)=4', 'definition': '4x4=16 oldugu icin karekoku 4'}], 'steps': ['Sayiyi belirle', 'Tam kare olup olmadigini kontrol et', 'Asal carpanlara ayir', 'Ciftleri kok disina cikar'], 'order_q': 'Karekoku hesaplama adimlarini sirala', 'fill': {'s': 'Karekoku 25 in degeri _____ dir.', 'a': '5', 'o': ['5', '25', '12.5', '10']}, 'quiz': {'q': 'Negatif sayilarin karekoku alinabilir mi?', 'o': ['Reel sayilarda alinamaz', 'Her zaman alinir', '0 olur', '1 olur'], 'c': 0}, 'err': {'s': 'Karekoku 4 degeri 8 dir.', 'w': '8', 'f': '2'}},
      ],
    },
  ];

  static final _physUnits = <Map<String, dynamic>>[
    {
      'title': 'Kuvvet ve Hareket',
      'topics': [
        {'title': 'Newton Hareket Yasalari', 'pairs': [{'term': '1. Yasa (Eylemsizlik)', 'definition': 'Cisim kuvvet uygulanmazsa durumunu korur'}, {'term': '2. Yasa (F=m.a)', 'definition': 'Kuvvet = kutle x ivme'}, {'term': '3. Yasa (Etki-Tepki)', 'definition': 'Her etkiye esit ve zit tepki vardir'}], 'steps': ['Cisim uzerindeki kuvvetleri belirle', 'Net kuvveti hesapla', 'F=m.a ile ivmeyi bul', 'Hareket yonunu ve buyuklugunu yorumla'], 'order_q': 'Kuvvet-hareket problemi cozum adimlarini sirala', 'fill': {'s': 'Newton un 2. yasasina gore F = m x _____ dir.', 'a': 'a (ivme)', 'o': ['a (ivme)', 'v (hiz)', 't (zaman)', 's (yol)']}, 'quiz': {'q': '5 kg kutleli cisme 10 N kuvvet uygulanirsa ivme kac m/s²?', 'o': ['2', '50', '0.5', '15'], 'c': 0}, 'err': {'s': 'Newton 3. yasasina gore etki ve tepki esit degildir.', 'w': 'degildir', 'f': 'esittir'}},
        {'title': 'Surtunme Kuvveti', 'pairs': [{'term': 'Statik surtunme', 'definition': 'Hareketten onceki surtunme'}, {'term': 'Kinetik surtunme', 'definition': 'Hareket halindeki surtunme'}, {'term': 'Surtunme katsayisi', 'definition': 'Yuzey puruztulugunu gosteren deger'}], 'steps': ['Normal kuvveti (N) hesapla', 'Surtunme katsayisini (k) belirle', 'Fs = k x N formulunu uygula', 'Surtunme yonunu harekete zit olarak ciz'], 'order_q': 'Surtunme kuvveti hesaplama adimlarini sirala', 'fill': {'s': 'Surtunme kuvveti harekete _____ yonde etki eder.', 'a': 'zit', 'o': ['zit', 'ayni', 'dik', 'paralel']}, 'quiz': {'q': 'Hangisi surtunmeyi azaltir?', 'o': ['Yag surme', 'Agirligi artirma', 'Yuzey puruzlugu', 'Hiz azaltma'], 'c': 0}, 'err': {'s': 'Surtunme kuvveti hareketi kolaylastirir.', 'w': 'kolaylastirir', 'f': 'zorlastirir'}},
        {'title': 'Is ve Enerji', 'pairs': [{'term': 'Is (W)', 'definition': 'Kuvvet x yer degistirme (Joule)'}, {'term': 'Kinetik Enerji', 'definition': '1/2 x m x v²'}, {'term': 'Potansiyel Enerji', 'definition': 'm x g x h'}], 'steps': ['Kuvveti ve yer degistirmeyi belirle', 'W = F x d ile isi hesapla', 'Enerji turunu belirle (kinetik/potansiyel)', 'Enerji korunum ilkesini uygula'], 'order_q': 'Is-enerji problemi cozum adimlarini sirala', 'fill': {'s': 'Kinetik enerji formulu Ek = 1/2 x m x _____ dir.', 'a': 'v²', 'o': ['v²', 'a²', 'g²', 't²']}, 'quiz': {'q': '10 N kuvvetle 5 m yol = kac Joule?', 'o': ['50 J', '2 J', '15 J', '500 J'], 'c': 0}, 'err': {'s': 'Potansiyel enerji cismin hizina baglidir.', 'w': 'hizina', 'f': 'yuksekligine'}},
        {'title': 'Duzgun Dogrusal Hareket', 'pairs': [{'term': 'Hiz', 'definition': 'Birim zamandaki yer degistirme'}, {'term': 'Ivme', 'definition': 'Birim zamandaki hiz degisimi'}, {'term': 'DDH', 'definition': 'Sabit hizla yapilan hareket'}], 'steps': ['Ivmenin sifir oldugunu kontrol et', 'Hiz ve zamani belirle', 'x = v x t formulunu uygula', 'Grafigi ciz (x-t dogrusal, v-t yatay)'], 'order_q': 'DDH problemi cozum adimlarini sirala', 'fill': {'s': 'DDH de ivme _____ dir.', 'a': 'sifir', 'o': ['sifir', 'sabit', 'artarak', 'degisken']}, 'quiz': {'q': '90 km/h ile 2 saat = kac km?', 'o': ['180 km', '45 km', '90 km', '360 km'], 'c': 0}, 'err': {'s': 'DDH de hiz surekli degisir.', 'w': 'degisir', 'f': 'sabittir'}},
        {'title': 'Ivmeli Hareket', 'pairs': [{'term': 'DDIH', 'definition': 'Sabit ivmeyle hizlanan hareket'}, {'term': 'Serbest dusme', 'definition': 'Yercekimi etkisiyle dusme (g≈10m/s²)'}, {'term': 'v=v₀+a.t', 'definition': 'Hiz-zaman baglantisi'}], 'steps': ['Baslangic hizi ve ivmeyi belirle', 'v = v₀ + a.t ile hizi bul', 'x = v₀.t + 1/2.a.t² ile yolu hesapla', 'Sonucu yorumla ve birimi yaz'], 'order_q': 'Ivmeli hareket problemi cozum adimlarini sirala', 'fill': {'s': 'Serbest dusmede ivme yaklasik _____ m/s² dir.', 'a': '10', 'o': ['10', '5', '20', '100']}, 'quiz': {'q': 'Durgundan 5 m/s² ivmeyle 4 s = hiz?', 'o': ['20 m/s', '9 m/s', '1.25 m/s', '40 m/s'], 'c': 0}, 'err': {'s': 'Serbest dusmede hafif cisimler yavas duser.', 'w': 'yavas', 'f': 'ayni hizda'}},
        {'title': 'Momentum', 'pairs': [{'term': 'Momentum', 'definition': 'Kutle x hiz (p=m.v)'}, {'term': 'Itme', 'definition': 'Kuvvet x zaman (I=F.t)'}, {'term': 'Korunum', 'definition': 'Dis kuvvet yoksa toplam momentum sabittir'}], 'steps': ['Cisimlerin kutle ve hizlarini belirle', 'p = m.v ile momentumlari hesapla', 'Carpismadan once toplam momentumu bul', 'Korunum ile carpismadan sonraki hizlari hesapla'], 'order_q': 'Momentum korunum problemi adimlarini sirala', 'fill': {'s': 'Momentum birimi _____ dir.', 'a': 'kg.m/s', 'o': ['kg.m/s', 'N', 'J', 'W']}, 'quiz': {'q': '2 kg, 3 m/s = momentum?', 'o': ['6 kg.m/s', '5 kg.m/s', '1.5 kg.m/s', '8 kg.m/s'], 'c': 0}, 'err': {'s': 'Capismada toplam momentum korunmaz.', 'w': 'korunmaz', 'f': 'korunur'}},
      ],
    },
  ];

  static final _engUnits = <Map<String, dynamic>>[
    {
      'title': 'Basic Grammar',
      'topics': [
        {'title': 'Simple Present Tense', 'pairs': [{'term': 'I play', 'definition': 'Ben oynarim'}, {'term': 'She goes', 'definition': 'O gider'}, {'term': 'They study', 'definition': 'Onlar calisir'}], 'steps': ['Ozneyi belirle', '3. tekil sahis ise fiile -s/-es ekle', 'Olumsuzda do not / does not kullan', 'Soruda Do/Does ile basla'], 'order_q': 'Simple Present cumle kurma adimlarini sirala', 'trans': {'s': 'She goes to school every day.', 'a': 'O her gun okula gider', 'chips': ['O', 'her', 'gun', 'okula', 'gider', 'gelir', 'aksam'], 'lang': 'en-US', 'q': 'Asagidaki cumleyi cevir'}, 'img': {'q': 'Hangisi "school" kelimesi?', 'images': ['🏫', '🏠', '🏥', '🏪'], 'labels': ['Okul', 'Ev', 'Hastane', 'Dukkan'], 'c': 0}, 'fill': {'s': 'She _____ to school every day.', 'a': 'goes', 'o': ['goes', 'go', 'going', 'gone']}, 'quiz': {'q': 'Simple Present ne zaman kullanilir?', 'o': ['Aliskanlik ve gercekler', 'Gecmis', 'Gelecek', 'Suanda olan'], 'c': 0}, 'err': {'s': 'He go to work every morning.', 'w': 'go', 'f': 'goes'}},
        {'title': 'Past Simple Tense', 'pairs': [{'term': 'played', 'definition': 'oynadi'}, {'term': 'went', 'definition': 'gitti'}, {'term': 'studied', 'definition': 'calisti'}], 'steps': ['Fiilin duzenli mi duzensiz mi kontrol et', 'Duzenli ise -ed ekle', 'Duzensiz ise 2. halini kullan', 'Olumsuzda did not + yalin fiil kullan'], 'order_q': 'Past Simple cumle kurma adimlarini sirala', 'trans': {'s': 'I went to the park yesterday.', 'a': 'Dun parka gittim', 'chips': ['Dun', 'parka', 'gittim', 'gidecegim', 'bugun', 'eve'], 'lang': 'en-US', 'q': 'Asagidaki cumleyi cevir'}, 'img': {'q': 'Hangisi "park" gorseli?', 'images': ['🌳', '🏢', '🚗', '📚'], 'labels': ['Park', 'Ofis', 'Araba', 'Kitap'], 'c': 0}, 'fill': {'s': 'I _____ a good book yesterday.', 'a': 'read', 'o': ['read', 'readed', 'reading', 'reads']}, 'quiz': {'q': 'Hangisi duzenli fiildir?', 'o': ['played', 'went', 'saw', 'took'], 'c': 0}, 'err': {'s': 'She goed to the market last week.', 'w': 'goed', 'f': 'went'}},
        {'title': 'Present Continuous', 'pairs': [{'term': 'I am reading', 'definition': 'Okuyorum'}, {'term': 'She is running', 'definition': 'Kosuyor'}, {'term': 'They are eating', 'definition': 'Yiyorlar'}], 'steps': ['Ozneyi belirle', 'am/is/are yardimci fiilini sec', 'Ana fiile -ing ekle', 'Zaman zarfi ekle'], 'order_q': 'Present Continuous cumle kurma adimlarini sirala', 'trans': {'s': 'The children are playing in the garden.', 'a': 'Cocuklar bahcede oynuyor', 'chips': ['Cocuklar', 'bahcede', 'oynuyor', 'uyuyor', 'evde', 'kosuyor'], 'lang': 'en-US', 'q': 'Asagidaki cumleyi cevir'}, 'img': {'q': 'Hangisi "playing" eylemi?', 'images': ['⚽', '😴', '📖', '🍽️'], 'labels': ['Oynamak', 'Uyumak', 'Okumak', 'Yemek'], 'c': 0}, 'fill': {'s': 'They _____ football right now.', 'a': 'are playing', 'o': ['are playing', 'plays', 'played', 'play']}, 'quiz': {'q': 'Present Continuous ne zaman kullanilir?', 'o': ['Su anda olan eylemler', 'Gecmis', 'Aliskanliklar', 'Tahmin'], 'c': 0}, 'err': {'s': 'She is play tennis now.', 'w': 'play', 'f': 'playing'}},
        {'title': 'Articles (a/an/the)', 'pairs': [{'term': 'a book', 'definition': 'bir kitap'}, {'term': 'an egg', 'definition': 'bir yumurta'}, {'term': 'the sun', 'definition': 'gunes'}], 'steps': ['Ismin sayilabilir mi kontrol et', 'Tekil ve belirsiz ise a/an sec', 'Ilk sesin unlu mu unsuz mu belirle', 'Belirli/bilinen ise the kullan'], 'order_q': 'Article secme adimlarini sirala', 'trans': {'s': 'I have an apple and a banana.', 'a': 'Bir elmam ve bir muzum var', 'chips': ['Bir', 'elmam', 've', 'bir', 'muzum', 'var', 'portakal', 'yok'], 'lang': 'en-US', 'q': 'Asagidaki cumleyi cevir'}, 'img': {'q': 'Hangisi "apple"?', 'images': ['🍎', '🍌', '🍇', '🍊'], 'labels': ['Elma', 'Muz', 'Uzum', 'Portakal'], 'c': 0}, 'fill': {'s': 'She is _____ honest person.', 'a': 'an', 'o': ['an', 'a', 'the', '-']}, 'quiz': {'q': 'Hangisi dogrudur?', 'o': ['an apple', 'a apple', 'an car', 'a umbrella'], 'c': 0}, 'err': {'s': 'I saw a elephant at the zoo.', 'w': 'a', 'f': 'an'}},
        {'title': 'Prepositions (in/on/at)', 'pairs': [{'term': 'in the box', 'definition': 'kutunun icinde'}, {'term': 'on the table', 'definition': 'masanin ustunde'}, {'term': 'at home', 'definition': 'evde'}], 'steps': ['Zaman mi yer mi belirle', 'Genis zaman dilimi ise in', 'Belirli gun/tarih ise on', 'Nokta/saat ise at kullan'], 'order_q': 'Preposition secme adimlarini sirala', 'trans': {'s': 'The cat is on the table.', 'a': 'Kedi masanin uzerinde', 'chips': ['Kedi', 'masanin', 'uzerinde', 'altinda', 'Kopek', 'yaninda'], 'lang': 'en-US', 'q': 'Asagidaki cumleyi cevir'}, 'img': {'q': 'Hangisi "cat"?', 'images': ['🐱', '🐶', '🐦', '🐟'], 'labels': ['Kedi', 'Kopek', 'Kus', 'Balik'], 'c': 0}, 'fill': {'s': 'The meeting is _____ Monday.', 'a': 'on', 'o': ['on', 'in', 'at', 'to']}, 'quiz': {'q': 'Hangisi dogrudur?', 'o': ['at 5 o\'clock', 'in 5 o\'clock', 'on 5 o\'clock', 'to 5 o\'clock'], 'c': 0}, 'err': {'s': 'I was born at 1995.', 'w': 'at', 'f': 'in'}},
        {'title': 'Basic Vocabulary', 'pairs': [{'term': 'enormous', 'definition': 'Cok buyuk'}, {'term': 'tiny', 'definition': 'Cok kucuk'}, {'term': 'ancient', 'definition': 'Cok eski'}, {'term': 'modern', 'definition': 'Cagdas, yeni'}], 'steps': ['Kelimeyi oku ve telaffuz et', 'Anlamini ogren', 'Cumle icinde kullan', 'Zit anlamli kelimelerle bagla'], 'order_q': 'Kelime ogrenme adimlarini sirala', 'trans': {'s': 'The weather is beautiful today.', 'a': 'Bugun hava cok guzel', 'chips': ['Bugun', 'hava', 'cok', 'guzel', 'soguk', 'dun', 'kotu'], 'lang': 'en-US', 'q': 'Asagidaki cumleyi cevir'}, 'img': {'q': 'Hangisi "sun"?', 'images': ['☀️', '🌧️', '❄️', '🌈'], 'labels': ['Gunes', 'Yagmur', 'Kar', 'Gokkusagi'], 'c': 0}, 'fill': {'s': 'The opposite of "big" is _____.', 'a': 'small', 'o': ['small', 'tall', 'fast', 'old']}, 'quiz': {'q': '"Delicious" ne demektir?', 'o': ['Lezzetli', 'Tehlikeli', 'Pahali', 'Guzel'], 'c': 0}, 'err': {'s': 'Happy means sad in English.', 'w': 'sad', 'f': 'mutlu'}},
      ],
    },
    {
      'title': 'Everyday English',
      'topics': [
        {'title': 'Daily Routines', 'pairs': [{'term': 'wake up', 'definition': 'uyanmak'}, {'term': 'have breakfast', 'definition': 'kahvalti yapmak'}, {'term': 'go to bed', 'definition': 'yatmak'}], 'steps': ['Sabah rutinini belirle', 'Ogle aktivitelerini sir', 'Aksam rutinini ekle', 'Zaman zarflariyla birlikte yaz'], 'order_q': 'Gunluk rutin adimlarini sirala', 'trans': {'s': 'I wake up at seven every morning.', 'a': 'Her sabah yedide uyaniyorum', 'chips': ['Her', 'sabah', 'yedide', 'uyaniyorum', 'uyuyorum', 'aksam', 'gece'], 'lang': 'en-US', 'q': 'Asagidaki cumleyi cevir'}, 'img': {'q': 'Hangisi "breakfast"?', 'images': ['🍳', '🌙', '📚', '🏃'], 'labels': ['Kahvalti', 'Gece', 'Ders', 'Kosu'], 'c': 0}, 'fill': {'s': 'I always _____ my teeth before bed.', 'a': 'brush', 'o': ['brush', 'wash', 'clean', 'make']}, 'quiz': {'q': '"Get dressed" ne demek?', 'o': ['Giyinmek', 'Soyunmak', 'Uyumak', 'Yemek'], 'c': 0}, 'err': {'s': 'She wake up at 6 every day.', 'w': 'wake', 'f': 'wakes'}},
        {'title': 'Food and Drinks', 'pairs': [{'term': 'bread', 'definition': 'ekmek'}, {'term': 'milk', 'definition': 'sut'}, {'term': 'chicken', 'definition': 'tavuk'}, {'term': 'rice', 'definition': 'pilav'}], 'steps': ['Yiyecek kategorisini belirle', 'Sayilabilir mi sayilamaz mi kontrol et', 'some/any ile kullan', 'Siparis cumlesi olustur'], 'order_q': 'Yemek siparis adimlarini sirala', 'trans': {'s': 'Can I have a glass of water please?', 'a': 'Bir bardak su alabilir miyim lutfen', 'chips': ['Bir', 'bardak', 'su', 'alabilir', 'miyim', 'lutfen', 'cay', 'ver'], 'lang': 'en-US', 'q': 'Asagidaki cumleyi cevir'}, 'img': {'q': 'Hangisi "water"?', 'images': ['💧', '🍕', '🍰', '🥤'], 'labels': ['Su', 'Pizza', 'Pasta', 'Meyve suyu'], 'c': 0}, 'fill': {'s': 'Would you like _____ cup of tea?', 'a': 'a', 'o': ['a', 'an', 'some', 'any']}, 'quiz': {'q': '"I am hungry" ne anlama gelir?', 'o': ['Acim', 'Susuzum', 'Yorgunum', 'Hastayim'], 'c': 0}, 'err': {'s': 'She drink two glass of milk.', 'w': 'glass', 'f': 'glasses'}},
        {'title': 'Family Members', 'pairs': [{'term': 'mother', 'definition': 'anne'}, {'term': 'father', 'definition': 'baba'}, {'term': 'sister', 'definition': 'kiz kardes'}, {'term': 'brother', 'definition': 'erkek kardes'}], 'steps': ['Aile bireyini belirle', 'Possessive kullan', 'Cumle kur', 'Aileden bahset'], 'order_q': 'Aile tanitim cumlesi kurma adimlarini sirala', 'trans': {'s': 'My brother is older than me.', 'a': 'Agabeyim benden buyuk', 'chips': ['Agabeyim', 'benden', 'buyuk', 'kucuk', 'Ablam', 'genc', 'daha'], 'lang': 'en-US', 'q': 'Asagidaki cumleyi cevir'}, 'img': {'q': 'Hangisi "family"?', 'images': ['👨‍👩‍👧‍👦', '🏫', '🚗', '🌳'], 'labels': ['Aile', 'Okul', 'Araba', 'Agac'], 'c': 0}, 'fill': {'s': 'My _____ is my father\'s wife.', 'a': 'mother', 'o': ['mother', 'sister', 'aunt', 'daughter']}, 'quiz': {'q': '"Uncle" ne demek?', 'o': ['Amca/Dayi', 'Kuzen', 'Dede', 'Kardes'], 'c': 0}, 'err': {'s': 'She is my brother.', 'w': 'brother', 'f': 'sister'}},
        {'title': 'Colors and Numbers', 'pairs': [{'term': 'red', 'definition': 'kirmizi'}, {'term': 'blue', 'definition': 'mavi'}, {'term': 'green', 'definition': 'yesil'}, {'term': 'yellow', 'definition': 'sari'}], 'steps': ['Rengi Ingilizce soyle', 'Sayiyi Ingilizce yaz', 'Renk ve sayi birlestir', 'Cumle icinde kullan'], 'order_q': 'Renk ve sayi ogrenme adimlarini sirala', 'trans': {'s': 'There are five red apples on the table.', 'a': 'Masada bes kirmizi elma var', 'chips': ['Masada', 'bes', 'kirmizi', 'elma', 'var', 'mavi', 'uc', 'yok'], 'lang': 'en-US', 'q': 'Asagidaki cumleyi cevir'}, 'img': {'q': 'Hangisi "blue"?', 'images': ['🔵', '🔴', '🟢', '🟡'], 'labels': ['Mavi', 'Kirmizi', 'Yesil', 'Sari'], 'c': 0}, 'fill': {'s': 'The sky is _____ today.', 'a': 'blue', 'o': ['blue', 'red', 'green', 'black']}, 'quiz': {'q': '"Thirteen" kac demek?', 'o': ['13', '30', '3', '33'], 'c': 0}, 'err': {'s': 'I have tree books.', 'w': 'tree', 'f': 'three'}},
        {'title': 'Weather and Seasons', 'pairs': [{'term': 'sunny', 'definition': 'gunesli'}, {'term': 'rainy', 'definition': 'yagmurlu'}, {'term': 'cold', 'definition': 'soguk'}, {'term': 'hot', 'definition': 'sicak'}], 'steps': ['Hava durumunu sor', 'Sicaklik ifadesini ekle', 'Mevsimi belirt', 'Aktivite oner'], 'order_q': 'Hava durumu konusmasi adimlarini sirala', 'trans': {'s': 'It is very cold in winter.', 'a': 'Kista hava cok soguk olur', 'chips': ['Kista', 'hava', 'cok', 'soguk', 'olur', 'sicak', 'yazin', 'guzel'], 'lang': 'en-US', 'q': 'Asagidaki cumleyi cevir'}, 'img': {'q': 'Hangisi "rainy"?', 'images': ['🌧️', '☀️', '❄️', '🌈'], 'labels': ['Yagmurlu', 'Gunesli', 'Karli', 'Gokkusagi'], 'c': 0}, 'fill': {'s': 'It _____ a lot in April.', 'a': 'rains', 'o': ['rains', 'snows', 'shines', 'blows']}, 'quiz': {'q': '"Spring" hangi mevsim?', 'o': ['Ilkbahar', 'Yaz', 'Sonbahar', 'Kis'], 'c': 0}, 'err': {'s': 'It is snow today.', 'w': 'snow', 'f': 'snowing'}},
        {'title': 'Places and Directions', 'pairs': [{'term': 'hospital', 'definition': 'hastane'}, {'term': 'library', 'definition': 'kutuphane'}, {'term': 'turn left', 'definition': 'sola don'}, {'term': 'go straight', 'definition': 'duz git'}], 'steps': ['Gidilecek yeri belirle', 'Yon tarif et', 'Mesafe soyle', 'Tesekkur et'], 'order_q': 'Yol tarif etme adimlarini sirala', 'trans': {'s': 'The hospital is next to the park.', 'a': 'Hastane parkin yaninda', 'chips': ['Hastane', 'parkin', 'yaninda', 'karsisinda', 'Okul', 'uzak', 'yakin'], 'lang': 'en-US', 'q': 'Asagidaki cumleyi cevir'}, 'img': {'q': 'Hangisi "hospital"?', 'images': ['🏥', '🏫', '🏪', '🏠'], 'labels': ['Hastane', 'Okul', 'Market', 'Ev'], 'c': 0}, 'fill': {'s': 'Go _____ and turn right.', 'a': 'straight', 'o': ['straight', 'left', 'back', 'around']}, 'quiz': {'q': '"Between" ne anlama gelir?', 'o': ['Arasinda', 'Yaninda', 'Uzerinde', 'Altinda'], 'c': 0}, 'err': {'s': 'The bank is in front to the school.', 'w': 'to', 'f': 'of'}},
      ],
    },
  ];

  // ── ALMANCA ──────────────────────────────────────────

  static final _deUnits = <Map<String, dynamic>>[
    {
      'title': 'Almanca Temel Gramer',
      'topics': [
        {'title': 'Selamlasma ve Tanisma', 'pairs': [{'term': 'Guten Morgen', 'definition': 'Gunaydin'}, {'term': 'Guten Tag', 'definition': 'Iyi gunler'}, {'term': 'Auf Wiedersehen', 'definition': 'Hosca kal'}, {'term': 'Wie geht es Ihnen?', 'definition': 'Nasilsiniz?'}], 'steps': ['Guten Morgen (sabah)', 'Guten Tag (gun icinde)', 'Guten Abend (aksam)', 'Gute Nacht (gece, vedalasmada)'], 'order_q': 'Almanca selamlamalari gun sirasina gore sirala', 'trans': {'s': 'Guten Morgen, wie geht es Ihnen?', 'a': 'Gunaydin nasilsiniz', 'chips': ['Gunaydin', 'nasilsiniz', 'hosca', 'kal', 'iyi', 'aksamlar'], 'lang': 'de-DE', 'q': 'Cumleyi Turkceye cevir'}, 'img': {'q': 'Hangisi "Guten Morgen" ile ilgili?', 'images': ['☀️', '🌙', '🌧️', '❄️'], 'labels': ['Sabah', 'Gece', 'Yagmur', 'Kis'], 'c': 0}, 'fill': {'s': 'Almanca\'da "Merhaba" demek icin _____ deriz.', 'a': 'Hallo', 'o': ['Hallo', 'Danke', 'Bitte', 'Tschuss']}, 'quiz': {'q': '"Guten Abend" ne demektir?', 'o': ['Iyi aksamlar', 'Gunaydin', 'Hosca kal', 'Tesekkurler'], 'c': 0}, 'err': {'s': 'Guten Morgen iyi aksamlar demektir.', 'w': 'aksamlar', 'f': 'gunler/gunaydin'}},
        {'title': 'Artikeller (der/die/das)', 'pairs': [{'term': 'der', 'definition': 'Erkek cinsiyet artikeli'}, {'term': 'die', 'definition': 'Disi cinsiyet artikeli'}, {'term': 'das', 'definition': 'Nötr cinsiyet artikeli'}, {'term': 'die (cogul)', 'definition': 'Tum cogul isimler'}], 'steps': ['Ismin cinsiyetini belirle (erkek/disi/notr)', 'Tekil ise der/die/das sec', 'Cogul ise die kullan', 'Cumledeki duruma gore (Nominativ/Akkusativ) degistir'], 'order_q': 'Artikel secme adimlarini sirala', 'trans': {'s': 'Der Hund ist sehr freundlich.', 'a': 'Kopek cok sevecen', 'chips': ['Kopek', 'cok', 'sevecen', 'kedi', 'buyuk', 'kucuk'], 'lang': 'de-DE', 'q': 'Cumleyi Turkceye cevir'}, 'img': {'q': 'Hangisi "der Hund"?', 'images': ['🐶', '🐱', '🐦', '🐠'], 'labels': ['Kopek', 'Kedi', 'Kus', 'Balik'], 'c': 0}, 'fill': {'s': 'Almanca\'da her ismin bir _____ vardir.', 'a': 'artikeli', 'o': ['artikeli', 'rengi', 'sayisi', 'harfi']}, 'quiz': {'q': '"der Hund" ifadesinde "der" ne anlama gelir?', 'o': ['Erkek artikel', 'Disi artikel', 'Notr artikel', 'Cogul artikel'], 'c': 0}, 'err': {'s': 'Almanca\'da artikeller onemli degildir.', 'w': 'degildir', 'f': 'cok onemlidir'}},
        {'title': 'Kisisel Zamirler', 'pairs': [{'term': 'ich', 'definition': 'ben'}, {'term': 'du', 'definition': 'sen'}, {'term': 'er/sie/es', 'definition': 'o (erkek/kadin/notr)'}, {'term': 'wir', 'definition': 'biz'}], 'steps': ['ich (ben) - 1. tekil', 'du (sen) - 2. tekil', 'er/sie/es (o) - 3. tekil', 'wir/ihr/sie (biz/siz/onlar) - cogul'], 'order_q': 'Almanca kisisel zamirleri sirala', 'trans': {'s': 'Wir gehen in die Schule.', 'a': 'Biz okula gidiyoruz', 'chips': ['Biz', 'okula', 'gidiyoruz', 'geliyoruz', 'eve', 'sen'], 'lang': 'de-DE', 'q': 'Cumleyi Turkceye cevir'}, 'img': {'q': 'Hangisi "die Schule"?', 'images': ['🏫', '🏠', '🏪', '🏥'], 'labels': ['Okul', 'Ev', 'Market', 'Hastane'], 'c': 0}, 'fill': {'s': 'Almanca\'da "biz" kelimesinin karsiligi _____ dir.', 'a': 'wir', 'o': ['wir', 'ihr', 'sie', 'ich']}, 'quiz': {'q': '"ihr" zamiri ne demektir?', 'o': ['siz', 'ben', 'biz', 'onlar'], 'c': 0}, 'err': {'s': '"ich" zamiri "sen" anlamina gelir.', 'w': 'sen', 'f': 'ben'}},
        {'title': 'sein ve haben Fiilleri', 'pairs': [{'term': 'ich bin', 'definition': 'ben ...im/yim'}, {'term': 'du bist', 'definition': 'sen ...sin'}, {'term': 'ich habe', 'definition': 'benim ...m var'}, {'term': 'er hat', 'definition': 'onun ...si var'}], 'steps': ['Ozneyi belirle (ich/du/er...)', 'Fiili sec (sein veya haben)', 'Fiili ozneye gore cek', 'Cumleyi tamamla'], 'fill': {'s': '"Ben ogrenciyim" cumlesi Almanca\'da "Ich _____ Student" olur.', 'a': 'bin', 'o': ['bin', 'bist', 'ist', 'sind']}, 'quiz': {'q': '"Sie ist Lehrerin" ne demektir?', 'o': ['O (kadin) ogretmendir', 'Sen ogrencisin', 'Biz doktoruz', 'Onlar iscidir'], 'c': 0}, 'err': {'s': '"Du bist" ifadesi "o var" anlamina gelir.', 'w': 'o var', 'f': 'sen ...sin'}},
        {'title': 'Sayilar (1-20)', 'pairs': [{'term': 'eins', 'definition': '1'}, {'term': 'funf', 'definition': '5'}, {'term': 'zehn', 'definition': '10'}, {'term': 'zwanzig', 'definition': '20'}], 'steps': ['eins (1) - drei (3)', 'vier (4) - sechs (6)', 'sieben (7) - neun (9)', 'zehn (10) - zwanzig (20)'], 'order_q': 'Almanca sayilari kucukten buyuge sirala', 'fill': {'s': 'Almanca\'da 3 sayisi _____ olarak soylenir.', 'a': 'drei', 'o': ['drei', 'drai', 'dri', 'tree']}, 'quiz': {'q': '"sieben" kac demektir?', 'o': ['7', '6', '8', '9'], 'c': 0}, 'err': {'s': '"neun" sayisi 6 demektir.', 'w': '6', 'f': '9'}},
        {'title': 'Gunluk Ifadeler', 'pairs': [{'term': 'Danke', 'definition': 'Tesekkurler'}, {'term': 'Bitte', 'definition': 'Lutfen / Rica ederim'}, {'term': 'Entschuldigung', 'definition': 'Afedersiniz'}, {'term': 'Ja / Nein', 'definition': 'Evet / Hayir'}], 'steps': ['Bitte (lutfen) ile istekte bulun', 'Danke (tesekkurler) ile yanit ver', 'Bitte schon (rica ederim) ile karsilik ver', 'Auf Wiedersehen ile vedahas'], 'order_q': 'Almanca kibar konusma sirasini olustur', 'fill': {'s': '"Tesekkur ederim" Almanca\'da _____ dir.', 'a': 'Danke', 'o': ['Danke', 'Bitte', 'Hallo', 'Tschuss']}, 'quiz': {'q': '"Es tut mir leid" ne demektir?', 'o': ['Uzgunum', 'Mutluyum', 'Aciktim', 'Yoruldum'], 'c': 0}, 'err': {'s': '"Bitte" kelimesi "hayir" anlamina gelir.', 'w': 'hayir', 'f': 'lutfen / rica ederim'}},
      ],
    },
    {
      'title': 'Almanca Kelime Hazinesi',
      'topics': [
        {'title': 'Aile Uyeleri', 'pairs': [{'term': 'die Mutter', 'definition': 'anne'}, {'term': 'der Vater', 'definition': 'baba'}, {'term': 'der Bruder', 'definition': 'erkek kardes'}, {'term': 'die Schwester', 'definition': 'kiz kardes'}], 'steps': ['die Grosseltern (buyuk ebeveynler)', 'die Eltern (anne-baba)', 'die Geschwister (kardesler)', 'die Kinder (cocuklar)'], 'order_q': 'Aile uyelerini nesil sirasina gore sirala', 'fill': {'s': '"Buyukanne" Almanca\'da _____ dir.', 'a': 'die Grossmutter', 'o': ['die Grossmutter', 'die Tante', 'die Mutter', 'die Schwester']}, 'quiz': {'q': '"der Onkel" ne demektir?', 'o': ['Amca/dayi', 'Dede', 'Baba', 'Kuzen'], 'c': 0}, 'err': {'s': '"der Vater" anne demektir.', 'w': 'anne', 'f': 'baba'}},
        {'title': 'Yiyecek ve Icecekler', 'pairs': [{'term': 'das Brot', 'definition': 'ekmek'}, {'term': 'die Milch', 'definition': 'sut'}, {'term': 'der Apfel', 'definition': 'elma'}, {'term': 'das Wasser', 'definition': 'su'}], 'steps': ['das Fruhstuck (kahvalti)', 'das Mittagessen (ogle yemegi)', 'der Snack (ara ogun)', 'das Abendessen (aksam yemegi)'], 'order_q': 'Almanca ogunleri gun sirasina gore sirala', 'fill': {'s': 'Almanca\'da "kahve" kelimesi _____ dir.', 'a': 'der Kaffee', 'o': ['der Kaffee', 'der Tee', 'das Bier', 'der Saft']}, 'quiz': {'q': '"die Kartoffel" ne demektir?', 'o': ['Patates', 'Domates', 'Havuc', 'Sogan'], 'c': 0}, 'err': {'s': '"das Wasser" sut anlamina gelir.', 'w': 'sut', 'f': 'su'}},
        {'title': 'Renkler', 'pairs': [{'term': 'rot', 'definition': 'kirmizi'}, {'term': 'blau', 'definition': 'mavi'}, {'term': 'grun', 'definition': 'yesil'}, {'term': 'gelb', 'definition': 'sari'}], 'steps': ['Rengi gor ve tani', 'Almanca karsiligini soyle', 'Artikelle birlikte kullan (das rote Auto)', 'Cumle icinde uygula'], 'order_q': 'Renk kelimesi ogrenme adimlarini sirala', 'fill': {'s': '"Beyaz" Almanca\'da _____ dir.', 'a': 'weiss', 'o': ['weiss', 'schwarz', 'grau', 'braun']}, 'quiz': {'q': '"schwarz" hangi renktir?', 'o': ['Siyah', 'Beyaz', 'Gri', 'Kahverengi'], 'c': 0}, 'err': {'s': '"blau" rengi kirmizi demektir.', 'w': 'kirmizi', 'f': 'mavi'}},
        {'title': 'Haftanin Gunleri', 'pairs': [{'term': 'Montag', 'definition': 'Pazartesi'}, {'term': 'Mittwoch', 'definition': 'Carsamba'}, {'term': 'Freitag', 'definition': 'Cuma'}, {'term': 'Sonntag', 'definition': 'Pazar'}], 'steps': ['Montag (Pazartesi)', 'Dienstag (Sali)', 'Mittwoch (Carsamba)', 'Donnerstag (Persembe)'], 'order_q': 'Almanca haftanin gunlerini sirala', 'fill': {'s': '"Cumartesi" Almanca\'da _____ dir.', 'a': 'Samstag', 'o': ['Samstag', 'Sonntag', 'Freitag', 'Donnerstag']}, 'quiz': {'q': '"Dienstag" hangi gundur?', 'o': ['Sali', 'Persembe', 'Pazartesi', 'Cuma'], 'c': 0}, 'err': {'s': '"Sonntag" Cumartesi demektir.', 'w': 'Cumartesi', 'f': 'Pazar'}},
        {'title': 'Meslekler', 'pairs': [{'term': 'der Arzt', 'definition': 'doktor (erkek)'}, {'term': 'die Lehrerin', 'definition': 'ogretmen (kadin)'}, {'term': 'der Ingenieur', 'definition': 'muhendis'}, {'term': 'der Koch', 'definition': 'asci'}], 'steps': ['Meslegi ogren (der Arzt)', 'Artikelini belirle (der/die)', 'Kadin halini olustur (-in eki: die Arztin)', 'Cumle icinde kullan (Ich bin Arzt)'], 'order_q': 'Meslek kelimesi ogrenme adimlarini sirala', 'fill': {'s': '"Ogrenci" Almanca\'da _____ dir.', 'a': 'der Student', 'o': ['der Student', 'der Lehrer', 'der Arzt', 'der Pilot']}, 'quiz': {'q': '"die Krankenschwester" hangi meslektir?', 'o': ['Hemsire', 'Doktor', 'Eczaci', 'Dis hekimi'], 'c': 0}, 'err': {'s': '"der Koch" muhendis demektir.', 'w': 'muhendis', 'f': 'asci'}},
        {'title': 'Soru Kelimeleri', 'pairs': [{'term': 'Wer?', 'definition': 'Kim?'}, {'term': 'Was?', 'definition': 'Ne?'}, {'term': 'Wo?', 'definition': 'Nerede?'}, {'term': 'Wann?', 'definition': 'Ne zaman?'}], 'steps': ['Soru kelimesini sec (Wer/Was/Wo...)', 'Fiili ikinci siraya koy', 'Ozneyi ucuncu siraya yerlestir', 'Cumleyi soru isareti ile bitir'], 'order_q': 'Almanca soru cumlesi kurma adimlarini sirala', 'fill': {'s': '"Nasil?" sorusu Almanca\'da _____ dir.', 'a': 'Wie?', 'o': ['Wie?', 'Wo?', 'Was?', 'Wer?']}, 'quiz': {'q': '"Warum?" ne sorar?', 'o': ['Neden?', 'Nerede?', 'Ne zaman?', 'Nasil?'], 'c': 0}, 'err': {'s': '"Wo?" sorusu "ne zaman" anlamina gelir.', 'w': 'ne zaman', 'f': 'nerede'}},
      ],
    },
  ];

  // ── KIMYA ───────────────────────────────────────────

  static final _chemUnits = <Map<String, dynamic>>[
    {
      'title': 'Genel Kimya Temelleri',
      'topics': [
        {'title': 'Atom Yapisi', 'pairs': [{'term': 'Proton', 'definition': 'Cekirdekte bulunan (+) yuklu parcacik'}, {'term': 'Notron', 'definition': 'Cekirdekte bulunan yuksuz parcacik'}, {'term': 'Elektron', 'definition': 'Cekirdek etrafinda dolanan (-) yuklu parcacik'}, {'term': 'Cekirdek', 'definition': 'Atomun merkezindeki yogun bolge'}], 'fill': {'s': 'Atomun merkezinde _____ bulunur.', 'a': 'cekirdek', 'o': ['cekirdek', 'elektron', 'orbital', 'kabuk']}, 'quiz': {'q': 'Protonun yuku nedir?', 'o': ['Pozitif (+)', 'Negatif (-)', 'Yuksuz', 'Degisken'], 'c': 0}, 'err': {'s': 'Elektronlar atomun cekirdeginde bulunur.', 'w': 'cekirdeginde', 'f': 'yoerungelerinde'}, 'steps': ['Cekirdegi belirle', 'Proton ve notronlari yerlestir', 'Elektron kabuklarini ciz', 'Elektronlari dagilimina gore yerlestir'], 'order_q': 'Atom modelini adim adim olustur'},
        {'title': 'Periyodik Tablo', 'pairs': [{'term': 'Periyot', 'definition': 'Yatay satirlar (enerji seviyesi)'}, {'term': 'Grup', 'definition': 'Dikey sutunlar (degerlik e-)'}, {'term': 'Metal', 'definition': 'Iletken, parlak elementler'}, {'term': 'Ametal', 'definition': 'Iletken olmayan elementler'}], 'steps': ['Elementin atom numarasini bul', 'Elektron dagilimini yaz', 'Periyodunu belirle (son enerji seviyesi)', 'Grubunu belirle (degerlik elektron sayisi)'], 'order_q': 'Periyodik tabloda element yerini bulma adimlarini sirala', 'fill': {'s': 'Periyodik tabloda ayni gruptaki elementler benzer _____ gosterir.', 'a': 'kimyasal ozellik', 'o': ['kimyasal ozellik', 'kutle', 'renk', 'boyut']}, 'quiz': {'q': 'Periyodik tabloda periyot neyi gosterir?', 'o': ['Enerji seviyesi sayisi', 'Elektron sayisi', 'Notron sayisi', 'Atom agirligi'], 'c': 0}, 'err': {'s': 'Soy gazlar cok reaktif elementlerdir.', 'w': 'reaktif', 'f': 'kararli (tepkimeye girmez)'}},
        {'title': 'Kimyasal Baglar', 'pairs': [{'term': 'Iyonik bag', 'definition': 'Elektron transferi ile olusan bag'}, {'term': 'Kovalent bag', 'definition': 'Elektron paylasimi ile olusan bag'}, {'term': 'Metalik bag', 'definition': 'Serbest elektron denizi modeli'}, {'term': 'H-bagi', 'definition': 'H ile N/O/F arasindaki zayif bag'}], 'steps': ['Atomlarin metal mi ametal mi belirle', 'Metal+Ametal ise iyonik bag', 'Ametal+Ametal ise kovalent bag', 'Metal+Metal ise metalik bag'], 'order_q': 'Kimyasal bag turu belirleme adimlarini sirala', 'fill': {'s': 'NaCl bilesiginde Na ve Cl arasinda _____ bag vardir.', 'a': 'iyonik', 'o': ['iyonik', 'kovalent', 'metalik', 'Van der Waals']}, 'quiz': {'q': 'Kovalent bagda ne olur?', 'o': ['Elektron paylasimi', 'Elektron transferi', 'Proton transferi', 'Notron paylasimi'], 'c': 0}, 'err': {'s': 'Metalik bagda elektronlar sabit konumdadir.', 'w': 'sabit', 'f': 'serbest halde hareket eder'}},
        {'title': 'Mol Kavrami', 'pairs': [{'term': 'Mol', 'definition': '6.02 x 10²³ tane parcacik'}, {'term': 'Avogadro', 'definition': '6.02 x 10²³ sayisi'}, {'term': 'Molar kutle', 'definition': '1 mol maddenin gram cinsinden kutlesi'}, {'term': 'Molalite', 'definition': '1 kg cozucudeki mol sayisi'}], 'steps': ['Maddenin formulunu yaz', 'Atom kutlelerini topla (molar kutle)', 'Gram / molar kutle = mol sayisi', 'Mol x Avogadro = parcacik sayisi'], 'order_q': 'Mol hesaplama adimlarini sirala', 'fill': {'s': '1 mol suda _____ tane molekul vardir.', 'a': '6.02 x 10²³', 'o': ['6.02 x 10²³', '3.14 x 10⁸', '1.6 x 10⁻¹⁹', '9.8 x 10¹']}, 'quiz': {'q': 'H₂O nun molar kutlesi kac g/mol dur?', 'o': ['18', '16', '2', '20'], 'c': 0}, 'err': {'s': 'Avogadro sayisi 6.02 x 10¹⁰ dur.', 'w': '10¹⁰', 'f': '10²³'}},
        {'title': 'Kimyasal Formuller', 'pairs': [{'term': 'H₂O', 'definition': 'Su'}, {'term': 'NaCl', 'definition': 'Sofra tuzu'}, {'term': 'CO₂', 'definition': 'Karbondioksit'}, {'term': 'H₂SO₄', 'definition': 'Sulfurik asit'}], 'steps': ['Elementlerin sembollerini ogren', 'Atom sayilarini alt indis olarak yaz', 'Bilesikteki toplam atom sayisini hesapla', 'Formulu oku ve adini ogren'], 'order_q': 'Kimyasal formul okuma adimlarini sirala', 'fill': {'s': 'Sofra tuzunun kimyasal formulu _____ dir.', 'a': 'NaCl', 'o': ['NaCl', 'KCl', 'NaOH', 'HCl']}, 'quiz': {'q': 'CO₂ hangi bilesiktir?', 'o': ['Karbondioksit', 'Karbonmonoksit', 'Metan', 'Etan'], 'c': 0}, 'err': {'s': 'H₂O formulu karbondioksiti temsil eder.', 'w': 'karbondioksiti', 'f': 'suyu'}},
        {'title': 'Asit ve Bazlar', 'pairs': [{'term': 'Asit', 'definition': 'H⁺ iyonu veren madde'}, {'term': 'Baz', 'definition': 'OH⁻ iyonu veren madde'}, {'term': 'pH', 'definition': 'Cozeltinin asitlik olcusu'}, {'term': 'Notr', 'definition': 'pH degeri 7 olan cozelti'}], 'steps': ['Cozeltiyi hazirla', 'pH kagidi veya olcer ile pH degerini olç', 'pH<7 ise asit, pH=7 ise notr, pH>7 ise baz', 'Asit-baz tepkimesinde tuz + su olusur'], 'order_q': 'Asit-baz tespiti adimlarini sirala', 'fill': {'s': 'pH degeri 7 den kucuk olan cozeltiler _____ dir.', 'a': 'asidik', 'o': ['asidik', 'bazik', 'notr', 'tuzlu']}, 'quiz': {'q': 'Limon suyunun pH degeri yaklasik kactir?', 'o': ['2-3', '7', '10-11', '14'], 'c': 0}, 'err': {'s': 'Bazlar H⁺ iyonu verir.', 'w': 'H⁺', 'f': 'OH⁻'}},
      ],
    },
    {
      'title': 'Kimyasal Tepkimeler',
      'topics': [
        {'title': 'Tepkime Denklemleri', 'pairs': [{'term': 'Girenler', 'definition': 'Tepkimeye giren maddeler (sol taraf)'}, {'term': 'Urunler', 'definition': 'Tepkime sonucu olusan maddeler'}, {'term': 'Denklemek', 'definition': 'Atom sayilarini esitlemek'}, {'term': 'Katsayi', 'definition': 'Formul onundeki sayi'}], 'steps': ['Girenler ve urunleri yaz', 'Her elementin atom sayisini say', 'Katsayilarla atom sayilarini esitle', 'Dengelenmis denklemi kontrol et'], 'order_q': 'Kimyasal denklem dengeleme adimlarini sirala', 'fill': {'s': 'Kimyasal denklemde ok isaretinin solunda _____ bulunur.', 'a': 'girenler', 'o': ['girenler', 'urunler', 'katalizor', 'cozucu']}, 'quiz': {'q': 'Denklem dengelemede ne korunur?', 'o': ['Atom sayisi', 'Molekul sayisi', 'Hacim', 'Sicaklik'], 'c': 0}, 'err': {'s': 'Kimyasal tepkimede atom sayisi degisir.', 'w': 'degisir', 'f': 'korunur'}},
        {'title': 'Tepkime Tipleri', 'pairs': [{'term': 'Sentez', 'definition': 'A + B → AB (birlesme)'}, {'term': 'Analiz', 'definition': 'AB → A + B (ayrisma)'}, {'term': 'Yer degistirme', 'definition': 'AB + C → AC + B'}, {'term': 'Yanma', 'definition': 'Madde + O₂ → CO₂ + H₂O'}], 'steps': ['Girenler ve urunleri incele', 'Madde sayisini karsilastir (birlesme/ayrisma)', 'Elementlerin yer degistirip degistirmedigini kontrol et', 'Tepkime tipini belirle (sentez/analiz/yer degistirme/yanma)'], 'order_q': 'Tepkime tipi belirleme adimlarini sirala', 'fill': {'s': 'Iki maddenin birlesmesiyle yeni madde olusmasina _____ tepkimesi denir.', 'a': 'sentez', 'o': ['sentez', 'analiz', 'yanma', 'cokme']}, 'quiz': {'q': '2H₂ + O₂ → 2H₂O hangi tepkime turudur?', 'o': ['Sentez', 'Analiz', 'Yer degistirme', 'Notrlesme'], 'c': 0}, 'err': {'s': 'Analiz tepkimesinde maddeler birlesir.', 'w': 'birlesir', 'f': 'ayrisir'}},
        {'title': 'Cozeltiler', 'pairs': [{'term': 'Cozucu', 'definition': 'Cozen madde (genelde su)'}, {'term': 'Cozunen', 'definition': 'Cozulen madde'}, {'term': 'Deriik', 'definition': 'Cok cozunen iceren cozelti'}, {'term': 'Seyreltik', 'definition': 'Az cozunen iceren cozelti'}], 'steps': ['Cozucuyu hazirla (genelde su)', 'Cozuneni ekle ve karistir', 'Cozunmenin gerceklestigini gozle', 'Derisimligi hesapla (mol/L)'], 'order_q': 'Cozelti hazirlama adimlarini sirala', 'fill': {'s': 'Tuzlu suda, su _____ dir.', 'a': 'cozucu', 'o': ['cozucu', 'cozunen', 'urun', 'katalizor']}, 'quiz': {'q': 'Derişik çözelti ne demektir?', 'o': ['Cok cozunen iceren', 'Az cozunen iceren', 'Cozucusu fazla olan', 'Soguk cozelti'], 'c': 0}, 'err': {'s': 'Cozucu, cozelti icinde cozunen maddedir.', 'w': 'cozunen', 'f': 'cozen'}},
        {'title': 'Gaz Yasalari', 'pairs': [{'term': 'Boyle', 'definition': 'P₁V₁ = P₂V₂ (sabit T)'}, {'term': 'Charles', 'definition': 'V₁/T₁ = V₂/T₂ (sabit P)'}, {'term': 'Ideal gaz', 'definition': 'PV = nRT'}, {'term': 'Avogadro', 'definition': 'Esit V, esit T → esit mol'}], 'steps': ['Sabit buyuklukleri belirle (T/P/V)', 'Uygun gaz yasasini sec', 'Bilinen degerleri formule yerlestir', 'Bilinmeyeni hesapla'], 'order_q': 'Gaz yasasi problemi cozum adimlarini sirala', 'fill': {'s': 'Ideal gaz denkleminde PV = _____ dir.', 'a': 'nRT', 'o': ['nRT', 'mRT', 'kT', 'PnR']}, 'quiz': {'q': 'Boyle yasasinda sabit tutulan nedir?', 'o': ['Sicaklik', 'Basinc', 'Hacim', 'Mol sayisi'], 'c': 0}, 'err': {'s': 'Charles yasasinda basinc degiskendir.', 'w': 'degiskendir', 'f': 'sabittir'}},
        {'title': 'Oksidasyon-Reduksiyon', 'pairs': [{'term': 'Oksidasyon', 'definition': 'Elektron kaybetme'}, {'term': 'Reduksiyon', 'definition': 'Elektron kazanma'}, {'term': 'Oksitleyici', 'definition': 'Elektron alan madde'}, {'term': 'Indirgen', 'definition': 'Elektron veren madde'}], 'steps': ['Elementlerin yukseltgenme basamaklarini belirle', 'Degisen basamaklari bul', 'Elektron kaybeden = oksitlenir (indirgen)', 'Elektron kazanan = indirgenir (oksitleyici)'], 'order_q': 'Redoks tepkimesi analiz adimlarini sirala', 'fill': {'s': 'Elektron kaybeden madde _____ olur.', 'a': 'oksitlenir', 'o': ['oksitlenir', 'indirgenir', 'notrlesir', 'cozunur']}, 'quiz': {'q': 'Reduksiyon nedir?', 'o': ['Elektron kazanma', 'Elektron kaybetme', 'Proton kazanma', 'Notron kaybetme'], 'c': 0}, 'err': {'s': 'Indirgen madde elektron alir.', 'w': 'alir', 'f': 'verir'}},
        {'title': 'Termokimya', 'pairs': [{'term': 'Ekzotermik', 'definition': 'Isi veren tepkime'}, {'term': 'Endotermik', 'definition': 'Isi alan tepkime'}, {'term': 'Entalpi', 'definition': 'Tepkimenin isi degisimi (ΔH)'}, {'term': 'Katalizor', 'definition': 'Tepkimeyi hizlandiran madde'}], 'steps': ['Tepkimedeki isi degisimini gozle', 'Ortam isiniyorsa ekzotermik (ΔH<0)', 'Ortam soguyorsa endotermik (ΔH>0)', 'Entalpi degerini hesapla'], 'order_q': 'Termokimya analiz adimlarini sirala', 'fill': {'s': 'Yanma tepkimeleri _____ tepkimelerdir.', 'a': 'ekzotermik', 'o': ['ekzotermik', 'endotermik', 'notr', 'tersinir']}, 'quiz': {'q': 'Katalizor tepkimede ne yapar?', 'o': ['Hizlandirir', 'Yavaslatir', 'Durdurur', 'Urun degistirir'], 'c': 0}, 'err': {'s': 'Endotermik tepkimelerde isi aciga cikar.', 'w': 'aciga cikar', 'f': 'absorbe edilir'}},
      ],
    },
  ];

  // ── BIYOLOJI ──────────────────────────────────────────

  static final _bioUnits = <Map<String, dynamic>>[
    {
      'title': 'Hucre Biyolojisi',
      'topics': [
        {'title': 'Hucre Yapisi', 'pairs': [{'term': 'Mitokondri', 'definition': 'Enerji ureten organel'}, {'term': 'Ribozom', 'definition': 'Protein sentezleyen organel'}, {'term': 'Golgi', 'definition': 'Maddeleri paketleyen organel'}, {'term': 'Lizozom', 'definition': 'Sindirim enzimi iceren organel'}], 'fill': {'s': 'Hucrenin enerji santrali _____ dir.', 'a': 'mitokondri', 'o': ['mitokondri', 'ribozom', 'golgi', 'lizozom']}, 'quiz': {'q': 'Protein sentezi nerede gerceklesir?', 'o': ['Ribozom', 'Mitokondri', 'Cekirdek', 'Golgi'], 'c': 0}, 'err': {'s': 'Lizozom enerji uretir.', 'w': 'enerji uretir', 'f': 'sindirim yapar'}, 'steps': ['Hucre zarindan gecis', 'Sitoplazmaya ulasim', 'Organele yonelim', 'Islevin gerceklesmesi'], 'order_q': 'Madde hucre icinde nasil islenir?'},
        {'title': 'DNA ve Genetik', 'pairs': [{'term': 'DNA', 'definition': 'Genetik bilgiyi tasiyan molekul'}, {'term': 'Gen', 'definition': 'Protein kodlayan DNA parcasi'}, {'term': 'Kromozom', 'definition': 'DNA nin yogunlasmis hali'}, {'term': 'RNA', 'definition': 'DNA dan bilgi tasiyan molekul'}], 'steps': ['DNA cift sarmali acilir', 'mRNA sentezlenir (transkripsiyon)', 'mRNA ribozoma gider', 'Protein sentezlenir (translasyon)'], 'order_q': 'Genetik bilgi akisi (santral dogma) adimlarini sirala', 'fill': {'s': 'Genetik bilgi _____ molekulunde saklanir.', 'a': 'DNA', 'o': ['DNA', 'RNA', 'protein', 'lipid']}, 'quiz': {'q': 'Insanda kac cift kromozom vardir?', 'o': ['23', '22', '46', '24'], 'c': 0}, 'err': {'s': 'RNA cift sarmal yapisinddair.', 'w': 'cift', 'f': 'tek'}},
        {'title': 'Fotosentez', 'pairs': [{'term': 'Kloroplast', 'definition': 'Fotosentezin gerceklestigi organel'}, {'term': 'Klorofil', 'definition': 'Isik soguran yesil pigment'}, {'term': 'CO₂', 'definition': 'Fotosentezde kullanilan gaz'}, {'term': 'O₂', 'definition': 'Fotosentezde aciga cikan gaz'}], 'steps': ['Isik klorofil tarafindan emilir', 'Su parcalanir (fotoliz) -> O2 aciga cikar', 'CO2 tutulur (karbon fiksasyonu)', 'Glikoz sentezlenir'], 'order_q': 'Fotosentez asamalarini sirala', 'fill': {'s': 'Fotosentez _____ organelinde gerceklesir.', 'a': 'kloroplast', 'o': ['kloroplast', 'mitokondri', 'ribozom', 'golgi']}, 'quiz': {'q': 'Fotosentezde hammadde nedir?', 'o': ['CO₂ ve H₂O', 'O₂ ve glikoz', 'Protein ve yag', 'ATP ve NADP'], 'c': 0}, 'err': {'s': 'Fotosentezde oksijen tuketilir.', 'w': 'tuketilir', 'f': 'uretilir'}},
        {'title': 'Hucre Bolunmesi', 'pairs': [{'term': 'Mitoz', 'definition': '2 esit hucre olusturan bolunme'}, {'term': 'Mayoz', 'definition': '4 haploid hucre olusturan bolunme'}, {'term': 'Interfaz', 'definition': 'Bolunme oncesi hazirlik evresi'}, {'term': 'Krossing over', 'definition': 'Homolog kromozomlarda gen degisimi'}], 'steps': ['Interfaz: DNA eslesir', 'Profaz: Kromozomlar yogunlasir', 'Metafaz: Kromozomlar ortaya dizilir', 'Anafaz-Telofaz: Ayrilma ve iki hucre olusur'], 'order_q': 'Mitoz bolunme evrelerini sirala', 'fill': {'s': 'Vucut hucrelerinin cogalmasi _____ bolunme ile olur.', 'a': 'mitoz', 'o': ['mitoz', 'mayoz', 'amitoz', 'biner']}, 'quiz': {'q': 'Mayoz bolunme sonucunda kac hucre olusur?', 'o': ['4', '2', '1', '8'], 'c': 0}, 'err': {'s': 'Mitoz bolunmede kromozom sayisi yarilir.', 'w': 'yarilir', 'f': 'ayni kalir'}},
        {'title': 'Sindirim Sistemi', 'pairs': [{'term': 'Agiz', 'definition': 'Mekanik ve kimyasal sindirimin basladigi yer'}, {'term': 'Mide', 'definition': 'Protein sindiriminin basladigi organ'}, {'term': 'Ince bagirsak', 'definition': 'Besin emiliminin yapildigi organ'}, {'term': 'Karaciger', 'definition': 'Safra ureten organ'}], 'steps': ['Agizda mekanik+kimyasal sindirim baslar', 'Yemek borusundan mideye iner', 'Midede protein sindirimi baslar', 'Ince bagirsakta sindirim tamamlanir ve emilim olur'], 'order_q': 'Sindirim sistemi calisma sirasini olustur', 'fill': {'s': 'Protein sindirimi _____ de baslar.', 'a': 'midede', 'o': ['midede', 'agizda', 'karacigerde', 'ince bagirsak']}, 'quiz': {'q': 'Besin emilimi nerede gerceklesir?', 'o': ['Ince bagirsak', 'Mide', 'Kalin bagirsak', 'Yemek borusu'], 'c': 0}, 'err': {'s': 'Safra midede uretilir.', 'w': 'midede', 'f': 'karacigerde'}},
        {'title': 'Dolasim Sistemi', 'pairs': [{'term': 'Kalp', 'definition': 'Kani pompalayan organ'}, {'term': 'Atardamar', 'definition': 'Kalpten organlara kan tasiyan damar'}, {'term': 'Toplardamar', 'definition': 'Organlardan kalbe kan getiren damar'}, {'term': 'Kilcal damar', 'definition': 'Madde degisiminin yapildigi ince damar'}], 'steps': ['Kalp kani pompalar', 'Atardamar ile organlara tasir', 'Kilcal damarlarda madde degisimi olur', 'Toplardamar ile kan kalbe doner'], 'order_q': 'Kan dolasim yolunu sirala', 'fill': {'s': 'Kalpten temiz kani organlara tasiyan damarlara _____ denir.', 'a': 'atardamar', 'o': ['atardamar', 'toplardamar', 'kilcal damar', 'lenf damari']}, 'quiz': {'q': 'Kilcal damarlarin gorevi nedir?', 'o': ['Madde degisimi', 'Kan pompalama', 'Kan depolama', 'Kan filtreleme'], 'c': 0}, 'err': {'s': 'Toplardamarlar kalpten organlara kan tasir.', 'w': 'kalpten organlara', 'f': 'organlardan kalbe'}},
      ],
    },
  ];

  // ── DGS (Matematik + Turkce) ──────────────────────────

  static final _dgsUnits = <Map<String, dynamic>>[
    {
      'title': 'DGS Matematik — Sayi Problemleri',
      'topics': [
        {'title': 'Dogal Sayilar ve Islemler', 'pairs': [{'term': 'Bolunebilme', 'definition': 'Bir sayinin baska bir sayiya kalansiz bolunmesi'}, {'term': 'EBOB', 'definition': 'En buyuk ortak bolen'}, {'term': 'EKOK', 'definition': 'En kucuk ortak kat'}, {'term': 'Asal sayi', 'definition': 'Sadece 1 ve kendisine bolunen sayi'}], 'steps': ['Sayilari asal carpanlarina ayir', 'Ortak carpanlari belirle', 'EBOB icin kucuk usluleri carp', 'EKOK icin buyuk usluleri carp'], 'order_q': 'EBOB/EKOK bulma adimlarini sirala', 'fill': {'s': 'En kucuk asal sayi _____ dir.', 'a': '2', 'o': ['2', '0', '1', '3']}, 'quiz': {'q': '12 ve 18 in EBOB u kactir?', 'o': ['6', '3', '12', '36'], 'c': 0}, 'err': {'s': '1 bir asal sayidir.', 'w': 'asal', 'f': 'asal olmayan'}},
        {'title': 'Oran-Oranti', 'pairs': [{'term': 'Oran', 'definition': 'Iki niceliğin bolumu'}, {'term': 'Oranti', 'definition': 'Iki oranin esitligi'}, {'term': 'Doğru oranti', 'definition': 'Biri artarken digeri de artar'}, {'term': 'Ters oranti', 'definition': 'Biri artarken digeri azalir'}], 'steps': ['Verilen bilgileri belirle', 'Oranti turunu tespit et (dogru/ters)', 'Orani kur (a/b = c/d)', 'Carpraz carpim ile bilinmeyeni bul'], 'order_q': 'Oranti problemi cozum adimlarini sirala', 'fill': {'s': 'Bir isci 5 gunde bitirirse, 2 isci _____ gunde bitirir.', 'a': '2.5', 'o': ['2.5', '10', '3', '7']}, 'quiz': {'q': 'Hiz ile sure arasindaki iliski nedir?', 'o': ['Ters oranti', 'Dogru oranti', 'Oransiz', 'Esit'], 'c': 0}, 'err': {'s': 'Isci sayisi artarsa sure de artar.', 'w': 'artar', 'f': 'azalir'}},
        {'title': 'Yuzde Problemleri', 'pairs': [{'term': '%25', 'definition': '1/4 (dortte bir)'}, {'term': '%50', 'definition': '1/2 (yarim)'}, {'term': '%10', 'definition': 'Onda bir'}, {'term': 'Kar/Zarar', 'definition': 'Satis - Alis farki'}], 'steps': ['Alis fiyatini belirle', 'Yuzdeyi hesapla (sayi x yuzde / 100)', 'Kar veya zarar miktarini bul', 'Satis fiyatini hesapla'], 'order_q': 'Kar/zarar problemi cozum adimlarini sirala', 'fill': {'s': '200 TL nin %15 i _____ TL dir.', 'a': '30', 'o': ['30', '15', '50', '20']}, 'quiz': {'q': 'Bir urun 100 TL ye alinip 120 TL ye satilirsa kar yuzdesi nedir?', 'o': ['%20', '%12', '%120', '%80'], 'c': 0}, 'err': {'s': 'Kar yuzdesi satis fiyati uzerinden hesaplanir.', 'w': 'satis', 'f': 'alis'}},
        {'title': 'Denklem Cozme', 'pairs': [{'term': 'Bilinmeyen', 'definition': 'Degeri aranan degisken (x)'}, {'term': '1. derece', 'definition': 'ax + b = 0 seklindeki denklem'}, {'term': 'Cozum', 'definition': 'Denklemi saglayan deger'}, {'term': 'Esitsizlik', 'definition': 'Iki ifade arasindaki buyukluk iliskisi'}], 'steps': ['Parantezleri ac', 'Bilinmeyenleri bir tarafa topla', 'Sabitleri diger tarafa topla', 'Her iki tarafi katsayiya bol'], 'order_q': 'Denklem cozme adimlarini sirala', 'fill': {'s': '3x + 6 = 15 denkleminde x = _____ dir.', 'a': '3', 'o': ['3', '5', '9', '7']}, 'quiz': {'q': '2(x-1) = 8 denkleminde x kactir?', 'o': ['5', '4', '3', '6'], 'c': 0}, 'err': {'s': 'Denklemde bir tarafa gecerken isaret degismez.', 'w': 'degismez', 'f': 'degisir'}},
        {'title': 'Problem Turleri', 'pairs': [{'term': 'Isci problemi', 'definition': 'Toplam is = hiz x sure'}, {'term': 'Hareket problemi', 'definition': 'Yol = Hiz x Zaman'}, {'term': 'Havuz problemi', 'definition': 'Doldurma/bosaltma hizi problemi'}, {'term': 'Yas problemi', 'definition': 'Yas farki sabit kalir'}], 'steps': ['Problemi oku ve ne soruldugunu bul', 'Bilinmeyen icin degisken (x) ata', 'Verilerle denklem kur', 'Denklemi coz ve sonucu dogrula'], 'order_q': 'Problem cozme adimlarini sirala', 'fill': {'s': 'Saatte 60 km hizla 3 saat gidilirse yol _____ km dir.', 'a': '180', 'o': ['180', '20', '63', '120']}, 'quiz': {'q': 'Ali 12 yasinda, babasi 36 yasinda. Yas farki kactir?', 'o': ['24', '48', '12', '36'], 'c': 0}, 'err': {'s': 'Yas farki zamanla degisir.', 'w': 'degisir', 'f': 'ayni kalir'}},
        {'title': 'Kume Problemleri', 'pairs': [{'term': 'Birlesim', 'definition': 'A veya B nin elemanlari'}, {'term': 'Kesisim', 'definition': 'A ve B nin ortak elemanlari'}, {'term': 'Fark', 'definition': 'A da olup B de olmayan'}, {'term': 'Tum eleman', 'definition': 'n(AUB) = n(A)+n(B)-n(AnB)'}], 'steps': ['Kumeleri ve eleman sayilarini belirle', 'Kesisim (ortak) eleman sayisini bul', 'Birlesim formulunu uygula: n(AUB)=n(A)+n(B)-n(AnB)', 'Sonucu dogrula'], 'order_q': 'Kume problemi cozum adimlarini sirala', 'fill': {'s': '30 kisiden 20 si futbol, 15 i basketbol seviyor, 10 u her ikisini seviyorsa toplam _____ kisi en az birini sever.', 'a': '25', 'o': ['25', '30', '45', '35']}, 'quiz': {'q': 'Kesisim kumesi ne gosterir?', 'o': ['Ortak elemanlari', 'Tum elemanlari', 'Fark elemanlari', 'Bos kumeyi'], 'c': 0}, 'err': {'s': 'Birlesim kumesi iki kumenin sadece ortak elemanlarindan olusur.', 'w': 'ortak', 'f': 'tum'}},
      ],
    },
    {
      'title': 'DGS Turkce — Soz Bilgisi',
      'topics': [
        {'title': 'Es Anlamli Kelimeler', 'pairs': [{'term': 'Yoksul', 'definition': 'Fakir'}, {'term': 'Sakin', 'definition': 'Durgun'}, {'term': 'Cesur', 'definition': 'Yigit'}, {'term': 'Hizli', 'definition': 'Seri'}], 'steps': ['Kelimenin anlamini belirle', 'Ayni anlama gelen kelimeleri dusun', 'Cumle icinde dene', 'Anlam uyumunu dogrula'], 'order_q': 'Es anlamli kelime bulma adimlarini sirala', 'fill': {'s': '"Genis" kelimesinin es anlamlisi _____ dir.', 'a': 'ferah', 'o': ['ferah', 'dar', 'uzun', 'kisa']}, 'quiz': {'q': '"Ozlem" kelimesinin es anlamlisi hangisidir?', 'o': ['Hasret', 'Sevinc', 'Keder', 'Ofke'], 'c': 0}, 'err': {'s': '"Buyuk" ve "kucuk" es anlamlidir.', 'w': 'es anlamlidir', 'f': 'zit anlamlidir'}},
        {'title': 'Zit Anlamli Kelimeler', 'pairs': [{'term': 'Sicak', 'definition': 'Soguk'}, {'term': 'Guzel', 'definition': 'Cirkin'}, {'term': 'Hizli', 'definition': 'Yavas'}, {'term': 'Uzun', 'definition': 'Kisa'}], 'steps': ['Kelimenin anlamini belirle', 'Karsi anlamdaki kelimeyi bul', 'Cumle icinde kontrol et', 'Zitlik iliskisini dogrula'], 'order_q': 'Zit anlamli kelime bulma adimlarini sirala', 'fill': {'s': '"Karanlik" kelimesinin zit anlamlisi _____ dir.', 'a': 'aydinlik', 'o': ['aydinlik', 'koyuluk', 'gece', 'sisli']}, 'quiz': {'q': '"Genis" in zit anlamlisi hangisidir?', 'o': ['Dar', 'Buyuk', 'Ferah', 'Uzun'], 'c': 0}, 'err': {'s': '"Mutlu" ve "mesut" zit anlamlidir.', 'w': 'zit', 'f': 'es'}},
        {'title': 'Deyimler', 'pairs': [{'term': 'Goz boyamak', 'definition': 'Gercegi saklamak, aldatmak'}, {'term': 'El ustunde tutmak', 'definition': 'Cok deger vermek'}, {'term': 'Agzinda bakla islanmamak', 'definition': 'Sir saklayamamak'}, {'term': 'Burnundan kil aldirmamak', 'definition': 'Cok kibirli olmak'}], 'steps': ['Deyimi cumle icinde bul', 'Kelimelerin gercek anlamini dusun', 'Mecazi (gercek olmayan) anlamini cikart', 'Cumleye uygunlugunu dogrula'], 'order_q': 'Deyim anlamini bulma adimlarini sirala', 'fill': {'s': '"Cok sevinmekten ucarcasina olmak" anlamina gelen deyim _____ dir.', 'a': 'havaya girmek', 'o': ['havaya girmek', 'goz boyamak', 'yere basmak', 'ayagi yere degmemek']}, 'quiz': {'q': '"Kulak misafiri olmak" ne demektir?', 'o': ['Baskalarinin konusmasini isitmek', 'Cok iyi duymak', 'Ses cikarmamak', 'Dinlememek'], 'c': 0}, 'err': {'s': '"Goz boyamak" gozleri guzellesirmek demektir.', 'w': 'guzellesirmek', 'f': 'aldatmak/kandirmak'}},
        {'title': 'Cumle Turleri', 'pairs': [{'term': 'Olumlu', 'definition': 'Eylemin yapildigini bildirir'}, {'term': 'Olumsuz', 'definition': 'Eylemin yapilmadigini bildirir'}, {'term': 'Soru', 'definition': 'Soru eki icerir'}, {'term': 'Sart', 'definition': '-se/-sa eki icerir'}], 'steps': ['Cumleyi oku', 'Yuklemin olumlu/olumsuz oldugunu belirle', 'Soru eki veya sart eki ara', 'Cumle turunu tespit et'], 'order_q': 'Cumle turu belirleme adimlarini sirala', 'fill': {'s': '"Hava guzel olursa piknik yapariz" cumlesinde sart eki _____ dir.', 'a': '-sa/-se', 'o': ['-sa/-se', '-di/-di', '-mis/-mus', '-r/-ir']}, 'quiz': {'q': '"Dun okula gitmedim" cumlesi hangi turdedir?', 'o': ['Olumsuz', 'Olumlu', 'Soru', 'Sart'], 'c': 0}, 'err': {'s': 'Soru cumleleri her zaman soru isareti ile biter.', 'w': 'her zaman', 'f': 'genellikle ama icerik olarak da soru olabilir'}},
        {'title': 'Paragraf Analizi', 'pairs': [{'term': 'Ana dusunce', 'definition': 'Paragrafin temel mesaji'}, {'term': 'Yardimci dusunce', 'definition': 'Ana dusunceyi destekleyen fikirler'}, {'term': 'Konu', 'definition': 'Paragrafin ne hakkinda oldugu'}, {'term': 'Baslik', 'definition': 'Konuyu en iyi ozetleyen ifade'}], 'steps': ['Paragrafi dikkatli oku', 'Konuyu belirle (ne hakkinda?)', 'Ana dusunceyi bul (yazar ne anlatmak istiyor?)', 'Yardimci dusunceleri isaretle'], 'order_q': 'Paragraf analizi adimlarini sirala', 'fill': {'s': 'Paragrafta yazar en cok _____ vurgulamak ister.', 'a': 'ana dusunceyi', 'o': ['ana dusunceyi', 'detaylari', 'ornekleri', 'tarihleri']}, 'quiz': {'q': 'Paragrafin konusu nasil bulunur?', 'o': ['Ne hakkinda oldugu sorulur', 'Son cumleye bakilir', 'Sayilar incelenir', 'Baslik okunur'], 'c': 0}, 'err': {'s': 'Ana dusunce her zaman ilk cumlede yer alir.', 'w': 'her zaman', 'f': 'her yerde olabilir'}},
        {'title': 'Anlatim Bozukluklari', 'pairs': [{'term': 'Gereksiz kelime', 'definition': 'Anlami tekrar eden fazla soz'}, {'term': 'Ozne-yuklem uyumsuzlugu', 'definition': 'Kisi/sayi uyusmazligi'}, {'term': 'Mantik hatasi', 'definition': 'Anlam bakimindan celiskili ifade'}, {'term': 'Anlam belirsizligi', 'definition': 'Birden fazla anlama gelen cumle'}], 'steps': ['Cumleyi dikkatli oku', 'Tekrar eden veya gereksiz sozcukleri bul', 'Ozne-yuklem uyumunu kontrol et', 'Anlam tutarliligi/mantik hatasini ara'], 'order_q': 'Anlatim bozuklugu bulma adimlarini sirala', 'fill': {'s': '"Karsiliksiz bos yere ugrastim" cumlesindeki hata _____ dir.', 'a': 'gereksiz kelime', 'o': ['gereksiz kelime', 'devrik cumle', 'kisa cumle', 'ed-at hatasi']}, 'quiz': {'q': '"Ben ve arkadaslarim okula gittiler" cumlesindeki hata nedir?', 'o': ['Yuklem kisi uyumsuzlugu', 'Gereksiz kelime', 'Mantik hatasi', 'Hata yok'], 'c': 0}, 'err': {'s': '"Herkes kendi gorevlerini yapsin" cumlesi doğrudur.', 'w': 'gorevlerini', 'f': 'gorevini (tekil olmali)'}},
      ],
    },
  ];

  // ── TARIH ──────────────────────────────────────────

  static final _tarihUnits = <Map<String, dynamic>>[
    {
      'title': 'Tarih — Ilk Caglar ve Uygarliklar',
      'topics': [
        {'title': 'Tarih Oncesi Donemler', 'pairs': [{'term': 'Paleolitik', 'definition': 'Eski Tas Devri (avcilik-toplayicilik)'}, {'term': 'Neolitik', 'definition': 'Yeni Tas Devri (tarimci yerleskici)'}, {'term': 'Kalkolitik', 'definition': 'Bakir-Tas Devri (maden kullanimi)'}, {'term': 'Demir Cagi', 'definition': 'Demiris isleminin basladigi donem'}], 'steps': ['Paleolitik (Eski Tas)', 'Mezolitik (Orta Tas)', 'Neolitik (Yeni Tas)', 'Kalkolitik (Bakir Cagi)'], 'order_q': 'Tarih oncesi donemleri kronolojik sirala', 'fill': {'s': 'Insanlarin yerleskik hayata gectigi donem _____ dir.', 'a': 'Neolitik', 'o': ['Neolitik', 'Paleolitik', 'Demir Cagi', 'Kalkolitik']}, 'quiz': {'q': 'Ilk yazili belge hangi uygarliga aittir?', 'o': ['Sumerler', 'Misir', 'Roma', 'Yunan'], 'c': 0}, 'err': {'s': 'Paleolitik donemde insanlar tarimla ugrasirdi.', 'w': 'tarimla', 'f': 'avcilik-toplayicilikla'}},
        {'title': 'Ilk Uygarliklar', 'pairs': [{'term': 'Sumer', 'definition': 'Yazıyı icat eden uygarlik'}, {'term': 'Misir', 'definition': 'Nil Nehri kenarinda kurulan'}, {'term': 'Hitit', 'definition': 'Anadoluda kurulan ilk buyuk devlet'}, {'term': 'Lidya', 'definition': 'Parayi icat eden uygarlik'}], 'steps': ['Sumerler: Yazinin icadi', 'Misir: Piramitler ve hiyeroglif', 'Hititler: Anadolunun ilk buyuk devleti', 'Lidya: Paranin icadi'], 'order_q': 'Ilk uygarliklari kronolojik sirala', 'fill': {'s': 'Tarihteki ilk yazili kanun olan Ur-Nammu Kanunlarini _____ yapti.', 'a': 'Sumerler', 'o': ['Sumerler', 'Romalılar', 'Hititler', 'Persliler']}, 'quiz': {'q': 'Anadolunun ilk buyuk devleti hangisidir?', 'o': ['Hititler', 'Lidyalilar', 'Urartular', 'Frigyalilar'], 'c': 0}, 'err': {'s': 'Parayi Romalılar icat etmistir.', 'w': 'Romalılar', 'f': 'Lidyalilar'}},
        {'title': 'Islam Oncesi Turk Devletleri', 'pairs': [{'term': 'Hun Devleti', 'definition': 'Bilinen ilk Turk devleti (Teoman)'}, {'term': 'Gokturk', 'definition': 'Turk adini kullanan ilk devlet'}, {'term': 'Uygur', 'definition': 'Yerleskik hayata gecen ilk Turk toplulugu'}, {'term': 'Mete Han', 'definition': 'Buyuk Hun Devletinin kurucusu'}], 'steps': ['Buyuk Hun Devleti (MO 220)', 'Gokturk Devleti (552)', 'Uygur Devleti (745)', 'Karahanlilar (840 - ilk Musluman Turk devleti)'], 'order_q': 'Islam oncesi Turk devletlerini kronolojik sirala', 'fill': {'s': 'Turk tarihinde bilinen ilk devlet _____ dir.', 'a': 'Buyuk Hun Devleti', 'o': ['Buyuk Hun Devleti', 'Gokturk', 'Uygur', 'Selcuklu']}, 'quiz': {'q': '"Turk" adini resmi olarak kullanan ilk devlet hangisidir?', 'o': ['Gokturk Devleti', 'Hun Devleti', 'Uygur Devleti', 'Osmanli'], 'c': 0}, 'err': {'s': 'Uygarlar gocebe bir yasam surmuslurdir.', 'w': 'gocebe', 'f': 'yerleskik'}},
        {'title': 'Osmanli Kurulusu', 'pairs': [{'term': 'Osman Gazi', 'definition': 'Osmanli Devletinin kurucusu'}, {'term': '1299', 'definition': 'Osmanli Devletinin kurulus yili'}, {'term': 'Bursa', 'definition': 'Osmanlinin ilk baskenti'}, {'term': 'Orhan Gazi', 'definition': 'Ilk Osmanli padisahi'}], 'steps': ['Osman Gazi beylik kurdu (1299)', 'Orhan Gazi Bursayi fethetti', 'I. Murat Edirniye gecti', 'Yildirim Bayezid Nicopolis Savasi'], 'order_q': 'Osmanli kurulus donemi olaylarini sirala', 'fill': {'s': 'Osmanli Devleti _____ yilinda kurulmustur.', 'a': '1299', 'o': ['1299', '1453', '1071', '1923']}, 'quiz': {'q': 'Osmanlinin ilk baskenti neresidir?', 'o': ['Bursa', 'Istanbul', 'Edirne', 'Sogut'], 'c': 0}, 'err': {'s': 'Osmanli Devletinin ilk baskenti Istanbuldur.', 'w': 'Istanbul', 'f': 'Bursa'}},
        {'title': 'Istanbulun Fethi', 'pairs': [{'term': '1453', 'definition': 'Istanbulun fetih yili'}, {'term': 'Fatih Sultan Mehmet', 'definition': 'Istanbulu fetheden padisah'}, {'term': 'Ortacag sonu', 'definition': 'Fetihle sona eren cag'}, {'term': 'Yeni Cag', 'definition': 'Fetihle baslayan donem'}], 'steps': ['Kusakma ve hazirliklar yapildi', 'Rumeli Hisari insa edildi', 'Gemiler karadan Halic e indirildi', '29 Mayis 1453 te sehir fethedildi'], 'order_q': 'Istanbul fethi asamalarini sirala', 'fill': {'s': 'Istanbul _____ yilinda fethedilmistir.', 'a': '1453', 'o': ['1453', '1299', '1071', '1923']}, 'quiz': {'q': 'Istanbul fethi hangi cagi baslatmistir?', 'o': ['Yeni Cag', 'Yakin Cag', 'Ortacag', 'Ilkcag'], 'c': 0}, 'err': {'s': 'Istanbulun fethi Ilkcagi baslatmistir.', 'w': 'Ilkcagi', 'f': 'Yeni Cagi'}},
        {'title': 'Ataturk ve Cumhuriyet', 'pairs': [{'term': '1923', 'definition': 'Cumhuriyetin ilan yili'}, {'term': 'Ankara', 'definition': 'Cumhuriyet baskenti'}, {'term': 'TBMM', 'definition': '1920 de acilan meclis'}, {'term': 'Lozanx', 'definition': 'Bagimsizligi taniyan antlasma'}], 'steps': ['19 Mayis 1919 - Samsuna cikis', '23 Nisan 1920 - TBMM acildi', '24 Temmuz 1923 - Lozan Antlasmasi', '29 Ekim 1923 - Cumhuriyet ilan edildi'], 'order_q': 'Kurtulus Savasi ve Cumhuriyet donemi olaylarini sirala', 'fill': {'s': 'Turkiye Cumhuriyeti _____ Ekim 1923 te ilan edildi.', 'a': '29', 'o': ['29', '23', '30', '19']}, 'quiz': {'q': 'TBMM hangi yil acilmistir?', 'o': ['1920', '1919', '1923', '1922'], 'c': 0}, 'err': {'s': 'Cumhuriyet Istanbul da ilan edilmistir.', 'w': 'Istanbul', 'f': 'Ankara'}},
      ],
    },
  ];

  // ── EKONOMI ──────────────────────────────────────────

  static final _econUnits = <Map<String, dynamic>>[
    {
      'title': 'Ekonomi Temelleri',
      'topics': [
        {'title': 'Arz ve Talep', 'pairs': [{'term': 'Arz', 'definition': 'Uretici tarafindan sunulan miktar'}, {'term': 'Talep', 'definition': 'Tuketici tarafindan istenen miktar'}, {'term': 'Denge fiyat', 'definition': 'Arz ve talebin esitlendi̇gi fiyat'}, {'term': 'Kıtlik', 'definition': 'Kaynaklarin ihtiyactan az olmasi'}], 'steps': ['Talep miktarini belirle', 'Arz miktarini belirle', 'Arz=Talep noktasini bul (denge)', 'Denge fiyatini ve miktarini oku'], 'order_q': 'Arz-talep dengesi bulma adimlarini sirala', 'fill': {'s': 'Bir urunun fiyati artarsa talebi _____.', 'a': 'azalir', 'o': ['azalir', 'artar', 'degismez', 'sifirlanir']}, 'quiz': {'q': 'Arz artarsa fiyat ne olur?', 'o': ['Duser', 'Artar', 'Degismez', 'Ikiye katlanir'], 'c': 0}, 'err': {'s': 'Fiyat artarsa talep artar.', 'w': 'artar', 'f': 'azalir'}},
        {'title': 'Para ve Enflasyon', 'pairs': [{'term': 'Enflasyon', 'definition': 'Genel fiyat duzeyinin artmasi'}, {'term': 'Deflasyon', 'definition': 'Genel fiyat duzeyinin dusmesi'}, {'term': 'Faiz', 'definition': 'Paranin kullanma bedeli'}, {'term': 'TCMB', 'definition': 'Turkiye Cumhuriyet Merkez Bankasi'}], 'steps': ['Fiyat endeksini belirle', 'Onceki donemle karsilastir', 'Artis oranini hesapla (enflasyon)', 'Merkez bankasi politika faizini ayarlar'], 'order_q': 'Enflasyon olcum adimlarini sirala', 'fill': {'s': 'Fiyatlarin genel olarak artmasina _____ denir.', 'a': 'enflasyon', 'o': ['enflasyon', 'deflasyon', 'devaluasyon', 'revaluas']}, 'quiz': {'q': 'Merkez bankasi faiz artirirsa ne olur?', 'o': ['Tuketim azalir', 'Tuketim artar', 'Hicbir etkisi olmaz', 'Ihracat duser'], 'c': 0}, 'err': {'s': 'Enflasyon paranin deger kazanmasidir.', 'w': 'kazanmasi', 'f': 'kaybetmesi'}},
        {'title': 'GSYH ve Buyume', 'pairs': [{'term': 'GSYH', 'definition': 'Bir ulkede uretilen tum mal/hizmet degeri'}, {'term': 'Buyume', 'definition': 'GSYH nin artis orani'}, {'term': 'Kisi basi gelir', 'definition': 'GSYH / nufus'}, {'term': 'Resesyon', 'definition': 'Ust uste iki ceyrek daralma'}], 'steps': ['Tum uretilen mal/hizmet degerini topla', 'GSYH yi bul', 'Onceki yil ile karsilastir (buyume orani)', 'Nufusa bol (kisi basi gelir)'], 'order_q': 'GSYH hesaplama adimlarini sirala', 'fill': {'s': 'Ulke ekonomisinin buyuklugu _____ ile olculur.', 'a': 'GSYH', 'o': ['GSYH', 'Enflasyon', 'Issizlik', 'Faiz']}, 'quiz': {'q': 'Resesyon ne demektir?', 'o': ['Ekonomik daralma', 'Hizli buyume', 'Yuksek enflasyon', 'Doviz artisi'], 'c': 0}, 'err': {'s': 'GSYH sadece tarim uretimini olcer.', 'w': 'tarim', 'f': 'tum sektorlerin'}},
        {'title': 'Vergi Cesitleri', 'pairs': [{'term': 'KDV', 'definition': 'Katma deger vergisi (tuketim)'}, {'term': 'Gelir vergisi', 'definition': 'Kazanc uzerinden alinan vergi'}, {'term': 'Kurumlar vergisi', 'definition': 'Sirketlerden alinan vergi'}, {'term': 'OTV', 'definition': 'Ozel tuketim vergisi'}], 'steps': ['Gelir elde et', 'Vergi turunu belirle (dolayli/dolaysiz)', 'Vergi matrahini hesapla', 'Vergi tutarini ode'], 'order_q': 'Vergi odeme surecini sirala', 'fill': {'s': 'Satilan her urun uzerinden alinan vergiye _____ denir.', 'a': 'KDV', 'o': ['KDV', 'OTV', 'MTV', 'Gelir vergisi']}, 'quiz': {'q': 'Dolayni vergi nedir?', 'o': ['Fiyata eklenen vergi (KDV)', 'Maas uzerinden kesilen', 'Miras vergisi', 'Emlak vergisi'], 'c': 0}, 'err': {'s': 'KDV sadece lüks urunlere uygulanir.', 'w': 'lüks', 'f': 'neredeyse tum'}},
        {'title': 'Dis Ticaret', 'pairs': [{'term': 'Ihracat', 'definition': 'Yurt disina mal satmak'}, {'term': 'Ithalat', 'definition': 'Yurt disindan mal almak'}, {'term': 'Dis ticaret acigi', 'definition': 'Ithalat > ihracat farki'}, {'term': 'Doviz kuru', 'definition': 'Bir para biriminin digeri karsisinda degeri'}], 'steps': ['Ihracat gelirlerini hesapla', 'Ithalat giderlerini hesapla', 'Farki bul (ihracat-ithalat)', 'Acik veya fazla olarak yorumla'], 'order_q': 'Dis ticaret dengesi hesaplama adimlarini sirala', 'fill': {'s': 'Yurt disina yapilan mal satisina _____ denir.', 'a': 'ihracat', 'o': ['ihracat', 'ithalat', 'transfer', 'yatirim']}, 'quiz': {'q': 'TL deger kaybederse ihracat ne olur?', 'o': ['Artar (ucuzlar)', 'Azalir', 'Degismez', 'Durur'], 'c': 0}, 'err': {'s': 'Ithalat yurt disina mal satmaktir.', 'w': 'satmak', 'f': 'almak'}},
        {'title': 'Issizlik', 'pairs': [{'term': 'Issizlik orani', 'definition': 'Issiz / isgucü x 100'}, {'term': 'Mevsimsel issizlik', 'definition': 'Mevsime bagli gecici issizlik'}, {'term': 'Yapisal issizlik', 'definition': 'Sektorel degisimden kaynaklanan'}, {'term': 'Isgucue', 'definition': 'Calisan + is arayan toplam kisi'}], 'steps': ['Calisabilir nufusu belirle', 'Isgucunu hesapla (calisan + is arayan)', 'Issiz sayisini bul', 'Issizlik orani = Issiz/Isgucu x 100'], 'order_q': 'Issizlik orani hesaplama adimlarini sirala', 'fill': {'s': 'Is arayan ama bulamayan kisilerin calismak isteyen nufusa oranina _____ denir.', 'a': 'issizlik orani', 'o': ['issizlik orani', 'enflasyon', 'buyume', 'verimlilik']}, 'quiz': {'q': 'Tarim iscilerinin kis aylinda isssiz kalmasi ne tur issizlik?', 'o': ['Mevsimsel', 'Yapisal', 'Devirsel', 'Friksiyonel'], 'c': 0}, 'err': {'s': 'Issizlik oraninda emekliler de sayilir.', 'w': 'sayilir', 'f': 'sayilmaz (isgucunde degillerdir)'}},
      ],
    },
  ];

  // ── SOSYAL BİLİMLER (Psikoloji/Sosyoloji/Felsefe) ──

  static final _socUnits = <Map<String, dynamic>>[
    {
      'title': 'Psikoloji Temelleri',
      'topics': [
        {'title': 'Psikoloji Nedir?', 'pairs': [{'term': 'Psikoloji', 'definition': 'Davranis ve zihinsel surecleri inceler'}, {'term': 'Davranis', 'definition': 'Gozlemlenebilir eylemler'}, {'term': 'Bilis', 'definition': 'Dusunme, algilama, hafiza surecleri'}, {'term': 'Bilinc', 'definition': 'Farkindalik durumu'}], 'steps': ['Gozlem yap (davranis)', 'Hipotez kur', 'Deney veya anket uygula', 'Sonuclari analiz et ve yorumla'], 'order_q': 'Psikolojik arastirma adimlarini sirala', 'fill': {'s': 'Psikoloji _____ ve zihinsel surecleri inceleyen bilim dalidir.', 'a': 'davranis', 'o': ['davranis', 'toplum', 'ekonomi', 'tarih']}, 'quiz': {'q': 'Psikolojinin temel konusu nedir?', 'o': ['Insan davranisi ve zihni', 'Toplumsal yapi', 'Ekonomik sistem', 'Tarihsel olaylar'], 'c': 0}, 'err': {'s': 'Psikoloji sadece ruhsal hastaliklari inceler.', 'w': 'sadece ruhsal hastaliklari', 'f': 'tum davranis ve zihinsel surecleri'}},
        {'title': 'Ogrenme Kuramlari', 'pairs': [{'term': 'Klasik kosullanma', 'definition': 'Pavlov — uyarana tepki baglama'}, {'term': 'Edimsel kosullanma', 'definition': 'Skinner — odul ve ceza'}, {'term': 'Gozlem yoluyla', 'definition': 'Bandura — model alarak ogrenme'}, {'term': 'Bilissel ogrenme', 'definition': 'Icerik ve anlam uzerinden ogrenme'}], 'steps': ['Uyaran (zil sesi) verilir', 'Kosulsuz uyaran (yemek) ile eslestirilir', 'Tekrarlarla baglanti olusur', 'Sadece zil sesine tepki verilir (kosullu tepki)'], 'order_q': 'Klasik kosullanma asamalarini sirala', 'fill': {'s': 'Pavlov un kopek deneyinde zil sesiyle salya salgilanmasi _____ ornegedir.', 'a': 'klasik kosullanma', 'o': ['klasik kosullanma', 'edimsel', 'gozlem', 'bilissel']}, 'quiz': {'q': 'Odul ve ceza ile ogrenme hangi kuramdir?', 'o': ['Edimsel kosullanma', 'Klasik kosullanma', 'Bilissel', 'Insancil'], 'c': 0}, 'err': {'s': 'Gozlem yoluyla ogrenmeyi Pavlov one surmustur.', 'w': 'Pavlov', 'f': 'Bandura'}},
        {'title': 'Motivasyon', 'pairs': [{'term': 'Ic motivasyon', 'definition': 'Kendi istegi ile yapma'}, {'term': 'Dis motivasyon', 'definition': 'Odul/ceza etkisiyle yapma'}, {'term': 'Maslow', 'definition': 'Ihtiyaclar hiyerarsisi kurami'}, {'term': 'Temel ihtiyaclar', 'definition': 'Yeme, icme, uyuma gibi'}], 'steps': ['Fizyolojik ihtiyaclar (yeme, icme)', 'Guvenlik ihtiyaclari', 'Ait olma ve sevgi', 'Saygi ve kendini gerceklestirme'], 'order_q': 'Maslow ihtiyaclar piramidini alttan uste sirala', 'fill': {'s': 'Maslow a gore ilk karsilanmasi gereken ihtiyaclar _____ ihtiyaclaridir.', 'a': 'fizyolojik', 'o': ['fizyolojik', 'sosyal', 'saygi', 'kendini gerceklestirme']}, 'quiz': {'q': 'Bir isi sevdiği icin yapan kisi hangi motivasyona sahiptir?', 'o': ['Ic motivasyon', 'Dis motivasyon', 'Zorunlu motivasyon', 'Motivasyonsuz'], 'c': 0}, 'err': {'s': 'Maslow a gore en ust ihtiyac fizyolojik ihtiyaclardir.', 'w': 'fizyolojik', 'f': 'kendini gerceklestirme'}},
        {'title': 'Duygular', 'pairs': [{'term': 'Temel duygular', 'definition': 'Sevinc, uzuntu, korku, ofke, igrenme, saskinlik'}, {'term': 'Empati', 'definition': 'Baskasinin duygusunu anlama'}, {'term': 'Duygusal zeka', 'definition': 'Duyguları tanima ve yonetme'}, {'term': 'Stres', 'definition': 'Baskiya karsi bedensel/ruhsal tepki'}], 'steps': ['Duyguyu fark et (farkindalik)', 'Duyguyu tanimla ve adlandir', 'Nedenini anla (tetikleyici)', 'Uygun sekilde ifade et veya yonet'], 'order_q': 'Duygu yonetimi adimlarini sirala', 'fill': {'s': 'Baskasinin duygularını anlayabilme becerisine _____ denir.', 'a': 'empati', 'o': ['empati', 'sempati', 'antipati', 'apati']}, 'quiz': {'q': 'Hangisi temel duygulardan biridir?', 'o': ['Korku', 'Hayal kirikligi', 'Nostalji', 'Huzur'], 'c': 0}, 'err': {'s': 'Stres her zaman zararlidir.', 'w': 'her zaman', 'f': 'belirli duzeyde faydali olabilir'}},
        {'title': 'Kisilik Kuramlari', 'pairs': [{'term': 'Freud', 'definition': 'Id, ego, superego modeli'}, {'term': 'Id', 'definition': 'Ilkel arzular ve durtuluer'}, {'term': 'Ego', 'definition': 'Gerceklik ilkesiyle calisan'}, {'term': 'Superego', 'definition': 'Ahlaki kurallar ve vicdan'}], 'steps': ['Id: Durtu ortaya cikar (haz ilkesi)', 'Ego: Gerceklige gore deger bicer', 'Superego: Ahlaki kurallari kontrol eder', 'Denge kurulur veya catisma olusur'], 'order_q': 'Freud kisilik yapisinda karar sureci adimlarini sirala', 'fill': {'s': 'Freud un kisilik yapisinda ilkel durtuleri temsil eden _____ dir.', 'a': 'id', 'o': ['id', 'ego', 'superego', 'bilis']}, 'quiz': {'q': 'Ego hangi ilkeyle calisir?', 'o': ['Gerceklik', 'Haz', 'Ahlak', 'Korku'], 'c': 0}, 'err': {'s': 'Superego haz ilkesiyle calisir.', 'w': 'haz', 'f': 'ahlak'}},
        {'title': 'Bellek Turleri', 'pairs': [{'term': 'Kisa sureli', 'definition': '15-30 sn bilgi tutar'}, {'term': 'Uzun sureli', 'definition': 'Kalici bilgi depolama'}, {'term': 'Duyusal bellek', 'definition': 'Anlık duyusal kayit (<1 sn)'}, {'term': 'Islem bellegi', 'definition': 'Bilgiyi aktif olarak isleme'}], 'steps': ['Duyusal bellek: Uyaran alinir (<1sn)', 'Dikkat edilirse kisa sureli bellege gecer', 'Tekrar/kodlama ile uzun sureli bellege aktarilir', 'Gerektiginde geri cagirilir (hatirlama)'], 'order_q': 'Bilgi bellek asamalarini sirala', 'fill': {'s': 'Bir telefon numarasini birka saniye hatirlamak _____ bellek ornegedir.', 'a': 'kisa sureli', 'o': ['kisa sureli', 'uzun sureli', 'duyusal', 'islemsel']}, 'quiz': {'q': 'Cocukluk anilari hangi bellekte saklanir?', 'o': ['Uzun sureli', 'Kisa sureli', 'Duyusal', 'Islem'], 'c': 0}, 'err': {'s': 'Duyusal bellek bilgiyi dakikalarca saklar.', 'w': 'dakikalarca', 'f': 'bir saniyeden kisa sure'}},
      ],
    },
  ];

  // ── FRANSIZCA ────────────────────────────────────────

  static final _frUnits = <Map<String, dynamic>>[
    {
      'title': 'Fransizca Temel Gramer',
      'topics': [
        {'title': 'Selamlasma', 'pairs': [{'term': 'Bonjour', 'definition': 'Merhaba / Gunaydin'}, {'term': 'Bonsoir', 'definition': 'Iyi aksamlar'}, {'term': 'Au revoir', 'definition': 'Hosca kal'}, {'term': 'Merci', 'definition': 'Tesekkurler'}], 'steps': ['Bonjour (sabah/gun icinde)', 'Bonsoir (aksam)', 'Bonne nuit (gece)', 'Au revoir (vedalasmada)'], 'order_q': 'Fransizca selamlamalari gun sirasina gore sirala', 'trans': {'s': 'Bonjour, comment allez-vous?', 'a': 'Merhaba nasilsiniz', 'chips': ['Merhaba', 'nasilsiniz', 'hosca', 'kalin', 'iyi', 'geceler'], 'lang': 'fr-FR', 'q': 'Cumleyi Turkceye cevir'}, 'img': {'q': 'Hangisi "Bonjour" ile iliskili?', 'images': ['\ud83d\udc4b', '\ud83d\ude34', '\ud83c\udf1e', '\u2744\ufe0f'], 'labels': ['Selamlama', 'Uyku', 'Gunes', 'Kar'], 'c': 0}, 'fill': {'s': 'Fransizca\'da "Hosca kal" demek icin _____ deriz.', 'a': 'Au revoir', 'o': ['Au revoir', 'Bonjour', 'Merci', 'Pardon']}, 'quiz': {'q': '"S\'il vous plait" ne demektir?', 'o': ['Lutfen', 'Tesekkurler', 'Afedersiniz', 'Merhaba'], 'c': 0}, 'err': {'s': '"Bonsoir" gunaydin demektir.', 'w': 'gunaydin', 'f': 'iyi aksamlar'}},
        {'title': 'Artikeller (le/la/les)', 'pairs': [{'term': 'le', 'definition': 'Erkek tekil artikel'}, {'term': 'la', 'definition': 'Disi tekil artikel'}, {'term': 'les', 'definition': 'Cogul artikel'}, {'term': "l'", 'definition': 'Unlu harf oncesi artikel'}], 'steps': ['Ismin cinsiyetini belirle', 'Erkek tekil ise le, disi tekil ise la', 'Unlu ile basliyorsa l\' kullan', 'Cogul ise les kullan'], 'order_q': 'Fransizca artikel secme adimlarini sirala', 'trans': {'s': 'Le chat est sur la table.', 'a': 'Kedi masanin uzerinde', 'chips': ['Kedi', 'masanin', 'uzerinde', 'altinda', 'kopek', 'icinde'], 'lang': 'fr-FR', 'q': 'Cumleyi Turkceye cevir'}, 'img': {'q': 'Hangisi "le chat"?', 'images': ['\ud83d\udc31', '\ud83d\udc36', '\ud83d\udc26', '\ud83d\udc20'], 'labels': ['Kedi', 'Kopek', 'Kus', 'Balik'], 'c': 0}, 'fill': {'s': '"Kitap" Fransizca\'da _____ livre olarak soylenir.', 'a': 'le', 'o': ['le', 'la', 'les', 'un']}, 'quiz': {'q': '"la maison" ifadesinde "la" ne gosterir?', 'o': ['Disi cinsiyet', 'Erkek cinsiyet', 'Cogul', 'Belirsiz'], 'c': 0}, 'err': {'s': '"les" artikeli tekil isimler icin kullanilir.', 'w': 'tekil', 'f': 'cogul'}},
        {'title': 'Kisisel Zamirler', 'pairs': [{'term': 'je', 'definition': 'ben'}, {'term': 'tu', 'definition': 'sen'}, {'term': 'il/elle', 'definition': 'o (erkek/kadin)'}, {'term': 'nous', 'definition': 'biz'}], 'steps': ['je (ben) - 1. tekil', 'tu (sen) - 2. tekil', 'il/elle (o) - 3. tekil', 'nous/vous/ils (biz/siz/onlar) - cogul'], 'order_q': 'Fransizca kisisel zamirleri sirala', 'trans': {'s': 'Nous allons a la plage.', 'a': 'Biz plaja gidiyoruz', 'chips': ['Biz', 'plaja', 'gidiyoruz', 'geliyoruz', 'eve', 'onlar'], 'lang': 'fr-FR', 'q': 'Cumleyi Turkceye cevir'}, 'img': {'q': 'Hangisi "la plage"?', 'images': ['\ud83c\udfd6\ufe0f', '\ud83c\udfd4\ufe0f', '\ud83c\udfde\ufe0f', '\ud83c\udfe0'], 'labels': ['Plaj', 'Dag', 'Orman', 'Ev'], 'c': 0}, 'fill': {'s': '"Onlar" Fransizca\'da _____ olarak soylenir.', 'a': 'ils/elles', 'o': ['ils/elles', 'nous', 'vous', 'je']}, 'quiz': {'q': '"vous" ne anlama gelir?', 'o': ['siz / sen (resmi)', 'ben', 'biz', 'onlar'], 'c': 0}, 'err': {'s': '"je" zamiri "sen" demektir.', 'w': 'sen', 'f': 'ben'}},
        {'title': 'Etre ve Avoir Fiilleri', 'pairs': [{'term': 'je suis', 'definition': 'ben ...im/yim'}, {'term': 'tu es', 'definition': 'sen ...sin'}, {'term': "j'ai", 'definition': 'benim ...m var'}, {'term': 'il a', 'definition': 'onun ...si var'}], 'steps': ['Ozneyi belirle (je/tu/il...)', 'Fiili sec (etre veya avoir)', 'Fiili ozneye gore cekimle', 'Cumleyi tamamla'], 'order_q': 'Fransizca fiil cekimi adimlarini sirala', 'fill': {'s': '"Ben mutluyum" Fransizca\'da "Je _____ content" olur.', 'a': 'suis', 'o': ['suis', 'es', 'est', 'ai']}, 'quiz': {'q': '"Nous avons" ne demektir?', 'o': ['Bizim var', 'Biz gidiyoruz', 'Onlar istiyor', 'Siz biliyorsunuz'], 'c': 0}, 'err': {'s': '"tu es" ifadesi "o var" anlamina gelir.', 'w': 'o var', 'f': 'sen ...sin'}},
        {'title': 'Sayilar (1-20)', 'pairs': [{'term': 'un', 'definition': '1'}, {'term': 'cinq', 'definition': '5'}, {'term': 'dix', 'definition': '10'}, {'term': 'vingt', 'definition': '20'}], 'steps': ['un (1) - trois (3)', 'quatre (4) - six (6)', 'sept (7) - neuf (9)', 'dix (10) - vingt (20)'], 'order_q': 'Fransizca sayilari kucukten buyuge sirala', 'fill': {'s': 'Fransizca\'da 3 sayisi _____ olarak soylenir.', 'a': 'trois', 'o': ['trois', 'tree', 'tri', 'tris']}, 'quiz': {'q': '"sept" kac demektir?', 'o': ['7', '6', '8', '9'], 'c': 0}, 'err': {'s': '"neuf" sayisi 6 demektir.', 'w': '6', 'f': '9'}},
        {'title': 'Gunluk Ifadeler', 'pairs': [{'term': 'Oui / Non', 'definition': 'Evet / Hayir'}, {'term': 'Excusez-moi', 'definition': 'Afedersiniz'}, {'term': 'Je ne comprends pas', 'definition': 'Anlamiyorum'}, {'term': "Je m'appelle...", 'definition': 'Benim adim...'}], 'steps': ['Bonjour ile selamla', 'Je m\'appelle... ile kendini tanit', 'Comment allez-vous? diye sor', 'Merci / Au revoir ile vedahas'], 'order_q': 'Fransizca tanisma diyalogu sirasini olustur', 'fill': {'s': '"Anlamiyorum" Fransizca\'da _____ dir.', 'a': 'Je ne comprends pas', 'o': ['Je ne comprends pas', 'Je suis content', 'Merci beaucoup', 'Au revoir']}, 'quiz': {'q': '"Comment allez-vous?" ne sorar?', 'o': ['Nasilsiniz?', 'Kac yasinda?', 'Nerelisiniz?', 'Ne istiyorsunuz?'], 'c': 0}, 'err': {'s': '"Oui" hayir demektir.', 'w': 'hayir', 'f': 'evet'}},
      ],
    },
    {
      'title': 'Fransizca Kelime Hazinesi',
      'topics': [
        {'title': 'Aile Uyeleri', 'pairs': [{'term': 'la mere', 'definition': 'anne'}, {'term': 'le pere', 'definition': 'baba'}, {'term': 'le frere', 'definition': 'erkek kardes'}, {'term': 'la soeur', 'definition': 'kiz kardes'}], 'steps': ['les grands-parents (buyuk ebeveynler)', 'les parents (anne-baba)', 'les freres et soeurs (kardesler)', 'les enfants (cocuklar)'], 'order_q': 'Fransizca aile uyelerini nesil sirasina gore sirala', 'fill': {'s': '"Buyukbaba" Fransizca\'da _____ dir.', 'a': 'le grand-pere', 'o': ['le grand-pere', 'le pere', 'le frere', 'l\'oncle']}, 'quiz': {'q': '"la tante" ne demektir?', 'o': ['Teyze/Hala', 'Anne', 'Kiz kardes', 'Buyukanne'], 'c': 0}, 'err': {'s': '"le pere" anne demektir.', 'w': 'anne', 'f': 'baba'}},
        {'title': 'Yiyecekler', 'pairs': [{'term': 'le pain', 'definition': 'ekmek'}, {'term': 'le fromage', 'definition': 'peynir'}, {'term': 'la pomme', 'definition': 'elma'}, {'term': "l'eau", 'definition': 'su'}], 'steps': ['le petit-dejeuner (kahvalti)', 'le dejeuner (ogle yemegi)', 'le gouter (ikindi atistirmasi)', 'le diner (aksam yemegi)'], 'order_q': 'Fransizca ogunleri gun sirasina gore sirala', 'fill': {'s': '"Sut" Fransizca\'da _____ dir.', 'a': 'le lait', 'o': ['le lait', 'le vin', 'le jus', 'le cafe']}, 'quiz': {'q': '"le poulet" ne demektir?', 'o': ['Tavuk', 'Balik', 'Et', 'Sebze'], 'c': 0}, 'err': {'s': '"le fromage" ekmek demektir.', 'w': 'ekmek', 'f': 'peynir'}},
        {'title': 'Renkler', 'pairs': [{'term': 'rouge', 'definition': 'kirmizi'}, {'term': 'bleu', 'definition': 'mavi'}, {'term': 'vert', 'definition': 'yesil'}, {'term': 'jaune', 'definition': 'sari'}], 'steps': ['Rengi gor ve tani', 'Fransizca karsiligini ogren', 'Cinsiyet uyumunu uygula (bleu/bleue)', 'Cumle icinde kullan'], 'order_q': 'Fransizca renk kelimesi ogrenme adimlarini sirala', 'fill': {'s': '"Beyaz" Fransizca\'da _____ dir.', 'a': 'blanc', 'o': ['blanc', 'noir', 'gris', 'brun']}, 'quiz': {'q': '"noir" hangi renktir?', 'o': ['Siyah', 'Beyaz', 'Gri', 'Mor'], 'c': 0}, 'err': {'s': '"bleu" rengi kirmizi demektir.', 'w': 'kirmizi', 'f': 'mavi'}},
        {'title': 'Haftanin Gunleri', 'pairs': [{'term': 'lundi', 'definition': 'Pazartesi'}, {'term': 'mercredi', 'definition': 'Carsamba'}, {'term': 'vendredi', 'definition': 'Cuma'}, {'term': 'dimanche', 'definition': 'Pazar'}], 'steps': ['lundi (Pazartesi)', 'mardi (Sali)', 'mercredi (Carsamba)', 'jeudi (Persembe)'], 'order_q': 'Fransizca haftanin gunlerini sirala', 'fill': {'s': '"Cumartesi" Fransizca\'da _____ dir.', 'a': 'samedi', 'o': ['samedi', 'dimanche', 'vendredi', 'jeudi']}, 'quiz': {'q': '"mardi" hangi gundur?', 'o': ['Sali', 'Persembe', 'Pazartesi', 'Cuma'], 'c': 0}, 'err': {'s': '"dimanche" Cumartesi demektir.', 'w': 'Cumartesi', 'f': 'Pazar'}},
        {'title': 'Mekanlar', 'pairs': [{'term': "l'ecole", 'definition': 'okul'}, {'term': 'la maison', 'definition': 'ev'}, {'term': "l'hopital", 'definition': 'hastane'}, {'term': 'le restaurant', 'definition': 'restoran'}], 'steps': ['Mekanin adini ogren', 'Artikelini belirle (le/la/l\')', 'Preposition ile kullan (a la, au, a l\')', 'Cumle icinde uygula (Je vais a l\'ecole)'], 'order_q': 'Fransizca mekan kelimesi ogrenme adimlarini sirala', 'fill': {'s': '"Kutuphane" Fransizca\'da _____ dir.', 'a': 'la bibliotheque', 'o': ['la bibliotheque', 'la librairie', 'le musee', 'le cinema']}, 'quiz': {'q': '"la gare" ne demektir?', 'o': ['Tren istasyonu', 'Okul', 'Hastane', 'Park'], 'c': 0}, 'err': {'s': '"la maison" okul demektir.', 'w': 'okul', 'f': 'ev'}},
        {'title': 'Soru Kelimeleri', 'pairs': [{'term': 'Qui?', 'definition': 'Kim?'}, {'term': 'Quoi?', 'definition': 'Ne?'}, {'term': 'Ou?', 'definition': 'Nerede?'}, {'term': 'Quand?', 'definition': 'Ne zaman?'}], 'steps': ['Soru kelimesini sec (Qui/Quoi/Ou...)', 'Est-ce que yapisini ekle', 'Fiil ve ozneyi yerlestir', 'Soru isareti ile bitir'], 'order_q': 'Fransizca soru cumlesi kurma adimlarini sirala', 'fill': {'s': '"Nasil?" sorusu Fransizca\'da _____ dir.', 'a': 'Comment?', 'o': ['Comment?', 'Combien?', 'Pourquoi?', 'Ou?']}, 'quiz': {'q': '"Pourquoi?" ne sorar?', 'o': ['Neden?', 'Nerede?', 'Ne zaman?', 'Nasil?'], 'c': 0}, 'err': {'s': '"Ou?" sorusu "ne zaman" anlamina gelir.', 'w': 'ne zaman', 'f': 'nerede'}},
      ],
    },
  ];

  // ── JAPONCA ─────────────────────────────────────────
  static final _jaUnits = <Map<String, dynamic>>[
    {
      'title': 'Japonca Alfabe: Hiragana',
      'topics': [
        {'title': 'Hiragana Unluler (a-i-u-e-o)', 'pairs': [{'term': 'あ', 'definition': 'a sesi'}, {'term': 'い', 'definition': 'i sesi'}, {'term': 'う', 'definition': 'u sesi'}, {'term': 'え', 'definition': 'e sesi'}], 'steps': ['あ (a)', 'い (i)', 'う (u)', 'え (e) ve お (o)'], 'order_q': 'Hiragana unluleri dogru sirada yaz', 'fill': {'s': 'Japonca\'da "o" sesi _____ karakteri ile yazilir.', 'a': 'お', 'o': ['お', 'あ', 'う', 'え']}, 'quiz': {'q': 'Hiragana alfabesinde kac temel karakter vardir?', 'o': ['46', '26', '52', '100'], 'c': 0}, 'err': {'s': 'Hiragana sadece yabanci kelimeler icin kullanilir.', 'w': 'yabanci', 'f': 'Japoncaya ozgu'}},
        {'title': 'Hiragana Ka-Ki-Ku-Ke-Ko', 'pairs': [{'term': 'か', 'definition': 'ka sesi'}, {'term': 'き', 'definition': 'ki sesi'}, {'term': 'く', 'definition': 'ku sesi'}, {'term': 'こ', 'definition': 'ko sesi'}], 'steps': ['か (ka)', 'き (ki)', 'く (ku)', 'け (ke) ve こ (ko)'], 'order_q': 'Ka sirasini dogru sirada yaz', 'fill': {'s': '"ki" sesi Hiragana\'da _____ olarak yazilir.', 'a': 'き', 'o': ['き', 'か', 'く', 'け']}, 'quiz': {'q': '"ke" sesini hangi karakter temsil eder?', 'o': ['け', 'き', 'か', 'こ'], 'c': 0}, 'err': {'s': 'か karakteri "ki" sesini verir.', 'w': 'ki', 'f': 'ka'}},
        {'title': 'Hiragana Sa-Shi-Su-Se-So', 'pairs': [{'term': 'さ', 'definition': 'sa sesi'}, {'term': 'し', 'definition': 'shi sesi'}, {'term': 'す', 'definition': 'su sesi'}, {'term': 'そ', 'definition': 'so sesi'}], 'steps': ['さ (sa)', 'し (shi)', 'す (su)', 'せ (se) ve そ (so)'], 'order_q': 'Sa sirasini dogru sirada yaz', 'fill': {'s': '"shi" sesi _____ karakteri ile gosterilir.', 'a': 'し', 'o': ['し', 'さ', 'す', 'せ']}, 'quiz': {'q': 'S sirasi neden duzensiz sayilir?', 'o': ['si yerine shi kullanilir', 'Eksik karakter var', 'Cok kolay', 'Hic kullanilmaz'], 'c': 0}, 'err': {'s': 'さ karakteri "su" sesini verir.', 'w': 'su', 'f': 'sa'}},
        {'title': 'Hiragana Ta-Chi-Tsu-Te-To', 'pairs': [{'term': 'た', 'definition': 'ta sesi'}, {'term': 'ち', 'definition': 'chi sesi'}, {'term': 'つ', 'definition': 'tsu sesi'}, {'term': 'と', 'definition': 'to sesi'}], 'steps': ['た (ta)', 'ち (chi)', 'つ (tsu)', 'て (te) ve と (to)'], 'order_q': 'Ta sirasini dogru sirada yaz', 'fill': {'s': '"chi" sesi _____ karakteri ile yazilir.', 'a': 'ち', 'o': ['ち', 'た', 'つ', 'て']}, 'quiz': {'q': 'T sirasinda hangi ses duzensizdir?', 'o': ['ti yerine chi ve tu yerine tsu', 'Hepsi duzenli', 'Sadece ta', 'Sadece to'], 'c': 0}, 'err': {'s': 'つ karakteri "tu" sesini verir.', 'w': 'tu', 'f': 'tsu'}},
        {'title': 'Hiragana Na-Ni-Nu-Ne-No', 'pairs': [{'term': 'な', 'definition': 'na sesi'}, {'term': 'に', 'definition': 'ni sesi'}, {'term': 'ぬ', 'definition': 'nu sesi'}, {'term': 'の', 'definition': 'no sesi'}], 'steps': ['な (na)', 'に (ni)', 'ぬ (nu)', 'ね (ne) ve の (no)'], 'order_q': 'Na sirasini dogru sirada yaz', 'fill': {'s': 'の karakteri gunluk Japonca\'da _____ anlaminda da kullanilir.', 'a': '-nin/-nun (iyelik eki)', 'o': ['-nin/-nun (iyelik eki)', 'degil', 'ile', 'icin']}, 'quiz': {'q': '"ne" sesini hangi karakter verir?', 'o': ['ね', 'な', 'ぬ', 'の'], 'c': 0}, 'err': {'s': 'に karakteri "na" sesini verir.', 'w': 'na', 'f': 'ni'}},
        {'title': 'Dakuten ve Handakuten', 'pairs': [{'term': 'が (ga)', 'definition': 'か + dakuten'}, {'term': 'ざ (za)', 'definition': 'さ + dakuten'}, {'term': 'だ (da)', 'definition': 'た + dakuten'}, {'term': 'ぱ (pa)', 'definition': 'は + handakuten'}], 'steps': ['Temel karakteri yaz (か, さ, た, は)', 'Dakuten (゛) veya handakuten (゜) ekle', 'Yeni sesi oku (ga, za, da, pa)', 'Kelime icinde kullan'], 'order_q': 'Dakuten/handakuten uygulama adimlarini sirala', 'fill': {'s': 'Dakuten isareti ekledigimizde か _____ olur.', 'a': 'が (ga)', 'o': ['が (ga)', 'ぎ (gi)', 'ぐ (gu)', 'ご (go)']}, 'quiz': {'q': 'Handakuten (maru) ne yapar?', 'o': ['h sesini p sesine cevirir', 'k sesini g yapar', 's sesini z yapar', 't sesini d yapar'], 'c': 0}, 'err': {'s': 'Dakuten isareti h sesini p ye cevirir.', 'w': 'Dakuten', 'f': 'Handakuten'}},
      ],
    },
    {
      'title': 'Japonca Temel Kelimeler',
      'topics': [
        {'title': 'Selamlasma', 'pairs': [{'term': 'こんにちは', 'definition': 'Merhaba (gun icinde)'}, {'term': 'おはようございます', 'definition': 'Gunaydin'}, {'term': 'こんばんは', 'definition': 'Iyi aksamlar'}, {'term': 'さようなら', 'definition': 'Hosca kal'}], 'steps': ['おはようございます (sabah)', 'こんにちは (gun icinde)', 'こんばんは (aksam)', 'おやすみなさい (gece)'], 'order_q': 'Japonca selamlamalari gun sirasina gore sirala', 'trans': {'s': 'こんにちは、お元気ですか？', 'a': 'Merhaba nasilsiniz', 'chips': ['Merhaba', 'nasilsiniz', 'hosca', 'kalin', 'iyi', 'geceler'], 'lang': 'ja-JP', 'q': 'Cumleyi Turkceye cevir'}, 'img': {'q': 'Hangisi "こんにちは" ile iliskili?', 'images': ['\ud83d\udc4b', '\ud83d\ude34', '\ud83c\udf1e', '\u2744\ufe0f'], 'labels': ['Selamlama', 'Uyku', 'Gunes', 'Kar'], 'c': 0}, 'fill': {'s': 'Japonca\'da "tesekkur ederim" demek icin _____ deriz.', 'a': 'ありがとうございます', 'o': ['ありがとうございます', 'すみません', 'おはよう', 'さようなら']}, 'quiz': {'q': '"すみません" ne anlama gelir?', 'o': ['Afedersiniz / Ozur dilerim', 'Merhaba', 'Tesekkurler', 'Hosca kal'], 'c': 0}, 'err': {'s': 'おはよう aksam selamidir.', 'w': 'aksam', 'f': 'sabah'}},
        {'title': 'Sayilar (1-10)', 'pairs': [{'term': 'いち (一)', 'definition': '1'}, {'term': 'に (二)', 'definition': '2'}, {'term': 'さん (三)', 'definition': '3'}, {'term': 'じゅう (十)', 'definition': '10'}], 'steps': ['いち (1) - さん (3)', 'し/よん (4) - ろく (6)', 'なな/しち (7) - きゅう (9)', 'じゅう (10)'], 'order_q': 'Japonca sayilari kucukten buyuge sirala', 'fill': {'s': 'Japonca\'da 5 sayisi _____ olarak soylenir.', 'a': 'ご (go)', 'o': ['ご (go)', 'く (ku)', 'し (shi)', 'ろく (roku)']}, 'quiz': {'q': '"なな" veya "しち" hangi sayidir?', 'o': ['7', '4', '6', '8'], 'c': 0}, 'err': {'s': 'し (shi) sayisi 7 demektir.', 'w': '7', 'f': '4'}},
        {'title': 'Gunler ve Zaman', 'pairs': [{'term': '今日 (きょう)', 'definition': 'bugun'}, {'term': '明日 (あした)', 'definition': 'yarin'}, {'term': '昨日 (きのう)', 'definition': 'dun'}, {'term': '今 (いま)', 'definition': 'simdi'}], 'steps': ['昨日 (dun)', '今日 (bugun)', '明日 (yarin)', '来週 (gelecek hafta)'], 'order_q': 'Japonca zaman ifadelerini kronolojik sirala', 'fill': {'s': '"Yarin" Japonca\'da _____ dir.', 'a': '明日 (あした)', 'o': ['明日 (あした)', '今日 (きょう)', '昨日 (きのう)', '来週 (らいしゅう)']}, 'quiz': {'q': '"今" (いま) ne demektir?', 'o': ['Simdi', 'Dun', 'Yarin', 'Sonra'], 'c': 0}, 'err': {'s': '昨日 yarin demektir.', 'w': 'yarin', 'f': 'dun'}},
        {'title': 'Temel Fiiller', 'pairs': [{'term': '食べる (taberu)', 'definition': 'yemek yemek'}, {'term': '飲む (nomu)', 'definition': 'icmek'}, {'term': '行く (iku)', 'definition': 'gitmek'}, {'term': '見る (miru)', 'definition': 'gormek/izlemek'}], 'steps': ['Fiil kokunu bul (taberu -> tabe)', 'Zaman ekini sec (masu formu)', 'Kibar hale getir: tabemasu', 'Olumsuz: tabemasen'], 'order_q': 'Japonca fiil cekimi adimlarini sirala', 'trans': {'s': '私は学校に行きます。', 'a': 'Ben okula gidiyorum', 'chips': ['Ben', 'okula', 'gidiyorum', 'geliyorum', 'eve', 'sen'], 'lang': 'ja-JP', 'q': 'Cumleyi Turkceye cevir'}, 'img': {'q': 'Hangisi "食べる"?', 'images': ['\ud83c\udf5c', '\ud83d\udca4', '\ud83d\udcda', '\ud83c\udfb5'], 'labels': ['Yemek', 'Uyumak', 'Okumak', 'Muzik'], 'c': 0}, 'fill': {'s': '"Gitmek" fiili Japonca\'da _____ dir.', 'a': '行く (iku)', 'o': ['行く (iku)', '来る (kuru)', '食べる (taberu)', '寝る (neru)']}, 'quiz': {'q': '"寝る" (neru) ne demektir?', 'o': ['Uyumak', 'Yemek', 'Kosmak', 'Okumak'], 'c': 0}, 'err': {'s': '飲む (nomu) yemek yemek demektir.', 'w': 'yemek yemek', 'f': 'icmek'}},
        {'title': 'Sifatlar', 'pairs': [{'term': '大きい (ookii)', 'definition': 'buyuk'}, {'term': '小さい (chiisai)', 'definition': 'kucuk'}, {'term': '新しい (atarashii)', 'definition': 'yeni'}, {'term': '古い (furui)', 'definition': 'eski'}], 'steps': ['i-sifat mi na-sifat mi belirle', 'i-sifat: sonu -i ile biter (ookii)', 'na-sifat: isimden once na eki alir', 'Cumle icinde kullan (Kono ie wa ookii desu)'], 'order_q': 'Japonca sifat kullanim adimlarini sirala', 'fill': {'s': '"Guzel" Japonca\'da _____ dir.', 'a': '美しい (utsukushii)', 'o': ['美しい (utsukushii)', '大きい (ookii)', '怖い (kowai)', '暑い (atsui)']}, 'quiz': {'q': '"暑い" (atsui) ne demektir?', 'o': ['Sicak', 'Soguk', 'Buyuk', 'Uzun'], 'c': 0}, 'err': {'s': '小さい buyuk demektir.', 'w': 'buyuk', 'f': 'kucuk'}},
        {'title': 'Aile Uyeleri', 'pairs': [{'term': 'お母さん (okaasan)', 'definition': 'anne'}, {'term': 'お父さん (otousan)', 'definition': 'baba'}, {'term': '兄 (ani)', 'definition': 'agabey'}, {'term': '姉 (ane)', 'definition': 'abla'}], 'steps': ['おじいさん/おばあさん (buyuk ebeveyn)', 'お父さん/お母さん (ebeveyn)', '兄/姉 (buyuk kardes)', '弟/妹 (kucuk kardes)'], 'order_q': 'Japonca aile uyelerini nesil/yas sirasina gore sirala', 'fill': {'s': '"Kiz kardes" Japonca\'da _____ dir.', 'a': '妹 (imouto)', 'o': ['妹 (imouto)', '姉 (ane)', '母 (haha)', '兄 (ani)']}, 'quiz': {'q': '"弟" (otouto) kimdir?', 'o': ['Erkek kardes (kucuk)', 'Agabey', 'Baba', 'Amca'], 'c': 0}, 'err': {'s': 'お父さん anne demektir.', 'w': 'anne', 'f': 'baba'}},
      ],
    },
  ];

  /// AI-uretilen plan'daki secenekleri karistir (correct_index randomize)
  static void _postProcessShuffleOptions(Map<String, dynamic> plan) {
    final units = plan['units'] as List?;
    if (units == null) return;
    for (final u in units) {
      final lessons = (u as Map<String, dynamic>)['lessons'] as List?;
      if (lessons == null) continue;
      for (final l in lessons) {
        final lesson = l as Map<String, dynamic>;
        final type = lesson['task_type'] as String?;
        final tc = lesson['task_content'] as Map<String, dynamic>?;
        if (tc == null) continue;
        final items = tc['items'] as List?;
        if (items == null) continue;
        for (final item in items) {
          final m = item as Map<String, dynamic>;
          if (type == 'tap_select') {
            final opts = m['options'] as List?;
            final idx = (m['correct_index'] as num?)?.toInt() ?? 0;
            if (opts != null && opts.length > 1 && idx < opts.length) {
              final correct = opts[idx];
              final shuffled = List<dynamic>.from(opts)..shuffle(_rng);
              m['options'] = shuffled;
              m['correct_index'] = shuffled.indexOf(correct);
            }
          } else if (type == 'fill_blank') {
            final opts = m['options'] as List?;
            if (opts != null && opts.length > 1) {
              final shuffled = List<dynamic>.from(opts)..shuffle(_rng);
              m['options'] = shuffled;
            }
          } else if (type == 'image_select') {
            final images = m['images'] as List?;
            final labels = m['labels'] as List?;
            final idx = (m['correct_index'] as num?)?.toInt() ?? 0;
            if (images != null && images.length > 1 && labels != null && labels.length == images.length && idx < images.length) {
              final indices = List.generate(images.length, (i) => i)..shuffle(_rng);
              m['images'] = indices.map((i) => images[i]).toList();
              m['labels'] = indices.map((i) => labels[i]).toList();
              m['correct_index'] = indices.indexOf(idx);
            }
          }
        }
      }
    }
  }

  // Diger diller icin basit yonlendirmeler (AI uretecek, fallback minimal)
  static final _esUnits = _jaUnits; // placeholder - AI uretecek
  static final _zhUnits = _jaUnits;
  static final _koUnits = _jaUnits;
  static final _itUnits = _jaUnits;
  static final _arUnits = _jaUnits;
  static final _ruUnits = _jaUnits;

  // ── Genel konu fallback (matematik yerine) ──────────
  static List<Map<String, dynamic>> _genericSubjectUnits(String subject) {
    return [
      {
        'title': '$subject - Temel Kavramlar',
        'topics': [
          {'title': '$subject Giris', 'pairs': [{'term': 'Kavram 1', 'definition': '$subject temel terimi'}, {'term': 'Kavram 2', 'definition': '$subject ikincil terimi'}, {'term': 'Kavram 3', 'definition': '$subject ucuncul terimi'}, {'term': 'Kavram 4', 'definition': '$subject dorduncul terimi'}], 'steps': ['Konuyu tani ve amacini ogren', 'Temel kavramlari listele', 'Kavramlar arasi iliskileri bul', 'Ozet cikar ve tekrar et'], 'order_q': '$subject giris konusunu ogrenme adimlarini sirala', 'fill': {'s': '$subject alaninda en temel kavram _____ dir.', 'a': 'temel prensip', 'o': ['temel prensip', 'ileri analiz', 'rastgele veri', 'bos bilgi']}, 'quiz': {'q': '$subject ogrenmede ilk adim nedir?', 'o': ['Temel kavramlari anlamak', 'Dogrudan ileri konulara gecmek', 'Sadece ezberlemek', 'Hicbir sey yapmamak'], 'c': 0}, 'err': {'s': '$subject ogrenmek icin on bilgi gerekmez.', 'w': 'gerekmez', 'f': 'gerekir'}},
          {'title': '$subject Tarihce', 'pairs': [{'term': 'Kurucu', 'definition': '$subject alaninin oncusu'}, {'term': 'Donem', 'definition': 'Gelisim sureci'}, {'term': 'Etki', 'definition': 'Toplumsal katkisi'}, {'term': 'Gelecek', 'definition': 'Gelisim yonu'}], 'steps': ['Alanin dogusunu ogren', 'Onemli kisileri ve kesflerini listele', 'Gelisim donemlerini kronolojik sirala', 'Gunumuze etkisini degerlend'], 'order_q': '$subject tarihce ogrenme adimlarini sirala', 'fill': {'s': '$subject alani _____ sayesinde gelismistir.', 'a': 'arastirma ve uygulama', 'o': ['arastirma ve uygulama', 'tesadufi olaylar', 'tek kisi', 'sadece teori']}, 'quiz': {'q': '$subject alaninin onemi nedir?', 'o': ['Bilgi ve beceri kazandirmasi', 'Sadece akademik deger', 'Hicbir onemi yok', 'Sadece sinav icin'], 'c': 0}, 'err': {'s': '$subject sadece teorik bir alandir.', 'w': 'sadece teorik', 'f': 'hem teorik hem pratik'}},
          {'title': '$subject Metodoloji', 'pairs': [{'term': 'Analiz', 'definition': 'Detayli inceleme'}, {'term': 'Sentez', 'definition': 'Birlestirme ve yeni olusturma'}, {'term': 'Uygulama', 'definition': 'Pratikte kullanma'}, {'term': 'Degerlendirme', 'definition': 'Sonuc cikarma'}], 'steps': ['Problem veya soruyu tanimla', 'Kaynak ve veri topla', 'Analiz yap ve sonuc cikar', 'Sonucu degerlendir ve raporla'], 'order_q': '$subject arastirma metodoloji adimlarini sirala', 'fill': {'s': '$subject alaninda basarili olmak icin _____ gerekir.', 'a': 'duzenli calisma', 'o': ['duzenli calisma', 'sadece okuma', 'hic pratik yapmama', 'rastgele calismak']}, 'quiz': {'q': 'En etkili ogrenme yontemi hangisidir?', 'o': ['Aktif katilim ve uygulama', 'Pasif dinleme', 'Sadece not alma', 'Sadece izleme'], 'c': 0}, 'err': {'s': '$subject icin pratik onemsizdir.', 'w': 'onemsizdir', 'f': 'cok onemlidir'}},
          {'title': '$subject Temel Ilkeler', 'pairs': [{'term': 'Ilke 1', 'definition': 'Temel kural'}, {'term': 'Ilke 2', 'definition': 'Yardimci kural'}, {'term': 'Ilke 3', 'definition': 'Uygulama kurali'}, {'term': 'Ilke 4', 'definition': 'Degerlendirme kurali'}], 'steps': ['Temel ilkeyi oku ve anla', 'Orneklerle pekistir', 'Farkli baglamlarda uygula', 'Ozet cikar ve icsellelestir'], 'order_q': '$subject temel ilke ogrenme adimlarini sirala', 'fill': {'s': 'Her alanin temel _____ vardir.', 'a': 'ilkeleri', 'o': ['ilkeleri', 'sorulari', 'cevaplari', 'sinavlari']}, 'quiz': {'q': '$subject icin en onemli beceri nedir?', 'o': ['Elestirel dusunme', 'Ezberleme', 'Hiz', 'Tesadufe birakmak'], 'c': 0}, 'err': {'s': 'Ilkeler her zaman degisir.', 'w': 'degisir', 'f': 'sabit kalir'}},
          {'title': '$subject Uygulamalari', 'pairs': [{'term': 'Gunluk kullanim', 'definition': 'Hayatta uygulama'}, {'term': 'Profesyonel', 'definition': 'Is hayatinda kullanim'}, {'term': 'Akademik', 'definition': 'Arastirma alani'}, {'term': 'Sosyal', 'definition': 'Toplumsal etki'}], 'steps': ['Teorik bilgiyi ogren', 'Gunluk hayata uyarla', 'Pratik ornekler uzerinde calis', 'Sonuclari degerlendir ve gelistir'], 'order_q': '$subject uygulama adimlarini sirala', 'fill': {'s': '$subject _____ hayatta kullanilir.', 'a': 'gunluk', 'o': ['gunluk', 'sadece akademik', 'hicbir zaman', 'nadiren']}, 'quiz': {'q': '$subject bilgisi nerede ise yarar?', 'o': ['Birçok alanda', 'Sadece okulda', 'Hicbir yerde', 'Sadece sinavda'], 'c': 0}, 'err': {'s': '$subject sadece sinav icin ogrenilir.', 'w': 'sadece sinav icin', 'f': 'hayat boyu'}},
          {'title': '$subject Kaynaklar', 'pairs': [{'term': 'Kitap', 'definition': 'Temel kaynak'}, {'term': 'Video', 'definition': 'Gorsel kaynak'}, {'term': 'Uygulama', 'definition': 'Pratik yapma araci'}, {'term': 'Topluluk', 'definition': 'Birlikte ogrenme'}], 'steps': ['Guvenilir kaynaklari ara', 'Kitap ve makale ile temel ogren', 'Video ve uygulama ile pekistir', 'Topluluk ve tartismalarla derinlestir'], 'order_q': '$subject kaynak kullanim adimlarini sirala', 'fill': {'s': 'En etkili ogrenme _____ kaynak kullanarak olur.', 'a': 'cesitli', 'o': ['cesitli', 'tek', 'sifir', 'pahali']}, 'quiz': {'q': 'Kaynak secerken neye dikkat edilmeli?', 'o': ['Guvenilirlik ve guncellik', 'Sadece fiyat', 'Sadece uzunluk', 'Rastgele secmek'], 'c': 0}, 'err': {'s': 'Tek kaynak her zaman yeterlidir.', 'w': 'yeterlidir', 'f': 'yetersizdir'}},
        ],
      },
    ];
  }
}
