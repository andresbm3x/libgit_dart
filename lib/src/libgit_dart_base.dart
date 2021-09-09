import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:libgit_dart/src/libgit_bindings/libgit_bindings.dart';

class Libgit {
  final LibgitBindings bindings = LibgitBindings(getLibPath());

  static final Libgit _instance = Libgit._internal();

  static Libgit get instance => _instance;

  Libgit._internal();

  void call(Function(LibgitBindings git) callback) {
    try {
      init();
      callback(bindings);
    } catch (e) {
      print(e);
      //rethrow;
    } finally {
      shutdown();
    }
  }

  void init() => bindings.git_libgit2_init();
  void shutdown() => bindings.git_libgit2_shutdown();

  void handleError(int errorCode) {
    if (errorCode < 0) {
      var lastError = bindings.git_error_last();
      final error = lastError.ref.message.cast<Utf8>().toDartString();
      throw Exception('Handled error: ' + error);
    }
  }

  static DynamicLibrary getLibPath() {
    DynamicLibrary libGit;
    if (Platform.isLinux) {
      libGit = DynamicLibrary.open(
          '/home/abde/Projects/C/libgit2-1.1.0/build/libgit2.so');
    } else if (Platform.isWindows) {
      libGit = DynamicLibrary.open('C:/Projects/libgit/build/git2.dll');
    } else {
      throw UnimplementedError("Platform not handled");
    }
    return libGit;
  }
}
