import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:libgit_dart/libgit_dart.dart';
import 'package:libgit_dart/src/libgit_bindings/libgit_bindings.dart';

class Repository {
  late Pointer<git_repository> repository;

  Repository._(this.repository);

  factory Repository.create(String path) {
    final repoOut = calloc<Pointer<git_repository>>();

    Libgit.instance((bindings) => Libgit.instance.handleError(
        bindings.git_repository_init(repoOut, path.toNativeUtf8().cast(), 0)));

    return Repository._(repoOut.value);
  }

  factory Repository.open(Libgit libgit, String path) {
    final repository = calloc<Pointer<git_repository>>();

    libgit((bindings) => libgit.handleError(
        bindings.git_repository_open(repository, path.toNativeUtf8().cast())));

    return Repository._(repository.value);
  }

  factory Repository.clone(Libgit libgit, String url, String path) {
    final repository = calloc<Pointer<git_repository>>();

    libgit((bindings) => libgit.handleError(bindings.git_clone(repository,
        url.toNativeUtf8().cast(), path.toNativeUtf8().cast(), nullptr)));

    return Repository._(repository.value);
  }

  factory Repository.cloneWithProgress(Libgit libgit, String url, String path) {
    final repository = calloc<Pointer<git_repository>>();

    //initialize options
    var options =
        calloc.allocate<git_clone_options>(sizeOf<git_clone_options>());
    libgit((bindings) => libgit.handleError(
        bindings.git_clone_init_options(options, GIT_CLONE_OPTIONS_VERSION)));

    var progress = calloc<git_indexer_options>(sizeOf<git_indexer_options>());
    // progress.ref.progress_cb_payload

    options.ref.fetch_opts.callbacks.transfer_progress = progress.cast();

    //clone the repo
    libgit((bindings) => libgit.handleError(bindings.git_clone(repository,
        url.toNativeUtf8().cast(), path.toNativeUtf8().cast(), nullptr)));

    return Repository._(repository.value);
  }

  factory Repository.cloneWithAuth(
      Libgit libgit, String url, String path, String user, String pass) {
    final repository = calloc<Pointer<git_repository>>();

    //initialize options
    var options =
        calloc.allocate<git_clone_options>(sizeOf<git_clone_options>());
    libgit((bindings) => libgit.handleError(
        bindings.git_clone_init_options(options, GIT_CLONE_OPTIONS_VERSION)));

    //set the credentials
    //var cred = calloc<Pointer<git_credential>>();

    // var fun = (Pointer<Pointer<git_credential>> cred, Pointer<Int8> url,
    //     Pointer<Int8> username, Uint32 allowedTypes, Pointer<Void> payload) {
    //   //t.ref.parent = cred.value.ref;
    //   print('test');
    //   return (libgit.bindings.git_credential_userpass_plaintext_new(
    //           cred, user.toNativeUtf8().cast(), pass.toNativeUtf8().cast())
    //       as Int32);
    // };

    // var func = libgit.bindings.git_credential_userpass(
    //     Pointer.fromAddress(cred.address),
    //     nullptr,
    //     nullptr,
    //     GIT_CREDTYPE_USERPASS_PLAINTEXT,
    //     nullptr);

    // options.ref.fetch_opts.callbacks.credentials = Pointer.fromFunction(func).cast();

    //call the clone with options
    libgit((bindings) => libgit.handleError(bindings.git_clone(repository,
        url.toNativeUtf8().cast(), path.toNativeUtf8().cast(), options)));

    calloc.free(options);

    return Repository._(repository.value);
  }

  String? workDir() {
    String? result;

    Libgit.instance((git) => result = Libgit.instance.bindings
        .git_repository_workdir(repository)
        .cast<Utf8>()
        .toDartString());

    return result;
  }

  void free() => Libgit.instance(
      (git) => Libgit.instance.bindings.git_repository_free(repository));
}
