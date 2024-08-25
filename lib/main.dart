import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ML Kit OCR Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(cameras: cameras),
    );
  }
}

class HomePage extends StatelessWidget {
  final List<CameraDescription> cameras;

  const HomePage({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ML Kit OCR Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton.icon(
              icon: Icon(Icons.camera_alt),
              label: Text('Take a Picture'),
              onPressed: () => _getImageAndProcess(context, ImageSource.camera),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.photo_library),
              label: Text('Choose from Gallery'),
              onPressed: () => _getImageAndProcess(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getImageAndProcess(BuildContext context, ImageSource source) async {
  final ImagePicker _picker = ImagePicker();
  try {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      print('Image path: ${image.path}');
      
      // Temporarily skip cropping
      final String finalImagePath = image.path;
      print('Final image path: $finalImagePath');

      // Navigate to OCR page
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OCRPage(imagePath: finalImagePath, cameras: cameras),
        ),
      );
    } else {
      print('No image selected');
    }
  } catch (e) {
    print('Error picking image: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error picking image: $e')),
    );
  }
}

  Future<CroppedFile?> _cropImage(String imagePath) async {
    return await ImageCropper().cropImage(
      sourcePath: imagePath,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.ratio3x2,
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.ratio4x3,
        CropAspectRatioPreset.ratio16x9
      ],
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.blue,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop Image',
        ),
      ],
    );
  }
}

class OCRPage extends StatefulWidget {
  final String imagePath;
  final List<CameraDescription> cameras;

  const OCRPage({Key? key, required this.imagePath, required this.cameras}) : super(key: key);

  @override
  _OCRPageState createState() => _OCRPageState();
}

class _OCRPageState extends State<OCRPage> {
  String _extractedText = '';
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _processImage() async {
    try {
      final inputImage = InputImage.fromFilePath(widget.imagePath);
      setState(() {
        _extractedText = 'Processing...';
      });
      final recognizedText = await _textRecognizer.processImage(inputImage);
      setState(() {
        _extractedText = recognizedText.text;
      });
    } catch (e) {
      print('Error in text recognition: $e');
      setState(() {
        _extractedText = 'Error in text recognition: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OCR Result'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.file(File(widget.imagePath)),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_extractedText),
            ),
          ],
        ),
      ),
    );
  }
}