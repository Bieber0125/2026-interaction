import processing.serial.*;

String myComPort = "COM3"; 

Serial myPort;
int currentPos = 0;
int score = 0;
int highScore = 0;
int gameState = 0; // 0=進行中, 1=命中, 2=失敗, 3=管理者模式
int targetPos1 = 4;
int targetPos2 = -1;
int targetPos3 = -1;
int speedLevel = 3;
int adminCursor = 0;
int targetCount = 1; // 直接接收管理者設定的黃點數量
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
  if (gameState == 3) {
    drawAdminScreen();
    return;
  }

  int level = (score / 2) + 1;
  if (level > 5) level = 5;

  if (gameState == 1) {
    background(40, 180, 95);
  } else if (gameState == 2) {
    background(190, 40, 40);
  } else {
    if (level == 1) background(25, 28, 36);
    else if (level == 2) background(20, 48, 82);
    else if (level == 3) background(58, 28, 86);
    else if (level == 4) background(115, 55, 18);
    else background(110, 20, 45);
  }

  // 左上角連線狀態
  fill(210);
  textAlign(LEFT);
  textSize(16);
  text(statusMsg, 20, 30);

  // 右上角等級與目前速度資訊
  fill(255, 230, 120);
  textAlign(RIGHT);
  textSize(18);
  text("LEVEL " + level + "  |  SPD: " + speedLevel, width - 25, 32);

  // 標題
  fill(255);
  textAlign(CENTER);
  textSize(28);
  text("MAKER UNO REACTION GAME", width/2, 75);
  
  // 分數與最高紀錄
  textSize(42);
  fill(255, 220, 50);
  text("SCORE: " + score, width * 0.32, 145);
  
  fill(100, 220, 255);
  text("BEST: " + highScore, width * 0.68, 145);

  // 畫出 9 顆虛擬 LED 燈珠（已消除的目標會自動變成熄滅狀態）
  float startX = 120;
  float spacing = 70;
  int activeTargets = 0;

  for (int i = 0; i < 9; i++) {
    float x = startX + i * spacing;
    float y = 275;
    
    boolean isTarget = (i == targetPos1) || 
                       (targetPos2 >= 0 && i == targetPos2) || 
                       (targetPos3 >= 0 && i == targetPos3);
    if (isTarget) activeTargets++;

    if (isTarget) {
      stroke(255, 200, 0);
      strokeWeight(4);
    } else {
      noStroke();
    }
    
    if (i == currentPos) {
      fill(0, 255, 200);
    } else if (isTarget) {
      fill(255, 180, 0, 130);
    } else {
      fill(255, 255, 255, 35);
    }
    ellipse(x, y, 48, 48);
  }

  // 下方提示文字
  textSize(32);
  if (gameState == 1) {
    fill(255);
    if (activeTargets > 0) {
      text("TARGET CLEARED! (" + activeTargets + " LEFT)", width/2, 390);
    } else if (score == highScore && score > 0) {
      text("NEW HIGH SCORE!", width/2, 390);
    } else {
      text("STAGE CLEAR!", width/2, 390);
    }
  } else if (gameState == 2) {
    fill(255);
    text("GAME OVER!", width/2, 390);
  } else {
    fill(220);
    textSize(20);
    if (activeTargets > 1) {
      text("Clear ALL " + activeTargets + " yellow targets to advance!", width/2, 390);
    } else {
      text("Press Joystick BUTTON when light hits YELLOW!", width/2, 390);
    }
  }
}

void drawAdminScreen() {
  background(15, 20, 25);
  
  noFill();
  stroke(0, 255, 180);
  strokeWeight(3);
  rect(40, 40, width - 80, height - 80, 15);
  noStroke();

  fill(0, 255, 180);
  textAlign(CENTER);
  textSize(32);
  text("[ ADMIN MODE - GAME SETTINGS ]", width/2, 100);

  // 選項 1：速度設定 (1 ~ 10)
  textSize(28);
  if (adminCursor == 0) {
    fill(255, 220, 50);
    text(">  INITIAL SPEED (1 - 10):   < " + speedLevel + " >", width/2, 200);
  } else {
    fill(140);
    text("   INITIAL SPEED (1 - 10):     " + speedLevel, width/2, 200);
  }

  // 選項 2：黃點數量設定 (1 ~ 3)
  if (adminCursor == 1) {
    fill(255, 220, 50);
    text(">  YELLOW TARGETS (1 - 3):   < " + targetCount + " >", width/2, 275);
  } else {
    fill(140);
    text("   YELLOW TARGETS (1 - 3):     " + targetCount, width/2, 275);
  }

  fill(200);
  textSize(18);
  text("UP/DOWN: Select Option   |   LEFT/RIGHT: Change Value", width/2, 360);
  
  fill(0, 255, 180);
  textSize(22);
  text("Press Joystick BUTTON to Start Game!", width/2, 405);
}

void serialEvent(Serial myPort) {
  String inString = myPort.readStringUntil('\n');
  if (inString != null) {
    inString = trim(inString);
    int[] data = int(split(inString, ','));
    if (data.length == 9) {
      currentPos = data[0];
      score = data[1];
      gameState = data[2];
      targetPos1 = data[3];
      targetPos2 = data[4];
      targetPos3 = data[5];
      speedLevel = data[6];
      adminCursor = data[7];
      targetCount = data[8];
      
      if (score > highScore && gameState != 3) {
        highScore = score;
      }
    }
  }
}
