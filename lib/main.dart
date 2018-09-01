import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// Entry point into the app
void main() => runApp(RedditClient());

// Main Widget
class RedditClient extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Today I Learned Stuffs...',
      theme: new ThemeData(
        primaryColor: Colors.red,
      ),
      home: RedditPosts(),
    );
  }
}

class RedditPosts extends StatefulWidget {
  @override
  RedditPostsState createState() => new RedditPostsState();
}

// Widget for the main list of posts
class RedditPostsState extends State<RedditPosts> {
  var _posts = List<Post>();
  final Set<Post> _liked = new Set<Post>();
  final _biggerFont = const TextStyle(fontSize: 18.0);

  @override
  void initState() {
    super.initState();

    print('In initState()');

    getPosts(null).then((result) {
      print('In setState(), results: $result');
      setState(() {
        print('In setState().setState(), results: $result');
        _posts = result;
      });
    }).catchError((err) {
      print('Error getting posts: $err');
    });
  }

  @override
  Widget build(BuildContext context) {
    if(_posts == null || _posts.length == 0) {
      print('if _posts == null');
      return new Scaffold(
        appBar: new AppBar(
          title: new Text("Loading..."),
        ),
      );
    } else {
      print('else _posts == $_posts');
      return Scaffold(
        appBar: AppBar(
          title: Text('/r/TodayILearned Posts'),
          actions: <Widget>[
            new IconButton(icon: const Icon(Icons.list), onPressed: _pushSaved),
          ],
        ),
        // TODO: change back to _buildPostList() once http request data comes back async
        body: _buildPostList(),
      );
    }
  }

  Widget _buildPostList() {
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        // The itemBuilder callback is called once per suggested word pairing,
        // and places each suggestion into a ListTile row.
        // For even rows, the function adds a ListTile row for the word pairing.
        // For odd rows, the function adds a Divider widget to visually
        // separate the entries. Note that the divider may be difficult
        // to see on smaller devices.
        itemBuilder: (context, i) {
          // Add a one-pixel-high divider widget before each row in theListView.
          if (i.isOdd) return Divider();

          // The syntax "i ~/ 2" divides i by 2 and returns an integer result.
          // For example: 1, 2, 3, 4, 5 becomes 0, 1, 1, 2, 2.
          // This calculates the actual number of word pairings in the ListView,
          // minus the divider widgets.
          final index = i ~/ 2;
          // If you've reached the end of the available word pairings...
          if (index >= _posts.length) {
            // ...then generate 10 more and add them to the suggestions list.

            // TODO: figure out how to get this working async
            List<Post> newPosts;
            getPosts('').then((result) {
              print('Got next page of results...');
              _posts.addAll(newPosts);
            });

          }
          print('In _buildPostList(), index: $index');
          return _buildRow(_posts[index]);
          //return null;
        }
    );
  }

  Widget _buildRow(Post post) {
    final bool alreadySaved = _liked.contains(post);

    return ListTile(
      leading: Image.network(post.imageUrl),
      title: Text(
        post.title,
        style: _biggerFont,
      ),
      trailing: new Icon(   // Add the lines from here...
        alreadySaved ? Icons.check_box : Icons.check_box_outline_blank,
        color: alreadySaved ? Colors.red : null,
      ),
      onTap: () {
        setState(() {
          if (alreadySaved) {
            _liked.remove(post);
          } else {
            _liked.add(post);
          }
        });
      },
    );
  }

  void _pushSaved() {
    Navigator.of(context).push(
      new MaterialPageRoute<void>(
        builder: (BuildContext context) {
          final Iterable<ListTile> tiles = _liked.map(
                (Post post) {
              return new ListTile(
                title: new Text(
                  post.title,
                  style: _biggerFont,
                ),
              );
            },
          );
          final List<Widget> divided = ListTile
              .divideTiles(
            context: context,
            tiles: tiles,
          )
              .toList();
          return new Scaffold(
            appBar: new AppBar(
              title: const Text('Saved Posts'),
            ),
            body: new ListView(children: divided),
          );
        },
      ),
    );
  }

  Future<List<Post>> getPosts(var lastPostId) async {
    List<Post> posts = new List<Post>();

    var url = "https://www.reddit.com/r/todayilearned.json";
    if(lastPostId != null) {
      url += '?$lastPostId';
    }
    await http.get(url).then((res) async {
      Map decoded = json.decode(res.body);

      var data = decoded['data'];
      for (var post in data['children']) {
        Post rPost = new Post(post['data']['name'],post['data']['title'],post['data']['thumbnail']);
        posts.add(rPost);
      }
      print('posts: $posts');

    });

    return posts;
  }
}


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