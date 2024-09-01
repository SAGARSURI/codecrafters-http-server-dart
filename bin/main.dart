import 'dart:io';

const crlf = '\r\n';

void main(List<String> args) async {
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
      final requestType = requestLine.split(' ')[0];
      final path = requestLine.split(' ')[1].trim();
      final pathSegments = path.split('/');
      final endpoint = pathSegments[1];

      if (requestType == 'GET') {
        if (path == '/') {
          clientSocket.write(buildResponse(ResponseType.ok));
          return;
        }

        if (endpoint == 'echo') {
          clientSocket.write(
            buildResponse(
              ResponseType.ok,
              body: pathSegments.last,
            ),
          );
          return;
        }

        if (endpoint == 'files') {
          final fileName = pathSegments[2];

          if (args.first != '--directory') {
            throw Exception('No directory provided');
          }
          final directoryName = args.last;
          final filPath = '$directoryName/$fileName';
          final file = File(filPath);
          if (!file.existsSync()) {
            clientSocket.write(buildResponse(ResponseType.notFound));
            return;
          }
          final fileContent = file.readAsStringSync();
          clientSocket.write(
            buildResponse(
              ResponseType.ok,
              body: fileContent,
              contentType: 'application/octet-stream',
            ),
          );
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
      } else if (requestType == 'POST') {
        if (endpoint == 'files') {
          final fileName = pathSegments[2];
          final requestBody = contents.last;

          if (args.first != '--directory') {
            throw Exception('No directory provided');
          }
          final directoryName = args.last;
          final filPath = '$directoryName/$fileName';
          final file = File(filPath);
          if (!file.existsSync()) {
            file.createSync(recursive: true);
          }
          file.writeAsStringSync(requestBody);
          clientSocket.write(
            buildResponse(
              ResponseType.created,
            ),
          );
        }
      }
      clientSocket.close();
    });
  }
}

String buildResponse(
  ResponseType responseType, {
  String? body,
  String contentType = 'text/plain',
}) {
  final contentLength = body?.length;
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
  notFound(404, 'Not Found'),
  created(201, 'Created');

  const ResponseType(this.code, this.message);
  final int code;
  final String message;
}
