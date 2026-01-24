// WasteMaster Arduino Sensor Node (DEBUG VERSION)
// Hardware: Arduino Uno/Nano, HC-SR04 Ultrasonic Sensor
// Function: Detects object in bin, sends "DETECTED" signal via Serial to Raspberry Pi.

#define TRIG_PIN 9
#define ECHO_PIN 10
#define THRESHOLD_CM 20  // Detection distance in cm

// Set this to true to see distance values in Serial Monitor
// Set to false when connecting to Raspberry Pi Python script
bool DEBUG_MODE = true; 

bool objectDetected = false;

void setup() {
  Serial.begin(9600); 
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  
  if (DEBUG_MODE) {
    Serial.println("--- WasteMaster Sensor DEBUG ---");
    Serial.println("1. Open Serial Monitor at 9600 baud");
    Serial.println("2. Verify distance readings below");
  }
}

void loop() {
  long duration;
  int distance;

  // Clear trig
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  
  // Trigger pulse
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);
  
  // Read echo
  duration = pulseIn(ECHO_PIN, HIGH);
  
  // Calculate dist (speed of sound 343m/s)
  distance = duration * 0.034 / 2;
  
  if (DEBUG_MODE) {
    Serial.print("Distance: ");
    Serial.print(distance);
    Serial.println(" cm");
  }

  // Logic: Only send "DETECTED" when an object ENTERS the range
  if (!objectDetected && distance > 0 && distance < THRESHOLD_CM) {
    // New Object Detected!
    objectDetected = true;
    Serial.println("DETECTED"); // This is the signal for the Pi
    
    if (DEBUG_MODE) {
       Serial.println(">>> TRIGGER SENT <<<");
    }
    
    delay(2000); // Wait 2s to avoid double triggers
  } 
  else if (objectDetected && distance > THRESHOLD_CM) {
    // Object removed
    objectDetected = false;
  }
  
  delay(200); // 5Hz sampling
}
