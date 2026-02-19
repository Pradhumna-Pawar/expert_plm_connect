# 🔴 Firestore Permission Denied - Quick Fix

## The Error
```
[cloud_firestore/permission-denied] The caller does not have 
permission to execute the specified operation.
```

## The Cause
Your Firestore security rules are too restrictive. They require `request.auth != null` but:
1. New users aren't authenticated yet during signup
2. The rules don't allow creating user documents during signup

## The Solution (3 Steps)

### Step 1: Open Firestore Rules
1. Go to: https://console.firebase.google.com/
2. Select: **expert-plm-connect**
3. Left menu: **Firestore Database**
4. Click: **Rules** tab

### Step 2: Replace Rules
DELETE all content and PASTE this:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write their own data
    match /users/{userId} {
      allow create: if request.auth != null;
      allow read, update, delete: if request.auth.uid == userId;
    }
    
    // Allow authenticated users full access to other collections
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Step 3: Publish
Click **Publish** button (blue, top right)

---

## ✅ What This Does
- Allows new users to create their user document
- Allows authenticated users to read/write all data
- Secure: Only authenticated users can access

## ⏰ Time: 2 minutes

After publishing, the error will be gone!

