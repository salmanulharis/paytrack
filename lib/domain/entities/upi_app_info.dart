import 'package:equatable/equatable.dart';

class UpiAppInfo extends Equatable {
  const UpiAppInfo({
    required this.id,
    required this.name,
    required this.packageName,
    this.iosSchemes = const [],
    this.iosPayPath = 'pay',
    this.isInstalled = true,
    this.usageCount = 0,
    this.lastUsedAt,
  });

  final String id;
  final String name;

  /// Android application id used with [Intent.setPackage].
  final String packageName;

  /// iOS URL schemes to probe (e.g. `phonepe`, `tez`). Requires Info.plist queries.
  final List<String> iosSchemes;

  /// Path/host segment after scheme for iOS deep link (`pay` or `upi/pay`).
  final String iosPayPath;

  final bool isInstalled;
  final int usageCount;
  final DateTime? lastUsedAt;

  static const List<UpiAppInfo> knownApps = [
    UpiAppInfo(
      id: 'gpay',
      name: 'Google Pay',
      packageName: 'com.google.android.apps.nbu.paisa.user',
      iosSchemes: ['tez', 'gpay', 'googlepay'],
      iosPayPath: 'upi/pay',
    ),
    UpiAppInfo(
      id: 'phonepe',
      name: 'PhonePe',
      packageName: 'com.phonepe.app',
      iosSchemes: ['phonepe'],
      iosPayPath: 'pay',
    ),
    UpiAppInfo(
      id: 'paytm',
      name: 'Paytm',
      packageName: 'net.one97.paytm',
      iosSchemes: ['paytmmp', 'paytm'],
      iosPayPath: 'pay',
    ),
    UpiAppInfo(
      id: 'cred',
      name: 'CRED',
      packageName: 'com.dreamplug.androidapp',
      iosSchemes: ['credpay', 'cred'],
      iosPayPath: 'pay',
    ),
    UpiAppInfo(
      id: 'jupiter',
      name: 'Jupiter',
      packageName: 'money.jupiter',
      iosSchemes: ['jupiter'],
      iosPayPath: 'pay',
    ),
    UpiAppInfo(
      id: 'bhim',
      name: 'BHIM',
      packageName: 'in.org.npci.upiapp',
      iosSchemes: ['bhim'],
      iosPayPath: 'pay',
    ),
    UpiAppInfo(
      id: 'amazonpay',
      name: 'Amazon Pay',
      packageName: 'in.amazon.mShop.android.shopping',
      iosSchemes: ['amazonpay'],
      iosPayPath: 'pay',
    ),
  ];

  UpiAppInfo copyWith({
    String? id,
    String? name,
    String? packageName,
    List<String>? iosSchemes,
    String? iosPayPath,
    bool? isInstalled,
    int? usageCount,
    DateTime? lastUsedAt,
  }) {
    return UpiAppInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      packageName: packageName ?? this.packageName,
      iosSchemes: iosSchemes ?? this.iosSchemes,
      iosPayPath: iosPayPath ?? this.iosPayPath,
      isInstalled: isInstalled ?? this.isInstalled,
      usageCount: usageCount ?? this.usageCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        packageName,
        iosSchemes,
        iosPayPath,
        isInstalled,
        usageCount,
        lastUsedAt,
      ];
}
