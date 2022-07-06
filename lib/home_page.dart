import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import 'package:supabase/supabase.dart';

import 'location_controller.dart';

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);

  final f = DateFormat('yyyy-MM-dd hh:mm');
  int myValue = 1558432747;
  final LocationController locationController = Get.put(LocationController());
  SupabaseClient client = SupabaseClient(
    'https://cayeijyxfdvbkjmmoeiz.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNheWVpanl4ZmR2YmtqbW1vZWl6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE2NTYzODIzMzksImV4cCI6MTk3MTk1ODMzOX0.VJMyYQsdAKWc-63HfQrVLA6oEDRecl29DtiK8XIYZvs'
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TrackMe Host'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0),
            child: Obx(() => Column(
              children: [

                Text('GPS Coordinates', style: TextStyle(fontSize: 18, color: Colors.grey.shade700)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Longitude: ${locationController.longitude}', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                    Text('Latitude: ${locationController.latitude}', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Altitude: ${locationController.altitude}', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                const SizedBox(height: 10),
                Text('Speed: ${locationController.speed}', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                const SizedBox(height: 30),
                Text('Location Address', style: TextStyle(fontSize: 18, color: Colors.grey.shade700)),
                const SizedBox(height: 30),
                Text('${locationController.address}', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                const SizedBox(height: 80),
                ElevatedButton(
                  onPressed: () async{
                   await checkPermissions();
                   Position? position = await Geolocator.getLastKnownPosition();
                   locationController.latitude.value = position!.latitude;
                   locationController.longitude.value = position.longitude;
                   locationController.altitude.value = position.altitude;
                   locationController.speed.value = position.speed;

                   final res = await client.from('device')
                      .insert({
                        'name': 'Toyota',
                        'model': 'Vitz',
                        'brand': 'HashBatch',
                        'longitude': position.longitude,
                        'latitude': position.latitude,
                        'altitude': position.altitude,
                        'speed': position.speed,
                      }).execute();
                   if(res.error != null){
                     print('Static error' + res.error!.message.toString());
                   }
                   else{
                     print(res.data.toString());
                   }
                   updateDeviceLocation();
                }, child: Text('Start GPS')),

                const SizedBox(height: 90),
                ElevatedButton(
                    onPressed: () async{

                    }, child: Text('Stop GPS'))
              ]
            )),
          ),
        ),
      ),
    );
  }

  void updateDeviceLocation() async {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
    );
    StreamSubscription<Position> positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
            (Position? position) async {
          List<Placemark> placemarks = await placemarkFromCoordinates(position!.latitude, position.longitude);
          position == null ? Get.snackbar('Error!', 'GPS Failed getting location!',
              backgroundColor: Colors.red, colorText: Colors.white) :
          locationController.longitude.value = position.longitude;
          locationController.latitude.value = position.latitude;
          locationController.altitude.value = position.altitude;
          locationController.speed.value = position.speed;
          locationController.address.value = '${placemarks[0].name}, ${placemarks[1].subLocality}, '
              '${placemarks[2].subAdministrativeArea}, ${placemarks[3].administrativeArea},'
              '${placemarks[4].country},';
          final res = await client.from('device')
              .update({
            'longitude': position.longitude,
            'latitude': position.latitude,
            'altitude': position.altitude,
            'created_at': f.format(DateTime.fromMillisecondsSinceEpoch(myValue)),
            'speed': position.speed,
          }).eq('id', 4).execute();
          if(res.error != null){
            print('Static error' + res.error!.message.toString());
          }
          else{
            print(res.data.toString());
          }
        });
  }

  checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      Get.snackbar('Error!', 'Location services are disabled!',
          backgroundColor: Colors.red, colorText: Colors.white);
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar('Error!', 'Location permissions are denied!',
            backgroundColor: Colors.red, colorText: Colors.white);
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar('Error!', 'Location permissions are permanently denied, we cannot request permissions!',
          backgroundColor: Colors.red, colorText: Colors.white);
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
  }
}
