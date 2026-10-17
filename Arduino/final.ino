#include <Arduino.h>
#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <Adafruit_Fingerprint.h>
#include <ESP32Servo.h>
#include <HardwareSerial.h>

// Helper functions for Firebase token/payload handling
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>

// ============================================================================
// CONFIGURATION & CREDENTIALS
// ============================================================================
#define WIFI_SSID         "HackMeIfYouCan"
#define WIFI_PASSWORD     "P@ssword8"
#define API_KEY           "AIzaSyCwXNa8Ki40gn8W3_QdC6dbiIRkJsILGxA"
#define DATABASE_URL      "https://locksync-ab6fa-default-rtdb.asia-southeast1.firebasedatabase.app"

#define LOCKER_ID         "locker_01"
const String lockerPath = "/lockers/" + String(LOCKER_ID);

// Pin Definitions
#define PIR_PIN           14
#define SERVO_PIN         13
#define BUZZER_PIN        25
#define LED_PIN           26
#define FP_RX_PIN         16   // ESP32 RX <- Sensor TX
#define FP_TX_PIN         17   // ESP32 TX -> Sensor RX

// Servo Angles & Delays
const int LOCKED_POS = 0;
const int UNLOCKED_POS = 90;
const unsigned long UNLOCK_TIME_MS = 3000;
const unsigned long ENROLL_TIMEOUT_MS = 25000; // 25s timeout for abandoned enrollment

// ============================================================================
// HARDWARE & FIREBASE OBJECTS
// ============================================================================
HardwareSerial fpSerial(2);
Adafruit_Fingerprint finger(&fpSerial);
Servo lockServo;

FirebaseData streamData;
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// ============================================================================
// GLOBAL STATE VARIABLES
// ============================================================================
bool isLocked = true;
String currentEnrollStatus = "IDLE";
String activeWorkflowId = "";
bool lastMotionState = false;
unsigned long lastMotionTime = 0;

// ============================================================================
// FUNCTION DECLARATIONS
// ============================================================================
void connectWiFi();
void initFirebase();
void streamCallback(StreamData data);
void streamTimeoutCallback(bool timeout);
void unlockDoor(String triggeredBy);
void lockDoor();
void alertUnauthorized();
int getFingerprintID();
int getNextFreeSlot();
void processAppEnrollment();
void syncRegisteredSlotsToFirebase();
void updateEnrollStatus(String status, String lastAction = "");

// ============================================================================
// SETUP
// ============================================================================
void setup() {
  Serial.begin(115200);
  delay(500);

  // Hardware Pin Configuration
  pinMode(PIR_PIN, INPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(LED_PIN, OUTPUT);

  // Attach & Initialize Servo
  lockServo.attach(SERVO_PIN);
  lockDoor();

  // Initialize ES608/AS608 Fingerprint Sensor
  fpSerial.begin(57600, SERIAL_8N1, FP_RX_PIN, FP_TX_PIN);
  finger.begin(57600);

  if (finger.verifyPassword()) {
    Serial.println("Fingerprint sensor detected.");
    finger.getTemplateCount();
    Serial.printf("Enrolled fingerprints count: %d\n", finger.templateCount);
  } else {
    Serial.println("ERROR: Fingerprint sensor NOT found! Check wiring.");
  }

  // Network & Cloud Setup
  connectWiFi();
  initFirebase();

  // Initial Sync of hardware slots to Firebase
  syncRegisteredSlotsToFirebase();

  Serial.println(">>> LockSync System Ready <<<");
}

// ============================================================================
// MAIN LOOP
// ============================================================================
void loop() {
  if (!Firebase.ready()) return;

  // 1. PIR Motion Sensor Monitor
  bool currentMotion = (digitalRead(PIR_PIN) == HIGH);
  if (currentMotion && !lastMotionState) {
    Serial.println("PIR: Motion detected near locker!");
    Firebase.RTDB.setBool(&fbdo, lockerPath + "/motionDetected", true);
    Firebase.RTDB.setString(&fbdo, lockerPath + "/lastAction", "MOTION_DETECTED");
  } else if (!currentMotion && lastMotionState) {
    Firebase.RTDB.setBool(&fbdo, lockerPath + "/motionDetected", false);
  }
  lastMotionState = currentMotion;

  // 2. Handle App-Initiated Enrollment State Machine
  if (currentEnrollStatus == "START_ENROLL") {
    processAppEnrollment();
  } 
  // 3. Normal Mode: Poll Fingerprint Sensor for Access
  else if (currentEnrollStatus == "IDLE") {
    int id = getFingerprintID();
    if (id >= 0) {
      Serial.printf("Match found! ID #%d\n", id);
      unlockDoor("MATCH_FINGER_ID_" + String(id));
    } else if (id == -2) {
      alertUnauthorized();
    }
  }

  delay(50);
}

// ============================================================================
// FIREBASE STREAM CALLBACK (REMOTE COMMANDS)
// ============================================================================
void streamCallback(StreamData data) {
  String path = data.dataPath();
  
  // A. Flutter Remote Lock / Unlock Toggle
  if (path == "/isLocked" || path == "/") {
    if (data.dataType() == "boolean") {
      bool targetLockState = data.boolData();
      if (targetLockState != isLocked) {
        if (targetLockState) {
          lockDoor();
        } else {
          unlockDoor("APP_REMOTE_TOGGLE");
        }
      }
    }
  }

  // B. Flutter Initiate Enrollment Request
  if (path == "/enrollStatus") {
    if (data.dataType() == "string") {
      String statusVal = data.stringData();
      if (statusVal == "START_ENROLL") {
        currentEnrollStatus = "START_ENROLL";
        Serial.println("Enrollment request received from Flutter App.");
      } else if (statusVal == "IDLE") {
        currentEnrollStatus = "IDLE";
      }
    }
  }

  // C. Capture Workflow Transaction ID
  if (path == "/workflowId") {
    if (data.dataType() == "string") {
      activeWorkflowId = data.stringData();
    }
  }
}

void streamTimeoutCallback(bool timeout) {
  if (timeout) Serial.println("Firebase stream connection timed out, resuming...");
}

// ============================================================================
// ENROLLMENT LOGIC (APP-DRIVEN)
// ============================================================================
void processAppEnrollment() {
  int targetSlot = getNextFreeSlot();
  if (targetSlot < 0) {
    Serial.println("Error: No available sensor slots remaining!");
    updateEnrollStatus("ERROR_STORAGE_FAILED", "STORAGE_FULL");
    return;
  }

  Serial.printf("Starting enrollment sequence for target Slot #%d\n", targetSlot);
  unsigned long startTime = millis();
  int p = -1;

  // --- STEP 1: First Scan ---
  updateEnrollStatus("PLACE_FINGER_1", "AWAITING_FIRST_SCAN");
  tone(BUZZER_PIN, 1000, 100);

  while (p != FINGERPRINT_OK) {
    if (millis() - startTime > ENROLL_TIMEOUT_MS) {
      updateEnrollStatus("TIMEOUT", "ENROLLMENT_TIMEOUT");
      return;
    }
    p = finger.getImage();
    delay(50);
  }

  p = finger.image2Tz(1);
  if (p != FINGERPRINT_OK) {
    updateEnrollStatus("ERROR_SCAN_FAILED", "FIRST_SCAN_READ_ERROR");
    alertUnauthorized();
    return;
  }

  // --- STEP 2: Lift Finger ---
  updateEnrollStatus("REMOVE_FINGER", "AWAITING_FINGER_REMOVE");
  tone(BUZZER_PIN, 1200, 100);
  delay(1000);

  p = 0;
  while (p != FINGERPRINT_NOFINGER) {
    p = finger.getImage();
    delay(50);
  }

  // --- STEP 3: Second Scan ---
  updateEnrollStatus("PLACE_FINGER_2", "AWAITING_SECOND_SCAN");
  tone(BUZZER_PIN, 1000, 100);

  p = -1;
  startTime = millis();
  while (p != FINGERPRINT_OK) {
    if (millis() - startTime > ENROLL_TIMEOUT_MS) {
      updateEnrollStatus("TIMEOUT", "ENROLLMENT_TIMEOUT");
      return;
    }
    p = finger.getImage();
    delay(50);
  }

  p = finger.image2Tz(2);
  if (p != FINGERPRINT_OK) {
    updateEnrollStatus("ERROR_SCAN_FAILED", "SECOND_SCAN_READ_ERROR");
    alertUnauthorized();
    return;
  }

  // --- STEP 4: Create Model & Validate Match ---
  updateEnrollStatus("PROCESSING", "VALIDATING_PRINTS");
  p = finger.createModel();
  if (p != FINGERPRINT_OK) {
    updateEnrollStatus("ERROR_PRINTS_DONT_MATCH", "MISMATCH_SCANS");
    alertUnauthorized();
    return;
  }

  // --- STEP 5: Store Model to Hardware Flash ---
  p = finger.storeModel(targetSlot);
  if (p == FINGERPRINT_OK) {
    Serial.printf("SUCCESS! Stored fingerprint in Slot #%d\n", targetSlot);

    // Save slot assignment metadata into Firebase
    String slotNode = lockerPath + "/registeredSlots/slot_" + String(targetSlot);
    Firebase.RTDB.setInt(&fbdo, slotNode + "/slotId", targetSlot);
    Firebase.RTDB.setString(&fbdo, slotNode + "/label", "Fingerprint " + String(targetSlot));
    Firebase.RTDB.setInt(&fbdo, slotNode + "/registeredAt", millis());

    // Confirmation Sound
    tone(BUZZER_PIN, 1500, 150);
    delay(150);
    tone(BUZZER_PIN, 2000, 200);

    // Signal App Completion
    updateEnrollStatus("COMPLETED", "BIOMETRIC_ENROLLED_SLOT_" + String(targetSlot));
    syncRegisteredSlotsToFirebase();
  } else {
    updateEnrollStatus("ERROR_STORAGE_FAILED", "HARDWARE_WRITE_ERROR");
    alertUnauthorized();
  }
}

// Find lowest unused template index (1..162)
int getNextFreeSlot() {
  finger.getTemplateCount();
  for (int slot = 1; slot <= 162; slot++) {
    if (finger.loadModel(slot) != FINGERPRINT_OK) {
      return slot;
    }
  }
  return -1;
}

// ============================================================================
// HARDWARE LOCK CONTROL & AUTHENTICATION
// ============================================================================
void unlockDoor(String triggeredBy) {
  Serial.printf("Access granted (%s) - Unlocking\n", triggeredBy.c_str());
  isLocked = false;
  lockServo.write(UNLOCKED_POS);
  digitalWrite(LED_PIN, HIGH);
  tone(BUZZER_PIN, 1000, 200);

  // Sync state to Cloud
  Firebase.RTDB.setBool(&fbdo, lockerPath + "/isLocked", false);
  Firebase.RTDB.setString(&fbdo, lockerPath + "/lastAction", triggeredBy);

  delay(UNLOCK_TIME_MS);

  // Auto Relock
  lockDoor();
}

void lockDoor() {
  Serial.println("Lock engaged");
  isLocked = true;
  lockServo.write(LOCKED_POS);
  digitalWrite(LED_PIN, LOW);

  // Sync state to Cloud
  Firebase.RTDB.setBool(&fbdo, lockerPath + "/isLocked", true);
  Firebase.RTDB.setString(&fbdo, lockerPath + "/lastAction", "LOCKED");
}

void alertUnauthorized() {
  Serial.println("Access Denied / Alert triggered");
  tone(BUZZER_PIN, 400, 300);
  delay(100);
  tone(BUZZER_PIN, 400, 300);

  Firebase.RTDB.setString(&fbdo, lockerPath + "/lastAction", "UNAUTHORIZED_ATTEMPT");
  Firebase.RTDB.setBool(&fbdo, lockerPath + "/tamperAlert", true);
}

int getFingerprintID() {
  uint8_t p = finger.getImage();
  if (p != FINGERPRINT_OK) return -1;

  p = finger.image2Tz();
  if (p != FINGERPRINT_OK) return -1;

  p = finger.fingerFastSearch();
  if (p == FINGERPRINT_NOTFOUND) return -2;
  if (p != FINGERPRINT_OK) return -1;

  return finger.fingerID;
}

// ============================================================================
// FIREBASE HELPER FUNCTIONS
// ============================================================================
void connectWiFi() {
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
  }
  Serial.println("\nWi-Fi Connected!");
}

void initFirebase() {
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  if (Firebase.signUp(&config, &auth, "", "")) {
    Serial.println("Firebase Sign-up Successful");
  } else {
    Serial.printf("Firebase Sign-up Error: %s\n", config.signer.signupError.message.c_str());
  }

  config.token_status_callback = tokenStatusCallback;
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  if (!Firebase.RTDB.beginStream(&streamData, lockerPath)) {
    Serial.printf("Stream error: %s\n", streamData.errorReason().c_str());
  }

  Firebase.RTDB.setStreamCallback(&streamData, streamCallback, streamTimeoutCallback);
}

void updateEnrollStatus(String status, String lastAction) {
  currentEnrollStatus = status;
  Firebase.RTDB.setString(&fbdo, lockerPath + "/enrollStatus", status);

  if (lastAction.length() > 0) {
    Firebase.RTDB.setString(&fbdo, lockerPath + "/lastAction", lastAction);
  }

  Serial.println("Enroll Status -> " + status);
}

void syncRegisteredSlotsToFirebase() {
  finger.getTemplateCount();
  FirebaseJson arrayJson;
  
  for (int i = 1; i <= 162; i++) {
    if (finger.loadModel(i) == FINGERPRINT_OK) {
      arrayJson.add(i);
    }
  }

  Firebase.RTDB.setArray(&fbdo, lockerPath + "/activeSlotsList", &arrayJson);
}
