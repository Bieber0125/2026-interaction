//week01_5_google_gemini_mouse_wheel_void_mosueWheel_MouseEvent_getCount
// google gemini: Pricessing 怎麼用到 mouse wheel
// 把AI摘要的程式碼copy過來用
float circleSize = 50; // 初始圓形大小

void setup() {
  size(400, 400);
}

void draw() {
  background(220);
  fill(100, 150, 250);
  ellipse(width/2, height/2, circleSize, circleSize);
}

// 當滑鼠滾輪轉動時自動執行
void mouseWheel(MouseEvent event) {
  float e = event.getCount(); // 取得滾輪數值 (向上為負，向下為正)
  
  // 根據滾動方向調整大小
  circleSize += e * 5; 
  
  // 限制大小範圍，避免變負數或過大
  circleSize = constrain(circleSize, 10, 300);
}
