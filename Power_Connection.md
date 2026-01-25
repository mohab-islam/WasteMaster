# WasteMaster - External Power Connection Guide

This guide details how to power the **2 Servo Motors** using an external 11.1V battery pack (3x 3.7V) regulated by an **LM2596 DC-DC Buck Converter**.

## Why this is needed?
Servo motors draw high current (spikes of 1A+). Powering them directly from the Arduino 5V pin often causes the Arduino to reset (brownout). External power ensures stable operation.

## Components
1.  **Battery Pack**: Case with 3x 18650 (3.7V) batteries in Series.
    *   **Voltage**: ~11.1V (12.6V fully charged).
2.  **Voltage Regulator**: LM2596 DC-DC Buck Converter.
3.  **Controller**: Arduino Uno/Nano.
4.  **Motors**: 2x Servo Motors (MG995, SG90, etc.).

## ⚠️ Important: Common Ground
You **MUST** connect the **Negative (-)** of the Battery/LM2596 output to the **GND** of the Arduino. Without this "Common Ground", the control signals won't work.

## Wiring Diagram

### 1. Power Source -> Regulator
*   **Battery Red (+)** -> **LM2596 IN +**
*   **Battery Black (-)** -> **LM2596 IN -**

**CRITICAL STEP**: Before connecting servos, use a screwdriver to turn the potentiometer on the LM2596. Measure the **OUT +** and **OUT -** with a multimeter. Adjust until it reads **5.0V - 6.0V**. (Do not exceed 6V for standard servos).

### 2. Regulator -> Servos
*   **LM2596 OUT +** -> **Servo Red Wire (VCC)** (Connect both servos here)
*   **LM2596 OUT -** -> **Servo Brown/Black Wire (GND)** (Connect both servos here)

### 3. Common Ground (The "Magic" Wire)
*   **LM2596 OUT -** -> **Arduino GND**
*   *(Alternatively: Connect Servo GND to Arduino GND, effectively linking them).*

### 4. Logic & Control (Arduino)
*   **Arduino Pin 3** -> **Servo 1 (Sorter) Orange/Yellow Wire (Signal)**
*   **Arduino Pin 5** -> **Servo 2 (Dumper) Orange/Yellow Wire (Signal)**

*Note: The Arduino itself can still be powered via USB from the Raspberry Pi. This isolates the logic power from the noisy motor power.*

## Full Circuit Summary

| From | To | Purpose |
| :--- | :--- | :--- |
| **Battery (+)** | **LM2596 IN (+)** | Raw Power (11.1V) |
| **Battery (-)** | **LM2596 IN (-)** | Raw Ground |
| **LM2596 OUT (+)** | **Servo 1 & 2 (Red)** | Regulated Power (5V) |
| **LM2596 OUT (-)** | **Servo 1 & 2 (Black)** | High Power Ground |
| **LM2596 OUT (-)** | **Arduino GND** | **Common Ground** (Essential) |
| **Arduino Pin 3** | **Servo 1 (Yellow)** | Control Signal |
| **Arduino Pin 5** | **Servo 2 (Yellow)** | Control Signal |
| **RPi USB** | **Arduino USB** | Logic Power & Serial Data |
