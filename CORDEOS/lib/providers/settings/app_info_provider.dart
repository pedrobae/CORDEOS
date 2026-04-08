import 'dart:async';
import 'dart:io';

import 'package:cordeos/models/domain/bug_report.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfoProvider extends ChangeNotifier {
  PackageInfo? _packageInfo;
  bool _isLoading = false;

  String get appVersion => _packageInfo?.version ?? 'Unknown';
  String get appVersionWithBuild => _packageInfo != null 
      ? '${_packageInfo!.version}+${_packageInfo!.buildNumber}' 
      : 'Unknown';
  String get deviceInfo => '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
  bool get isLoading => _isLoading;

  AppInfoProvider();

  Future<void> initialize() async {
    await _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    _isLoading = true;
    try {
      _packageInfo = await PackageInfo.fromPlatform();
    } catch (e) {
      _packageInfo = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<NetworkState> getNetworkState() async {
    try {
      // Lightweight reachability check without platform plugin.
      final result = await InternetAddress.lookup('one.one.one.one').timeout(
        const Duration(seconds: 3),
      );
      if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
        return NetworkState.online;
      }
      return NetworkState.offline;
    } on SocketException {
      return NetworkState.offline;
    } on TimeoutException {
      return NetworkState.intermittent;
    } catch (e) {
      return NetworkState.intermittent;
    }
  }
}
