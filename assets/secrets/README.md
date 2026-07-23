# FCM service account setup (one-time)

The app sends task-assignment push notifications directly from the client
using the FCM v1 API, authenticated with a **restricted** service account.
Do this once per Firebase project:

1. Go to [Google Cloud Console → IAM & Admin → Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts) for project `myattendanceproj-f4022`.
2. Create a new service account, e.g. `fcm-sender`.
3. Grant it **only** the role `Firebase Cloud Messaging API Admin`
   (`roles/firebasecloudmessaging.admin`). Do not grant Editor/Owner or any
   other role — this account's key ships inside the app, so it must not be
   able to touch anything besides sending messages.
4. Create a JSON key for that service account and download it.
5. Save it as `assets/secrets/fcm_service_account.json` in this repo
   (same folder as this file). It is git-ignored — never commit it.
6. Run `flutter pub get` and rebuild the app.

Security note: because this key is bundled into the compiled app, anyone who
decompiles the APK/IPA can extract it and send arbitrary push notifications
as this app to any of its topics. It cannot access Firestore, your database,
or anything else in the project as long as the role above is the only one
granted. Rotate the key (delete + recreate) if you ever suspect it leaked.
