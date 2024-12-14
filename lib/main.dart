import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  const WebSocketScreen({super.key});

  @override
  State<WebSocketScreen> createState() => _WebSocketScreenState();
}

class _WebSocketScreenState extends State<WebSocketScreen> {
  WebSocketChannel? channel;
  String receivedData = '';
  String receivedMessage = "";
  String esp32Ip = '';
  final TextEditingController ipController = TextEditingController();
  final FocusNode ipFocusNode = FocusNode();
  bool isConnected = false; // Trạng thái kết nối

  @override
  void dispose() {
    // Đóng WebSocket khi không sử dụng nữa
    channel?.sink.close();
    ipController.dispose();
    ipFocusNode.dispose();
    super.dispose();
  }

  Color getIconColor(String message) {
    switch (message) {
      case "Thiết bị hoạt động bình thường":
        return Colors.green; // Màu xanh cho trạng thái bình thường
      case "Thiết bị bị kẹt":
        return Colors.orange; // Màu cam cho trạng thái bị kẹt
      case "Thiết bị bị hỏng":
        return Colors.red; // Màu đỏ cho trạng thái hỏng
      default:
        return Colors.grey; // Màu xám cho trạng thái không xác định
    }
  }

  void connectToESP32() async {
    FocusScope.of(context).unfocus(); // Loại bỏ focus khỏi TextField

    if (esp32Ip.isNotEmpty) {
      try {
        // Đóng kênh cũ trước khi tạo kết nối mới
        channel?.sink.close();

        // Tạo kết nối WebSocket
        channel = WebSocketChannel.connect(
          Uri.parse('ws://$esp32Ip:81'),
        );

        // Lắng nghe phản hồi từ ESP32
        channel!.stream.listen(
              (message) {
            setState(() {
              receivedData = message;
              switch (receivedData) {
                case "4":
                  receivedMessage = "Thiết bị hoạt động bình thường";
                  break;
                case "5":
                  receivedMessage = "Thiết bị bị kẹt";
                  break;
                case "6":
                  receivedMessage = "Thiết bị bị hỏng";
                  break;
                default:
                  receivedMessage = "Dữ liệu không xác định: $message";
              }
              if (message == 'pong') {
                isConnected = true;
              }
            });
          },
          onDone: () {
            setState(() {
              isConnected = false;
            });
          },
          onError: (error) {
            setState(() {
              isConnected = false;
              receivedData = 'Lỗi kết nối: $error';
            });
          },
        );

        // Gửi tin nhắn kiểm tra kết nối (ping)
        channel!.sink.add('ping');

        // Chờ phản hồi trong 2 giây
        await Future.delayed(const Duration(seconds: 2));

        // Kiểm tra nếu không nhận được phản hồi
        if (!isConnected) {
          setState(() {
            receivedData = 'Không thể kết nối tới $esp32Ip';
            isConnected = false;
          });
        }
      } catch (e) {
        setState(() {
          isConnected = false;
          receivedData = 'Kết nối thất bại: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Loại bỏ focus khi nhấn ra ngoài
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ESP32 DATA'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ipController,
                      focusNode: ipFocusNode, // Gắn FocusNode
                      decoration: const InputDecoration(
                        labelText: 'Nhập địa chỉ IP của ESP32',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.text,
                      onChanged: (value) {
                        esp32Ip = value.trim();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isConnected
                        ? Icons.check_circle
                        : Icons.error_outline, // Biểu tượng kết nối
                    color: isConnected ? Colors.green : Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: connectToESP32,
                child: const Text('Kết nối'),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity, // Chiều rộng full theo bố cục cha
                height: 60, // Chiều cao cố định
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: getIconColor(receivedMessage)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications, // Icon chuông
                      color: getIconColor(receivedMessage),
                      size: 24,
                    ),
                    const SizedBox(width: 8), // Khoảng cách giữa icon và dòng chữ
                    Expanded(
                      child: Text(
                        receivedMessage,
                        style: TextStyle(
                          fontSize: 16,
                          color: getIconColor(receivedMessage),
                        ),
                        maxLines: 2, // Giới hạn tối đa 2 dòng nếu chữ dài
                        overflow: TextOverflow.ellipsis, // Hiển thị ... nếu nội dung dài
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Gửi số tới ESP32',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (value) {
                  if (channel != null) {
                    channel!.sink.add(value);
                  }
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Nhận từ ESP32: $receivedData',
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
