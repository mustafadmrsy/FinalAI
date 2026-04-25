Sen bir senior Flutter + Node.js mimarısın. Aşağıdaki mevcut projeyi inceleyip adım adım refactor edeceksin ve gamification sistemi ekleyeceksin. Önce mevcut kodu oku, sonra aşağıdaki sırayla ilerle. Her adımı bitirmeden diğerine geçme.

---

## MEVCUT MİMARİ (oku, anla, dokunma henüz)

- Monorepo: root = /finalai
- Backend: apps/api/src/server.js (tüm iş mantığı tek dosyada)
- Flutter: apps/finalai/lib/ (Riverpod + go_router)
- Supabase tabloları: notes, user_profiles, user_stats, quiz_sessions
- Mevcut flow: PDF yükle → AI işle (SSE) → özet/quiz/flashcard üret → Supabase'e kaydet

---

## ADIM 1 — BACKEND REFACTOR

server.js'i böl, tek dosyada kalmasın:

apps/api/src/
├── server.js              # sadece Express init + middleware + route mount
├── routes/
│   └── ai.routes.js       # /ai/* endpointleri
├── services/
│   ├── ai.service.js      # Anthropic iletişimi, fallback, retry
│   ├── pdf.service.js     # pdf-parse + OCR fallback
│   └── validation.service.js  # JSON normalize, repair, validate
└── middleware/
    └── error.middleware.js

Kurallar:
- Her servis sadece kendi işini yapsın
- Dışa sadece ihtiyaç duyulan fonksiyonları export et
- Mevcut SSE akışı, progress sistemi, fallback endpoint bozulmasın
- generateMissingItems ve createMessageWithFallback mantığı korunsun

---

## ADIM 2 — FLUTTER REPOSITORY KATMANI

supabase_service.dart'ı parçala:

apps/finalai/lib/core/repositories/
├── note_repository.dart        # saveNote, getRecentNotes, getNoteById
├── stats_repository.dart       # getUserStats, updateStats, updateStreak
├── game_repository.dart        # createGameSession, getGameHistory
└── leaderboard_repository.dart # getWeeklyLeaderboard, searchUsers

apps/finalai/lib/core/services/
├── supabase_service.dart  # sadece Supabase client init
└── ai_service.dart        # mevcut, dokunma

Kurallar:
- Her repository sadece Supabase ile konuşur, iş mantığı içermez
- Provider'lar repository'leri kullanır, servisleri değil
- Mevcut quiz_provider, upload_provider, stats_provider bağlantıları korunsun

---

## ADIM 3 — SUPABASE ŞEMASI (yeni tablolar)

Aşağıdaki SQL'i çalıştır (migration dosyası olarak yaz: apps/api/migrations/001_gamification.sql):

-- XP kayıtları
create table xp_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  amount int not null,
  reason text not null, -- 'correct_answer', 'combo_bonus', 'boss_kill', 'daily_goal', 'streak_bonus'
  game_session_id uuid,
  created_at timestamptz default now()
);

-- Oyun oturumları (quiz_sessions'ın yerini almaz, yanına ekle)
create table game_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  note_id uuid references notes,
  mode text not null, -- 'quiz_blitz', 'boss_fight', 'flashcard_duel', 'cloze_rush'
  score int default 0,
  xp_earned int default 0,
  combo_max int default 0,
  accuracy numeric(5,2),
  duration_seconds int,
  completed_at timestamptz default now()
);

-- Haftalık lig
create table user_leagues (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null unique,
  league text default 'bronze', -- bronze, silver, gold, platinum
  weekly_xp int default 0,
  week_start date not null,
  updated_at timestamptz default now()
);

-- Mağaza itemları
create table shop_items (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  type text not null, -- 'theme', 'card_skin', 'profile_frame', 'badge'
  cost_xp int default 0,
  is_premium boolean default false,
  metadata jsonb
);

-- Kullanıcı envanteri
create table user_inventory (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  item_id uuid references shop_items not null,
  equipped boolean default false,
  acquired_at timestamptz default now()
);

-- Haftalık leaderboard view
create or replace view leaderboard_weekly as
select
  up.username,
  up.display_name,
  up.avatar_url,
  ul.weekly_xp,
  ul.league,
  us.study_streak
from user_leagues ul
join user_profiles up on up.user_id = ul.user_id
join user_stats us on us.user_id = ul.user_id
order by ul.weekly_xp desc;

-- user_profiles'a ekle (yoksa)
alter table user_profiles add column if not exists username text unique;
alter table user_profiles add column if not exists display_name text;
alter table user_profiles add column if not exists bio text;
alter table user_profiles add column if not exists is_public boolean default true;

-- user_stats'a ekle (yoksa)
alter table user_stats add column if not exists total_xp int default 0;
alter table user_stats add column if not exists weekly_xp int default 0;

---

## ADIM 4 — FLUTTER GAME ENGINE MODÜLÜ

apps/finalai/lib/core/game_engine/
├── models/
│   ├── game_session_model.dart     # mode, score, xp, combo, lives, duration
│   └── game_config_model.dart      # her mod için config (süre, can, combo çarpanı)
├── services/
│   ├── xp_calculator.dart          # XP hesaplama kuralları
│   └── combo_tracker.dart          # combo sayacı ve çarpan mantığı
└── game_engine.dart                # tek giriş noktası, dışarıya sadece bu expose edilir

XP Kuralları (xp_calculator.dart içinde):
- Doğru cevap: 10 XP
- Combo x2 (3+ üst üste): +5 bonus
- Combo x3 (6+ üst üste): +10 bonus  
- Boss öldürme: +50 XP
- Günlük hedef tamamlama: +20 XP
- 7 günlük streak: +100 XP

Can Sistemi (boss_fight modu için):
- Başlangıç: 3 can
- Yanlış cevap: -1 can
- Can 0 → game over

Game Engine dışarıya şunları expose etsin:
- startSession(mode, config) → GameSession
- answerQuestion(isCorrect) → XPResult
- endSession() → GameSession (final)

---

## ADIM 5 — OYUN MODLARI (Flutter screens)

apps/finalai/lib/features/game/
├── screens/
│   ├── game_mode_select_screen.dart   # mod seçim ekranı
│   ├── quiz_blitz_screen.dart         # timer + combo göstergeli quiz
│   ├── boss_fight_screen.dart         # can göstergeli boss arayüzü
│   └── flashcard_duel_screen.dart     # biliyorum/bilmiyorum akışı
├── widgets/
│   ├── combo_indicator.dart
│   ├── lives_indicator.dart
│   ├── xp_progress_bar.dart
│   └── timer_bar.dart
└── providers/
    └── game_provider.dart             # GameNotifier → game_engine kullanır

go_router'a eklenecek route'lar:
- /game/select
- /game/quiz-blitz/:noteId
- /game/boss-fight/:noteId
- /game/flashcard-duel/:noteId

---

## ADIM 6 — LEADERBOARD & PROFİL

apps/finalai/lib/features/leaderboard/
├── screens/
│   ├── leaderboard_screen.dart     # haftalık XP sıralaması + lig rozeti
│   └── public_profile_screen.dart  # başka kullanıcının profili
├── widgets/
│   └── league_badge_widget.dart
└── providers/
    └── leaderboard_provider.dart

apps/finalai/lib/features/profile/ içine ekle:
- username arama fonksiyonu
- public/private toggle

---

## GENEL KURALLAR (tüm adımlarda uygula)

- Her dosya tek sorumluluk taşısın (Single Responsibility)
- Hiçbir widget doğrudan Supabase'e erişmesin, repository üzerinden gitsin
- Hiçbir provider iş mantığı içermesin, sadece state yönetsin
- Game engine Flutter'a bağımlı olmasın (test edilebilir olsun)
- Her yeni tablo için RLS (Row Level Security) politikası ekle
- Tüm async işlemlerde hata yakalanıp kullanıcıya anlamlı mesaj dönüşsün
- Mevcut çalışan hiçbir özellik bozulmasın (PDF upload, AI processing, klasik quiz)

---

## ÖNCELİK SIRASI

1. Adım 1 (backend refactor) → test et, çalıştığını doğrula
2. Adım 2 (Flutter repository) → mevcut ekranlar bozulmadan çalışsın
3. Adım 3 (DB migration) → SQL çalıştır
4. Adım 4 (game engine) → unit test yaz
5. Adım 5 (oyun modları) → önce quiz_blitz, sonra diğerleri
6. Adım 6 (leaderboard) → en son

Başla.