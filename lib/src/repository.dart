import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:libgit_dart/libgit_dart.dart';
import 'package:libgit_dart/src/commit.dart';
import 'package:libgit_dart/src/libgit_bindings/libgit_bindings.dart';

class Repository {
  static final Libgit _libgit = Libgit.instance;
  late Pointer<git_repository> repository;

  Repository._(this.repository);

  factory Repository.create(String path) {
    final repoOut = calloc<Pointer<git_repository>>();

    _libgit((bindings) => _libgit.handleError(
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

    _libgit((git) => result = _libgit.bindings
        .git_repository_workdir(repository)
        .cast<Utf8>()
        .toDartString());

    return result;
  }

  //Get the file Status of the repository
  Status getStatus() {
    final result = Status();
    final statusList = calloc.allocate<Pointer<git_status_list>>(0);
    final statusOptions =
        calloc.allocate<git_status_options>(sizeOf<git_status_options>());

    _libgit((git) {
      _libgit.handleError(git.git_status_options_init(statusOptions, 1));
      statusOptions.ref.show_1 =
          git_status_show_t.GIT_STATUS_SHOW_INDEX_AND_WORKDIR;
      statusOptions.ref.flags = GIT_STATUS_OPT_DEFAULTS;

      _libgit.handleError(
          git.git_status_list_new(statusList, repository, statusOptions));

      final count = git.git_status_list_entrycount(statusList.value);
      for (var i = 0; i < count; i++) {
        final diffOptions =
            calloc.allocate<git_diff_options>(sizeOf<git_diff_options>());
        Pointer<git_status_entry> statusEntry;
        _libgit.handleError(git.git_diff_options_init(diffOptions, 1));

        statusEntry = git.git_status_byindex(statusList.value, i);

        final headToIndexAddress = statusEntry.ref.head_to_index.address;
        final indexToWorkdirAddress = statusEntry.ref.index_to_workdir.address;
        if (headToIndexAddress != 0) {
          final headToIndex = statusEntry.ref.head_to_index.ref;
          final newFile = headToIndex.new_file;

          final newFilePath = newFile.path.cast<Utf8>().toDartString();

          result.staged.add(FileStatus(newFilePath, FileState.Changed));
        }

        if (indexToWorkdirAddress != 0) {
          final indexToWorkdir = statusEntry.ref.index_to_workdir.ref;
          final file = indexToWorkdir.new_file;
          final newFilePath = file.path.cast<Utf8>().toDartString();
          result.unstaged.add(FileStatus(newFilePath, FileState.Changed));
        }

        calloc.free(diffOptions);
      }
    });

    calloc.free(statusOptions);

    return result;
  }

  //get all the current reference
  String getReference(String branch) {
    var result = '';
    branch = 'refs/heads/master';

    var ref = calloc.allocate<Pointer<git_reference>>(0);

    _libgit((git) {
      _libgit.handleError(git.git_reference_lookup(
          ref, repository, branch.toNativeUtf8().cast()));

      var refName = git.git_reference_name(ref.value);

      result = refName.cast<Utf8>().toDartString();

      git.git_reference_free(ref.value);
    });

    return result;
  }

  // Get all the references.
  List<String> getAllReferences() {
    var result = <String>[];

    _libgit((git) {
      final refs = calloc.allocate<git_strarray>(0);
      _libgit.handleError(git.git_reference_list(refs, repository));

      for (var i = 0; i < refs.ref.count; i++) {
        var ref = refs.ref.strings[i].cast<Utf8>().toDartString();
        result.add(ref);
      }

      git.git_strarray_free(refs);
    });

    return result;
  }

  // get all the references that are brances (with iterator)
  List<String> getBranches() {
    var result = <String>[];

    _libgit((git) {
      var reference = calloc.allocate<Pointer<git_reference>>(0);
      var iterator = calloc.allocate<Pointer<git_reference_iterator>>(0);
      ////método con Callback que no es necesario
      //git.git_reference_foreach(repository, Pointer.fromFunction<git_reference_foreach_cb>(_eachRef,0), nullptr);

      _libgit.handleError(git.git_reference_iterator_new(iterator, repository));

      while (git.git_reference_next(reference, iterator.value) !=
          git_error_code.GIT_ITEROVER) {
        if (git.git_reference_is_branch(reference.value) == 1) {
          var refName = git
              .git_reference_name(reference.value)
              .cast<Utf8>()
              .toDartString();
          result.add(refName);
        }
      }

      git.git_reference_iterator_free(iterator.value);
      git.git_reference_free(reference.value);
    });

    return result;
  }

  // //Callback for the foreach on git_reference_foreach
  // //NOTE: It has to be static by eggs..!!
  // @Int32()
  // static int _eachRef(Pointer<git_reference> ref, Pointer<Void> payload) {
  //   print('internal callback: ' +
  //       _libgit.bindings.git_reference_name(ref).cast<Utf8>().toDartString());
  //   return 0;
  // }

  List<String> getAllTags() {
    var result = <String>[];

    var tags = calloc.allocate<git_strarray>(0);
    _libgit((git) {
      _libgit.handleError(git.git_tag_list(tags, repository));

      for (var i = 0; i < tags.ref.count; i++) {
        var tag = tags.ref.strings[i].cast<Utf8>().toDartString();
        result.add(tag);
      }

      git.git_strarray_free(tags);
    });

    return result;
  }

  //NO FUNCIONA: misa no entender..
  List<Commit> getCommitListOld() {
    final commits = <Commit>[];

    _libgit((git) {
      var walker = calloc.allocate<Pointer<git_revwalk>>(0);
      try {
        _libgit.handleError(git.git_revwalk_new(walker, repository));

        var oid = calloc.allocate<git_oid>(0);
        while (git.git_revwalk_next(oid, walker.value) !=
            git_error_code.GIT_ITEROVER) {
          var commitPointer = calloc.allocate<Pointer<git_commit>>(0);
          try {
            _libgit.handleError(
                git.git_commit_lookup(commitPointer, repository, oid));
            var commit = commitPointer.value;

            var id = git.git_commit_id(commit);
            var message = git.git_commit_message(commit);
            var summary = git.git_commit_summary(commit);
            var author = git.git_commit_author(commit);

            commits.add(
              Commit(
                  id.ref.id.toString(),
                  author.ref.name.cast<Utf8>().toDartString(),
                  message.cast<Utf8>().toDartString(),
                  summary.cast<Utf8>().toDartString()),
            );
          } finally {
            git.git_commit_free(commitPointer.value);
          }
        }
      } finally {
        git.git_revwalk_free(walker.value);
      }
    });

    return commits;
  }

  //FUNCIONA (WIP)
  List<Commit> getCommitList() {
    final commits = <Commit>[];

    _libgit((git) {
      var walker = calloc.allocate<Pointer<git_revwalk>>(0);
      var oid = calloc.allocate<git_oid>(0);
      try {
        _libgit.handleError(git.git_revwalk_new(walker, repository));
        _libgit.handleError(git.git_revwalk_sorting(walker.value, git_sort_t.GIT_SORT_TIME));
        _libgit.handleError(git.git_revwalk_push_head(walker.value));
        _libgit.handleError(git.git_revwalk_push_ref(walker.value, 'HEAD'.toNativeUtf8().cast()));

        //_libgit.handleError(git.git_revwalk_next(oid, walker.value));

        while (git.git_revwalk_next(oid, walker.value) == 0) {
          var commitPointer = calloc.allocate<Pointer<git_commit>>(0);
          try {
            _libgit.handleError(
                git.git_commit_lookup(commitPointer, repository, oid));
            var commit = commitPointer.value;
            var out = calloc.allocate<Int8>(0);
            var id = git.git_commit_id(commit);

            git.git_oid_tostr(out, 9, id);// da un mini id del commit
            var message = git.git_commit_message(commit);
            var summary = git.git_commit_summary(commit);
            var author = git.git_commit_author(commit);
            

            commits.add(
              Commit(
                  out.cast<Utf8>().toDartString(),
                  author.ref.name.cast<Utf8>().toDartString(),
                  message.cast<Utf8>().toDartString(),
                  summary.cast<Utf8>().toDartString()),
            );
          } finally {
            git.git_commit_free(commitPointer.value);
          }
        }
      } finally {
        git.git_revwalk_free(walker.value);
      }
    });

    return commits;
  }

  void free() =>
      _libgit((git) => _libgit.bindings.git_repository_free(repository));
}
