class PlacementQuestions {
  PlacementQuestions._();

  static List<Map<String, dynamic>> forSubject(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('alman')) return _german;
    if (s.contains('frans')) return _french;
    if (s.contains('ingil') || s.contains('english')) return _english;
    if (s.contains('matematik') || s.contains('math')) return _math;
    if (s.contains('fizik') || s.contains('physics')) return _physics;
    if (s.contains('kimya') || s.contains('chem')) return _chemistry;
    if (s.contains('biyoloji') || s.contains('bio')) return _biology;
    if (s.contains('yazilim') || s.contains('programlama') || s.contains('kod')) return _software;
    if (s.contains('python')) return _python;
    if (s.contains('java') && !s.contains('javascript')) return _java;
    if (s.contains('javascript') || s.contains('js')) return _javascript;
    if (s.contains('tarih')) return _history;
    if (s.contains('cogra')) return _geography;
    if (s.contains('ekonomi') || s.contains('finans')) return _economics;
    return _generic(subject);
  }

  // ── ALMANCA ──────────────────────────────────────────
  static const _german = <Map<String, dynamic>>[
    {'q': '"Guten Morgen" ne demektir?', 'options': ['Iyi aksamlar', 'Gunaydin', 'Iyi geceler', 'Hosca kal'], 'answer': 1, 'difficulty': 'easy'},
    {'q': 'Almanca\'da "Ich bin" ne anlama gelir?', 'options': ['Sen var', 'O gidiyor', 'Ben ...im/...yim', 'Biz istiyoruz'], 'answer': 2, 'difficulty': 'easy'},
    {'q': '"Der Hund" hangi hayvandir?', 'options': ['Kedi', 'Kopek', 'Kus', 'Balik'], 'answer': 1, 'difficulty': 'easy'},
    {'q': 'Almanca\'da artikeller hangileridir?', 'options': ['le, la, les', 'the, a, an', 'der, die, das', 'el, la, los'], 'answer': 2, 'difficulty': 'medium'},
    {'q': '"Ich habe Hunger" ne demektir?', 'options': ['Yorgunum', 'Acim var', 'Mutluyum', 'Susuzum'], 'answer': 1, 'difficulty': 'medium'},
    {'q': '"Wo ist die Schule?" cumlesinde "Wo" ne sorar?', 'options': ['Ne zaman', 'Nasil', 'Nerede', 'Kim'], 'answer': 2, 'difficulty': 'medium'},
    {'q': '"Er spricht Deutsch" cumlesinde fiil hangisidir?', 'options': ['Er', 'spricht', 'Deutsch', 'Hicbiri'], 'answer': 1, 'difficulty': 'hard'},
    {'q': 'Almanca\'da Perfekt (gecmis zaman) icin yardimci fiil hangisidir?', 'options': ['werden', 'haben / sein', 'mussen', 'konnen'], 'answer': 1, 'difficulty': 'hard'},
  ];

  // ── FRANSIZCA ────────────────────────────────────────
  static const _french = <Map<String, dynamic>>[
    {'q': '"Bonjour" ne demektir?', 'options': ['Iyi aksamlar', 'Merhaba / Gunaydin', 'Hosca kal', 'Tesekkurler'], 'answer': 1, 'difficulty': 'easy'},
    {'q': '"Je suis" ne anlama gelir?', 'options': ['Sen var', 'Ben ...im/...yim', 'O gidiyor', 'Biz biliyoruz'], 'answer': 1, 'difficulty': 'easy'},
    {'q': 'Fransizca\'da "chat" hangi hayvandir?', 'options': ['Kopek', 'Kus', 'Kedi', 'At'], 'answer': 2, 'difficulty': 'easy'},
    {'q': '"Les" artikeli ne tur isimler icin kullanilir?', 'options': ['Tekil erkek', 'Tekil disi', 'Cogul', 'Belirsiz'], 'answer': 2, 'difficulty': 'medium'},
    {'q': '"Qu\'est-ce que c\'est?" ne sorar?', 'options': ['Nasil?', 'Bu nedir?', 'Ne zaman?', 'Nereye?'], 'answer': 1, 'difficulty': 'medium'},
    {'q': '"Il fait beau" ne anlatir?', 'options': ['Hasta', 'Hava guzel', 'Gec kaldi', 'Yorgun'], 'answer': 1, 'difficulty': 'medium'},
    {'q': '"Aller" fiilinin "je" ile cekimi nedir?', 'options': ['je alle', 'je vais', 'je va', 'je aller'], 'answer': 1, 'difficulty': 'hard'},
    {'q': 'Passe compose icin yardimci fiil hangisidir?', 'options': ['faire', 'avoir / etre', 'aller', 'venir'], 'answer': 1, 'difficulty': 'hard'},
  ];

  // ── INGILIZCE ────────────────────────────────────────
  static const _english = <Map<String, dynamic>>[
    {'q': '"She goes to school" cumlesinde neden "goes" kullanilir?', 'options': ['Gecmis zaman', '3. tekil sahis -s takisi', 'Gelecek zaman', 'Edilgen cati'], 'answer': 1, 'difficulty': 'easy'},
    {'q': '"I have been waiting" hangi zamandir?', 'options': ['Simple Past', 'Present Perfect Continuous', 'Future Simple', 'Past Perfect'], 'answer': 1, 'difficulty': 'medium'},
    {'q': '"Brought" hangi fiilin gecmis halidir?', 'options': ['break', 'bring', 'buy', 'build'], 'answer': 1, 'difficulty': 'easy'},
    {'q': '"Despite" kelimesinden sonra ne gelir?', 'options': ['Fiil', 'Isim / gerund', 'Sifat', 'Zamir'], 'answer': 1, 'difficulty': 'medium'},
    {'q': '"If I were you, I would..." hangi conditional?', 'options': ['Zero', 'First', 'Second', 'Third'], 'answer': 2, 'difficulty': 'medium'},
    {'q': '"The book which I read" cumlesinde "which" ne ise yarar?', 'options': ['Soru sorar', 'Relative clause baslatir', 'Olumsuzluk yapar', 'Zaman belirtir'], 'answer': 1, 'difficulty': 'medium'},
    {'q': '"Had I known, I would have helped." Bu ne tur bir yapidir?', 'options': ['Reported speech', 'Inversion', 'Passive voice', 'Gerund'], 'answer': 1, 'difficulty': 'hard'},
    {'q': '"Ubiquitous" kelimesinin anlami nedir?', 'options': ['Nadir', 'Her yerde bulunan', 'Belirsiz', 'Gizli'], 'answer': 1, 'difficulty': 'hard'},
  ];

  // ── MATEMATIK ────────────────────────────────────────
  static const _math = <Map<String, dynamic>>[
    {'q': '15 + 27 kactir?', 'options': ['41', '42', '43', '52'], 'answer': 1, 'difficulty': 'easy'},
    {'q': 'Bir ucgenin ic acilarinin toplami kac derecedir?', 'options': ['90', '180', '270', '360'], 'answer': 1, 'difficulty': 'easy'},
    {'q': '2^5 (2 uzeri 5) kactir?', 'options': ['10', '25', '32', '64'], 'answer': 2, 'difficulty': 'easy'},
    {'q': '12 ve 18 in EBOB degeri kactir?', 'options': ['3', '6', '12', '36'], 'answer': 1, 'difficulty': 'medium'},
    {'q': 'x² - 9 = 0 denkleminin kokleri nelerdir?', 'options': ['3 ve -3', '9 ve -9', '0 ve 9', '3 ve 0'], 'answer': 0, 'difficulty': 'medium'},
    {'q': 'log₂(8) kactir?', 'options': ['2', '3', '4', '8'], 'answer': 1, 'difficulty': 'medium'},
    {'q': 'Turev: d/dx (x³) = ?', 'options': ['x²', '3x²', '3x', 'x³'], 'answer': 1, 'difficulty': 'hard'},
    {'q': '∫ 2x dx = ?', 'options': ['x²', 'x² + C', '2x²', '2x² + C'], 'answer': 1, 'difficulty': 'hard'},
  ];

  // ── FIZIK ────────────────────────────────────────────
  static const _physics = <Map<String, dynamic>>[
    {'q': 'Newton\'un 2. yasasi nedir?', 'options': ['F = m × a', 'E = mc²', 'P = m × v', 'W = F × d'], 'answer': 0, 'difficulty': 'easy'},
    {'q': 'Serbest dusmede ivme yaklasik kac m/s² dir?', 'options': ['5', '10', '15', '20'], 'answer': 1, 'difficulty': 'easy'},
    {'q': 'Isik hizi yaklasik kac km/s dir?', 'options': ['30.000', '300.000', '3.000.000', '300'], 'answer': 1, 'difficulty': 'easy'},
    {'q': 'Kinetik enerji formulu nedir?', 'options': ['mgh', '½mv²', 'Fd', 'mv'], 'answer': 1, 'difficulty': 'medium'},
    {'q': 'Ohm yasasina gore V = ?', 'options': ['I / R', 'I × R', 'R / I', 'I + R'], 'answer': 1, 'difficulty': 'medium'},
    {'q': 'Dalga hizi = dalga boyu × ?', 'options': ['Genlik', 'Frekans', 'Periyot', 'Ivme'], 'answer': 1, 'difficulty': 'medium'},
    {'q': 'Termodinamigin 1. yasasi neyi ifade eder?', 'options': ['Entropi artar', 'Enerji korunur', 'Isik hizi sabittir', 'Kutle korunur'], 'answer': 1, 'difficulty': 'hard'},
    {'q': 'Heisenberg Belirsizlik Ilkesi neyi soyler?', 'options': ['Enerji ve kutle esittir', 'Konum ve momentum ayni anda kesin olculemez', 'Isik hem dalga hem parcaciktir', 'Entropi azalmaz'], 'answer': 1, 'difficulty': 'hard'},
  ];

  // ── KIMYA ────────────────────────────────────────────
  static const _chemistry = <Map<String, dynamic>>[
    {'q': 'Suyun kimyasal formulu nedir?', 'options': ['CO₂', 'H₂O', 'NaCl', 'O₂'], 'answer': 1, 'difficulty': 'easy'},
    {'q': 'Periyodik tablodaki ilk element hangisidir?', 'options': ['Helyum', 'Hidrojen', 'Lityum', 'Karbon'], 'answer': 1, 'difficulty': 'easy'},
    {'q': 'pH degeri 7 olan cozelti nasil tanimlanir?', 'options': ['Asidik', 'Bazik', 'Notr', 'Tuzlu'], 'answer': 2, 'difficulty': 'easy'},
    {'q': 'Avogadro sayisi yaklasik kactir?', 'options': ['6.02 × 10²³', '3.14 × 10⁸', '1.6 × 10⁻¹⁹', '9.8 × 10¹'], 'answer': 0, 'difficulty': 'medium'},
    {'q': 'Kovalent bag nedir?', 'options': ['Elektron aktarimi', 'Elektron paylasimi', 'Iyon cekimi', 'Metalik bag'], 'answer': 1, 'difficulty': 'medium'},
    {'q': 'Ideal gaz denkleminde PV = ?', 'options': ['mRT', 'nRT', 'kT', 'nRV'], 'answer': 1, 'difficulty': 'medium'},
    {'q': 'Oksidasyon nedir?', 'options': ['Elektron kazanma', 'Elektron kaybetme', 'Proton kazanma', 'Notron kaybetme'], 'answer': 1, 'difficulty': 'hard'},
    {'q': 'Le Chatelier ilkesi neyi aciklar?', 'options': ['Atom yapisi', 'Dengeye etki eden degisimler', 'Radyoaktif bozunma', 'Isik kirilmasi'], 'answer': 1, 'difficulty': 'hard'},
  ];

  // ── BIYOLOJI ─────────────────────────────────────────
  static const _biology = <Map<String, dynamic>>[
    {'q': 'Hucrenin enerji ureticisi hangisidir?', 'options': ['Ribozom', 'Mitokondri', 'Golgi', 'Lizozom'], 'answer': 1, 'difficulty': 'easy'},
    {'q': 'DNA\'nin acilimi nedir?', 'options': ['Deoksiribonukleik Asit', 'Diribonukleik Asit', 'Dinamik Nukleer Asit', 'Deoksijen Asit'], 'answer': 0, 'difficulty': 'easy'},
    {'q': 'Fotosentez hangi organelde gerceklesir?', 'options': ['Mitokondri', 'Ribozom', 'Kloroplast', 'Cekirdek'], 'answer': 2, 'difficulty': 'easy'},
    {'q': 'Insan vuucudunda kac cift kromozom vardir?', 'options': ['22', '23', '46', '24'], 'answer': 1, 'difficulty': 'medium'},
    {'q': 'Mitoz bolunmede kac yeni hucre olusur?', 'options': ['1', '2', '4', '8'], 'answer': 1, 'difficulty': 'medium'},
    {'q': 'Hangisi bir bakteri ozelligi degildir?', 'options': ['Prokaryot', 'Cekirdeksiz', 'Cok hucreli', 'Hucre duvari var'], 'answer': 2, 'difficulty': 'medium'},
    {'q': 'Hardy-Weinberg dengesi ne ile ilgilidir?', 'options': ['Hucre bolunmesi', 'Populasyon genetigi', 'Sinir sistemi', 'Sindirim'], 'answer': 1, 'difficulty': 'hard'},
    {'q': 'Krebs dongusu nerede gerceklesir?', 'options': ['Sitoplazma', 'Mitokondri matriks', 'Ribozom', 'Cekirdek'], 'answer': 1, 'difficulty': 'hard'},
  ];

  // ── YAZILIM / PROGRAMLAMA ────────────────────────────
  static const _software = <Map<String, dynamic>>[
    {'q': 'Hangisi bir programlama dilidir?', 'options': ['HTML', 'Python', 'CSS', 'SQL'], 'answer': 1, 'difficulty': 'easy'},
    {'q': '"if-else" yapisi ne ise yarar?', 'options': ['Dongu olusturur', 'Kosullu dallanma yapar', 'Fonksiyon tanimlar', 'Dizi olusturur'], 'answer': 1, 'difficulty': 'easy'},
    {'q': 'Dizilerde (array) ilk elemanin index\'i kactir?', 'options': ['1', '0', '-1', '10'], 'answer': 1, 'difficulty': 'easy'},
    {'q': 'OOP\'de "encapsulation" ne demektir?', 'options': ['Kalitim', 'Cok bicimlilik', 'Kapsulleme', 'Soyutlama'], 'answer': 2, 'difficulty': 'medium'},
    {'q': 'Big-O notasyonunda O(n) ne anlama gelir?', 'options': ['Sabit zaman', 'Dogrusal zaman', 'Logaritmik zaman', 'Karesel zaman'], 'answer': 1, 'difficulty': 'medium'},
    {'q': 'Stack veri yapisinda hangi prensip gecerlidir?', 'options': ['FIFO', 'LIFO', 'Random', 'Priority'], 'answer': 1, 'difficulty': 'medium'},
    {'q': 'Binary search\'un zaman karmasikligi nedir?', 'options': ['O(n)', 'O(log n)', 'O(n²)', 'O(1)'], 'answer': 1, 'difficulty': 'hard'},
    {'q': 'SOLID\'deki "S" prensibi nedir?', 'options': ['Security', 'Single Responsibility', 'Scalability', 'Simplicity'], 'answer': 1, 'difficulty': 'hard'},
  ];

  // ── PYTHON ───────────────────────────────────────────
  static const _python = <Map<String, dynamic>>[
    {'q': 'Python\'da yorum satiri hangi isaretle baslar?', 'options': ['//', '#', '--', '/*'], 'answer': 1, 'difficulty': 'easy'},
    {'q': 'print("Merhaba") ne yapar?', 'options': ['Dosya olusturur', 'Ekrana yazar', 'Degisken tanimlar', 'Dongu baslatir'], 'answer': 1, 'difficulty': 'easy'},
    {'q': 'Python\'da liste olusturmak icin hangi sembol kullanilir?', 'options': ['{}', '()', '[]', '<>'], 'answer': 2, 'difficulty': 'easy'},
    {'q': 'len([1,2,3]) sonucu nedir?', 'options': ['2', '3', '6', 'Hata'], 'answer': 1, 'difficulty': 'medium'},
    {'q': '"def" anahtar kelimesi ne yapar?', 'options': ['Degisken tanimlar', 'Fonksiyon tanimlar', 'Sinif tanimlar', 'Dongu baslatir'], 'answer': 1, 'difficulty': 'medium'},
    {'q': 'Dictionary\'de erisim nasil yapilir?', 'options': ['dict[index]', 'dict.get(key)', 'dict(key)', 'dict->key'], 'answer': 1, 'difficulty': 'medium'},
    {'q': 'List comprehension ornegi hangisidir?', 'options': ['for x in list', '[x for x in list]', 'list.map(x)', 'map(x, list)'], 'answer': 1, 'difficulty': 'hard'},
    {'q': 'Python\'da decorator (@) ne ise yarar?', 'options': ['Yorum ekler', 'Fonksiyonu sarar/degistirir', 'Tip belirtir', 'Hata yakalar'], 'answer': 1, 'difficulty': 'hard'},
  ];

  // ── JAVA ─────────────────────────────────────────────
  static const _java = <Map<String, dynamic>>[
    {'q': 'Java\'da "public static void main" ne ise yarar?', 'options': ['Sinif tanimlar', 'Programin giris noktasi', 'Degisken tanimlar', 'Paket import eder'], 'answer': 1, 'difficulty': 'easy'},
    {'q': 'Java\'da String degismez (immutable) midir?', 'options': ['Evet', 'Hayir', 'Bazen', 'Sadece final ise'], 'answer': 0, 'difficulty': 'easy'},
    {'q': 'System.out.println() ne yapar?', 'options': ['Dosya okur', 'Ekrana yazar', 'Hata firlatir', 'Dongu calistirir'], 'answer': 1, 'difficulty': 'easy'},
    {'q': '"extends" anahtar kelimesi ne ise yarar?', 'options': ['Interface uygular', 'Sinif miras alir', 'Paket ekler', 'Hata yakalar'], 'answer': 1, 'difficulty': 'medium'},
    {'q': 'ArrayList ile Array arasindaki fark nedir?', 'options': ['Fark yok', 'ArrayList dinamik boyutlu', 'Array dinamik boyutlu', 'ArrayList sadece int tutar'], 'answer': 1, 'difficulty': 'medium'},
    {'q': 'try-catch-finally blogu ne ise yarar?', 'options': ['Dongu kontrol', 'Hata yonetimi', 'Bellek temizleme', 'Thread olusturma'], 'answer': 1, 'difficulty': 'medium'},
    {'q': 'Java\'da Garbage Collector ne yapar?', 'options': ['Kod derler', 'Kullanilmayan nesneleri siler', 'Dosya yonetir', 'Thread olusturur'], 'answer': 1, 'difficulty': 'hard'},
    {'q': 'Java Generics (<T>) ne saglar?', 'options': ['Performans', 'Tip guvenligi', 'Coklu miras', 'Polimorfizm'], 'answer': 1, 'difficulty': 'hard'},
  ];

  // ── JAVASCRIPT ───────────────────────────────────────
  static const _javascript = <Map<String, dynamic>>[
    {'q': 'JavaScript\'te degisken tanimlamak icin hangi anahtar kelime kullanilir?', 'options': ['var / let / const', 'int / str', 'dim / set', 'define / declare'], 'answer': 0, 'difficulty': 'easy'},
    {'q': 'console.log("test") ne yapar?', 'options': ['Dosya olusturur', 'Konsola yazar', 'Sayfa yeniler', 'Alert gosterir'], 'answer': 1, 'difficulty': 'easy'},
    {'q': '"===" operatoru ne kontrol eder?', 'options': ['Sadece deger', 'Deger ve tip', 'Sadece tip', 'Referans'], 'answer': 1, 'difficulty': 'easy'},
    {'q': 'Arrow function sozdizimi hangisidir?', 'options': ['function() {}', '() => {}', 'fn() {}', 'lambda() {}'], 'answer': 1, 'difficulty': 'medium'},
    {'q': 'Promise ne ise yarar?', 'options': ['DOM manipulasyonu', 'Asenkron islem yonetimi', 'CSS degistirme', 'Degisken tanimlama'], 'answer': 1, 'difficulty': 'medium'},
    {'q': '"null" ile "undefined" arasindaki fark nedir?', 'options': ['Fark yok', 'null kasitli bos, undefined atanmamis', 'undefined kasitli bos', 'Ikisi de hata'], 'answer': 1, 'difficulty': 'medium'},
    {'q': 'Closure nedir?', 'options': ['Bir dongu turu', 'Fonksiyonun dis scope\'a erisimi', 'Hata yonetimi', 'DOM eventi'], 'answer': 1, 'difficulty': 'hard'},
    {'q': 'Event loop ne yapar?', 'options': ['DOM gunceller', 'Asenkron gorevleri siralar', 'CSS render eder', 'HTTP istegi gonderir'], 'answer': 1, 'difficulty': 'hard'},
  ];

  // ── TARIH ────────────────────────────────────────────
  static const _history = <Map<String, dynamic>>[
    {'q': 'Istanbul\'un fethi hangi yilda gerceklesti?', 'options': ['1071', '1299', '1453', '1923'], 'answer': 2, 'difficulty': 'easy'},
    {'q': 'Turkiye Cumhuriyeti hangi yil ilan edildi?', 'options': ['1919', '1920', '1922', '1923'], 'answer': 3, 'difficulty': 'easy'},
    {'q': 'Birinci Dunya Savasi hangi yillar arasinda yasandi?', 'options': ['1905-1910', '1914-1918', '1939-1945', '1950-1953'], 'answer': 1, 'difficulty': 'easy'},
    {'q': 'Malazgirt Savasi\'nin onemi nedir?', 'options': ['Istanbul fethinin yolu acildi', 'Anadolu\'nun kapisi acildi', 'Cumhuriyet ilan edildi', 'Sanayi devrimi basladi'], 'answer': 1, 'difficulty': 'medium'},
    {'q': 'Magna Carta hangi ulkede imzalandi?', 'options': ['Fransa', 'Ingiltere', 'Almanya', 'Ispanya'], 'answer': 1, 'difficulty': 'medium'},
    {'q': 'Sanayi Devrimi ilk nerede basladi?', 'options': ['ABD', 'Fransa', 'Ingiltere', 'Almanya'], 'answer': 2, 'difficulty': 'medium'},
    {'q': 'Soguk Savas hangi iki guc arasinda yasandi?', 'options': ['ABD-Cin', 'ABD-SSCB', 'Ingiltere-Fransa', 'Almanya-Rusya'], 'answer': 1, 'difficulty': 'hard'},
    {'q': 'Vestfalya Antlasmasi (1648) neyi degistirdi?', 'options': ['Sinir sistemi', 'Ulus-devlet kavrami', 'Sanayi uretimi', 'Deniz ticareti'], 'answer': 1, 'difficulty': 'hard'},
  ];

  // ── COGRAFYA ─────────────────────────────────────────
  static const _geography = <Map<String, dynamic>>[
    {'q': 'Dunya\'nin en buyuk okyanusu hangisidir?', 'options': ['Atlantik', 'Hint', 'Pasifik', 'Arktik'], 'answer': 2, 'difficulty': 'easy'},
    {'q': 'Turkiye hangi iki kita arasinda yer alir?', 'options': ['Avrupa-Afrika', 'Avrupa-Asya', 'Asya-Afrika', 'Avrupa-Amerika'], 'answer': 1, 'difficulty': 'easy'},
    {'q': 'Nil Nehri hangi kitadadir?', 'options': ['Asya', 'Avrupa', 'Afrika', 'Guney Amerika'], 'answer': 2, 'difficulty': 'easy'},
    {'q': 'Ekvatorda mevsimler nasil yasanir?', 'options': ['4 mevsim belirgin', 'Yaz ve kis belirgin', 'Yil boyu sicak ve yagisli', 'Yil boyu soguk'], 'answer': 2, 'difficulty': 'medium'},
    {'q': 'Ruzgarin yonu neye gore belirlenir?', 'options': ['Yukseklik', 'Basinc farki', 'Sicaklik', 'Nem'], 'answer': 1, 'difficulty': 'medium'},
    {'q': 'Plakalarin hareketiyle olusan olay hangisidir?', 'options': ['Yagmur', 'Deprem', 'Ruzgar', 'Gel-git'], 'answer': 1, 'difficulty': 'medium'},
    {'q': 'Karstik araziler hangi kayac turunde olusur?', 'options': ['Granit', 'Kalker', 'Bazalt', 'Mermer'], 'answer': 1, 'difficulty': 'hard'},
    {'q': 'Coriolis etkisi neyi etkiler?', 'options': ['Deprem', 'Ruzgar ve akintilar', 'Volkan', 'Yagis'], 'answer': 1, 'difficulty': 'hard'},
  ];

  // ── EKONOMI / FINANS ─────────────────────────────────
  static const _economics = <Map<String, dynamic>>[
    {'q': 'Arz ve talep dengesi neyi belirler?', 'options': ['Uretim hizi', 'Fiyat', 'Kalite', 'Reklam'], 'answer': 1, 'difficulty': 'easy'},
    {'q': 'Enflasyon ne demektir?', 'options': ['Fiyatlarin dusmesi', 'Fiyatlarin artmasi', 'Uretin artmasi', 'Issizlik'], 'answer': 1, 'difficulty': 'easy'},
    {'q': 'GDP (GSYIH) neyi olcer?', 'options': ['Nufus', 'Toplam uretim degeri', 'Issizlik', 'Ihracat'], 'answer': 1, 'difficulty': 'easy'},
    {'q': 'Merkez bankasinin temel gorevi nedir?', 'options': ['Vergi toplamak', 'Para politikasi yurutmek', 'Ithalat yapmak', 'Borse yonetmek'], 'answer': 1, 'difficulty': 'medium'},
    {'q': 'Firsat maliyeti ne demektir?', 'options': ['En dusuk maliyet', 'Vazgecilen en iyi alternatif', 'Uretim maliyeti', 'Tasima maliyeti'], 'answer': 1, 'difficulty': 'medium'},
    {'q': 'Monopol piyasada kac satici vardir?', 'options': ['Cok', 'Tek', 'Iki', 'Birkac'], 'answer': 1, 'difficulty': 'medium'},
    {'q': 'Phillips egrisi neyi gosterir?', 'options': ['Arz-talep', 'Enflasyon-issizlik iliskisi', 'Faiz-kur', 'Gelir dagilimi'], 'answer': 1, 'difficulty': 'hard'},
    {'q': 'Likidite tuzagi ne demektir?', 'options': ['Yuksek enflasyon', 'Faiz oranlarinin dusurulememesi', 'Borse cokmesi', 'Kur krizi'], 'answer': 1, 'difficulty': 'hard'},
  ];

  // ── GENEL (bilinmeyen konu) ──────────────────────────
  static List<Map<String, dynamic>> _generic(String subject) {
    return [
      {'q': '$subject konusunda temel kavramlar neden onemlidir?', 'options': ['Ileri konulara zemin hazirlar', 'Gereksizdir', 'Sadece sinav icin', 'Onemsiz'], 'answer': 0, 'difficulty': 'easy'},
      {'q': 'Etkili ogrenmenin ilk adimi nedir?', 'options': ['Ezberlemek', 'Kavramlari anlamak', 'Hizli okumak', 'Not almamak'], 'answer': 1, 'difficulty': 'easy'},
      {'q': 'Bir konuyu derinlemesine ogrenmek icin en iyi yontem hangisidir?', 'options': ['Sadece okumak', 'Uygulama yapmak', 'Sadece video izlemek', 'Tekrar yapmamak'], 'answer': 1, 'difficulty': 'easy'},
      {'q': 'Bilimsel yontemin ilk adimi nedir?', 'options': ['Sonuc cikarma', 'Gozlem yapma', 'Rapor yazma', 'Deney yapma'], 'answer': 1, 'difficulty': 'medium'},
      {'q': 'Kritik dusunme becerisi ne ise yarar?', 'options': ['Hizli karar verme', 'Bilgiyi sorgulama ve degerlendirme', 'Ezberleme', 'Hic soru sormama'], 'answer': 1, 'difficulty': 'medium'},
      {'q': 'Aralikli tekrar yontemi neden etkilidir?', 'options': ['Zaman kazandirir', 'Uzun sureli bellek guclendirir', 'Kolay oldugu icin', 'Eglenceli oldugu icin'], 'answer': 1, 'difficulty': 'medium'},
      {'q': 'Bloom taksonomisinde en ust duzey hangisidir?', 'options': ['Hatırlama', 'Uygulama', 'Analiz', 'Yaratma'], 'answer': 3, 'difficulty': 'hard'},
      {'q': 'Metabilissel ogrenme ne demektir?', 'options': ['Hizli ogrenme', 'Kendi ogrenme surecini dusunme', 'Grup calismasi', 'Dijital ogrenme'], 'answer': 1, 'difficulty': 'hard'},
    ];
  }
}
