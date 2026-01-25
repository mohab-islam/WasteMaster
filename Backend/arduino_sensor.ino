#include <Servo.h>

// WasteMaster Sorting Node
// Hardware: 
// 1. HC-SR04 Ultrasonic Sensor
// 2. Servo 1 (Sorter/Aligner) - Pin 3
// 3. Servo 2 (Dumper) - Pin 5

// PINS
#define TRIG_PIN 9
#define ECHO_PIN 10
#define SERVO_SORT_PIN 3
#define SERVO_DUMP_PIN 5

// SETTINGS
#define THRESHOLD_CM 20
bool DEBUG_MODE = false;

// SERVO ANGLES (Calibrate these!)
// 4 Chambers assumed at 0, 90, 180, (and maybe 270 if 360 servo)
// Standard Servo (0-180) mapping example:
int POS_PAPER = 0;
int POS_PLASTIC = 60;
int POS_METAL = 120;
int POS_GLASS = 180;
int POS_TRASH = 90; // Default

// Dumper Angles
int DUMP_REST = 0;
int DUMP_ACTIVE = 45;

Servo sortServo;
Servo dumpServo;

bool objectDetected = false;
String command = "";

void setup() {
  Serial.begin(9600);
  
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  
  sortServo.attach(SERVO_SORT_PIN);
  dumpServo.attach(SERVO_DUMP_PIN);
  
  // Reset positions
  sortServo.write(90); // Center
  dumpServo.write(DUMP_REST);
  
  if (DEBUG_MODE) Serial.println("System Ready.");
}

void loop() {
  // 1. Check for Incoming Commands from Pi (Python)
  if (Serial.available() > 0) {
    command = Serial.readStringUntil('\n');
    command.trim();
    
    if (command.length() > 0) {
      if (DEBUG_MODE) {
        Serial.print("Recv: ");
        Serial.println(command);
      }
      performSorting(command);
      // Reset detection logic after sorting
      objectDetected = false;
      delay(1000); 
    }
  }

  // 2. Sensor Logic (Only if not already processing)
  if (!objectDetected) {
    int dist = getDistance();
    
    if (DEBUG_MODE) {
      // Serial.println(dist);
    }

    if (dist > 0 && dist < THRESHOLD_CM) {
      objectDetected = true;
      Serial.println("DETECTED"); // Trigger Pi
      delay(500); // Debounce
    }
  }
  
  delay(100);
}

void performSorting(String wasteType) {
  int targetAngle = 90;
  
  if (wasteType == "PAPER") targetAngle = POS_PAPER;
  else if (wasteType == "PLASTIC") targetAngle = POS_PLASTIC;
  else if (wasteType == "METAL") targetAngle = POS_METAL;
  else if (wasteType == "GLASS") targetAngle = POS_GLASS;
  else targetAngle = POS_TRASH;
  
  // Attach Servos only when needed
  sortServo.attach(SERVO_SORT_PIN);
  dumpServo.attach(SERVO_DUMP_PIN);
  delay(100); // Startup delay
  
  // Step 1: Align Sorter
  sortServo.write(targetAngle);
  delay(1000); // Wait for servo to reach position
  
  // Step 2: Dump
  dumpServo.write(DUMP_ACTIVE);
  delay(1000); // Hold
  dumpServo.write(DUMP_REST);
  delay(1000); // Recover and ensure fully back
  
  // Step 3: Detach to save power (reduces hum/jitter)
  sortServo.detach();
  dumpServo.detach();
}

int getDistance() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);
  
  long duration = pulseIn(ECHO_PIN, HIGH);
  return duration * 0.034 / 2;
}
