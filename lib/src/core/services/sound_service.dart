/// Professional UI sounds: notifications, messages, likes, taps.
/// Uses generated short WAV tones so no external assets are required.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum AppSound {
  notification,
  messageSent,
  messageReceived,
  like,
  tap,
}

class SoundService {
  static final SoundService _instance = SoundService._();
  factory SoundService() => _instance;

  SoundService._();

  static AudioPlayer? _player;
  static bool _enabled = true;
  static final Map<AppSound, Uint8List?> _cache = {};

  static bool get enabled => _enabled;
  static set enabled(bool value) => _enabled = value;

  static AudioPlayer get _audioPlayer {
    _player ??= AudioPlayer();
    return _player!;
  }

  /// Play a short professional sound. No-op if disabled or on error.
  static Future<void> play(AppSound sound) async {
    if (!_enabled) return;
    try {
      final bytes = _cache[sound] ?? _generateWav(sound);
      if (bytes == null || bytes.isEmpty) return;
      await _audioPlayer.play(BytesSource(bytes, mimeType: 'audio/wav'));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SoundService.play($sound): $e');
      }
    }
  }

  static Uint8List? _generateWav(AppSound sound) {
    final cached = _cache[sound];
    if (cached != null) return cached;

    double frequencyHz;
    int lengthMs;
    double volume;
    String envelope; // 'soft' | 'click' | 'ding'

    switch (sound) {
      case AppSound.notification:
        frequencyHz = 880;
        lengthMs = 120;
        volume = 0.35;
        envelope = 'ding';
        break;
      case AppSound.messageSent:
        frequencyHz = 660;
        lengthMs = 80;
        volume = 0.28;
        envelope = 'soft';
        break;
      case AppSound.messageReceived:
        frequencyHz = 523;
        lengthMs = 100;
        volume = 0.32;
        envelope = 'ding';
        break;
      case AppSound.like:
        frequencyHz = 698;
        lengthMs = 90;
        volume = 0.3;
        envelope = 'ding';
        break;
      case AppSound.tap:
        frequencyHz = 1200;
        lengthMs = 35;
        volume = 0.2;
        envelope = 'click';
        break;
    }

    final bytes = _makeWav(
      sampleRateHz: 44100,
      frequencyHz: frequencyHz,
      lengthMs: lengthMs,
      volume: volume,
      envelope: envelope,
    );
    _cache[sound] = bytes;
    return bytes;
  }

  static Uint8List _makeWav({
    required int sampleRateHz,
    required double frequencyHz,
    required int lengthMs,
    required double volume,
    required String envelope,
  }) {
    const bitsPerSample = 16;
    const numChannels = 1;
    final numSamples = (sampleRateHz * lengthMs / 1000).round();
    final dataSize = numSamples * 2;
    final byteRate = sampleRateHz * numChannels * (bitsPerSample >> 3);
    final blockAlign = numChannels * (bitsPerSample >> 3);

    final out = ByteData(44 + dataSize);
    int i = 0;
    void writeU8(int v) => out.setUint8(i++, v);
    void writeU16(int v) {
      out.setUint16(i, v, Endian.little);
      i += 2;
    }
    void writeU32(int v) {
      out.setUint32(i, v, Endian.little);
      i += 4;
    }

    out.setUint8(i++, 0x52);
    out.setUint8(i++, 0x49);
    out.setUint8(i++, 0x46);
    out.setUint8(i++, 0x46);
    writeU32(36 + dataSize);
    out.setUint8(i++, 0x57);
    out.setUint8(i++, 0x41);
    out.setUint8(i++, 0x56);
    out.setUint8(i++, 0x45);
    out.setUint8(i++, 0x66);
    out.setUint8(i++, 0x6d);
    out.setUint8(i++, 0x74);
    out.setUint8(i++, 0x20);
    writeU32(16);
    writeU16(1);
    writeU16(numChannels);
    writeU32(sampleRateHz);
    writeU32(byteRate);
    writeU16(blockAlign);
    writeU16(bitsPerSample);
    out.setUint8(i++, 0x64);
    out.setUint8(i++, 0x61);
    out.setUint8(i++, 0x74);
    out.setUint8(i++, 0x61);
    writeU32(dataSize);

    final scale = volume * 0.3 * 32767;
    final omega = 2 * math.pi * frequencyHz / sampleRateHz;
    for (int s = 0; s < numSamples; s++) {
      double t = s / sampleRateHz;
      double env = 1.0;
      if (envelope == 'soft') {
        final attack = 0.02;
        final decay = lengthMs / 1000.0;
        if (t < attack) {
          env = t / attack;
        } else {
          env = math.exp(-(t - attack) * 8 / decay);
        }
      } else if (envelope == 'click') {
        env = math.exp(-t * 80);
      } else {
        final attack = 0.015;
        final decay = lengthMs / 1000.0;
        if (t < attack) {
          env = t / attack;
        } else {
          env = math.exp(-(t - attack) * 6 / decay);
        }
      }
      final sample = (scale * env * math.sin(omega * s)).round().clamp(-32768, 32767);
      out.setInt16(44 + s * 2, sample, Endian.little);
    }

    return out.buffer.asUint8List();
  }

  static Future<void> dispose() async {
    await _player?.dispose();
    _player = null;
    _cache.clear();
  }
}
