import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() => runApp(
  DevicePreview(
    enabled: kReleaseMode,
    builder: (context) => DictionaryApp(), // Wrap your app
  ),
);

class DictionaryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DictionaryScreen(),
    );
  }
}

class DictionaryScreen extends StatefulWidget {
  @override
  _DictionaryScreenState createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  TextEditingController _controller = TextEditingController();
  Map<String, dynamic>? _wordData;
  bool _isLoading = false;
  String? _error;

  Future<void> fetchWordData(String word) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final url = Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/$word');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _wordData = json.decode(response.body)[0];
        });
      } else {
        setState(() {
          _error = 'Word not found!';
          _wordData = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred!';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dictionary App',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter a word',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      fetchWordData(_controller.text);
                    }
                  },
                ),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : _error != null
                ? Text(
              _error!,
              style: TextStyle(color: Colors.red, fontSize: 18),
            )
                : _wordData != null
                ? Expanded(
              child: ListView(
                children: [
                  Text(
                    _wordData!['word'],
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  if (_wordData!['phonetics'] != null &&
                      _wordData!['phonetics'].isNotEmpty)
                    Text('Pronunciation: ${_wordData!['phonetics'][0]['text'] ?? ''}'),
                  ..._wordData!['meanings'].map<Widget>((meaning) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10),
                        Text(
                          meaning['partOfSpeech'],
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent),
                        ),
                        ...meaning['definitions'].map<Widget>((def) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text('- ${def['definition']}'),
                          );
                        }).toList(),
                        if (meaning['synonyms'] != null && meaning['synonyms'].isNotEmpty)
                          Text('Synonyms: ${meaning['synonyms'].join(', ')}',
                              style: TextStyle(color: Colors.green)),
                      ],
                    );
                  }).toList(),
                ],
              ),
            )
                : Container(),
          ],
        ),
      ),
    );
  }
}
