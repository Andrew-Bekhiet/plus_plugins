// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:package_info_plus_platform_interface/package_info_platform_interface.dart';

export 'src/package_info_plus_linux.dart';
export 'src/package_info_plus_windows.dart'
    if (dart.library.js_interop) 'src/package_info_plus_web.dart';

/// Application metadata. Provides application bundle information on iOS and
/// application package information on Android.
class PackageInfo {
  /// Constructs an instance with the given values for testing. [PackageInfo]
  /// instances constructed this way won't actually reflect any real information
  /// from the platform, just whatever was passed in at construction time.
  ///
  /// See [fromPlatform] for the right API to get a [PackageInfo]
  /// that's actually populated with real data.
  PackageInfo({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
    this.buildSignature = '',
    this.installerStore,
    this.installTime,
  });

  static PackageInfo? _fromPlatform;

  /// Retrieves package information from the platform.
  /// The result is cached.
  ///
  /// The [baseUrl] parameter is for web use only and the other platforms will
  /// ignore it.
  ///
  /// ## Web platform
  ///
  /// In a web environment, the package uses the `version.json` file that it is
  /// generated in the build process.
  ///
  /// The package will try to locate this file in 3 ways:
  ///
  ///   * If you provide the optional custom [baseUrl] parameter, it will be
  ///     used as the first option where to search. Example:
  ///
  ///     ```dart
  ///     await PackageInfo.fromPlatform(baseUrl: 'https://cdn.domain.com/with/some/path/');
  ///     ```
  ///
  ///     With this, the package will try to search the file in `https://cdn.domain.com/with/some/path/version.json`
  ///
  ///   * The second option where it will search is the [assetBase] parameter
  ///     that you can pass to the Flutter Web Engine when you initialize it.
  ///
  ///     ```javascript
  ///     _flutter.loader.loadEntrypoint({
  ///         onEntrypointLoaded: async function(engineInitializer) {
  ///           let appRunner = await engineInitializer.initializeEngine({
  ///             assetBase: "https://cdn.domain.com/with/some/path/"
  ///           });
  ///           appRunner.runApp();
  ///         }
  ///     });
  ///     ```
  ///
  ///     For more information about the Flutter Web Engine initialization see here:
  ///     https://docs.flutter.dev/platform-integration/web/initialization#initializing-the-engine
  ///
  ///   * Finally, if none of the previous locations return the `version.json` file,
  ///     the package will use the browser window base URL to resolve its location.
  static Future<PackageInfo> fromPlatform({String? baseUrl}) async {
    if (_fromPlatform != null) {
      return _fromPlatform!;
    }

    final platformData = await PackageInfoPlatform.instance.getAll(
      baseUrl: baseUrl,
    );

    _fromPlatform = PackageInfo(
      appName: platformData.appName,
      packageName: platformData.packageName,
      version: platformData.version,
      buildNumber: platformData.buildNumber,
      buildSignature: platformData.buildSignature,
      installerStore: platformData.installerStore,
      installTime: platformData.installTime,
    );
    return _fromPlatform!;
  }

  /// The app name.
  ///
  /// - `CFBundleDisplayName` on iOS and macOS, falls back to `CFBundleName`.
  ///   Defined in the `info.plist` and/or product target in xcode.
  /// - `application/label` on Android.
  ///   Defined in `AndroidManifest.xml` or String resources.
  /// - `app_name` from `version.json` on Web.
  ///   Defined in the `manifest.json`.
  /// - `app_name` from `version.json` on Linux.
  ///   Defined in the `CMakeLists.txt` file.
  /// - `ProductName` from the compiled executable file on Windows.
  ///    Defined in the `Runner.rc` file.
  final String appName;

  /// The package name.
  ///
  /// - `bundleIdentifier` on iOS and macOS.
  ///   Defined in the product target in xcode.
  /// - `packageName` on Android.
  ///   Defined in `build.gradle` as `applicationId`.
  /// - `package_name` from `version.json` on Web and Linux
  ///   Generated by Flutter.
  /// - `InternalName` from the compiled executable file on Windows.
  ///   Defined in the `Runner.rc` file.
  final String packageName;

  /// The package version.
  /// Generated from the version in `pubspec.yaml`.
  ///
  /// - `CFBundleShortVersionString` on iOS and macOS.
  /// - `versionName` on Android.
  /// - `version` from `version.json` on Web and Linux.
  /// - `ProductVersion` from the compiled executable file on Windows.
  final String version;

  /// The build number.
  /// Generated from the version in `pubspec.yaml`.
  ///
  /// - `CFBundleVersion` on iOS and macOs.
  /// - `versionCode` on Android.
  /// - `build_number` from `version.json` on Web and Linux.
  /// - `ProductVersion` from the compiled executable file on Windows.
  ///
  /// Note, on iOS if an app has no buildNumber specified this property will return version
  /// Docs about CFBundleVersion: https://developer.apple.com/documentation/bundleresources/information_property_list/cfbundleversion
  final String buildNumber;

  /// The build signature.
  /// SHA-256 signing key signature (hex) on Android.
  /// Empty string on all the other platforms.
  final String buildSignature;

  /// The installer store. Indicates through which store this application was installed.
  final String? installerStore;

  /// The time when the application was installed.
  ///
  /// - On Android, returns `PackageManager.firstInstallTime`
  /// - On iOS and macOS, return the creation date of the app default `NSDocumentDirectory`
  /// - On Windows and Linux, returns the creation date of the app executable.
  ///   If the creation date is not available, returns the last modified date of the app executable.
  ///   If the last modified date is not available, returns `null`.
  /// - On web, returns `null`.
  final DateTime? installTime;

  /// Initializes the application metadata with mock values for testing.
  ///
  /// If the singleton instance has been initialized already, it is overwritten.
  @visibleForTesting
  static void setMockInitialValues({
    required String appName,
    required String packageName,
    required String version,
    required String buildNumber,
    required String buildSignature,
    String? installerStore,
    DateTime? installTime,
  }) {
    _fromPlatform = PackageInfo(
      appName: appName,
      packageName: packageName,
      version: version,
      buildNumber: buildNumber,
      buildSignature: buildSignature,
      installerStore: installerStore,
      installTime: installTime,
    );
  }

  /// Overwrite equals for value equality
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PackageInfo &&
          runtimeType == other.runtimeType &&
          appName == other.appName &&
          packageName == other.packageName &&
          version == other.version &&
          buildNumber == other.buildNumber &&
          buildSignature == other.buildSignature &&
          installerStore == other.installerStore &&
          installTime == other.installTime;

  /// Overwrite hashCode for value equality
  @override
  int get hashCode =>
      appName.hashCode ^
      packageName.hashCode ^
      version.hashCode ^
      buildNumber.hashCode ^
      buildSignature.hashCode ^
      installerStore.hashCode ^
      installTime.hashCode;

  @override
  String toString() {
    return 'PackageInfo(appName: $appName, buildNumber: $buildNumber, packageName: $packageName, version: $version, buildSignature: $buildSignature, installerStore: $installerStore, installTime: $installTime)';
  }

  Map<String, dynamic> _toMap() {
    return {
      'appName': appName,
      'buildNumber': buildNumber,
      'packageName': packageName,
      'version': version,
      if (buildSignature.isNotEmpty) 'buildSignature': buildSignature,
      if (installerStore?.isNotEmpty ?? false) 'installerStore': installerStore,
      if (installTime != null) 'installTime': installTime
    };
  }

  /// Gets a map representation of the [PackageInfo] instance.
  Map<String, dynamic> get data => _toMap();
}
