import 'package:libgit_dart/libgit_dart.dart';

void main() {
  print('======Open existing repository======');
  var repo = Repository.create(
      'C:/TEST/git_test'); //Repository.open('C:/Projects/Dart/password_manager');
  print('======Repository Working path======');
  print(repo.workDir());

  print('======Tag list======');
  var tags = TagCollection(repo);
  tags.forEach(print);
  print('======Commit list======');
  var commits = CommitCollection(repo);
  commits.forEach(print);
  print('======Branches list======');
  var refs = References.getBranches(repo);
  refs.forEach(print);
  print('======references list======');
  var refs2 = References.getAllReferences(repo);
  refs2.forEach(print);
  print('======STATUS======');
  var status = RepositoryStatus.getStatus(repo);
  print('======STATUS - Staged======');
  status.staged.forEach(print);
  print('======STATUS - unestaged======');
  status.unstaged.forEach(print);


  print('======Release the repository======');
  repo.free();
  // print('======Clone without credentials======');
  // repo = Repository.clone(
  //     libgit, 'https://github.com/jlord/hello.git', 'C:/test/TestClone');
  // print(repo.workDir());
}
