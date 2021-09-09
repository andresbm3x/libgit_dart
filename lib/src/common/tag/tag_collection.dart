import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit_dart/libgit_dart.dart';
import 'package:libgit_dart/src/libgit_bindings/libgit_bindings.dart';

class TagCollection extends Iterable<String> {
  final Repository _repository;

  late List<String> _tags;

  TagCollection(this._repository) {
    _tags = <String>[];

    var tags = calloc.allocate<git_strarray>(0);
    Libgit.instance((git) {
      Libgit.instance
          .handleError(git.git_tag_list(tags, _repository.repository));

      for (var i = 0; i < tags.ref.count; i++) {
        var tag = tags.ref.strings[i].cast<Utf8>().toDartString();
        _tags.add(tag);
      }

      git.git_strarray_free(tags);
    });
  }

  @override
  Iterator<String> get iterator => _tags.iterator;
}
