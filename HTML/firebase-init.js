// Initialize Firebase
var config = {
    apiKey: "AIzaSyAOYYj0KlnTNyNxw1i3p7mOeyWiLRfTLZQ",
    authDomain: "arduinoble-ios.firebaseapp.com",
    databaseURL: "https://arduinoble-ios-default-rtdb.asia-southeast1.firebasedatabase.app",
    projectId: "arduinoble-ios",
    storageBucket: "arduinoble-ios.appspot.com",
    messagingSenderId: "1077016884008",
    appId: "1:1077016884008:web:f9262ad6e13e6f00c5961d",
    measurementId: "G-NSS6N0D6S2"
};
firebase.initializeApp(config);
// Get a reference to the database service
var database = firebase.database();