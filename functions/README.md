# Firebase Cloud Functions Setup & Deployment Guide

This directory contains the modularized Firebase Cloud Functions code backend for EdTech App. 

## Structure
* `index.js`: Main entry point (initializes Admin SDK and exports functions).
* `auth.js`: Handles user profile fetching (`getUserProfile`) and updates (`updateUserProfile`).
* `content.js`: Handles secure file upload signed URLs (`generateSignedUrl`) and course material fetching (`getSubjectsAndMaterials`).

---

## Prerequisites

1. **Install Node.js:** Ensure Node.js (v18 or v20 recommended) is installed on your local machine.
2. **Install Firebase CLI:** Install the command-line interface globally:
   ```bash
   npm install -g firebase-tools
   ```
3. **Login to Firebase:** Login to your Google account linked with your Firebase projects:
   ```bash
   firebase login
   ```

---

## Setup & Local Installation

Before deploying, navigate to the `functions/` directory and install the local packages:
```bash
cd functions
npm install
```

---

## Configuration & Project Association

Make sure you're associated with the correct Firebase project. List your projects:
```bash
firebase projects:list
```

Select/use the target project:
```bash
firebase use --add [PROJECT_ID]
```

---

## Deployment

Deploy only the cloud functions using the following command:
```bash
firebase deploy --only functions
```

### Deploying Specific Functions
If you want to deploy just one specific function (e.g. only `getUserProfile`), you can run:
```bash
firebase deploy --only functions:getUserProfile
```
