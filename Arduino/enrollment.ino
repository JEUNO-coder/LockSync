#include <Adafruit_Fingerprint.h>
#include <HardwareSerial.h>

#define FP_RX_PIN 16   // ESP32 RX  <- sensor TX
#define FP_TX_PIN 17   // ESP32 TX  -> sensor RX

HardwareSerial fpSerial(2);
Adafruit_Fingerprint finger(&fpSerial);

uint8_t readNumber() {
  uint8_t num = 0;
  while (num == 0) {
    while (!Serial.available());
    num = Serial.parseInt();
  }
  return num;
}

uint8_t enrollFingerprint(uint8_t id) {
  int p = -1;

  Serial.print("Place finger to enroll as ID #");
  Serial.println(id);
  while (p != FINGERPRINT_OK) {
    p = finger.getImage();
    delay(50);
  }
  p = finger.image2Tz(1);
  if (p != FINGERPRINT_OK) { Serial.println("Could not read that print, try again"); return p; }

  Serial.println("Remove finger");
  delay(2000);
  while (finger.getImage() != FINGERPRINT_NOFINGER) delay(50);

  Serial.println("Place the SAME finger again");
  p = -1;
  while (p != FINGERPRINT_OK) {
    p = finger.getImage();
    delay(50);
  }
  p = finger.image2Tz(2);
  if (p != FINGERPRINT_OK) { Serial.println("Could not read that print, try again"); return p; }

  p = finger.createModel();
  if (p != FINGERPRINT_OK) { Serial.println("The two scans did not match, try again"); return p; }

  p = finger.storeModel(id);
  if (p == FINGERPRINT_OK) {
    Serial.println("Stored!");
  } else {
    Serial.println("Could not store fingerprint");
  }
  return p;
}

void setup() {
  Serial.begin(115200);
  delay(500);

  fpSerial.begin(57600, SERIAL_8N1, FP_RX_PIN, FP_TX_PIN);
  finger.begin(57600);

  if (finger.verifyPassword()) {
    Serial.println("Fingerprint sensor found!");
  } else {
    Serial.println("Sensor NOT found. Check wiring.");
    while (true) delay(1);
  }
}

void loop() {
  Serial.println("\nType an ID number (1-127) in the Serial Monitor and press Enter:");
  uint8_t id = readNumber();
  enrollFingerprint(id);
}
