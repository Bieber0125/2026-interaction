// week11_3_processing_joystick_serial_?????
// 要把 Arduino 的資料，用 USB 讀入 (要記得關 A...
import processing.serial.*; // 使用 USB 的 Seri...
Serial myPort;
void setup() {
  size(512, 512);
  myPort = new Serial( this, "COM3", 9600);
}
int x = 0, y = 0, sw = 0;
void draw() {
  background(255);
  if (myPort.available() >= 3) { // 亂碼、亂碼、...
    x = (int) myPort.read();
    y = (int) myPort.read();
    sw = (int) myPort.read();
    //myPort.read();
  }
  ellipse( x+128, y+128, 8, 8);
}
