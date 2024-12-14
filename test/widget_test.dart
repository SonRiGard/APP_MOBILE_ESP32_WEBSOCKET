import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32 WebSocket',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WebSocketScreen(),
    );
  }
}

class WebSocketScreen extends StatefulWidget {
  const WebSocketScreen({Key? key}) : super(key: key);

  @override
  State<WebSocketScreen> createState() => _WebSocketScreenState();
}

class _WebSocketScreenState extends State<WebSocketScreen> {
  late WebSocketChannel channel;
  String receivedData = '';

  @override
  void initState() {
    super.initState();

    // Kết nối đến WebSocket
    channel = WebSocketChannel.connect(
      Uri.parse('ws://192.168.1.100:81'), // Thay bằng địa chỉ IP của ESP32
    );

    // Lắng nghe dữ liệu từ WebSocket
    channel.stream.listen((message) {
      setState(() {
        receivedData = message;
      });
    });
  }

  @override
  void dispose() {
    // Đóng WebSocket khi không sử dụng nữa
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ESP32 WebSocket'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Send number to ESP32',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onSubmitted: (value) {
                // Gửi số tới ESP32
                channel.sink.add(value);
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Received from ESP32: $receivedData',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
