import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sync_engine.dart';

/// Emits a new value after every successful server pull. Paged / derived
/// providers `ref.watch` this to reload from the freshly-merged local data.
final syncRevisionProvider = StreamProvider<int>((ref) {
  final ctrl = StreamController<int>();
  void listener() => ctrl.add(SyncEngine.instance.revision.value);
  SyncEngine.instance.revision.addListener(listener);
  ref.onDispose(() {
    SyncEngine.instance.revision.removeListener(listener);
    ctrl.close();
  });
  ctrl.add(SyncEngine.instance.revision.value);
  return ctrl.stream;
});
