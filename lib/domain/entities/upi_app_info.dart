import 'package:equatable/equatable.dart';

class UpiAppInfo extends Equatable {
  const UpiAppInfo({
    required this.id,
    required this.name,
    required this.packageName,
    this.isInstalled = true,
    this.usageCount = 0,
    this.lastUsedAt,
  });

  final String id;
  final String name;
  final String packageName;
  final bool isInstalled;
  final int usageCount;
  final DateTime? lastUsedAt;

  static const List<UpiAppInfo> knownApps = [
    UpiAppInfo(
      id: 'gpay',
      name: 'Google Pay',
      packageName: 'com.google.android.apps.nbu.paisa.user',
    ),
    UpiAppInfo(
      id: 'phonepe',
      name: 'PhonePe',
      packageName: 'com.phonepe.app',
    ),
    UpiAppInfo(
      id: 'paytm',
      name: 'Paytm',
      packageName: 'net.one97.paytm',
    ),
    UpiAppInfo(
      id: 'cred',
      name: 'CRED',
      packageName: 'com.dreamplug.androidapp',
    ),
    UpiAppInfo(
      id: 'jupiter',
      name: 'Jupiter',
      packageName: 'money.jupiter',
    ),
    UpiAppInfo(
      id: 'bhim',
      name: 'BHIM',
      packageName: 'in.org.npci.upiapp',
    ),
    UpiAppInfo(
      id: 'amazonpay',
      name: 'Amazon Pay',
      packageName: 'in.amazon.mShop.android.shopping',
    ),
  ];

  UpiAppInfo copyWith({
    String? id,
    String? name,
    String? packageName,
    bool? isInstalled,
    int? usageCount,
    DateTime? lastUsedAt,
  }) {
    return UpiAppInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      packageName: packageName ?? this.packageName,
      isInstalled: isInstalled ?? this.isInstalled,
      usageCount: usageCount ?? this.usageCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, packageName, isInstalled, usageCount, lastUsedAt];
}
