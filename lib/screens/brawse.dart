import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:video_player/video_player.dart';


class BrowseScreen extends StatefulWidget {
  @override
  _MovieScreenState createState() => _MovieScreenState();
}

class _MovieScreenState extends State<BrowseScreen> {
  List movies = [];
  final List<String> categories = ["Action", "Comedy", "Drama", "Horror", "Sci-Fi"];
  String selectedCategory = "Action";

  @override
  void initState() {
    super.initState();
    fetchMovies();
  }

  Future<void> fetchMovies() async {
    final response = await http.get(Uri.parse('https://yts.mx/api/v2/list_movies.json?limit=10&genre=$selectedCategory'));
    if (response.statusCode == 200) {
      setState(() => movies = json.decode(response.body)['data']['movies']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((category) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: ChoiceChip(
                    label: Text(category, style: TextStyle(color: Colors.black)),
                    selected: selectedCategory == category,
                    selectedColor: Colors.orange,
                    backgroundColor: Colors.grey[300],
                    onSelected: (selected) {
                      setState(() {
                        selectedCategory = category;
                        fetchMovies();
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: movies.isEmpty
                ? Center(child: CircularProgressIndicator())
                : GridView.builder(
              padding: EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: movies.length,
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerScreen(movies[index]['torrents'][0]['url'], movies[index]['title']),
                  ),
                ),
                child: MovieCard(movies[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MovieCard extends StatelessWidget {
  final movie;
  MovieCard(this.movie);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        image: DecorationImage(image: NetworkImage(movie['medium_cover_image']), fit: BoxFit.cover),
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String movieTitle;
  VideoPlayerScreen(this.videoUrl, this.movieTitle);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isBuffering = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          _isBuffering = false;
          _controller.setLooping(true);
          _controller.play();
        });
      })
      ..addListener(() {
        if (!_controller.value.isBuffering && _isBuffering) {
          setState(() {
            _isBuffering = false;
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, title: Text("Now Playing")),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Center(
            child: _controller.value.isInitialized
                ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            )
                : CircularProgressIndicator(),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.grey,
              onPressed: () {
                setState(() {
                  _controller.seekTo(_controller.value.position - Duration(seconds: 10));
                });
              },
              child: Icon(Icons.replay_10),
            ),
          ),
          Positioned(
            bottom: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.orange,
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying ? _controller.pause() : _controller.play();
                });
              },
              child: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.grey,
              onPressed: () {
                setState(() {
                  _controller.seekTo(_controller.value.position + Duration(seconds: 10));
                });
              },
              child: Icon(Icons.forward_10),
            ),
          ),
        ],
      ),
    );
  }
}
