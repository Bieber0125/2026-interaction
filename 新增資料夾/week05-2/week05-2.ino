// week05-2
void setup() {
  Serial.begin(9600); // USB Serial 開始傳輸, 速度 9600 bps
  tone(8, 523, 100);delay(200);//DO
  tone(8, 587, 100);delay(200);//RE
  tone(8, 659, 100);delay(200);//MI
  tone(8, 587, 100);delay(200);//RE
  tone(8, 523, 100);delay(200);//DO
}
char c = '0';
void loop() {
  if (Serial.available()){ // 如果 USB Serial 有收到資料
    c = Serial.read(); // 就讀進來
  }
    if (c=='0') noTone(8);
    if (c=='1') tone(8, 523, 100); // Do 1秒
    if (c=='2') tone(8, 587, 100); // Re 1秒
    if (c=='3') tone(8, 659, 100); // Mi 1秒
  }
