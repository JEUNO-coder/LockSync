#include <Adafruit_Fingerprint.h>
#include <ESP32Servo.h>
#include <HardwareSerial.h>

#define PIR_PIN     14
#define FP_RX_PIN   16   // ESP32 RX  <- sensor TX
#define FP_TX_PIN   17   // ESP32 TX  -> sensor RX
#define SERVO_PIN   13
#define BUZZER_PIN  25
#define LED_PIN     26

HardwareSerial fpSerial(2);
Adafruit_Fingerprint finger(&fpSerial);
Servo lockServo;

const int LOCKED_POS = 0;
const int UNLOCKED_POS = 90;
const unsigned long UNLOCK_TIME_MS = 3000;

void unlockDoor() {
  Serial.println("Access granted - unlocking");
  lockServo.write(UNLOCKED_POS);
  digitalWrite(LED_PIN, HIGH);
  tone(BUZZER_PIN, 1000, 200);   // short confirmation beep
  delay(UNLOCK_TIME_MS);
  lockServo.write(LOCKED_POS);
  digitalWrite(LED_PIN, LOW);
  Serial.println("Re-locked");
}

void alertUnauthorized() {
  Serial.println("Access denied");
  tone(BUZZER_PIN, 400, 300);
  delay(400);
  tone(BUZZER_PIN, 400, 300);
}

// Returns: ID number (>= 0) on a match, -1 if no finger / read error, -2 if not recognized
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

void setup() {
  Serial.begin(115200);

  pinMode(PIR_PIN, INPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(LED_PIN, OUTPUT);

  lockServo.attach(SERVO_PIN);
  lockServo.write(LOCKED_POS);

  fpSerial.begin(57600, SERIAL_8N1, FP_RX_PIN, FP_TX_PIN);
  finger.begin(57600);

  if (finger.verifyPassword()) {
    Serial.println("Fingerprint sensor found.");
    finger.getTemplateCount();
    Serial.print("Enrolled fingerprints: ");
    Serial.println(finger.templateCount);
  } else {
    Serial.println("Fingerprint sensor NOT found. Check wiring.");
  }

  Serial.println("LockSync ready. Waiting for fingerprint...");
}

void loop() {
  static bool lastMotion = false;
  bool motion = (digitalRead(PIR_PIN) == HIGH);
  if (motion && !lastMotion) {
    Serial.println("Motion detected near locker");
  }
  lastMotion = motion;

  int id = getFingerprintID();
  if (id >= 0) {
    Serial.print("Match found, ID #");
    Serial.println(id);
    unlockDoor();
  } else if (id == -2) {
    alertUnauthorized();
  }

  delay(100);
}
