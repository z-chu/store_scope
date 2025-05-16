import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kDebugMode;



class StoreScopeConfig {
  static bool isLogEnable = kDebugMode;
  static bool throwOnCloseError = kDebugMode;
  static LogWriterCallback log = defaultLogWriterCallback;
}

///VoidCallback from logs
typedef LogWriterCallback = void Function(String text, {bool isError});

/// default logger from GetX
void defaultLogWriterCallback(String value, {bool isError = false}) {
  if (isError || StoreScopeConfig.isLogEnable) developer.log(value, name: 'STORE_SCOPE');
}
