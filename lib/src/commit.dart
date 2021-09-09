class Commit {
  final String id;
  final String author;
  final String title;
  final String message;

  Commit(this.id, this.author, this.title, this.message);

  @override
  String toString() {
    return 'Commit(id: $id, author: $author, title: $title, message: $message)';
  }
}
