//week03-6 processing NS SHAFT 03 spike
//小朋友下樓梯
void setup(){
  size(600, 600);
  for(int i=0; i<20; i++)floorX[i] = int(random(600-140));
}
int []floorX = new int[20];
void draw(){
 background(0, 5, 95);
 fill(47, 105, 190);
 for(int i =0; i<10; i++){
   rect(0, i*60, 25, 60);
   rect(600-25, i*60, 25, 60);
  }
  fill(208, 216, 189);
  //rect(200, 200, 140, 25);
  for(int i=0; i<20; i++){
    //rect(floorX[i], 75+i*75, 140, 25);
    //rect(floorX[i], 75+i*75 - frameCount%1500, 140, 25);
    float y = 75 + i *75 - frameCount%1500;
    if(y < -25) y += 1500;
    rect(floorX[i], y, 140, 25);
  }
  fill(255);
  for(int i=0; i<24; i++){
    float x = i * 23 + 27; 
    triangle(x, 0, x+9, 30, x+18, 0);
  }
}
