import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/yolo.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() => runApp(YOLODemo());

class YOLODemo extends StatefulWidget {
  @override
  _YOLODemoState createState() => _YOLODemoState();
}

class _YOLODemoState extends State<YOLODemo> {
  YOLO? yolo;
  File? selectedImage;
  List<dynamic> results = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadYOLO();
  }

  Future<void> loadYOLO() async {
    setState(() => isLoading = true);
    try {
      yolo = YOLO(
        modelPath: 'yolo11n',
        task: YOLOTask.detect,
      );
      await yolo!.loadModel();
    } catch (e) {
      print("Error loading model: $e");
    }
    setState(() => isLoading = false);
  }

  Future<void> pickAndDetect() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
        isLoading = true;
      });

      if (yolo != null) {
        final imageBytes = await selectedImage!.readAsBytes();
        final detectionResults = await yolo!.predict(imageBytes);

        setState(() {
          results = detectionResults['boxes'] ?? [];
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('YOLO Quick Demo')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selectedImage != null)
                Container(height: 300, child: Image.file(selectedImage!)),
              SizedBox(height: 20),
              if (isLoading)
                CircularProgressIndicator()
              else
                Text('Detected ${results.length} objects'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: yolo != null ? pickAndDetect : null,
                child: Text('Pick Image & Detect'),
              ),
              SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final detection = results[index];
                    return ListTile(
                      title: Text(detection['class'] ?? 'Unknown'),
                      subtitle: Text('Confidence: ${(detection['confidence'] * 100).toStringAsFixed(1)}%'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
