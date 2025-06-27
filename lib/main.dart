import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // для kReleaseMode
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;


// Flutter ругался что нельзя юзать print()
// Этот код выводит все print в debug режиме
void logDebug(String message) {
  if (!kReleaseMode) {
    print(message); 
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 49, 130, 206)),
      ),
      home: const MyHomePage(title: 'My App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});


  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    PageOne(), // первый экран
    PageTwo(), // второй экран
    ];
    
    void _onItemTapped(int index) {
      setState(() {
       _selectedIndex = index;
    });
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        
        title: Text('Выбрана страница ${_selectedIndex + 1}'),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      items: [
        BottomNavigationBarItem(
        icon: Icon(Icons.location_on),
        label: 'Location',
        ),
        BottomNavigationBarItem( 
        icon: Icon(Icons.add),
        label: 'Конвертация \n валюты',
        ),
      ],
    ),
    );
  }
}

class PageOne extends StatefulWidget {
  const PageOne({super.key});
  
  @override
  State<PageOne> createState() => _PageOneState();
}

class _PageOneState extends State<PageOne> {
  String? _weatherInfo;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      final position = await _getCurrentLocation();
      final weather = await _getWeather(position.latitude, position.longitude);
      setState(() {
        _weatherInfo = weather;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Геолокация выключена');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Нет разрешения на геолокацию');
      }
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<String> _getWeather(double lat, double lon) async {
    const apiKey = '534fccfe40dd6b70b6a1062280a6037c'; 
    final url =
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final temp = data['main']['temp'];
      final city = data['name'];
      return '$city: $temp°C';
    } else {
      throw Exception('Ошибка при получении погоды');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _weatherInfo != null
          ? Text(_weatherInfo!, style: const TextStyle(fontSize: 24))
          : _error != null
              ? Text(_error!, style: const TextStyle(color: Colors.red))
              : const CircularProgressIndicator(),
    );
  }
}

class PageTwo extends StatefulWidget {
  const PageTwo({super.key});

  @override
  State<PageTwo> createState() => _PageTwoState();
}

class _PageTwoState extends State<PageTwo> {
  final TextEditingController _controller = TextEditingController();
  String _selectedCurrency = 'USD'; // по умолчанию
  double? _convertedValue;

  final Map<String, double> _rates = {
    'USD': 0.011,
    'EUR': 0.010,
    'RUB': 1.0,
  };

  void _converter() {
    final input = double.tryParse(_controller.text);
    if (input == null) return;

    final rate = _rates[_selectedCurrency]!;
    setState(() {
      _convertedValue = input * rate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Поле ввода
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Введите сумму в KGS',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Dropdown для выбора валюты
          DropdownButton<String>(
            value: _selectedCurrency,
            onChanged: (value) {
              setState(() {
                _selectedCurrency = value!;
              });
              _converter();
            },
            items: _rates.keys.map((currency) {
              return DropdownMenuItem(
                value: currency,
                child: Text(currency),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Результат
          if (_convertedValue != null)
            Text(
              'Результат: $_convertedValue $_selectedCurrency',
              style: const TextStyle(fontSize: 18),
            ),
        ],
      ),
    );
  }
}