import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../services/api_service.dart';

enum LocationDetectState { detecting, ready, failed }

enum VoiceNotePhase { idle, recording, recorded, playing }

enum ImagePickSource { camera, gallery }

/// Local composer state for a new citizen report. Reset per route instance.
class ReportFormProvider extends ChangeNotifier {
  ReportFormProvider({this._onReportSubmitted});

  static const categories = <String>[
    'Roads & Transport',
    'Water & Sewage',
    'Electricity & Lighting',
    'Waste & Sanitation',
    'Public Hazards & Safety',
    'Public Infrastructure',
  ];
  String _title = '';
  String _category = categories.first;
  String _locationLabel = 'Detecting Location...';
  LocationDetectState _locationState = LocationDetectState.detecting;
  XFile? _imageFile;
  String? _selectedImagePath;
  XFile? _videoFile;
  String? _selectedVideoPath;
  String? _uploadedVideoUrl;
  ImagePickSource? _imageSource;
  String? _recordedAudioPath;
  VoiceNotePhase _voicePhase = VoiceNotePhase.idle;
  Duration _voiceElapsed = Duration.zero;
  Duration _playbackElapsed = Duration.zero;
  bool _isSubmitting = false;
  bool _submitted = false;
  String? _errorMessage;
  final Future<void> Function()? _onReportSubmitted;
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  double? _latitude;
  double? _longitude;

  Timer? _locationTimer;
  Timer? _voiceTimer;
  Timer? _playbackTimer;

  String get title => _title;
  String get category => _category;
  String get locationLabel => _locationLabel;
  LocationDetectState get locationState => _locationState;
  bool get hasImage => _imageFile != null;
  XFile? get imageFile => _imageFile;
  String? get selectedImagePath => _selectedImagePath;
  XFile? get videoFile => _videoFile;
  String? get selectedVideoPath => _selectedVideoPath;
  ImagePickSource? get imageSource => _imageSource;
  String? get recordedAudioPath => _recordedAudioPath;
  VoiceNotePhase get voicePhase => _voicePhase;
  Duration get voiceElapsed => _voiceElapsed;
  Duration get playbackElapsed => _playbackElapsed;
  Duration get recordedDuration => _voiceElapsed;
  bool get isSubmitting => _isSubmitting;
  bool get submitted => _submitted;
  bool get hasVoiceNote => _recordedAudioPath != null;
  bool get hasVideo => _videoFile != null;
  String? get errorMessage => _errorMessage;
  double? get latitude => _latitude;
  double? get longitude => _longitude;

  bool get canSubmit =>
      !_isSubmitting &&
      (_title.trim().isNotEmpty || hasImage || hasVoiceNote || hasVideo);

  String get voiceTimerLabel {
    final current = _voicePhase == VoiceNotePhase.playing
        ? _playbackElapsed
        : _voiceElapsed;
    return _fmt(current);
  }

  String get imageHint {
    if (!hasImage) return 'Tap to Take Photo or Upload Image';
    return _imageSource == ImagePickSource.camera
        ? 'Photo captured'
        : 'Image uploaded';
  }

  Map<String, dynamic> toPayload() => {
    'title': _title.trim(),
    'category': _category,
    'location_name': _locationLabel,
    'latitude': _latitude,
    'longitude': _longitude,
    'image_source': _imageSource?.name,
    'audio_duration_ms': _voiceElapsed.inMilliseconds,
    'video_url': _uploadedVideoUrl,
  };

  Future<void> startLocationDetection() async {
    _locationTimer?.cancel();
    _locationState = LocationDetectState.detecting;
    _locationLabel = 'Detecting Location...';
    notifyListeners();
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Location disabled');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }
      final position = await Geolocator.getCurrentPosition();
      _latitude = position.latitude;
      _longitude = position.longitude;
      final placemarks = await placemarkFromCoordinates(
        _latitude!,
        _longitude!,
      );
      final place = placemarks.isEmpty ? null : placemarks.first;
      _locationLabel = [
        place?.street,
        place?.locality,
        place?.administrativeArea,
      ].whereType<String>().where((part) => part.trim().isNotEmpty).join(', ');
      if (_locationLabel.isEmpty) {
        _locationLabel =
            '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}';
      }
      _locationState = LocationDetectState.ready;
    } catch (_) {
      _locationState = LocationDetectState.failed;
      _locationLabel = 'Location unavailable';
    }
    notifyListeners();
  }

  void setLocationLabel(String value) {
    _locationLabel = value;
    notifyListeners();
  }

  void setSelectedLocation({
    required double latitude,
    required double longitude,
    required String label,
  }) {
    _latitude = latitude;
    _longitude = longitude;
    _locationLabel = label;
    _locationState = LocationDetectState.ready;
    notifyListeners();
  }

  void setTitle(String value) {
    _title = value;
    notifyListeners();
  }

  void setCategory(String value) {
    if (!categories.contains(value)) return;
    _category = value;
    notifyListeners();
  }

  Future<void> categorizeText(String text) async {
    final category = await _apiService.categorizeText(text);
    setCategory(category);
  }

  Future<void> pickImage(ImagePickSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source == ImagePickSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 85,
      );
      if (file == null) return;
      _imageFile = file;
      _selectedImagePath = file.path;
      _imageSource = source;
      _errorMessage = null;
      notifyListeners();
    } catch (_) {
      _setError('Unable to access the camera or photo library.');
    }
  }

  void clearImage() {
    _imageFile = null;
    _selectedImagePath = null;
    _imageSource = null;
    notifyListeners();
  }

  Future<void> pickVideo(ImageSource source) async {
    try {
      final file = await _imagePicker.pickVideo(source: source);
      if (file == null) return;
      _videoFile = file;
      _selectedVideoPath = file.path;
      _uploadedVideoUrl = null;
      _errorMessage = null;
      notifyListeners();
    } catch (error) {
      debugPrint('[VIDEO ERROR] Unable to select video: $error');
      _setError('Unable to access the camera or video library.');
    }
  }

  void clearVideo() {
    _videoFile = null;
    _selectedVideoPath = null;
    _uploadedVideoUrl = null;
    notifyListeners();
  }

  Future<void> startRecording() async {
    if (_voicePhase == VoiceNotePhase.recording) return;
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        _setError('Microphone permission is required to record a voice note.');
        return;
      }
      _voiceTimer?.cancel();
      _playbackTimer?.cancel();
      _voicePhase = VoiceNotePhase.recording;
      _voiceElapsed = Duration.zero;
      _playbackElapsed = Duration.zero;
      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: filePath,
      );
      _errorMessage = null;
      notifyListeners();
      _voiceTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
        _voiceElapsed += const Duration(milliseconds: 200);
        notifyListeners();
      });
    } catch (error) {
      debugPrint('[AUDIO ERROR] Unable to start recording: $error');
      _voicePhase = VoiceNotePhase.idle;
      _voiceTimer?.cancel();
      _voiceTimer = null;
      _setError(
        'Microphone permission is unavailable. Please allow access and try again.',
      );
    }
  }

  String? consumeErrorMessage() {
    final message = _errorMessage;
    _errorMessage = null;
    return message;
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> stopRecording() async {
    if (_voicePhase != VoiceNotePhase.recording) return;
    final path = await _recorder.stop();
    _voiceTimer?.cancel();
    _voiceTimer = null;
    if (_voiceElapsed < const Duration(milliseconds: 400)) {
      _voicePhase = VoiceNotePhase.idle;
      _voiceElapsed = Duration.zero;
      _recordedAudioPath = null;
    } else {
      _voicePhase = VoiceNotePhase.recorded;
      _recordedAudioPath = path;
    }
    notifyListeners();
  }

  Future<void> deleteRecording() async {
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

  Future<void> reRecord() async {
    await deleteRecording();
    await startRecording();
  }

  Future<void> togglePlayback() async {
    if (_voicePhase == VoiceNotePhase.playing) {
      _stopPlayback();
      return;
    }
    if (_voicePhase != VoiceNotePhase.recorded ||
        _voiceElapsed == Duration.zero) {
      return;
    }
    _playbackElapsed = Duration.zero;
    _voicePhase = VoiceNotePhase.playing;
    await _audioPlayer.play(DeviceFileSource(_recordedAudioPath!));
    notifyListeners();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      _playbackElapsed += const Duration(milliseconds: 200);
      if (_playbackElapsed >= _voiceElapsed) {
        unawaited(_stopPlayback());
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
      String? imageUrl;
      if (_imageFile != null) {
        final imageUpload = await _apiService.uploadMedia(_imageFile!);
        imageUrl = imageUpload['url'];
      }
      if (_selectedVideoPath != null) {
        final videoUpload = await _apiService.uploadMedia(
          XFile(_selectedVideoPath!),
        );
        _uploadedVideoUrl = videoUpload['video_url'] ?? videoUpload['url'];
      }
      final payload = toPayload();
      if (imageUrl != null) payload['image_url'] = imageUrl;
      if (_recordedAudioPath != null) {
        payload['audio_url'] = await _apiService.uploadFile(
          XFile(_recordedAudioPath!),
        );
      }
      await _apiService.submitReport(payload);
      await _onReportSubmitted?.call();
      _submitted = true;
      return true;
    } catch (_) {
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> _stopPlayback() async {
    _playbackTimer?.cancel();
    await _audioPlayer.stop();
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
    _recorder.dispose();
    _audioPlayer.dispose();
    _apiService.dispose();
    super.dispose();
  }
}
