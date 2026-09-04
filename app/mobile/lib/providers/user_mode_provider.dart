import 'package:flutter/foundation.dart';

/// App-wide view mode. Citizen feed is the default landing experience.
class UserModeProvider extends ChangeNotifier {
  bool _isCitizenMode = true;
  String _username = 'Username';

  bool get isCitizenMode => _isCitizenMode;
  String get username => _username;
  String get modeLabel => _isCitizenMode ? 'Citizen Mode' : 'Official Mode';

  void toggleMode() {
    _isCitizenMode = !_isCitizenMode;
    notifyListeners();
  }

  void setCitizenMode(bool value) {
    if (_isCitizenMode == value) return;
    _isCitizenMode = value;
    notifyListeners();
  }

  void setUsername(String value) {
    if (_username == value) return;
    _username = value;
    notifyListeners();
  }
}
