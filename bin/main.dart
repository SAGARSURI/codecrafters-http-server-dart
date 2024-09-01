import 'dart:io';

const http200 = 'HTTP/1.1 200 OK\r\n\r\n';
const http404 = 'HTTP/1.1 404 Not Found\r\n\r\n';
void main() async {
  var serverSocket = await ServerSocket.bind('0.0.0.0', 4221);

  await for (final clientSocket in serverSocket) {
    print("Client connected");
    clientSocket.listen((List<int> data) {
      String request = String.fromCharCodes(data);
      final requestLine = request = request.split('\r\n')[0];
      final path = requestLine.split(' ')[1];

      if (path == '/') {
        clientSocket.write(http200);
        return;
      }

      final pathSegments = path.split('/');
      if (pathSegments.length > 2 && pathSegments[1] == 'echo') {
        clientSocket.write(
          buildResponse(
            ResponseType.ok,
            body: pathSegments.last,
          ),
        );
      } else {
        clientSocket.write(http404);
      }
      clientSocket.close();
    });
  }
}

String buildResponse(ResponseType responseType, {String? body}) {
  final contentLength = body?.length;
  final contentType = 'text/plain';
  return responseBuilder(
    responseType: responseType,
    contentType: contentType,
    contentLength: contentLength.toString(),
    body: body,
  );
}

String responseBuilder({
  required ResponseType responseType,
  String? contentType,
  String? contentLength,
  String? body,
}) {
  String statusLine =
      'HTTP/1.1 ${responseType.code} ${responseType.message}\r\n';
  if (contentType != null) {
    statusLine += 'Content-Type: $contentType\r\n';
  }
  if (contentLength != null) {
    statusLine += 'Content-Length: $contentLength\r\n';
  }
  statusLine += '\r\n';
  if (body != null) {
    statusLine += body;
  }
  return statusLine;
}

enum ResponseType {
  ok(200, 'OK'),
  notFound(404, 'Not Found');

  const ResponseType(this.code, this.message);
  final int code;
  final String message;
}
