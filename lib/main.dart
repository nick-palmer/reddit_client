import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:reddit_client/models/post.dart';
//import 'package:reddit_client/widgets/infinite_scroll.dart';

// Entry point into the app
void main() => runApp(RedditClient());
//void main() => runApp(InfiniteScroll());

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
  var _lastPostId;
  final _biggerFont = const TextStyle(fontSize: 18.0);
  ScrollController _scrollController = new ScrollController();
  bool isPerformingRequest = false;


  @override
  void initState() {
    super.initState();
    print('In initState()');
    _scrollController.addListener(() {
      print(_scrollController.position.pixels);
      print(_scrollController.position.maxScrollExtent);
      if (_posts.isNotEmpty && _scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        _lastPostId = _posts[_posts.length - 1].postId;
        print('Got last post id: $_lastPostId');
        _getPosts(_lastPostId);
      }
    });
  }


  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {

    var futureBuilder = new FutureBuilder(
      future: _makeRequest(null),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        print(snapshot);
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            print("LOADING");
            return new Text('loading...');
          default:
            if (snapshot.hasError) {
              print("ERROR::");
              return new Text('Error: ${snapshot.error}');
            }
            else {
              print("Building inital post list");
              _posts.addAll(snapshot.data);
              return _buildPostList(context, snapshot);
            }
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('/r/TodayILearned Posts'),
      ),
      body: futureBuilder,
    );
  }


  Widget _buildPostList(BuildContext context, AsyncSnapshot snapshot) {
    List<Post> newPosts = snapshot.data;
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: newPosts.length,
        itemBuilder: (context, i) {
          return _buildRow(newPosts[i]);
        },
      controller: _scrollController,
    );
  }

  Widget _buildRow(Post post) {
    return ListTile(
      leading: Image.network(post.imageUrl),
      title: Text(
        post.title,
        style: _biggerFont,
      )
    );
  }

  _getPosts(var lastPostId) async {
    print("isPerformingRequest:$isPerformingRequest, params:$lastPostId");
    if (!isPerformingRequest) {
      setState(() => isPerformingRequest = true);

      List<Post> newPosts = await _makeRequest(lastPostId);
      print("Got response data, setting state...");
      print(newPosts[0].postId);
      setState(() {
        _posts.addAll(newPosts);
        print(_posts.length);
        isPerformingRequest = false;
      });
    }
  }

  Future<List<Post>> _makeRequest(var postId) async {
    List<Post> posts = new List<Post>();
    var url = "https://www.reddit.com/r/todayilearned.json";
    if(postId != null) {
      url += '?$postId';
    }
    print("Making request to $url");
    await http.get(url).then((res) async {
      Map decoded = json.decode(res.body);

      var data = decoded['data'];
      for (var post in data['children']) {
        Post rPost = new Post(post['data']['name'], post['data']['title'],
            post['data']['thumbnail']);
        posts.add(rPost);
      }
    });
    print('makeRequest():posts:');
    return posts;
  }
}
