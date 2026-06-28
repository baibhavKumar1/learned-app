# In-App Purchases (IAP) Implementation Guide

Adding In-App Purchases (IAP) for subscriptions in a Flutter app involves coordinating between Apple, Google, and your Flutter code. 

Because managing receipts, cross-platform syncing, and subscription renewals manually is notoriously difficult, the industry standard for Flutter apps is to use **RevenueCat** (a wrapper around the native stores).

Here is the step-by-step process to implement student subscriptions:

## Phase 1: Store Setup (Apple & Google)
You cannot test or implement IAP without creating the products in the developer consoles first.

1. **Google Play Console:**
   * Create your app and complete the merchant account setup.
   * Go to Monetization > Subscriptions and create a new subscription product (e.g., `student_monthly_sub`).
2. **Apple App Store Connect:**
   * Create your app and sign the "Paid Applications Agreement".
   * Go to In-App Purchases and create an Auto-Renewable Subscription (e.g., `student_monthly_sub`).

## Phase 2: RevenueCat Configuration
1. Create a free account at [RevenueCat.com](https://www.revenuecat.com/).
2. Create a Project and add your iOS and Android apps to it.
3. Enter your Google Play Service Credentials and App Store Shared Secret into RevenueCat so they can communicate with the stores.
4. **Create an Entitlement:** Call it `premium_student`. An entitlement represents what the user *gets*.
5. **Map Products:** Link your Apple and Google `student_monthly_sub` products to this `premium_student` entitlement.

## Phase 3: Flutter Integration
1. **Add the package:** Run the following command in your terminal:
   ```bash
   flutter pub add purchases_flutter
   ```
2. **Initialization:** In your `main.dart`, initialize the SDK before `runApp()`:
   ```dart
   import 'package:purchases_flutter/purchases_flutter.dart';
   import 'dart:io';

   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await Purchases.setLogLevel(LogLevel.debug);
     
     if (Platform.isIOS) {
       await Purchases.configure(PurchasesConfiguration("apple_api_key"));
     } else if (Platform.isAndroid) {
       await Purchases.configure(PurchasesConfiguration("google_api_key"));
     }
     
     runApp(const MyApp());
   }
   ```
3. **Link to Firebase UID:** When a student logs into Firebase, immediately log them into RevenueCat so their purchases are tied to their Firebase ID:
   ```dart
   await Purchases.logIn(FirebaseAuth.instance.currentUser!.uid);
   ```

## Phase 4: The Paywall & Purchase Flow
When a student tries to click a Premium video, you show them a Paywall screen:

1. **Fetch the Offerings:**
   ```dart
   final offerings = await Purchases.getOfferings();
   final monthlyPackage = offerings.current?.monthly; // Gets the price/details
   ```
2. **Trigger the Purchase:** When they click "Subscribe", trigger the native Apple/Google bottom sheet:
   ```dart
   try {
     CustomerInfo customerInfo = await Purchases.purchasePackage(monthlyPackage!);
     if (customerInfo.entitlements.all["premium_student"]?.isActive == true) {
       // Purchase successful! Unlock premium videos.
     }
   } catch (e) {
     // Handle user cancellation or payment error
   }
   ```
3. **Check Access on Startup:** When the app starts up or a video is tapped, check if they have the active entitlement:
   ```dart
   CustomerInfo customerInfo = await Purchases.getCustomerInfo();
   if (customerInfo.entitlements.all["premium_student"]?.isActive == true) {
     // Grant access
   } else {
     // Show Paywall
   }
   ```

## Phase 5: Firebase Backend Sync (Best Practice)
While you can check the user's status directly via the RevenueCat SDK in the app, it's best to keep your Firestore database as the source of truth.

1. In the RevenueCat dashboard, navigate to Integrations and set up a **Webhook**.
2. Point it to a **Firebase Cloud Function** endpoint.
3. Whenever Apple/Google charges the student, RevenueCat hits your Cloud Function. 
4. The Cloud Function then updates the student's Firestore document (e.g., `isPremium: true`), ensuring your database is always perfectly synced with their payment status.
