# ArduinoBLE_FireBase_IOS_HTML
Author: Fan Gaoyige
E-mail: fangaoyige@live.com

## Branch master
This project is about using an Arduino Nano 33 BLE Sense board to detect the motion of body trunk and transfer the data to an IOS device through BLE. The IOS app can update the data to firebase database and show the data in a html .

To acquire high adaption to all kinds of BLE devices, I change the policy of only recognizing the Arduino device to all kind of devices once their UUID for BLE service is the same as profile. 
Implemented ios real time communication with Firebase both Mac and IOS platform

## Branch AAchart
Based on AAChart library, implemented real time plotting during receiving data and transport to the database.
Currently, the plot can contain 200 data points for each frame, and will refresh for each 10 points' update.

Unfortunately, my personal iPhone 12 mini may limit the performance of the app, it would stuck in some cases.

## Branch Collecting 
This version mainly focus on python program for collecting data from BLE based on the library Bleak. This Bleak lib operation is in Asynchronous mode. And the program can write the date to a csv file for building machine learning dataset.

Especially, for helping with the operator to collect data, I add special sound notice to the program. Wish it will help.
