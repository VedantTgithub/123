import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageUploadPage extends StatefulWidget {
  @override
  _ImageUploadPageState createState() => _ImageUploadPageState();
}

class _ImageUploadPageState extends State<ImageUploadPage> {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  File? _imageFile;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  late QRViewController qrController;
  String scannedQRData = '';
  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice? _selectedDevice;
  User? _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _getDevices();
  }

  Future<void> _requestPermissions() async {
    // Request CAMERA permissions
    Map<Permission, PermissionStatus> statuses =
        await [Permission.camera].request();
    // Check if permission is denied
    if (statuses[Permission.camera]!.isDenied) {
      // Handle denied permissions
      print('Camera permission is denied');
    }
  }

  Future<void> _getImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _imageFile = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> _takePhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _imageFile = File(pickedFile.path);
      } else {
        print('No image taken.');
      }
    });
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) {
      print('No image selected.');
      return;
    }

    print('Starting image upload...');

    try {
      // Reference the user's document and the images collection inside it
      DocumentReference userDocRef =
          FirebaseFirestore.instance.collection('users').doc(_user!.uid);
      CollectionReference imagesCollectionRef = userDocRef.collection('images');

      // Ensure that the user's document exists
      if (!(await userDocRef.get()).exists) {
        await userDocRef
            .set({}); // Create an empty document if it doesn't exist
      }

      // Upload image to Firebase Storage
      Reference ref = _storage.ref().child(
          'users/${_user!.uid}/images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      UploadTask uploadTask = ref.putFile(_imageFile!);

      // Wait for the upload to complete
      TaskSnapshot snapshot = await uploadTask;

      // Get download URL of the uploaded image
      String downloadUrl = await snapshot.ref.getDownloadURL();

      print('Image uploaded successfully. Download URL: $downloadUrl');

      // Create a new document in the images collection with auto-generated ID
      DocumentReference newImageRef = await imagesCollectionRef.add({
        'imgurl': downloadUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image uploaded successfully'),
        ),
      );
    } catch (error) {
      print('Error uploading image: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image. Please try again later.'),
        ),
      );
    }
  }

  Future<void> _openQRScanner() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerPage(qrKey: qrKey),
      ),
    );
  }

  Future<void> _openBluetoothSettings() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BluetoothDevicesPage(),
      ),
    );
  }

  Future<void> _getDevices() async {
    List<BluetoothDevice> devices = [];
    try {
      devices = await _bluetooth.getBondedDevices();
    } catch (ex) {
      print("Error getting devices: $ex");
    }

    setState(() {
      _devicesList = devices;
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await _bluetooth.connect(device).then((_) {
        print('Connected to device ${device.name}');
      });
    } catch (ex) {
      print("Error connecting to device: $ex");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Image'),
        actions: [
          IconButton(
            icon: Icon(Icons.photo),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PhotosPage()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.qr_code),
            onPressed: _openQRScanner,
          ),
          IconButton(
            icon: Icon(Icons.bluetooth),
            onPressed: _openBluetoothSettings,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _imageFile != null
                ? Image.file(_imageFile!)
                : Placeholder(
                    fallbackHeight: 200,
                    fallbackWidth: double.infinity,
                  ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _getImageFromGallery,
              child: Text('Select Image from Gallery'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _takePhoto,
              child: Text('Take a Photo'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadImage,
              child: Text('Upload Image'),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class PhotosPage extends StatelessWidget {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photos'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('images')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No photos found.'));
          }
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8.0,
              crossAxisSpacing: 8.0,
            ),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var imageUrl = snapshot.data!.docs[index]['imgurl'];
              return GestureDetector(
                onTap: () {
                  // Handle tap on image
                },
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class QRScannerPage extends StatefulWidget {
  final GlobalKey qrKey;

  const QRScannerPage({Key? key, required this.qrKey}) : super(key: key);

  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  late QRViewController qrController;
  String scannedQRData = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code Scanner'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: Stack(
              children: <Widget>[
                QRView(
                  key: widget.qrKey,
                  onQRViewCreated: _onQRViewCreated,
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Text(
                    scannedQRData,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    qrController = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        print('Scanned QR code: ${scanData.code}');
        scannedQRData = scanData.code ?? '';
        _openInChrome(scannedQRData);
      });
    });
  }

  void _openInChrome(String url) async {
    url = url.trim();
    if (url.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Open in Chrome'),
            content: Text('Do you want to open this URL in Google Chrome?'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _launchURL(url);
                },
                child: Text('Yes'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('No'),
              ),
            ],
          );
        },
      );
    } else {
      print('URL is empty or invalid.');
    }
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
    }
  }

  @override
  void dispose() {
    qrController.dispose();
    super.dispose();
  }
}

class BluetoothDevicesPage extends StatefulWidget {
  @override
  _BluetoothDevicesPageState createState() => _BluetoothDevicesPageState();
}

class _BluetoothDevicesPageState extends State<BluetoothDevicesPage> {
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice? _selectedDevice;

  @override
  void initState() {
    super.initState();
    _getDevices();
  }

  Future<void> _getDevices() async {
    List<BluetoothDevice> devices = [];
    try {
      devices = await _bluetooth.getBondedDevices();
    } catch (ex) {
      print("Error getting devices: $ex");
    }

    setState(() {
      _devicesList = devices;
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await FlutterBluetoothSerial.instance
          .connect(device)
          .then((_) => print('Connected to device ${device.name}'));
    } catch (ex) {
      print("Error connecting to device: $ex");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Devices'),
      ),
      body: ListView.builder(
        itemCount: _devicesList.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_devicesList[index].name ?? ''),
            subtitle: Text(_devicesList[index].address ?? ''),
            onTap: () {
              setState(() {
                _selectedDevice = _devicesList[index];
              });
              if (_selectedDevice != null) {
                _connectToDevice(_selectedDevice!);
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Refresh the list of devices
          _getDevices();
        },
        child: Icon(Icons.refresh),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: ImageUploadPage(),
  ));
}
