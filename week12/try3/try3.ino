const int joyX = A0;
const int joyY = A1;
const int joyBtn = A2;
const int buzzer = 8;

int leds[] = {3, 4, 5, 6, 7, 9, 10, 11, 12}; 
const int ledCount = 9;

// 目標位置陣列（最多支援 3 顆黃點，-1 代表該顆已消除或未開啟）
int targets[3] = {4, -1, -1}; 

int currentPos = 0;
int direction = 1;
int score = 0;
int centerX = 512;
int centerY = 512;

// 遊戲參數設定（可透過管理者模式調整）
int speedLevel = 3;       // 速度等級 1 ~ 10 (預設 3)
int targetCount = 1;      // 黃點數量 1 ~ 3 (預設 1)
int gameSpeed = 160;      // 實際延遲毫秒數

// 管理者模式與秘技偵測變數（1=上, 2=下, 3=左, 4=右）
const int secretCode[8] = {1, 1, 2, 2, 3, 3, 4, 4}; // 上上下下左左右右
int codeStep = 0;
bool isAdminMode = false;
int adminCursor = 0;      // 0 = 調整速度, 1 = 調整黃點數

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
  centerY = analogRead(joyY);
  applyAdminSettings();
}

void loop() {
  if (isAdminMode) {
    handleAdminMode();
    return;
  }

  // --- 正常遊戲模式 ---
  for (int i = 0; i < ledCount; i++) {
    digitalWrite(leds[i], LOW);
  }
  
  // 點亮場上「還沒被消除」的黃色目標燈
  for (int t = 0; t < 3; t++) {
    if (targets[t] >= 0) {
      digitalWrite(leds[targets[t]], HIGH);
    }
  }
  // 點亮目前跑動的光點
  digitalWrite(leds[currentPos], HIGH);

  sendDataToProcessing(0);

  // 讀取搖桿方向（比對秘技）
  int dir = readJoystickDirection();
  if (dir != 0) {
    checkSecretCode(dir);
    while (readJoystickDirection() != 0) {
      delay(20);
    }
  }

  // 按下搖桿中央按鈕判定命中
  if (digitalRead(joyBtn) == LOW) {
    checkHit();
    while (digitalRead(joyBtn) == LOW) {
      delay(20);
    }
    delay(150);
  }

  currentPos += direction;
  if (currentPos >= ledCount - 1 || currentPos <= 0) {
    direction = -direction;
  }

  delay(gameSpeed);
}

int readJoystickDirection() {
  int xVal = analogRead(joyX);
  int yVal = analogRead(joyY);
  
  if (yVal < centerY - 320) return 1; // 上
  if (yVal > centerY + 320) return 2; // 下
  if (xVal < centerX - 320) return 3; // 左
  if (xVal > centerX + 320) return 4; // 右
  return 0;
}

void checkSecretCode(int dir) {
  if (dir == secretCode[codeStep]) {
    codeStep++;
    tone(buzzer, 800 + codeStep * 100, 40);
    if (codeStep == 8) {
      codeStep = 0;
      isAdminMode = true;
      adminCursor = 0;
      generateTargets(targetCount); // 確保進入時同步顯示目前的黃點設定數
      playAdminEnterSound();
    }
  } else {
    codeStep = (dir == secretCode[0]) ? 1 : 0;
  }
}

void handleAdminMode() {
  // 板子 LED 顯示目前設定的數值
  for (int i = 0; i < ledCount; i++) {
    int val = (adminCursor == 0) ? speedLevel : targetCount;
    digitalWrite(leds[i], (i < val) ? HIGH : LOW);
  }

  sendDataToProcessing(3);

  int dir = readJoystickDirection();
  if (dir != 0) {
    if (dir == 1 || dir == 2) {
      // 上或下：切換調整項目
      adminCursor = 1 - adminCursor;
      tone(buzzer, 1000, 50);
    } else if (dir == 3) {
      // 左：減少數值
      if (adminCursor == 0 && speedLevel > 1) speedLevel--;
      if (adminCursor == 1 && targetCount > 1) {
        targetCount--;
        generateTargets(targetCount); // ★ 修正：立刻更新陣列，讓畫面同步顯示新的數量！
      }
      tone(buzzer, 700, 50);
    } else if (dir == 4) {
      // 右：增加數值
      if (adminCursor == 0 && speedLevel < 10) speedLevel++;
      if (adminCursor == 1 && targetCount < 3) {
        targetCount++;
        generateTargets(targetCount); // ★ 修正：立刻更新陣列，讓畫面同步顯示新的數量！
      }
      tone(buzzer, 1200, 50);
    }
    while (readJoystickDirection() != 0) delay(20);
  }

  // 按下搖桿按鈕：確認設定並開始遊戲！
  if (digitalRead(joyBtn) == LOW) {
    tone(buzzer, 1500, 150);
    while (digitalRead(joyBtn) == LOW) delay(20);
    isAdminMode = false;
    score = 0;
    currentPos = 0;
    direction = 1;
    applyAdminSettings();
    delay(300);
  }
  delay(50);
}

void applyAdminSettings() {
  gameSpeed = map(speedLevel, 1, 10, 220, 40);
  generateTargets(targetCount);
}

void generateTargets(int count) {
  for (int i = 0; i < 3; i++) targets[i] = -1;
  
  for (int i = 0; i < count; i++) {
    int candidate;
    bool duplicate;
    do {
      candidate = random(0, ledCount);
      duplicate = false;
      for (int j = 0; j < i; j++) {
        if (targets[j] == candidate) duplicate = true;
      }
    } while (duplicate);
    targets[i] = candidate;
  }
}

void checkHit() {
  int hitIndex = -1;
  for (int i = 0; i < 3; i++) {
    if (targets[i] >= 0 && currentPos == targets[i]) {
      hitIndex = i;
      break;
    }
  }

  if (hitIndex != -1) {
    // 1. 先把命中的這顆黃點「消除」（設為 -1）
    targets[hitIndex] = -1;

    // 2. 檢查場上是否還有其他還沒消除的黃點
    int remaining = 0;
    for (int i = 0; i < 3; i++) {
      if (targets[i] >= 0) remaining++;
    }

    if (remaining > 0) {
      // 【還有黃點未消除】：只播放「消除單顆黃點」的清脆音效，不進下一關！
      sendDataToProcessing(1); // 閃一下綠底回饋手感
      tone(buzzer, 1319, 100); // 高音 Mi
      delay(110);
    } else {
      // 【場上黃點已全部消除！正式過關進下一關】：
      score++;
      sendDataToProcessing(1);

      if (score % 2 == 0 && score <= 8) {
        playLevelUpMelody();
      } else {
        tone(buzzer, 988, 80);
        delay(85);
        tone(buzzer, 1319, 220);
        delay(220);
      }

      // 決定下一關的黃點數量（取管理者設定值與晉級規則的最大值）
      int nextTargets = targetCount;
      if (score >= 4 && nextTargets < 2) nextTargets = 2;
      generateTargets(nextTargets);

      if (gameSpeed > 35) gameSpeed -= 10;
    }
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
    
    // 失敗重置回目前設定的初始難度
    score = 0;
    currentPos = 0;
    direction = 1;
    applyAdminSettings();
    centerX = analogRead(joyX);
    centerY = analogRead(joyY);
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

void playAdminEnterSound() {
  tone(buzzer, 1047, 80); delay(90);
  tone(buzzer, 1319, 80); delay(90);
  tone(buzzer, 1568, 80); delay(90);
  tone(buzzer, 2093, 180); delay(200);
}

// 傳送 9 個數值：位置, 分數, 狀態, 目標1, 目標2, 目標3, 速度設定, 游標位置, 黃點設定數
void sendDataToProcessing(int state) {
  Serial.print(currentPos);   Serial.print(",");
  Serial.print(score);        Serial.print(",");
  Serial.print(state);        Serial.print(",");
  Serial.print(targets[0]);   Serial.print(",");
  Serial.print(targets[1]);   Serial.print(",");
  Serial.print(targets[2]);   Serial.print(",");
  Serial.print(speedLevel);   Serial.print(",");
  Serial.print(adminCursor);  Serial.print(",");
  Serial.println(targetCount);
}
