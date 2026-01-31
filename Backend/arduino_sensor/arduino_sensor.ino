#include <Servo.h>

// WasteMaster Arduino (Integrated Version)
// Merges User's Sensor Logic + Servo Sorting

// PINS
#define TRIG_PIN 9
#define ECHO_PIN 10
#define SERVO_SORT_PIN 3
#define SERVO_DUMP_PIN 5
#define LED_STRAP_PIN 6  // New 12V LED Control Pin

#define THRESHOLD_CM 10   // Restored to 10cm as per user reference

// SERVO ANGLES
// Calibrate these for your specific chamber locations!
int POS_PAPER = 0;
int POS_PLASTIC = 90;
int POS_GLASS = 180;
int POS_METAL = 270; 

int DUMP_REST = 0;
int DUMP_ACTIVE = 45;

Servo sortServo;
Servo dumpServo;

// DEBUG MODE: Set to false after testing
bool DEBUG_MODE = true; 

bool objectDetected = false;

void setup() {
  Serial.begin(9600);
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  pinMode(LED_STRAP_PIN, OUTPUT);
  digitalWrite(LED_STRAP_PIN, LOW); // Keep off initially
  
  // Attach servos briefly to reset position
  sortServo.attach(SERVO_SORT_PIN);
  dumpServo.attach(SERVO_DUMP_PIN);
  sortServo.write(0);       // Reset / Default to 0
  dumpServo.write(DUMP_REST);
  delay(500);
  sortServo.detach();
  dumpServo.detach();
  
  if (DEBUG_MODE) {
    Serial.println("--- System Ready ---");
    Serial.println("1. Hand in front (<10cm) -> 'DETECTED'");
    Serial.println("2. Wait for Python to send command...");
  }
}

void loop() {
  // 1. Check for Incoming Commands (Sorting)
  // This must be checked continuously so we don't miss the Pi's reply
  if (Serial.available() > 0) {
    String command = Serial.readStringUntil('\n');
    command.trim();
    
    if (command.length() > 0) {
      if (DEBUG_MODE) {
        Serial.print("RX Command: ");
        Serial.println(command);
      }
      performSorting(command);
      
      // After sorting, the object should be gone. 
      // We assume clear to prevent immediate re-trigger if sensor is slow.
      objectDetected = false; 
      digitalWrite(LED_STRAP_PIN, LOW); 
    }
  }

  // 2. Measure Distance (User's Logic)
  long duration;
  int distance;

  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);
  
  duration = pulseIn(ECHO_PIN, HIGH);
  distance = duration * 0.034 / 2;
  
  // Optional Debug of distance
  // if (DEBUG_MODE) { Serial.println(distance); }

  // 3. Sensor State Machine
  // Only trigger if we haven't already detected an object
  if (!objectDetected && distance > 0 && distance < THRESHOLD_CM) {
    // New Object!
    objectDetected = true;
    digitalWrite(LED_STRAP_PIN, HIGH); // Turn ON Light for Camera
    Serial.println("DETECTED"); 
    
    if (DEBUG_MODE) Serial.println(">>> DETECTED (Waiting for Pi...) <<<");
    
    // DO NOT use delay(2000) here, or you will block the Serial read!
    // The flag `objectDetected = true` prevents spamming.
    delay(500); // Short debounce
  } 
  else if (objectDetected && distance > THRESHOLD_CM + 5) {
    // Input Logic: Object Removed Manually (or successfully dumped)
    // The +5 is a hysteresis buffer
    objectDetected = false;
    digitalWrite(LED_STRAP_PIN, LOW);  // Turn OFF Light
    if (DEBUG_MODE) Serial.println(">>> CLEARED <<<");
    delay(200);
  }
  
  delay(50); // Fast loop to stay responsive
}

void performSorting(String wasteType) {
  int targetAngle = -1;
  
  if (wasteType == "PAPER") targetAngle = POS_PAPER;
  else if (wasteType == "PLASTIC") targetAngle = POS_PLASTIC;
  else if (wasteType == "GLASS") targetAngle = POS_GLASS;
  else if (wasteType == "METAL") targetAngle = POS_METAL;
  
  if (targetAngle == -1) {
    if (DEBUG_MODE) Serial.println("Ignored: Unknown Category");
    return;
  }
  
  if (DEBUG_MODE) Serial.println("Moving Servos...");

  sortServo.attach(SERVO_SORT_PIN);
  dumpServo.attach(SERVO_DUMP_PIN);
  delay(50);

  // Align
  sortServo.write(targetAngle);
  delay(1000); 
  
  // Dump
  dumpServo.write(DUMP_ACTIVE);
  delay(800); 
  dumpServo.write(DUMP_REST);
  delay(800); 
  
  sortServo.write(0);
  delay(500);
  sortServo.detach();
  dumpServo.detach();
}
