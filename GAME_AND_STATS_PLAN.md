# 🎮 FinalAI - Oyun ve İstatistik Sistemi Planı

## 📋 Genel Bakış

### Hedefler
1. **Quiz Sistemi**: Mevcut not bazlı quiz sistemi
2. **Oyun Sistemi**: Kullanıcıyı geliştiren eğlenceli oyunlar
3. **İstatistik Sistemi**: Başarı ve hataları takip eden detaylı analiz

---

## 🎯 1. Quiz Sistemi (Mevcut - Geliştirilecek)

### Özellikler
- ✅ Not bazlı quiz
- ✅ Çoktan seçmeli sorular
- ✅ Doğru/yanlış takibi
- 🔄 Quiz geçmişi kaydetme
- 🔄 Başarı oranı hesaplama

### Veritabanı Şeması
```sql
-- Quiz oturumları
CREATE TABLE quiz_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  note_id UUID REFERENCES notes(id) NOT NULL,
  total_questions INT NOT NULL,
  correct_answers INT NOT NULL,
  score_percentage DECIMAL(5,2) NOT NULL,
  time_spent_seconds INT,
  completed_at TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Quiz soru detayları (hangi soruyu doğru/yanlış yaptı)
CREATE TABLE quiz_answers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id UUID REFERENCES quiz_sessions(id) NOT NULL,
  question_index INT NOT NULL,
  selected_answer INT NOT NULL,
  correct_answer INT NOT NULL,
  is_correct BOOLEAN NOT NULL,
  time_spent_seconds INT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 🎮 2. Oyun Sistemi (Yeni)

### 2.1 Oyun Türleri

#### A) Kelime Eşleştirme (Word Match)
**Açıklama**: Terim ve tanımları eşleştir
**Mekanik**:
- Sol tarafta terimler, sağ tarafta tanımlar
- Sürükle-bırak veya tıklama ile eşleştir
- Süre sınırı: 60 saniye
- Puan: Doğru eşleştirme başına +10, yanlış -5

#### B) Hızlı Cevap (Speed Quiz)
**Açıklama**: Doğru/Yanlış soruları hızlıca cevapla
**Mekanik**:
- Ekranda bir ifade göster
- Kullanıcı Doğru/Yanlış seç
- Her soru için 5 saniye
- 10 soru üst üste
- Combo sistemi: Üst üste doğrular bonus puan

#### C) Hafıza Kartları (Memory Cards)
**Açıklama**: Eşleşen kartları bul
**Mekanik**:
- Flashcard'lar kapalı kartlar halinde
- 2 kart aç, eşleşiyorsa kalır
- Tüm kartları eşleştir
- Puan: Hamle sayısına göre

#### D) Kelime Avı (Word Hunt)
**Açıklama**: Harflerden kelime oluştur
**Mekanik**:
- Rastgele harfler grid'de
- Konuyla ilgili kelimeleri bul
- Süre: 90 saniye
- Puan: Kelime uzunluğuna göre

### 2.2 Oyun Veritabanı Şeması
```sql
-- Oyun türleri
CREATE TYPE game_type AS ENUM ('word_match', 'speed_quiz', 'memory_cards', 'word_hunt');

-- Oyun oturumları
CREATE TABLE game_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  note_id UUID REFERENCES notes(id),
  game_type game_type NOT NULL,
  score INT NOT NULL,
  max_score INT NOT NULL,
  time_spent_seconds INT NOT NULL,
  accuracy_percentage DECIMAL(5,2),
  completed_at TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Oyun başarıları (achievements)
CREATE TABLE game_achievements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  achievement_key VARCHAR(50) NOT NULL,
  unlocked_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, achievement_key)
);

-- Başarı tanımları
-- 'first_quiz' - İlk quiz tamamlandı
-- 'perfect_quiz' - %100 doğrulukla quiz
-- 'speed_master' - Speed Quiz'de 10/10
-- 'memory_expert' - Memory Cards'ı minimum hamle ile
-- 'word_hunter' - Word Hunt'ta 10+ kelime
-- 'quiz_streak_3' - 3 gün üst üste quiz
-- 'quiz_streak_7' - 7 gün üst üste quiz
```

---

## 📊 3. İstatistik Sistemi

### 3.1 Ana Sayfa İstatistik Widget'ı

**Tasarım**: Kompakt kart görünümü
```
┌─────────────────────────────────────┐
│  📊 Bu Hafta                        │
├─────────────────────────────────────┤
│  ✅ 12 Quiz Tamamlandı              │
│  🎯 %78 Ortalama Başarı             │
│  🔥 5 Günlük Seri                   │
│  ⭐ 3 Yeni Rozet                    │
└─────────────────────────────────────┘
```

**Veriler**:
- Bu hafta tamamlanan quiz/oyun sayısı
- Ortalama başarı yüzdesi
- Günlük seri (streak)
- Kazanılan rozetler

### 3.2 İstatistik Sayfası (Detaylı)

#### Genel Özet
- Toplam çalışma süresi
- Toplam quiz/oyun sayısı
- Toplam doğru/yanlış cevap
- Ortalama başarı oranı
- En iyi performans gösteren konular
- Geliştirilmesi gereken konular

#### Grafikler
1. **Haftalık Aktivite**: Bar chart (her gün kaç quiz/oyun)
2. **Başarı Trendi**: Line chart (zaman içinde başarı oranı)
3. **Konu Dağılımı**: Pie chart (hangi konularda ne kadar çalışıldı)
4. **Doğru/Yanlış Oranı**: Donut chart

#### Rozet Sistemi
```
┌────────────────────────────────────┐
│  🏆 Rozetlerim                     │
├────────────────────────────────────┤
│  ⭐ İlk Adım (İlk quiz)            │
│  🎯 Mükemmel (100% quiz)           │
│  🔥 Ateş Topu (7 gün seri)         │
│  🧠 Beyin Fırtınası (50 quiz)      │
│  🚀 Hız Canavarı (Speed Quiz 10/10)│
└────────────────────────────────────┘
```

### 3.3 İstatistik Veritabanı Şeması
```sql
-- Kullanıcı istatistikleri (özet)
CREATE TABLE user_stats (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id),
  total_quizzes INT DEFAULT 0,
  total_games INT DEFAULT 0,
  total_correct_answers INT DEFAULT 0,
  total_wrong_answers INT DEFAULT 0,
  total_study_time_seconds INT DEFAULT 0,
  current_streak_days INT DEFAULT 0,
  longest_streak_days INT DEFAULT 0,
  last_activity_date DATE,
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Günlük aktivite
CREATE TABLE daily_activity (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  activity_date DATE NOT NULL,
  quizzes_completed INT DEFAULT 0,
  games_completed INT DEFAULT 0,
  correct_answers INT DEFAULT 0,
  wrong_answers INT DEFAULT 0,
  study_time_seconds INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, activity_date)
);

-- Konu bazlı performans
CREATE TABLE subject_performance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  subject VARCHAR(255) NOT NULL,
  total_questions INT DEFAULT 0,
  correct_answers INT DEFAULT 0,
  accuracy_percentage DECIMAL(5,2),
  last_practiced_at TIMESTAMP,
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, subject)
);
```

---

## 🎨 4. UI/UX Tasarım Planı

### 4.1 Bottom Navigation Güncellemesi
```
┌─────────────────────────────────────┐
│  🏠 Ana    📄 Notlar  🎮 Oyun       │
│  📊 İstatistik        👤 Profil     │
└─────────────────────────────────────┘
```

### 4.2 Oyun Sayfası Tasarımı
```
┌─────────────────────────────────────┐
│  🎮 Oyunlar                         │
├─────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  │
│  │ 🔤 Kelime   │  │ ⚡ Hızlı    │  │
│  │ Eşleştirme  │  │ Cevap       │  │
│  │ En iyi: 85  │  │ En iyi: 9/10│  │
│  └─────────────┘  └─────────────┘  │
│  ┌─────────────┐  ┌─────────────┐  │
│  │ 🧠 Hafıza   │  │ 🔍 Kelime   │  │
│  │ Kartları    │  │ Avı         │  │
│  │ En iyi: 12  │  │ En iyi: 15  │  │
│  └─────────────┘  └─────────────┘  │
└─────────────────────────────────────┘
```

### 4.3 İstatistik Sayfası Tasarımı
```
┌─────────────────────────────────────┐
│  📊 İstatistikler                   │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐   │
│  │  Bu Hafta                   │   │
│  │  ✅ 12 Quiz  🎮 8 Oyun      │   │
│  │  🎯 %78      🔥 5 Gün       │   │
│  └─────────────────────────────┘   │
│                                     │
│  📈 Başarı Trendi (Grafik)          │
│  ┌─────────────────────────────┐   │
│  │      ╱╲                      │   │
│  │     ╱  ╲    ╱╲               │   │
│  │    ╱    ╲  ╱  ╲              │   │
│  │   ╱      ╲╱    ╲             │   │
│  └─────────────────────────────┘   │
│                                     │
│  🏆 Rozetler                        │
│  ⭐⭐⭐🔒🔒🔒                        │
└─────────────────────────────────────┘
```

---

## 🚀 5. Uygulama Adımları

### Faz 1: Quiz İyileştirmeleri (Şimdi)
- [x] Quiz şık seçme düzelt
- [ ] Quiz oturumlarını kaydet
- [ ] Quiz geçmişi göster

### Faz 2: Temel İstatistikler
- [ ] Veritabanı tablolarını oluştur
- [ ] Ana sayfa istatistik widget'ı
- [ ] Basit istatistik sayfası (sayılar)

### Faz 3: Oyun Sistemi
- [ ] Oyun sayfası UI
- [ ] Kelime Eşleştirme oyunu
- [ ] Hızlı Cevap oyunu
- [ ] Oyun skorlarını kaydet

### Faz 4: Gelişmiş İstatistikler
- [ ] Grafikler ekle (fl_chart paketi)
- [ ] Rozet sistemi
- [ ] Günlük seri takibi
- [ ] Konu bazlı performans

### Faz 5: Hafıza ve Kelime Oyunları
- [ ] Hafıza Kartları oyunu
- [ ] Kelime Avı oyunu
- [ ] Liderlik tablosu (opsiyonel)

---

## 📦 Gerekli Paketler

```yaml
dependencies:
  # Grafikler için
  fl_chart: ^0.68.0
  
  # Animasyonlar için
  flutter_animate: ^4.5.0
  
  # Confetti efekti (başarı anında)
  confetti: ^0.7.0
  
  # Süre sayacı
  stop_watch_timer: ^3.1.1
```

---

## 🎯 Başarı Kriterleri

1. **Kullanıcı Bağlılığı**: Günlük aktif kullanıcı artışı
2. **Öğrenme Etkisi**: Quiz başarı oranında artış trendi
3. **Eğlence**: Oyun tamamlanma oranı >60%
4. **Motivasyon**: Ortalama günlük seri >3 gün

---

## 📝 Notlar

- Oyunlar not bazlı olacak (kullanıcının yüklediği notlardan içerik)
- Offline mod için local cache kullan
- Gamification öğeleri: XP, level, rozetler
- Push notification: "3 gündür quiz çözmedin!" gibi hatırlatmalar
