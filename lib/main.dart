import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:reddit_client/models/post.dart';
//import 'package:reddit_client/widgets/infinite_scroll.dart';

// Entry point into the app
void main() => runApp(RedditClient());

// Main Widget
class RedditClient extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Today I Learned Stuffs...',
      theme: new ThemeData(primaryColor: Colors.red,),
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
  var _futureBuilder;
  ScrollController _scrollController = new ScrollController();
  bool isPerformingRequest = false;
  // final _biggerFont = const TextStyle(fontSize: 18.0);


  @override
  void initState() {
    print('initState()');
    super.initState();

    // Create the scroll controller, which gets additional posts when at the
    // bottom of the page.
    _scrollController.addListener(() {
      if (_posts.isNotEmpty && _scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _lastPostId = _posts[_posts.length - 1].postId;
        print('Post count...');
        print(_posts.length);
        print('Got last post id: $_lastPostId, need to request more.');
        _getPosts(_lastPostId);
      }
    });

    // Included the future builder here so the async request occurs only once
    _futureBuilder = new FutureBuilder(
      future: _makeRequest(_lastPostId),
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
              print("Recieved response, building inital post list");
              _posts.addAll(snapshot.data);
              return _buildPostList(context, snapshot);
            }
        }
      },
    );

  }


  @override
  void dispose() {
    print("DISPOSE");
    _scrollController.dispose();
    super.dispose();
  }


  _getPosts(var lastPostId) async {
    print("isPerformingRequest:$isPerformingRequest, params:$lastPostId");
    if (!isPerformingRequest) {
      setState(() => this.isPerformingRequest = true);

      List<Post> newPosts = await _makeRequest(lastPostId);
      print("Got response data, setting state...");
      setState(() {
        this._posts.addAll(newPosts);
        this.isPerformingRequest = false;
      });
      print(_posts.length);

    }
  }

  Future<List<Post>> _makeRequest(var postId) async {
    List<Post> posts = new List<Post>();
    var url = "https://www.reddit.com/r/todayilearned.json";
    if(postId != null) {
      url += '?after=$postId';
    }
    print("Making request to $url");
    await http.get(url).then((res) async {
      Map decoded = json.decode(res.body);

      var data = decoded['data'];
      for (var post in data['children']) {
        Post rPost = new Post(
            post['data']['name'],
            post['data']['title'],
            post['data']['thumbnail']
        );
        posts.add(rPost);
      }
    });
    return posts;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('/r/TodayILearned Posts'),
      ),
      body: _futureBuilder,
    );
  }


  Widget _buildPostList(BuildContext context, AsyncSnapshot snapshot) {
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _posts.length,
        itemBuilder: (BuildContext context, int i) {
          print(_posts[i].postId);
          return _buildRow(_posts[i]);
        },
      controller: _scrollController,
    );
  }

  Widget _buildRow(Post post) {
    return ListTile(
     // leading: Image.network(post.imageUrl),
      title: Text(
        post.title,
        //style: _biggerFont,
      )
    );
  }
}
