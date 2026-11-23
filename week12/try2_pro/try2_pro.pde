import processing.serial.*;

String myComPort = "COM3"; 

Serial myPort;
int currentPos = 0;
int score = 0;
int highScore = 0;
int gameState = 0;
int targetPos1 = 4;
int targetPos2 = -1; // -1 代表目前只有 1 個目標點；>= 0 代表開啟第 2 個目標點
String statusMsg = "";

void setup() {
  size(800, 480);
  
  try {
    myPort = new Serial(this, myComPort, 9600);
    myPort.bufferUntil('\n');
    statusMsg = "Connecting to: " + myComPort;
  } catch (Exception e) {
    statusMsg = "Connection failed! Check " + myComPort + " or close Serial Monitor";
    println(e.getMessage());
  }
}

void draw() {
  int level = (score / 2) + 1;
  if (level > 5) level = 5;

  if (gameState == 1) {
    background(40, 180, 95);     // 得分綠底
  } else if (gameState == 2) {
    background(190, 40, 40);     // 失敗紅底
  } else {
    if (level == 1) {
      background(25, 28, 36);    // Level 1 (0~1分)
    } else if (level == 2) {
      background(20, 48, 82);    // Level 2 (2~3分)
    } else if (level == 3) {
      background(58, 28, 86);    // Level 3 (4~5分)：開始出現雙黃點！
    } else if (level == 4) {
      background(115, 55, 18);   // Level 4 (6~7分)
    } else {
      background(110, 20, 45);   // Level 5 (8分以上)
    }
  }

  // 左上角連線狀態
  fill(210);
  textAlign(LEFT);
  textSize(16);
  text(statusMsg, 20, 30);

  // 右上角顯示目前等級
  fill(255, 230, 120);
  textAlign(RIGHT);
  textSize(18);
  text("LEVEL " + level, width - 25, 32);

  // 標題
  fill(255);
  textAlign(CENTER);
  textSize(28);
  text("MAKER UNO REACTION GAME", width/2, 75);
  
  // 目前分數與最高紀錄
  textSize(42);
  fill(255, 220, 50);
  text("SCORE: " + score, width * 0.32, 145);
  
  fill(100, 220, 255);
  text("BEST: " + highScore, width * 0.68, 145);

  // 畫出 9 顆虛擬 LED 燈珠
  float startX = 120;
  float spacing = 70;
  for (int i = 0; i < 9; i++) {
    float x = startX + i * spacing;
    float y = 275;
    
    // 判斷該格是否為「目標1」或「目標2」
    boolean isTarget = (i == targetPos1) || (targetPos2 >= 0 && i == targetPos2);
    
    if (isTarget) {
      stroke(255, 200, 0);
      strokeWeight(4);
    } else {
      noStroke();
    }
    
    if (i == currentPos) {
      fill(0, 255, 200);          // 移動光點（亮青色）
    } else if (isTarget) {
      fill(255, 180, 0, 130);     // 目標位置（黃色，兩個目標都會亮黃框）
    } else {
      fill(255, 255, 255, 35);    // 熄滅狀態
    }
    ellipse(x, y, 48, 48);
  }

  // 下方提示文字
  textSize(32);
  if (gameState == 1) {
    fill(255);
    if (score == highScore && score > 0) {
      text("NEW HIGH SCORE!", width/2, 390);
    } else {
      text("PERFECT HIT!", width/2, 390);
    }
  } else if (gameState == 2) {
    fill(255);
    text("GAME OVER!", width/2, 390);
  } else {
    fill(220);
    textSize(20);
    if (level >= 3) {
      text("DOUBLE TARGETS! Hit ANY yellow LED!", width/2, 390);
    } else {
      text("Hit the yellow target LED using the Joystick!", width/2, 390);
    }
  }
}

void serialEvent(Serial myPort) {
  String inString = myPort.readStringUntil('\n');
  if (inString != null) {
    inString = trim(inString);
    int[] data = int(split(inString, ','));
    // 現在接收 5 個數值：位置, 分數, 狀態, 目標1, 目標2
    if (data.length == 5) {
      currentPos = data[0];
      score = data[1];
      gameState = data[2];
      targetPos1 = data[3];
      targetPos2 = data[4];
      
      if (score > highScore) {
        highScore = score;
      }
    }
  }
}
