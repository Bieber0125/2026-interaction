//week03-5 processing NS SHAFT 02 floor
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
    rect(floorX[i], 75+i*75, 140, 25);
  }
}
 
