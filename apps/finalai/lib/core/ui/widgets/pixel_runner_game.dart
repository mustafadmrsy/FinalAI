import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// ═══════════════════════════════════════════════════════════════
//  PIXEL RUNNER GAME — T-Rex style mini game
//  Tap to jump over obstacles while waiting for AI
// ═══════════════════════════════════════════════════════════════

class PixelRunnerGame extends StatefulWidget {
  const PixelRunnerGame({super.key, this.onScore});
  final ValueChanged<int>? onScore;

  @override
  State<PixelRunnerGame> createState() => _PixelRunnerGameState();
}

class _PixelRunnerGameState extends State<PixelRunnerGame> with SingleTickerProviderStateMixin {
  static const double _gravity = 1200;
  static const double _jumpVelocity = -520;
  static const double _groundY = 0.78;
  static const double _playerSize = 32;
  static const double _obstacleW = 14;

  late final Ticker _ticker;
  final _rng = Random();

  double _playerY = _groundY;
  double _velocityY = 0;
  bool _isJumping = false;
  bool _gameOver = false;
  bool _started = false;
  int _score = 0;
  double _speed = 200;

  final List<_Obstacle> _obstacles = [];
  double _spawnTimer = 0;
  double _nextSpawn = 1.8;

  Duration _lastTick = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_update);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _started = true;
      _gameOver = false;
      _score = 0;
      _speed = 200;
      _playerY = _groundY;
      _velocityY = 0;
      _isJumping = false;
      _obstacles.clear();
      _spawnTimer = 0;
      _nextSpawn = 1.8;
      _lastTick = Duration.zero;
    });
    _ticker.start();
  }

  void _jump() {
    if (!_started) {
      _start();
      return;
    }
    if (_gameOver) {
      _start();
      return;
    }
    if (!_isJumping) {
      setState(() {
        _velocityY = _jumpVelocity;
        _isJumping = true;
      });
    }
  }

  void _update(Duration elapsed) {
    if (_gameOver) return;
    final dt = _lastTick == Duration.zero ? 0.016 : (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    if (dt <= 0 || dt > 0.1) return;

    setState(() {
      // Player physics
      if (_isJumping) {
        _velocityY += _gravity * dt;
        _playerY += _velocityY * dt / 400; // normalize
        if (_playerY >= _groundY) {
          _playerY = _groundY;
          _velocityY = 0;
          _isJumping = false;
        }
      }

      // Spawn obstacles
      _spawnTimer += dt;
      if (_spawnTimer >= _nextSpawn) {
        _spawnTimer = 0;
        _nextSpawn = 1.2 + _rng.nextDouble() * 1.2;
        final h = 18.0 + _rng.nextDouble() * 14;
        _obstacles.add(_Obstacle(x: 1.1, height: h));
      }

      // Move obstacles
      for (final o in _obstacles) {
        o.x -= _speed * dt / 400;
      }

      // Remove off-screen
      _obstacles.removeWhere((o) => o.x < -0.1);

      // Collision
      for (final o in _obstacles) {
        if (_checkCollision(o)) {
          _gameOver = true;
          _ticker.stop();
          _lastTick = Duration.zero;
          return;
        }
      }

      // Score
      for (final o in _obstacles) {
        if (!o.scored && o.x < 0.15) {
          o.scored = true;
          _score++;
          widget.onScore?.call(_score);
        }
      }

      // Increase speed
      _speed = 200 + _score * 8;
    });
  }

  bool _checkCollision(_Obstacle o) {
    // ── Y axis — match rendering coordinate system ──
    // Player rendered:   top = 160 * _playerY - _playerSize  →  bottom = _playerY
    // Obstacle rendered: top = 160 * _groundY - h + 2        →  bottom = _groundY + 2/160
    const ch = 160.0;
    const m = 0.02; // forgiveness margin (~3px)

    final pTop = _playerY - _playerSize / ch + m;
    final pBot = _playerY - m;
    final oTop = _groundY + (2 - o.height) / ch + m;
    const oBot = _groundY + 2 / ch;

    if (pBot <= oTop || pTop >= oBot) return false;

    // ── X axis — approximate overlap ──
    const pLeft = 0.12;
    const pRight = 0.12 + _playerSize / 400;
    final oLeft = o.x;
    final oRight = o.x + _obstacleW / 400;

    return pRight > oLeft && pLeft < oRight;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _jump,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2D2D4E), width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(children: [
            // Ground line
            Positioned(
              bottom: 160 * (1 - _groundY) - 6,
              left: 0, right: 0,
              child: Container(height: 2, color: const Color(0xFF3D3D5C)),
            ),

            // Ground dots
            Positioned(
              bottom: 160 * (1 - _groundY) - 10,
              left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(20, (i) => Container(
                  width: 2, height: 2,
                  color: const Color(0xFF2D2D4E),
                )),
              ),
            ),

            // Player
            Positioned(
              left: 160 * 0.12,
              top: 160 * _playerY - _playerSize,
              child: _buildPlayer(),
            ),

            // Obstacles
            for (final o in _obstacles)
              Positioned(
                left: (MediaQuery.of(context).size.width - 80) * o.x,
                top: 160 * _groundY - o.height + 2,
                child: _buildObstacle(o.height),
              ),

            // Score
            Positioned(
              top: 8, right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$_score', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'monospace')),
              ),
            ),

            // Overlay messages
            if (!_started)
              const Center(child: Text('Ziplamak icin dokun!', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w800, fontSize: 13))),
            if (_gameOver)
              Center(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(180),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Skor: $_score  •  Tekrar dene!', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
              )),
          ]),
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    return Container(
      width: _playerSize,
      height: _playerSize,
      decoration: BoxDecoration(
        color: const Color(0xFF58CC02),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF46A302), width: 2),
        boxShadow: [BoxShadow(color: const Color(0xFF46A302).withAlpha(80), offset: const Offset(0, 2), blurRadius: 0)],
      ),
      child: Stack(children: [
        // Eyes
        Positioned(top: 6, left: 6, child: Container(width: 5, height: 5, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)))),
        Positioned(top: 6, right: 6, child: Container(width: 5, height: 5, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)))),
        // Pupils
        Positioned(top: 8, left: 8, child: Container(width: 2, height: 2, color: const Color(0xFF1A1A2E))),
        Positioned(top: 8, right: 7, child: Container(width: 2, height: 2, color: const Color(0xFF1A1A2E))),
        // Mouth
        Positioned(bottom: 6, left: 8, right: 8, child: Container(height: 3, decoration: BoxDecoration(color: const Color(0xFF46A302), borderRadius: BorderRadius.circular(2)))),
      ]),
    );
  }

  Widget _buildObstacle(double h) {
    return Container(
      width: _obstacleW,
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B6B),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        border: Border.all(color: const Color(0xFFCC4444), width: 2),
        boxShadow: [BoxShadow(color: const Color(0xFFCC4444).withAlpha(60), offset: const Offset(0, 2), blurRadius: 0)],
      ),
      child: Column(children: [
        const SizedBox(height: 3),
        Container(width: 8, height: 3, decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(1))),
      ]),
    );
  }
}

class _Obstacle {
  _Obstacle({required this.x, required this.height});
  double x;
  final double height;
  bool scored = false;
}
