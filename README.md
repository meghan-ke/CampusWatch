# CampusWatch

CampusWatch is a Flutter mobile app that lets students report campus problems such as broken facilities, water or electricity outages, damaged furniture, sanitation issues and safety concerns. Authorised staff review the reports and update their status, so every problem can be followed from submission to resolution.

## What it does

Students register with an ALU email (@alustudent.com or @alueducation.com) and must verify it before they can use the app. They can submit a report with a category, title, description, location and up to three photos, then browse, search and filter all reports. Each report has a details page with a photo gallery, a progress bar and a status timeline. A student can delete their own report while it is still Submitted.

Staff log in with the same screen but see a different dashboard. They can open any report, change its status and add a note, which then shows up in the timeline.

## How it is built

The app uses Flutter with Provider for state management. Firebase Authentication handles register, login and email verification, Cloud Firestore stores users and reports, and Cloudinary hosts the photos. Only the photo links are saved in Firestore.

The code in the `lib` folder is split into layers: `models` describes the data, `services` is the only code that talks to Firebase and Cloudinary, `providers` holds the app state, `screens` are the full pages, `widgets` are reusable pieces, and `utils` holds the theme, constants and form validators. A screen asks a provider, the provider asks a service, and the service talks to the backend. Screens never call Firebase directly.

## Running the app

Install the Flutter SDK, then clone the repository and run `flutter pub get`. The Firebase settings are already in the project, so the app connects to the existing Firebase project without any extra setup. If you want to use your own Firebase project, enable Email/Password sign-in and create a Firestore database, then run `flutterfire configure`.

Photos need a Cloudinary account. Create an unsigned upload preset in the Cloudinary dashboard, then put your cloud name and preset name in `lib/utils/constants.dart`. Do not put the Cloudinary secret key in the app. Finally, start the app with `flutter run` on an Android emulator, a phone, or Chrome.

## Making a staff account

Every new account is a student. To make a staff account, register it in the app, open the user's document in the `users` collection in the Firebase console, and change the `role` field from `student` to `staff`. Then log out and log in again.

## Links and test accounts

Demo video: https://drive.google.com/drive/folders/1yvWlKizVhETXl1FN9v85zf6lf-o90KAj?usp=sharing

Student test account: m.mwizerwa@alustudent.com, Password: megane123

Staff test account: ridaa@gmail.com, Password: ridaa12
