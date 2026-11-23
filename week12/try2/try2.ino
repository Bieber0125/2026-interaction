const int joyX = A0;
const int joyY = A1;
const int joyBtn = A2;
const int buzzer = 8;

int leds[] = {3, 4, 5, 6, 7, 9, 10, 11, 12}; 
const int ledCount = 9;
int targetIndex1 = 4;      // 第一個目標燈（一開始在正中央第 4 格）
int targetIndex2 = -1;     // 第二個目標燈（-1 代表尚未開啟，Level 3 才開啟）

int currentPos = 0;
int direction = 1;
int gameSpeed = 150;
int score = 0;
int centerX = 512;

void setup() {
  Serial.begin(9600);
  for (int i = 0; i < ledCount; i++) {
    pinMode(leds[i], OUTPUT);
  }
  pinMode(joyBtn, INPUT_PULLUP);
  pinMode(buzzer, OUTPUT);
  
  randomSeed(analogRead(A5)); 
  
  delay(200);
  centerX = analogRead(joyX);
}

void loop() {
  for (int i = 0; i < ledCount; i++) {
    digitalWrite(leds[i], LOW);
  }
  
  // 點亮第一個目標燈
  digitalWrite(leds[targetIndex1], HIGH);
  // 如果已進入 Level 3 (targetIndex2 >= 0)，同時點亮第二個目標燈
  if (targetIndex2 >= 0) {
    digitalWrite(leds[targetIndex2], HIGH);
  }
  // 點亮目前跑動的光點
  digitalWrite(leds[currentPos], HIGH);

  sendDataToProcessing(0);

  bool isPressed = (digitalRead(joyBtn) == LOW);
  int xVal = analogRead(joyX);
  bool isMoved = (abs(xVal - centerX) > 300);

  if (isPressed || isMoved) {
    checkHit();
    while (digitalRead(joyBtn) == LOW || abs(analogRead(joyX) - centerX) > 200) {
      delay(20);
    }
    delay(200);
  }

  currentPos += direction;
  if (currentPos >= ledCount - 1 || currentPos <= 0) {
    direction = -direction;
  }

  delay(gameSpeed);
}

void checkHit() {
  // 判斷是否命中「第一個目標」或「第二個目標」
  bool hitTarget1 = (currentPos == targetIndex1);
  bool hitTarget2 = (targetIndex2 >= 0 && currentPos == targetIndex2);

  if (hitTarget1 || hitTarget2) {
    // 【過關！】
    score++;
    sendDataToProcessing(1);

    // 判斷是否剛好晉級（每得 2 分晉升 1 級，最高到 Level 5 即 8 分）
    if (score % 2 == 0 && score <= 8) {
      playLevelUpMelody(); 
    } else {
      tone(buzzer, 988, 80);   // B5
      delay(85);
      tone(buzzer, 1319, 220); // E6
      delay(220);
    }
    
    // 隨機抽取下一個不重複的 targetIndex1
    int newTarget1 = targetIndex1;
    while (newTarget1 == targetIndex1) {
      newTarget1 = random(0, ledCount);
    }
    targetIndex1 = newTarget1;

    // ★★★ 如果分數達到 4 分以上（進入 Level 3），開啟並抽取第二個不重複的黃點 ★★★
    if (score >= 4) {
      int newTarget2 = targetIndex1;
      while (newTarget2 == targetIndex1) {
        newTarget2 = random(0, ledCount);
      }
      targetIndex2 = newTarget2;
    } else {
      targetIndex2 = -1;
    }

    if (gameSpeed > 35) gameSpeed -= 15;
  } else {
    // 【失敗！】
    sendDataToProcessing(2);

    tone(buzzer, 200, 500);
    for (int k = 0; k < 2; k++) {
      for (int i = 0; i < ledCount; i++) digitalWrite(leds[i], HIGH);
      delay(200);
      for (int i = 0; i < ledCount; i++) digitalWrite(leds[i], LOW);
      delay(200);
    }
    
    for (int i = 0; i < ledCount; i++) {
      digitalWrite(leds[i], (i < score) ? HIGH : LOW);
    }
    delay(1500);
    
    // 重置遊戲（回到單一目標，正中央）
    score = 0;
    gameSpeed = 150;
    currentPos = 0;
    direction = 1;
    targetIndex1 = 4;
    targetIndex2 = -1;
    centerX = analogRead(joyX);
  }
}

void playLevelUpMelody() {
  int melody[] = {392, 523, 659, 784, 1047, 1319, 1568, 1319};
  int duration[] = {90, 90, 90, 90, 90, 90, 240, 320};

  for (int i = 0; i < 8; i++) {
    tone(buzzer, melody[i], duration[i]);
    delay(duration[i] * 1.15);
  }
  noTone(buzzer);
}

// 傳送 5 個數值：目前位置, 分數, 狀態, 目標1, 目標2
void sendDataToProcessing(int state) {
  Serial.print(currentPos);
  Serial.print(",");
  Serial.print(score);
  Serial.print(",");
  Serial.print(state);
  Serial.print(",");
  Serial.print(targetIndex1);
  Serial.print(",");
  Serial.println(targetIndex2);
}
