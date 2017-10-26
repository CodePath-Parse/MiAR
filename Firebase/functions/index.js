'use strict';

// [START all]
// [START import]
// The Cloud Functions for Firebase SDK to create Cloud Functions and setup triggers.
const functions = require('firebase-functions');

// The Firebase Admin SDK to access the Firebase Realtime Database. 
const admin = require('firebase-admin');

var serviceAccount = require("./praxis-zoo-521-firebase-adminsdk-zmywl-83de0d74cd.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://praxis-zoo-521.firebaseio.com"
});
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

// Listens for new messages added to /messages/:pushId/original and creates an
// uppercase version of the message to /messages/:pushId/uppercase
exports.sendNotificationRealtime = functions.database.ref('/notes/{documentId}')
    .onCreate(event => {
      // Grab the current value of what was written to the Realtime Database.
      const original = event.data.val();
      console.log('Uppercasing', event.params.documentId, original);

      var payload = {
		  notification: {
		    title: "$GOOG up 1.43% on the day",
		    body: "$GOOG gained 11.80 points to close at 835.67, up 1.43% on the day."
		  },
		  data: {
		    stock: "GOOG",
		    close: "635.67"
		  }
		};
      // const uppercase = original.toUpperCase();
      // You must return a Promise when performing asynchronous tasks inside a Functions such as
      // writing to the Firebase Realtime Database.
      // Setting an 'uppercase' sibling in the Realtime Database returns a Promise.
      // return event.data.ref.set({uppercase}, {merge: true});
      // [END makeUppercaseBody]
          // Send notifications to all tokens.
      // Send a message to devices subscribed to the provided topic.
      console.log("/topics/" + original['to_uid']);
		return admin.messaging().sendToTopic("/topics/miar", payload)
		  .then(function(response) {
		    // See the MessagingTopicResponse reference documentation for the
		    // contents of response.
		    console.log("Successfully sent message:", response);
		  })
		  .catch(function(error) {
		    console.log("Error sending message:", error);
		  });
    });

exports.sendNotification = functions.firestore.document('/notes/{documentId}')
    .onCreate(event => {
// [END makeUppercaseTrigger]
      // [START makeUppercaseBody]

      // Grab the current value of what was written to the Realtime Database.
      const original = event.data.data().original;
      console.log('Uppercasing', event.params.documentId, original);

		var payload = {
		  notification: {
		    title: "$GOOG up 1.43% on the day",
		    body: "$GOOG gained 11.80 points to close at 835.67, up 1.43% on the day."
		  },
		  data: {
		    stock: "GOOG",
		    open: 829.62,
		    close: "635.67"
		  }
		};
      // const uppercase = original.toUpperCase();
      // You must return a Promise when performing asynchronous tasks inside a Functions such as
      // writing to the Firebase Realtime Database.
      // Setting an 'uppercase' sibling in the Realtime Database returns a Promise.
      // return event.data.ref.set({uppercase}, {merge: true});
      // [END makeUppercaseBody]
          // Send notifications to all tokens.
      // Send a message to devices subscribed to the provided topic.
		return admin.messaging().sendToTopic(original['to_uid'], payload)
		  .then(function(response) {
		    // See the MessagingTopicResponse reference documentation for the
		    // contents of response.
		    console.log("Successfully sent message:", response);
		  })
		  .catch(function(error) {
		    console.log("Error sending message:", error);
		  });
    });
// [END makeUppercase]
// [END all]
