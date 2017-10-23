'use strict';

// [START all]
// [START import]
// The Cloud Functions for Firebase SDK to create Cloud Functions and setup triggers.
const functions = require('firebase-functions');

// The Firebase Admin SDK to access the Firebase Realtime Database. 
const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);
// [END import]

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });

// [START makeUppercase]
// Listens for new messages added to /notes/:documentId/original and creates an
// uppercase version of the message to /notes/:documentId/uppercase
// [START makeUppercaseTrigger]
exports.sendNotification = functions.firestore.document('/notes/{documentId}')
    .onCreate(event => {
// [END makeUppercaseTrigger]
      // [START makeUppercaseBody]

      // Grab the current value of what was written to the Realtime Database.
      const original = event.data.data().original;
      console.log('Uppercasing', event.params.documentId, original);
      const uppercase = original.toUpperCase();
      // You must return a Promise when performing asynchronous tasks inside a Functions such as
      // writing to the Firebase Realtime Database.
      // Setting an 'uppercase' sibling in the Realtime Database returns a Promise.
      return event.data.ref.set({uppercase}, {merge: true});
      // [END makeUppercaseBody]
    });
// [END makeUppercase]
// [END all]
