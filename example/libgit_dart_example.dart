import 'package:libgit_dart/libgit_dart.dart';

void main() {
  // final libgit = Libgit();
  print('======Open existing repository======');
  var repo = Repository.create(
      'C:/TEST/git_test'); //Repository.open('C:/Projects/Dart/password_manager');
  print(repo.workDir());

  final commits = repo.getCommitList();
  commits.forEach((element) => print(element.toString()));

  repo.free();
  // print('======Clone without credentials======');
  // repo = Repository.clone(
  //     libgit, 'https://github.com/jlord/hello.git', 'C:/test/TestClone');
  // print(repo.workDir());

  
}
