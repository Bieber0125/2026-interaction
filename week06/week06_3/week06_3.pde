//week06-3
void setup(){
  size(500, 500);
}
void draw(){
  background(0);
  translate(250, 250);
  //translate(mouseX, mouseY);
  //println(mouseX, mouseY);
  rotate( radians(frameCount));
  rect(-200, -200, 400, 400);
}
