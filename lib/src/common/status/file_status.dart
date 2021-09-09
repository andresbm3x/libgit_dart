
enum FileState {
  Added,
  Changed,
  Removed,
}


class FileStatus {
  final String filePath;
  final FileState state;

  FileStatus(this.filePath, this.state);
}