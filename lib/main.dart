import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class Post {
  Post(this.title, this.author, this.link);
  final String title;
  final String author;
  final String link;

  factory Post.fromData(dynamic data) {
    final title = data['title'];
    final author = data['by'];
    final link = data['url'] ?? "";

    return Post(title, author, link);
  }
}

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.red,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  Future<List<Post>> downloadData() async {
    final response = await http.get(Uri.parse(
        'https://hacker-news.firebaseio.com/v0/topstories.json?print=pretty'));

    final List<dynamic> postIds = jsonDecode(response.body);

    return Future.wait(postIds.take(10).map((id) async {
      final response = await http.get(Uri.parse(
          "https://hacker-news.firebaseio.com/v0/item/${id}.json?print=pretty"));
      return Post.fromData(jsonDecode(response.body));
    }));
  }

  Widget buildList(List<Post> posts) {
    return ListView.separated(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          leading: IconButton(
              onPressed: () {
                launch(posts[index].link);
              },
              icon: Icon(Icons.exit_to_app)),
          title: Text(posts[index].title),
          subtitle: Text('by ${posts[index].author}'),
        );
      },
      separatorBuilder: (context, index) {
        return Container(
          height: 1,
          color: Colors.black12,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hacker News'),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: downloadData(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return Center(
                child: CircularProgressIndicator(),
              );

            default:
              if (snapshot.error != null) {
                return Center(
                  child: Icon(
                    Icons.error,
                    size: 30,
                  ),
                );
              } else {
                List<Post>? posts =
                    (snapshot.data as List).cast<Post>().toList();
                return buildList(posts);
              }
          }
        },
      ),
    );
  }
}
