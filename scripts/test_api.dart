import 'package:dio/dio.dart';

void main() async {
  const apiKey = '25ab153720mshb5306c51953cddap123896jsn5627703e9564';

  final dio = Dio()
    ..options.headers = {
      'x-rapidapi-key': apiKey,
      'x-rapidapi-host': 'exercisedb.p.rapidapi.com',
    }
    ..options.connectTimeout = const Duration(seconds: 15)
    ..options.receiveTimeout = const Duration(seconds: 15);

  print('Testing ExerciseDB Image Endpoint...\n');

  // Test the image endpoint with query parameters
  print('Testing: /image?exerciseId=0025&resolution=360');
  try {
    final response = await dio.get(
      'https://exercisedb.p.rapidapi.com/image',
      queryParameters: {
        'exerciseId': '0025',
        'resolution': '360',
      },
      options: Options(
        responseType: ResponseType.bytes,
        validateStatus: (status) => true,
      ),
    );
    print('Status: ${response.statusCode}');
    print('Content-Type: ${response.headers['content-type']}');
    print('Content-Length: ${response.data.length} bytes');

    if (response.statusCode == 200) {
      print('\n✅ Image endpoint works!');
      print('\nImage URL format:');
      print('https://exercisedb.p.rapidapi.com/image?exerciseId={ID}&resolution=360&rapidapi-key=$apiKey');
    }
  } catch (e) {
    print('Error: $e');
    if (e is DioException) {
      print('Status: ${e.response?.statusCode}');
      print('Response: ${e.response?.data}');
    }
  }
}
