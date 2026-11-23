import processing.serial.*;
import javax.sound.sampled.*;

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
int targetCount = 1;
boolean soundEnabled = true;
String statusMsg = "";

// 賽博龐克與像素小人對話系統變數
float scanlineY = 0;
PFont cyberFont;
String currentDialogue = "逃生艙引擎已預熱！快解開黃色密碼鎖！";
int lastTrackedState = -1;
int lastTrackedScore = 0;

// 劇情漫畫與突發怪物驚嚇變數
boolean showIntroComic = true;
int comicPage = 0;
int scareTimer = 0;
int lastScareScore = -1;

// 原生 Java 16-bit 立體聲背景音樂執行緒變數
volatile boolean audioRunning = true;
int bgmStep = 0;
double[] tenseBassFreqs = {73.42, 73.42, 87.31, 73.42, 103.83, 98.00, 87.31, 82.41};

String[] winQuotes = {
  "漂亮！一道密碼鎖解開了，怪物就在門外！",
  "神級手速！逃生艙加密系統同步率 100%！",
  "太神啦！在這種壓迫感下還能精準解鎖！",
  "就是這樣！離脫離這艘鬼飛船只差幾道鎖了！",
  "節奏感滿分！繼續破解下一組神經密碼！"
};

String[] tauntQuotes = {
  "哈哈！這手速是被怪物嚇到腿軟了嗎？",
  "差十萬八千里！密碼鎖直接被你按到當機！",
  "警告：反應神經嚴重延遲，異形已經貼到玻璃上了！",
  "就這？再不快點解鎖，我們都要變成怪物晚餐了！",
  "笑死，黃點這麼大顆也能按歪，手在抖喔？",
  "連逃生艙密碼都解不開，準備留在太空餵怪物吧！"
};

String[] idleQuotes = {
  "快一點！艙門外傳來爪子刮玻璃的聲音了！",
  "抓準光點與黃色加密十字重疊的瞬間！",
  "別被剛剛的怪物嚇到，穩住呼吸繼續解鎖！"
};

void setup() {
  size(940, 560);
  smooth(8);
  
  cyberFont = createFont("Microsoft JhengHei Bold", 24);
  textFont(cyberFont);

  startTenseBgmThread();
  
  try {
    myPort = new Serial(this, myComPort, 9600);
    myPort.bufferUntil('\n');
    statusMsg = "飛船終端已連線 // 連接埠: " + myComPort;
  } catch (Exception e) {
    statusMsg = "連線失敗！請檢查 " + myComPort + " 或關閉 Arduino 序列埠視窗";
    println(e.getMessage());
  }
}

void draw() {
  if (showIntroComic) {
    drawComicStoryScreen();
    drawScanlines();
    return;
  }

  updateCharacterAndEvents();

  if (scareTimer > 0) {
    scareTimer--;
    drawMonsterJumpScare();
    drawScanlines();
    return;
  }

  if (gameState == 3) {
    drawCyberAdminScreen();
    return;
  }

  int level = (score / 2) + 1;
  if (level > 5) level = 5;

  pushMatrix();
  if (gameState == 2) {
    translate(random(-7, 7), random(-5, 5));
  }

  color themeAccent;
  if (gameState == 1) {
    background(10, 45, 35);
    themeAccent = color(0, 255, 170);
  } else if (gameState == 2) {
    background(60, 10, 20);
    themeAccent = color(255, 35, 85);
  } else {
    if (level == 1) {
      background(11, 14, 23);
      themeAccent = color(0, 243, 255);
    } else if (level == 2) {
      background(14, 22, 42);
      themeAccent = color(50, 180, 255);
    } else if (level == 3) {
      background(28, 12, 44);
      themeAccent = color(215, 60, 255);
    } else if (level == 4) {
      background(38, 22, 12);
      themeAccent = color(255, 140, 0);
    } else {
      background(40, 10, 22);
      themeAccent = color(255, 230, 0);
    }
  }

  drawCyberGrid(themeAccent);
  drawHudFrame(themeAccent, level);
  drawScorePanels(themeAccent);
  int activeTargets = drawCyberNodes(themeAccent);
  drawPixelCharacterAndDialogue(themeAccent, activeTargets);
  drawScanlines();

  popMatrix();
}

// =========================================================================
// 16-bit 44100Hz 立體聲緊張懸疑背景音樂引擎（高相容性、高音量）
// =========================================================================
void startTenseBgmThread() {
  Thread bgmThread = new Thread(new Runnable() {
    public void run() {
      try {
        float sampleRate = 44100;
        // 改用標準 16-bit signed little-endian 立體聲，相容所有 Windows 音效卡
        AudioFormat af = new AudioFormat(sampleRate, 16, 2, true, false);
        DataLine.Info info = new DataLine.Info(SourceDataLine.class, af);
        SourceDataLine sdl = (SourceDataLine) AudioSystem.getLine(info);
        sdl.open(af, 8192);
        sdl.start();

        while (audioRunning) {
          if (!soundEnabled) {
            Thread.sleep(100);
            continue;
          }

          int level = (score / 2) + 1;
          int noteMs = constrain(240 - level * 22, 110, 240);
          if (scareTimer > 0) noteMs = 65;

          double freq;
          double highAlarmFreq = 0;

          if (scareTimer > 0) {
            freq = 130 + (bgmStep % 2) * 90;
            highAlarmFreq = 820 + (bgmStep % 3) * 150;
          } else if (gameState == 2) {
            freq = 65.0;
          } else {
            freq = tenseBassFreqs[bgmStep % tenseBassFreqs.length];
            if (level >= 3 && bgmStep % 4 == 2) freq *= 2.0;
            if (bgmStep % 4 == 0) highAlarmFreq = freq * 6.0;
          }

          int numSamples = (int)((noteMs / 1000.0) * sampleRate);
          byte[] buf = new byte[numSamples * 4]; // 16-bit 立體聲每個採樣佔 4 bytes

          for (int i = 0; i < numSamples; i++) {
            double t = i / sampleRate;
            double env = Math.max(0.0, 1.0 - (double)i / numSamples);
            // 混合鋸齒波與正弦次低音，讓筆電小喇叭也能清楚聽到低音脈衝
            double bassWave = 0.6 * (((t * freq) % 1.0) * 2.0 - 1.0)
                            + 0.4 * Math.sin(2.0 * Math.PI * (freq * 2.0) * t);
            if (highAlarmFreq > 0) {
              bassWave += 0.35 * Math.sin(2.0 * Math.PI * highAlarmFreq * t);
            }

            short sampleVal = (short)(constrain((float)(bassWave * env * 18000.0), -32000, 32000));
            int idx = i * 4;
            // 左聲道 (Little-Endian)
            buf[idx]     = (byte)(sampleVal & 0xFF);
            buf[idx + 1] = (byte)((sampleVal >> 8) & 0xFF);
            // 右聲道 (Little-Endian)
            buf[idx + 2] = (byte)(sampleVal & 0xFF);
            buf[idx + 3] = (byte)((sampleVal >> 8) & 0xFF);
          }

          sdl.write(buf, 0, buf.length);
          bgmStep++;
          Thread.sleep(25);
        }
        sdl.drain();
        sdl.close();
      } catch (Exception e) {
        println("音效引擎啟動失敗原因: " + e.getMessage());
      }
    }
  });
  bgmThread.setDaemon(true);
  bgmThread.start();
}

void exit() {
  audioRunning = false;
  super.exit();
}

void mousePressed() {
  if (showIntroComic) {
    comicPage++;
    if (comicPage > 2) showIntroComic = false;
  }
}

void keyPressed() {
  if (showIntroComic) {
    comicPage++;
    if (comicPage > 2) showIntroComic = false;
  }
}

void updateCharacterAndEvents() {
  if (score > 0 && score % 3 == 0 && score != lastScareScore && gameState != 2) {
    scareTimer = 95;
    lastScareScore = score;
  }
  if (score == 0) {
    lastScareScore = -1;
  }

  if (gameState != lastTrackedState || score != lastTrackedScore) {
    if (gameState == 1) {
      currentDialogue = winQuotes[int(random(winQuotes.length))];
    } else if (gameState == 2) {
      currentDialogue = tauntQuotes[int(random(tauntQuotes.length))];
    } else if (gameState == 0 && lastTrackedState == 2) {
      currentDialogue = "備用電源啟動！趁怪物還沒破門，快重新破解密碼！";
    } else if (gameState == 0 && lastTrackedState == 1) {
      currentDialogue = idleQuotes[int(random(idleQuotes.length))];
    }
    lastTrackedState = gameState;
    lastTrackedScore = score;
  }
}

void drawComicStoryScreen() {
  background(8, 10, 18);
  color cyberCyan = color(0, 243, 255);
  color cyberYellow = color(255, 230, 0);
  color alarmRed = color(255, 45, 85);

  drawCyberGrid(cyberCyan);

  fill(cyberYellow);
  noStroke();
  rect(40, 25, width - 80, 44);
  fill(10, 12, 18);
  textAlign(CENTER);
  textSize(22);
  text("【緊急檔案 // 深空逃亡日誌 - 第 0" + (comicPage + 1) + " / 03 幕】", width/2, 55);

  float panelX = 70;
  float panelY = 90;
  float panelW = width - 140;
  float panelH = 270;

  fill(16, 22, 34);
  stroke(comicPage == 1 ? alarmRed : cyberCyan);
  strokeWeight(4);
  rect(panelX, panelY, panelW, panelH, 6);

  fill(255, 200);
  noStroke();
  for (int s = 0; s < 25; s++) {
    float sx = panelX + 20 + ((s * 73) % int(panelW - 40));
    float sy = panelY + 20 + ((s * 41) % int(panelH - 40));
    rect(sx, sy, 3, 3);
  }

  if (comicPage == 0) {
    drawPixelSpaceship(panelX + 160, panelY + 110, 8, false);
    drawPixelAlien(panelX + 520, panelY + 75, 10);
    fill(alarmRed);
    textSize(28);
    text("轟隆！！滋滋——！！", panelX + 430, panelY + 65);
  } else if (comicPage == 1) {
    pushMatrix();
    translate(random(-4, 4), random(-4, 4));
    drawPixelBot(panelX + 180, panelY + 85, 11);
    drawPixelAlien(panelX + 500, panelY + 65, 12);
    fill(255, 230, 0);
    textSize(30);
    text("快逃啊！！怪物追上來了！！", panelX + 380, panelY + 60);
    popMatrix();
  } else {
    drawPixelSpaceship(panelX + 140, panelY + 105, 8, true);
    drawPixelLock(panelX + 540, panelY + 80, 10);
    fill(alarmRed);
    textSize(26);
    text("[ 警告：主控系統已鎖死！ ]", panelX + 580, panelY + 60);
  }

  float bubbleX = 70;
  float bubbleY = 380;
  float bubbleW = width - 140;
  float bubbleH = 120;

  fill(245, 248, 255);
  stroke(10, 12, 18);
  strokeWeight(4);
  rect(bubbleX, bubbleY, bubbleW, bubbleH, 12);
  triangle(bubbleX + 160, bubbleY, bubbleX + 190, bubbleY - 22, bubbleX + 210, bubbleY);

  fill(15, 20, 30);
  textAlign(LEFT);
  textSize(20);
  if (comicPage == 0) {
    text("領航員 V-07：「警報！在未知星域遭遇嗜血太空異形襲擊，船身正在解體！」", bubbleX + 28, bubbleY + 42);
    text("旁白：你必須立刻拋棄主艦，衝向最後一艘逃生飛船展開緊急逃難！", bubbleX + 28, bubbleY + 82);
  } else if (comicPage == 1) {
    text("領航員 V-07：「可惡！那隻怪物緊追在後，隨時會把艙門撕碎！」", bubbleX + 28, bubbleY + 42);
    text("旁白：好不容易跳進逃生艙，你立刻按下點火按鈕準備全速脫離——", bubbleX + 28, bubbleY + 82);
  } else {
    text("飛船 AI：「【嚴重危機】逃生推進器遭遇密碼鎖死，無法啟動！」", bubbleX + 28, bubbleY + 42);
    text("領航員 V-07：「快用搖桿抓準黃色節點破解密碼！注意，怪物隨時會撲過來嚇你！」", bubbleX + 28, bubbleY + 82);
  }

  fill(cyberYellow);
  textAlign(RIGHT);
  textSize(16);
  if (comicPage < 2) {
    text(">> 點擊滑鼠左鍵 或 按任意鍵繼續下一幕 ( " + (comicPage + 1) + " / 3 ) >>", width - 70, height - 18);
  } else {
    text(">> 點擊滑鼠左鍵 或 按任意鍵，立即開始破解飛船密碼！ >>", width - 70, height - 18);
  }
}

void drawMonsterJumpScare() {
  if (frameCount % 4 < 2) {
    background(180, 0, 25);
  } else {
    background(10, 0, 5);
  }

  pushMatrix();
  translate(random(-22, 22), random(-18, 18));
  drawPixelAlien(width/2 - 190, 35, 32);

  fill(255, 240, 0);
  textAlign(CENTER);
  textSize(46);
  text("！！警告：怪物貼臉突襲！！", width/2, 470);
  
  fill(255);
  textSize(24);
  text("別慌張！穩住搖桿，千萬別按錯！", width/2, 515);
  popMatrix();
}

void drawPixelAlien(float startX, float startY, int pSize) {
  noStroke();
  int[][] alien = {
    {0,0,1,1,1,1,1,1,1,1,0,0},
    {0,1,1,1,1,1,1,1,1,1,1,0},
    {1,1,2,2,1,1,1,1,2,2,1,1},
    {1,1,2,2,1,1,1,1,2,2,1,1},
    {1,1,1,1,1,2,2,1,1,1,1,1},
    {0,1,1,1,1,1,1,1,1,1,1,0},
    {0,1,3,1,3,1,1,3,1,3,1,0},
    {0,1,0,0,0,0,0,0,0,0,1,0},
    {0,1,3,1,3,1,1,3,1,3,1,0},
    {0,0,1,1,1,4,4,1,1,1,0,0},
    {0,1,1,0,1,4,0,1,0,1,1,0},
    {1,1,0,0,0,4,0,0,0,0,1,1}
  };

  for (int r = 0; r < 12; r++) {
    for (int c = 0; c < 12; c++) {
      int code = alien[r][c];
      if (code == 0) continue;
      if (code == 1) fill(95, 20, 120);
      else if (code == 2) fill(255, 20, 40);
      else if (code == 3) fill(255, 255, 240);
      else if (code == 4) fill(80, 255, 60);
      rect(startX + c * pSize, startY + r * pSize, pSize, pSize);
    }
  }
}

void drawPixelSpaceship(float startX, float startY, int pSize, boolean isLocked) {
  noStroke();
  int[][] ship = {
    {0,0,0,0,0,1,1,0,0,0,0,0},
    {0,0,0,0,1,1,1,1,0,0,0,0},
    {0,0,0,1,1,2,2,1,1,0,0,0},
    {0,0,1,1,2,2,2,2,1,1,0,0},
    {0,1,1,1,1,1,1,1,1,1,1,0},
    {1,1,3,1,1,1,1,1,1,3,1,1},
    {1,0,3,0,1,1,1,1,0,3,0,1},
    {0,0,0,0,4,4,4,4,0,0,0,0}
  };
  for (int r = 0; r < 8; r++) {
    for (int c = 0; c < 12; c++) {
      int code = ship[r][c];
      if (code == 0) continue;
      if (code == 1) fill(220, 230, 245);
      else if (code == 2) fill(0, 243, 255);
      else if (code == 3) fill(isLocked ? color(255, 45, 85) : color(255, 210, 0));
      else if (code == 4) fill(isLocked ? color(100) : color(255, 120, 0));
      rect(startX + c * pSize, startY + r * pSize, pSize, pSize);
    }
  }
}

void drawPixelLock(float startX, float startY, int pSize) {
  noStroke();
  int[][] lockIcon = {
    {0,0,1,1,1,1,0,0},
    {0,1,0,0,0,0,1,0},
    {0,1,0,0,0,0,1,0},
    {1,1,1,1,1,1,1,1},
    {1,1,1,2,2,1,1,1},
    {1,1,1,2,2,1,1,1},
    {1,1,1,1,1,1,1,1}
  };
  for (int r = 0; r < 7; r++) {
    for (int c = 0; c < 8; c++) {
      int code = lockIcon[r][c];
      if (code == 0) continue;
      fill(code == 1 ? color(255, 215, 0) : color(255, 35, 85));
      rect(startX + c * pSize, startY + r * pSize, pSize, pSize);
    }
  }
}

void drawCyberGrid(color accent) {
  stroke(red(accent), green(accent), blue(accent), 22);
  strokeWeight(1);
  int gridSize = 45;
  for (int x = 0; x < width; x += gridSize) line(x, 0, x, height);
  for (int y = 0; y < height; y += gridSize) line(0, y, width, y);
}

void drawHudFrame(color accent, int level) {
  noFill();
  stroke(accent);
  strokeWeight(2);
  
  beginShape();
  vertex(20, 45);
  vertex(45, 20);
  vertex(width - 45, 20);
  vertex(width - 20, 45);
  vertex(width - 20, height - 45);
  vertex(width - 45, height - 20);
  vertex(45, height - 20);
  vertex(20, height - 45);
  endShape(CLOSE);

  fill(accent);
  textAlign(LEFT);
  textSize(14);
  text(">> " + statusMsg, 48, 45);

  textAlign(RIGHT);
  String audioTag = soundEnabled ? "音效:ON" : "音效:OFF";
  text("逃生階段: LV." + level + "  //  脈衝速度: " + speedLevel + " 級  //  " + audioTag, width - 48, 45);

  textAlign(CENTER);
  textSize(30);
  fill(red(accent), green(accent), blue(accent), 90);
  text("太空逃生艙密碼破解 // MAKER UNO", width/2 + 2, 87);
  fill(255);
  text("太空逃生艙密碼破解 // MAKER UNO", width/2, 85);
}

void drawScorePanels(color accent) {
  stroke(accent);
  strokeWeight(2);
  fill(15, 20, 30, 200);
  quad(150, 108, 430, 108, 410, 172, 130, 172);

  fill(accent);
  textAlign(LEFT);
  textSize(14);
  text("已解開密碼層數 // SCORE", 162, 129);
  fill(255, 235, 60);
  textSize(32);
  text(nf(score, 2) + " 層", 162, 163);

  stroke(0, 243, 255);
  fill(15, 20, 30, 200);
  quad(530, 108, 810, 108, 790, 172, 510, 172);

  fill(0, 243, 255);
  textAlign(LEFT);
  textSize(14);
  text("最高逃生紀錄 // BEST", 542, 129);
  fill(255);
  textSize(32);
  text(nf(highScore, 2) + " 層", 542, 163);
}

int drawCyberNodes(color accent) {
  float startX = 150;
  float spacing = 80;
  float y = 265;
  int activeTargets = 0;

  stroke(red(accent), green(accent), blue(accent), 80);
  strokeWeight(3);
  line(startX, y, startX + 8 * spacing, y);

  for (int i = 0; i < 9; i++) {
    float x = startX + i * spacing;
    boolean isTarget = (i == targetPos1) || 
                       (targetPos2 >= 0 && i == targetPos2) || 
                       (targetPos3 >= 0 && i == targetPos3);
    if (isTarget) activeTargets++;

    noFill();
    if (i == currentPos) {
      fill(0, 243, 255, 45);
      noStroke();
      ellipse(x, y, 76, 76);
      stroke(0, 243, 255);
      strokeWeight(3);
    } else if (isTarget) {
      fill(255, 225, 0, 40);
      noStroke();
      ellipse(x, y, 72, 72);
      stroke(255, 225, 0);
      strokeWeight(3);
    } else {
      stroke(100, 120, 140, 110);
      strokeWeight(1.5);
    }

    if (i == currentPos) {
      fill(0, 243, 255);
    } else if (isTarget) {
      fill(255, 210, 0, 190);
    } else {
      fill(18, 24, 36);
    }
    ellipse(x, y, 48, 48);

    if (isTarget && i != currentPos) {
      stroke(255, 255, 255, 200);
      strokeWeight(1.5);
      line(x - 14, y, x + 14, y);
      line(x, y - 14, x, y + 14);
    }

    fill(140, 160, 180);
    textAlign(CENTER);
    textSize(12);
    text("密碼鎖 0" + (i + 1), x, y + 44);
  }
  return activeTargets;
}

void drawPixelCharacterAndDialogue(color accent, int activeTargets) {
  float boxX = 80;
  float boxY = 345;
  float boxW = width - 160;
  float boxH = 165;

  fill(12, 16, 26, 230);
  stroke(accent);
  strokeWeight(2);
  rect(boxX, boxY, boxW, boxH, 8);

  fill(20, 26, 40);
  stroke(accent);
  strokeWeight(1.5);
  rect(boxX + 18, boxY + 18, 128, 128, 6);

  drawPixelBot(boxX + 34, boxY + 32, 8);

  float textStartX = boxX + 168;
  
  fill(accent);
  textAlign(LEFT);
  textSize(16);
  if (gameState == 1) {
    text("【領航員 V-07 // 密碼破解成功】", textStartX, boxY + 38);
  } else if (gameState == 2) {
    fill(255, 50, 95);
    text("【領航員 V-07 // 絕望嘲諷模式】", textStartX, boxY + 38);
  } else {
    text("【領航員 V-07 // 逃生艙通訊】", textStartX, boxY + 38);
  }

  if (gameState == 1) {
    fill(0, 255, 170);
  } else if (gameState == 2) {
    fill(255, 100, 120);
  } else {
    fill(255);
  }
  textSize(21);
  text("「" + currentDialogue + "」", textStartX, boxY + 82);

  fill(170, 190, 210);
  textSize(15);
  if (gameState == 1) {
    if (activeTargets > 0) {
      text(">> 成功解除一道加密！還剩 " + activeTargets + " 顆黃色密碼點，繼續！", textStartX, boxY + 128);
    } else if (score == highScore && score > 0) {
      text(">> 刷新最高逃生紀錄！推進器加速，準備突破下一層！", textStartX, boxY + 128);
    } else {
      text(">> 密碼全數破解！飛船推進器充能，進入下一階段！", textStartX, boxY + 128);
    }
  } else if (gameState == 2) {
    text(">> 密碼錯誤觸發警報！系統即將重置密碼鎖...", textStartX, boxY + 128);
  } else {
    if (activeTargets > 1) {
      text(">> 多重加密危機：請依序消除場上所有 " + activeTargets + " 顆黃色密碼點！", textStartX, boxY + 128);
    } else {
      text(">> 操作提示：光點跑到黃色密碼鎖時，按下搖桿按鈕！", textStartX, boxY + 128);
    }
  }
}

void drawPixelBot(float startX, float startY, int pSize) {
  noStroke();
  float bobY = sin(frameCount * 0.12) * 3;
  startY += bobY;

  int[][] sprite = {
    {0,0,0,0,1,1,1,1,0,0,0,0},
    {0,0,0,1,1,1,1,1,1,0,0,0},
    {0,0,1,1,2,2,2,2,1,1,0,0},
    {0,0,2,2,2,2,2,2,2,2,0,0},
    {0,0,2,3,3,2,2,3,3,2,0,0},
    {0,0,2,3,3,2,2,3,3,2,0,0},
    {0,0,2,2,2,2,2,2,2,2,0,0},
    {0,0,0,2,5,5,5,5,2,0,0,0},
    {0,0,4,4,4,1,1,4,4,4,0,0},
    {0,4,4,4,4,1,1,4,4,4,4,0},
    {0,4,2,4,4,4,4,4,4,2,4,0},
    {0,0,0,4,4,0,0,4,4,0,0,0}
  };

  if (gameState == 2) {
    sprite[3][3] = 1;
    sprite[3][8] = 1;
    sprite[7][4] = 0;
    sprite[7][7] = 0;
  }

  for (int row = 0; row < 12; row++) {
    for (int col = 0; col < 12; col++) {
      int code = sprite[row][col];
      if (code == 0) continue;

      if (code == 1) fill(255, 230, 0);
      else if (code == 2) fill(235, 240, 250);
      else if (code == 3) {
        if (gameState == 1) fill(0, 255, 140);
        else if (gameState == 2) fill(255, 30, 70);
        else fill(0, 243, 255);
      }
      else if (code == 4) fill(35, 95, 160);
      else if (code == 5) {
        if (gameState == 1) fill(0, 255, 170);
        else if (gameState == 2) fill(255, 45, 95);
        else fill(80, 100, 120);
      }

      rect(startX + col * pSize, startY + row * pSize, pSize, pSize);
    }
  }
}

void drawScanlines() {
  stroke(255, 255, 255, 10);
  strokeWeight(1);
  for (int y = 0; y < height; y += 4) line(0, y, width, y);
  
  noStroke();
  fill(0, 243, 255, 14);
  rect(0, scanlineY, width, 18);
  scanlineY += 2.5;
  if (scanlineY > height) scanlineY = 0;
}

void drawCyberAdminScreen() {
  background(10, 12, 18);
  color cyberYellow = color(255, 230, 0);
  color cyberCyan = color(0, 243, 255);

  drawCyberGrid(cyberYellow);

  noFill();
  stroke(cyberYellow);
  strokeWeight(2.5);
  rect(45, 45, width - 90, height - 90);
  
  fill(cyberYellow);
  noStroke();
  rect(45, 45, width - 90, 52);
  
  fill(10, 12, 18);
  textAlign(CENTER);
  textSize(24);
  text("// 最高權限已解鎖：管理者控制台 //", width/2, 79);

  textSize(25);
  if (adminCursor == 0) {
    fill(cyberCyan);
    text(">> [ 初始脈衝速度 (01 - 10) ] :   < 第 " + nf(speedLevel, 2) + " 級 >", width/2, 180);
  } else {
    fill(110, 125, 140);
    text("   [ 初始脈衝速度 (01 - 10) ] :     第 " + nf(speedLevel, 2) + " 級", width/2, 180);
  }

  if (adminCursor == 1) {
    fill(cyberCyan);
    text(">> [ 目標黃點數量 (01 - 03) ] :   < 0" + targetCount + " 顆 >", width/2, 245);
  } else {
    fill(110, 125, 140);
    text("   [ 目標黃點數量 (01 - 03) ] :     0" + targetCount + " 顆", width/2, 245);
  }

  String soundLabel = soundEnabled ? "開啟 (ON)" : "靜音 (OFF)";
  if (adminCursor == 2) {
    fill(cyberCyan);
    text(">> [ 緊張背景音樂與音效開關 ] :   < " + soundLabel + " >", width/2, 310);
  } else {
    fill(110, 125, 140);
    text("   [ 緊張背景音樂與音效開關 ] :     " + soundLabel, width/2, 310);
  }

  fill(190);
  textSize(17);
  text("搖桿【上 / 下】：切換調整項目   |   搖桿【左 / 右】：增減數值 / 切換開關", width/2, 395);
  
  fill(cyberYellow);
  textSize(21);
  text("[ 按下搖桿中央按鈕，立即套用設定並啟動模擬！ ]", width/2, 445);

  drawScanlines();
}

void serialEvent(Serial myPort) {
  String inString = myPort.readStringUntil('\n');
  if (inString != null) {
    inString = trim(inString);
    int[] data = int(split(inString, ','));
    if (data.length == 10) {
      currentPos = data[0];
      score = data[1];
      gameState = data[2];
      targetPos1 = data[3];
      targetPos2 = data[4];
      targetPos3 = data[5];
      speedLevel = data[6];
      adminCursor = data[7];
      targetCount = data[8];
      soundEnabled = (data[9] == 1);
      
      if (score > highScore && gameState != 3) {
        highScore = score;
      }
    }
  }
}
