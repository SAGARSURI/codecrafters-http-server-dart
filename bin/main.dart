import 'dart:io';

const http200 = 'HTTP/1.1 200 OK\r\n\r\n';
const http400 = 'HTTP/1.1 404 Not Found\r\n\r\n';
void main() async {
  var serverSocket = await ServerSocket.bind('0.0.0.0', 4221);

  await for (final clientSocket in serverSocket) {
    print("Client connected");
    clientSocket.listen((List<int> data) {
      String request = String.fromCharCodes(data);
      final requestLine = request = request.split('\r\n')[0];
      final path = requestLine.split(' ')[1];

      if (path != '/') {
        clientSocket.write(http400);
      } else {
        clientSocket.write(http200);
      }
      clientSocket.close();
    });
  }
}
