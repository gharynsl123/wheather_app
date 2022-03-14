import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main(List<String> args) => runApp(const WheatherApp());

class WheatherApp extends StatefulWidget {
  const WheatherApp({Key? key}) : super(key: key);

  @override
  State<WheatherApp> createState() => _WheatherAppState();
}

class _WheatherAppState extends State<WheatherApp> {
  int? temprature;
  String location = 'Jakarta';
  String weather = 'clear';
  int woeid = 1047378;
  String abbreviation = 'c';

  String errormessage = '';

  //buat var untuk list temprature nya

  var minTempratureForcast = List.filled(7, 0);
  var maxTempratureForcast = List.filled(7, 0);
  var abbreviationForcast = List.filled(7, '');

  String searchApiUrl =
      'https://www.metaweather.com/api/location/search/?query=';
  String locationApiUrl = 'https://www.metaweather.com/api/location/';

  @override
  void initState() {
    super.initState();
    fetchLocation();
    fecthLocationDay();
  }

  Future<void> fechSearch(String input) async {
    try {
      var searchResult = await http.get(Uri.parse(searchApiUrl + input));
      var result = json.decode(searchResult.body)[0];

      setState(() {
        location = result['title'];
        woeid = result['woeid'];
        errormessage = '';
      });
    } catch (error) {
      errormessage =
          "Maaf Kita tidak ada data untuk kota itu. Coba Kota yang lain";
    }
  }

  Future<void> fetchLocation() async {
    var locationResult =
        await http.get(Uri.parse(locationApiUrl + woeid.toString()));
    var result = json.decode(locationResult.body);
    var consolidatedWeather = result['consolidated_weather'];
    var data = consolidatedWeather[0];

    setState(() {
      temprature = data['the_temp'].toInt();
      weather = data['weather_state_name'].replaceAll(' ', '').toLowerCase();
      abbreviation = data['weather_state_abbr'];
    });
  }

  Future<void> fecthLocationDay() async {
    var today = DateTime.now();
    for (var i = 0; i < 7; i++) {
      var locationDayResult = await http.get(Uri.parse(locationApiUrl +
          woeid.toString() +
          '/' +
          DateFormat('y/M/d')
              .format(today.add(Duration(days: i + 1)))
              .toString()));
      var result = jsonDecode(locationDayResult.body);
      var data = result[0];

      setState(() {
        minTempratureForcast[i] = data['min_temp'].round();
        maxTempratureForcast[i] = data['max_temp'].round();
        abbreviationForcast[i] = data['weather_state_abbr'];
      });
    }
  }

  void onTextFieldSubmitted(String input) async {
    await fetchLocation();
    await fechSearch(input);
    await fecthLocationDay();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Container(
        decoration: BoxDecoration(
            image: DecorationImage(
          image: AssetImage('assets/images/$weather.png'),
          fit: BoxFit.cover,
        )),
        child: temprature == null
            ? const Center(child: CircularProgressIndicator())
            : Scaffold(
                backgroundColor: Colors.transparent,
                body: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Center(
                            child: Image.network(
                                'https://www.metaweather.com/static/img/weather/png/' +
                                    abbreviation +
                                    '.png',
                                width: 100)),
                        Center(
                            child: Text(temprature.toString() + '°C',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 60,
                                ))),
                        Center(
                            child: Text(location,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 40))),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (var i = 0; i < 7; i++)
                              forecastElement(
                                1 + 1,
                                abbreviationForcast[i],
                                maxTempratureForcast[i],
                                minTempratureForcast[i],
                              )
                          ],
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Container(
                          width: 300,
                          child: TextField(
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                            ),
                            decoration: const InputDecoration(
                                hintText: 'Search another location...',
                                hintStyle: TextStyle(
                                    color: Colors.white, fontSize: 14),
                                prefixIcon:
                                    Icon(Icons.search, color: Colors.white)),
                            onSubmitted: (String input) {
                              onTextFieldSubmitted(input);
                            },
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            errormessage,
                            style: TextStyle(
                                color: Colors.red,
                                fontSize: Platform.isAndroid ? 15 : 20),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
      ),
    );
  }
}

Widget forecastElement(
    daysFromNow, abbreviation, maxTemperature, minTemperature) {
  var now = DateTime.now();
  var oneDayFromNow = now.add(Duration(days: daysFromNow));
  return Padding(
    padding: EdgeInsets.only(left: 16),
    child: Container(
      decoration: BoxDecoration(
          color: Color.fromRGBO(205, 212, 228, 0.2),
          borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              DateFormat.E().format(oneDayFromNow),
              style: TextStyle(color: Colors.white, fontSize: 25),
            ),
            Text(
              DateFormat.MMMd().format(oneDayFromNow),
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Image.network(
                'https://www.metaweather.com/static/img/weather/png/' +
                    abbreviation +
                    '.png',
                width: 50,
              ),
            ),
            Text(
              'High ' + maxTemperature.toString() + '°C',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            Text(
              'Low ' + minTemperature.toString() + '°C',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
      ),
    ),
  );
}
