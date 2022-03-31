# ArduinoBLE_FireBase_IOS_HTML

Author: Fan Gaoyige
E-mail: fangaoyige@live.com
Lab: NUS Lab of Sensor, MEMS and NMES
Contributor: Sun Wenmao, Zhou Jinfeng

## Version 2.0

### Machine Learning

Implememted 6 machine learning methods, Random Forest, AdaBoost, XGBoost, LightGBM, SVM, GBDT and a converlution neural network for recognizing different postures.  After trained,  the models are save to "Machine Learning/model" dictionary.

For adapting IOS app, the scikit-learn python package should satisfy the version <= 0.19.2.

```
pip install scikit-learn==0.19.2
```
IOS app provides an API CoreML for achieving machine learning. To implement the recognition in IOS app, we should convert the model to the format of *.mlmodel.


## Version 1.2
This version mainly focus on python program for collecting data from BLE based on the library Bleak. This Bleak lib operation is in Asynchronous mode. And the program can write the date to a csv file for building machine learning dataset.

Especially, for helping with the operator to collect data, I add special sound notice to the program. Wish it will help.

## Version 1.1
Based on AAChart library, implemented real time plotting during receiving data and transport to the database.
Currently, the plot can contain 200 data points for each frame, and will refresh for each 10 points' update.

Unfortunately, my personal iPhone 12 mini may limit the performance of the app, it would stuck in some cases.


## Version 1.0

This project is about using an Arduino Nano 33 BLE Sense board to detect the motion of body trunk and transfer the data to an IOS device through BLE. The IOS app can update the data to firebase database and show the data in a html .

To acquire high adaption to all kinds of BLE devices, I change the policy of only recognizing the Arduino device to all kind of devices once their UUID for BLE service is the same as profile. 
Implemented ios real time communication with Firebase both Mac and IOS platform



