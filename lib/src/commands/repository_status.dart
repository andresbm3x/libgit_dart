import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit_dart/libgit_dart.dart';
import 'package:libgit_dart/src/libgit_bindings/libgit_bindings.dart';

class RepositoryStatus {
  //Get the file Status of the repository
  static Status getStatus(Repository repository) {
    final _libgit = Libgit.instance;
    final result = Status();
    final statusList = calloc.allocate<Pointer<git_status_list>>(0);
    final statusOptions =
        calloc.allocate<git_status_options>(sizeOf<git_status_options>());

    _libgit((git) {
      _libgit.handleError(git.git_status_options_init(statusOptions, 1));
      statusOptions.ref.show1 =
          git_status_show_t.GIT_STATUS_SHOW_INDEX_AND_WORKDIR;
      statusOptions.ref.flags = GIT_STATUS_OPT_DEFAULTS;

      _libgit.handleError(
          git.git_status_list_new(statusList, repository.repository, statusOptions));

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
}
