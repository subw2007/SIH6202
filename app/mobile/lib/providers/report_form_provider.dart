import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../services/api_service.dart';
import '../services/image_picker_helper.dart';

enum LocationDetectState { detecting, ready, failed }

enum VoiceNotePhase { idle, recording, recorded, playing }

enum ImagePickSource { camera, gallery }

/// Local composer state for a new citizen report. Reset per route instance.
class ReportFormProvider extends ChangeNotifier {
  static const maxVoice = Duration(seconds: 60);
  static const mockAddress = 'Main St, Sector 4';

  String _title = '';
  String _locationLabel = 'Detecting Location...';
  LocationDetectState _locationState = LocationDetectState.detecting;
  bool _hasImage = false;
  ImagePickSource? _imageSource;
  Uint8List? _imageBytes;
  String? _recordedAudioPath;
  VoiceNotePhase _voicePhase = VoiceNotePhase.idle;
  Duration _voiceElapsed = Duration.zero;
  Duration _playbackElapsed = Duration.zero;
  bool _isSubmitting = false;
  bool _submitted = false;

  Timer? _locationTimer;
  Timer? _voiceTimer;
  Timer? _playbackTimer;

  String get title => _title;
  String get locationLabel => _locationLabel;
  LocationDetectState get locationState => _locationState;
  bool get hasImage => _hasImage;
  ImagePickSource? get imageSource => _imageSource;
  Uint8List? get imageBytes => _imageBytes;
  String? get recordedAudioPath => _recordedAudioPath;
  VoiceNotePhase get voicePhase => _voicePhase;
  Duration get voiceElapsed => _voiceElapsed;
  Duration get playbackElapsed => _playbackElapsed;
  Duration get recordedDuration => _voiceElapsed;
  bool get isSubmitting => _isSubmitting;
  bool get submitted => _submitted;
  bool get hasVoiceNote => _recordedAudioPath != null;

  bool get canSubmit =>
      !_isSubmitting &&
      (_title.trim().isNotEmpty || _hasImage || hasVoiceNote);

  String get voiceTimerLabel {
    final current = _voicePhase == VoiceNotePhase.playing
        ? _playbackElapsed
        : _voiceElapsed;
    return '${_fmt(current)} / ${_fmt(maxVoice)}';
  }

  String get imageHint {
    if (!_hasImage) return 'Tap to Take Photo or Upload Image';
    return _imageSource == ImagePickSource.camera
        ? 'Photo captured'
        : 'Image uploaded';
  }

  Map<String, dynamic> toPayload() => {
        'title': _title.trim(),
        'location': _locationLabel,
        'has_image': _hasImage,
        'image_source': _imageSource?.name,
        'image_base64': _imageBytes != null ? base64Encode(_imageBytes!) : null,
        'audio_path': _recordedAudioPath,
        'audio_duration_ms': _voiceElapsed.inMilliseconds,
      };

  void startLocationDetection() {
    _locationTimer?.cancel();
    _locationState = LocationDetectState.detecting;
    _locationLabel = 'Detecting Location...';
    notifyListeners();
    _locationTimer = Timer(const Duration(milliseconds: 900), () {
      _locationState = LocationDetectState.ready;
      _locationLabel = mockAddress;
      notifyListeners();
    });
  }

  void setTitle(String value) {
    _title = value;
    notifyListeners();
  }

  Future<void> pickImage(ImagePickSource source) async {
    _hasImage = true;
    _imageSource = source;
    notifyListeners();

    try {
      final bytes = await selectImage(source);
      if (bytes != null && bytes.isNotEmpty) {
        _imageBytes = bytes;
        _hasImage = true;
        notifyListeners();
      }
    } catch (_) {
      // Keep optimistic mock state
    }
  }

  void clearImage() {
    _hasImage = false;
    _imageSource = null;
    _imageBytes = null;
    notifyListeners();
  }

  void startRecording() {
    if (_voicePhase == VoiceNotePhase.recording) return;
    _voiceTimer?.cancel();
    _playbackTimer?.cancel();
    _voicePhase = VoiceNotePhase.recording;
    _voiceElapsed = Duration.zero;
    _playbackElapsed = Duration.zero;
    _recordedAudioPath = null;
    notifyListeners();
    _voiceTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      _voiceElapsed += const Duration(milliseconds: 200);
      if (_voiceElapsed >= maxVoice) {
        stopRecording();
        return;
      }
      notifyListeners();
    });
  }

  void stopRecording() {
    if (_voicePhase != VoiceNotePhase.recording) return;
    _voiceTimer?.cancel();
    _voiceTimer = null;
    if (_voiceElapsed < const Duration(milliseconds: 400)) {
      _voicePhase = VoiceNotePhase.idle;
      _voiceElapsed = Duration.zero;
      _recordedAudioPath = null;
    } else {
      _voicePhase = VoiceNotePhase.recorded;
      _recordedAudioPath =
          'mock://voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    }
    notifyListeners();
  }

  void deleteRecording() {
    _voiceTimer?.cancel();
    _playbackTimer?.cancel();
    _voiceTimer = null;
    _playbackTimer = null;
    _voicePhase = VoiceNotePhase.idle;
    _voiceElapsed = Duration.zero;
    _playbackElapsed = Duration.zero;
    _recordedAudioPath = null;
    notifyListeners();
  }

  void reRecord() {
    deleteRecording();
    startRecording();
  }

  void togglePlayback() {
    if (_voicePhase == VoiceNotePhase.playing) {
      _stopPlayback();
      return;
    }
    if (_voicePhase != VoiceNotePhase.recorded || _voiceElapsed == Duration.zero) {
      return;
    }
    _playbackElapsed = Duration.zero;
    _voicePhase = VoiceNotePhase.playing;
    notifyListeners();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      _playbackElapsed += const Duration(milliseconds: 200);
      if (_playbackElapsed >= _voiceElapsed) {
        _stopPlayback();
        return;
      }
      notifyListeners();
    });
  }

  Future<bool> submit() async {
    if (!canSubmit) return false;
    _isSubmitting = true;
    notifyListeners();
    try {
      await ApiService.instance.submitReport(toPayload());
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 450));
    _isSubmitting = false;
    _submitted = true;
    notifyListeners();
    return true;
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _playbackElapsed = Duration.zero;
    _voicePhase = VoiceNotePhase.recorded;
    notifyListeners();
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _voiceTimer?.cancel();
    _playbackTimer?.cancel();
    super.dispose();
  }
}
