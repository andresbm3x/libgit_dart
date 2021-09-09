import 'package:libgit_dart/libgit_dart.dart';

class CommitCommand {
  final Repository _repository;
  final Status _status;

  CommitCommand(this._repository, this._status);

  void stageFiles(List<String> files) {}
  void unstageFiles(List<String> files) {}

  void stageAll() {}
  void unstageAll() {}

  void stageFile(String filePath) {}
  void unstageFile(String filePath) {}

  void commit(){

  }
}
