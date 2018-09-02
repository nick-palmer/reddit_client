class Post {
  final String title;
  final String imageUrl;
  final String postId;

  Post(this.postId, this.title, this.imageUrl) {
    if (postId == null || title == null) {
      throw new ArgumentError("PostId and Tile cannot be null. "
          "Received: '$postId', '$title', '$imageUrl'");
    }
    if (postId.isEmpty || title.isEmpty) {
      throw new ArgumentError("PostId and Title cannot be empty. "
          "Received: '$postId', '$title', '$imageUrl'");
    }
  }

  @override
  String toString() => '$title$imageUrl$postId';
}