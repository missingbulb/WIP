import 'dart:convert';
import 'dart:io';

import 'material.dart';

/// Where the library lives between launches.
///
/// Phase A keeps everything on the device, so the only implementation writes a
/// file inside the app's own container — a location the user can delete by
/// deleting the app.
abstract interface class LibraryStore {
  Future<Library> load();
  Future<void> save(Library library);
}

class FileLibraryStore implements LibraryStore {
  const FileLibraryStore(this.file);

  /// The store's home inside a container directory. Named, not defaulted, so a
  /// caller cannot accidentally write outside the container.
  factory FileLibraryStore.inContainer(Directory container) =>
      FileLibraryStore(File('${container.path}/library.json'));

  final File file;

  @override
  Future<Library> load() async {
    if (!await file.exists()) return Library();
    return Library.fromJson(json.decode(await file.readAsString()) as Map<String, dynamic>);
  }

  @override
  Future<void> save(Library library) async {
    await file.parent.create(recursive: true);
    // Written aside and moved into place: a set half-written while the app is
    // killed on stage would lose the material, and losing material is the one
    // unforgivable bug. A rename within a directory is atomic.
    final pending = File('${file.path}.writing');
    await pending.writeAsString(json.encode(library.toJson()), flush: true);
    await pending.rename(file.path);
  }
}
