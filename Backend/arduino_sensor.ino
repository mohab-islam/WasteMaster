// WasteMaster Arduino Sensor Node
// Hardware: Arduino Uno/Nano, HC-SR04 Ultrasonic Sensor
// Function: Detects object in bin, sends "DETECTED" signal via Serial to Raspberry Pi.

#define TRIG_PIN 9
#define ECHO_PIN 10
#define THRESHOLD_CM 20  // Detection distance in cm
#define HYSTERESIS_CM 5  // Buffer to prevent flickering

bool objectDetected = false;

void setup() {
  Serial.begin(9600); // Communication with Raspberry Pi
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  
  // Initialize Serial
  // Serial.println("WasteMaster Sensor Node Ready");
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
  
  // Debug (Optional, might confuse Pi if not careful with parsing)
  // Serial.print("Distance: ");
  // Serial.println(distance);

  // Logic with Hysteresis
  if (!objectDetected && distance > 0 && distance < THRESHOLD_CM) {
    // New Object Detected!
    objectDetected = true;
    Serial.println("DETECTED"); // Trigger Signal for Pi
    delay(2000); // Wait for object to settle/process
  } 
  else if (objectDetected && distance > (THRESHOLD_CM + HYSTERESIS_CM)) {
    // Object removed / Bin clear
    objectDetected = false;
    // Serial.println("CLEAR"); 
    delay(500);
  }
  
  delay(100); // 10Hz sampling
}
