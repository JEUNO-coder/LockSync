#include <Adafruit_Fingerprint.h>
#include <ESP32Servo.h>
#include <HardwareSerial.h>

#define PIR_PIN        14
#define FP_RX_PIN      16
#define FP_TX_PIN      17
#define SERVO_PIN      13
#define BUZZER_PIN     25
#define LED_PIN        26

HardwareSerial fpSerial(2); // UART2 on ESP32
Adafruit_Fingerprint finger(&fpSerial);
Servo lockServo;

const int LOCKED_POS   = 0;
const int UNLOCKED_POS = 90;

void unlockDoor() {
  lockServo.write(UNLOCKED_POS);
  digitalWrite(LED_PIN, HIGH);
  tone(BUZZER_PIN, 1000, 200); // short confirmation beep
  delay(3000);                 // stay unlocked
  lockServo.write(LOCKED_POS);
  digitalWrite(LED_PIN, LOW);
}

void alertUnauthorized() {
  tone(BUZZER_PIN, 400, 500);
  delay(500);
  tone(BUZZER_PIN, 400, 500);
}

int getFingerprintID() {
  if (finger.getImage() != FINGERPRINT_OK) return -1;
  if (finger.image2Tz() != FINGERPRINT_OK) return -1;
  if (finger.fingerFastSearch() != FINGERPRINT_OK) return -1;
  return finger.fingerID; // matched ID
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
  } else {
    Serial.println("Fingerprint sensor NOT found. Check wiring.");
  }
}

void loop() {
  bool motionDetected = digitalRead(PIR_PIN) == HIGH;

  if (motionDetected) {
    Serial.println("Motion detected, scanning for fingerprint...");

    int id = getFingerprintID();
    if (id >= 0) {
      Serial.print("Access granted. ID #");
      Serial.println(id);
      unlockDoor();
    } else {
      Serial.println("No match / no finger.");
    }
  }

  delay(200); // small polling delay
}