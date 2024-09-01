import 'dart:io';

const crlf = '\r\n';

void main() async {
  var serverSocket = await ServerSocket.bind('0.0.0.0', 4221);

  await for (final clientSocket in serverSocket) {
    print("Client connected");
    clientSocket.listen((List<int> data) {
      String request = String.fromCharCodes(data);
      final contents = request.split(crlf);
      final requestLine = contents.first;
      // final [
      //   requestLine,
      //   requestHost,
      //   requestUserAgent,
      //   requestMediaType,
      //   requestBody,
      //   ...
      // ] = contents;
      final path = requestLine.split(' ')[1];

      if (path == '/') {
        clientSocket.write(buildResponse(ResponseType.ok));
        return;
      }

      final pathSegments = path.split('/');
      final endpoint = pathSegments[1];
      if (endpoint == 'echo') {
        clientSocket.write(
          buildResponse(
            ResponseType.ok,
            body: pathSegments.last,
          ),
        );
        return;
      }

      if (endpoint == 'user-agent') {
        final userAgentContent = contents[2].split(': ')[1].trim();

        clientSocket.write(
          buildResponse(
            ResponseType.ok,
            body: userAgentContent,
          ),
        );
      } else {
        clientSocket.write(buildResponse(ResponseType.notFound));
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
      'HTTP/1.1 ${responseType.code} ${responseType.message}$crlf';
  if (body != null) {
    if (contentType != null) {
      statusLine += 'Content-Type: $contentType$crlf';
    }
    if (contentLength != null) {
      statusLine += 'Content-Length: $contentLength$crlf';
    }
  }
  statusLine += crlf;
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
