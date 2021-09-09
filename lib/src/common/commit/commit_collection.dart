import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit_dart/libgit_dart.dart';
import 'package:libgit_dart/src/common/commit/commit.dart';
import 'package:libgit_dart/src/libgit_bindings/libgit_bindings.dart';

class CommitCollection extends Iterable<Commit> {
  late List<Commit> _commits;

  CommitCollection(Repository repository) {
    _commits = _getCommits(repository);
  }

  @override
  Iterator<Commit> get iterator => _commits.iterator;
}

List<Commit> _getCommits(Repository repository) {
  final commits = <Commit>[];

  Libgit.instance((git) {
    var walker = calloc<Pointer<git_revwalk>>();
    var oid = calloc<git_oid>();
    try {
      Libgit.instance
          .handleError(git.git_revwalk_new(walker, repository.repository));
      Libgit.instance.handleError(
          git.git_revwalk_sorting(walker.value, git_sort_t.GIT_SORT_TIME));
      Libgit.instance.handleError(git.git_revwalk_push_head(walker.value));
      Libgit.instance.handleError(
          git.git_revwalk_push_ref(walker.value, 'HEAD'.toNativeUtf8().cast()));

      while (git.git_revwalk_next(oid, walker.value) == 0) {
        var commitPointer = calloc<Pointer<git_commit>>();
        try {
          Libgit.instance.handleError(
              git.git_commit_lookup(commitPointer, repository.repository, oid));
          var commit = commitPointer.value;
          var out = calloc<Int8>();
          var id = git.git_commit_id(commit);

          git.git_oid_tostr(out, 9, id); // da un mini id del commit
          //git.git_oid_tostr(out, GIT_OID_HEXSZ, id); 
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
