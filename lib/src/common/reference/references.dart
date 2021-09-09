import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit_dart/libgit_dart.dart';
import 'package:libgit_dart/src/libgit_bindings/libgit_bindings.dart';

class References {
  static List<String> getAllReferences(Repository repository) {
    var result = <String>[];

    Libgit.instance((git) {
      final refs = calloc.allocate<git_strarray>(0);
      Libgit.instance
          .handleError(git.git_reference_list(refs, repository.repository));

      for (var i = 0; i < refs.ref.count; i++) {
        var ref = refs.ref.strings[i].cast<Utf8>().toDartString();
        result.add(ref);
      }

      git.git_strarray_free(refs);
    });

    return result;
  }

  static List<String> getBranches(Repository repository) {
    var result = <String>[];

    Libgit.instance((git) {
      var reference = calloc.allocate<Pointer<git_reference>>(0);
      var iterator = calloc.allocate<Pointer<git_reference_iterator>>(0);
      ////método con Callback que no es necesario
      //git.git_reference_foreach(repository, Pointer.fromFunction<git_reference_foreach_cb>(_eachRef,0), nullptr);

      Libgit.instance.handleError(
          git.git_reference_iterator_new(iterator, repository.repository));

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

  // get all the references that are brances (with iterator)

  // //Callback for the foreach on git_reference_foreach
  // //NOTE: It has to be static by eggs..!!
  // @Int32()
  // static int _eachRef(Pointer<git_reference> ref, Pointer<Void> payload) {
  //   print('internal callback: ' +
  //       _libgit.bindings.git_reference_name(ref).cast<Utf8>().toDartString());
  //   return 0;
  // }

  static String getReference(Repository repository, String branch) {
    var result = '';
    branch = 'refs/heads/master';

    var ref = calloc.allocate<Pointer<git_reference>>(0);

    Libgit.instance((git) {
      Libgit.instance.handleError(git.git_reference_lookup(
          ref, repository.repository, branch.toNativeUtf8().cast()));

      var refName = git.git_reference_name(ref.value);

      result = refName.cast<Utf8>().toDartString();

      git.git_reference_free(ref.value);
    });

    return result;
  }
}
