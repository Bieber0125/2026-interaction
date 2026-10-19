//week07-1
import processing.sound.*;
SoundFile sound;
void setup(){
  size(300, 300);
  sound = new SoundFile(this, "music.mp3");
  sound.play();
}
void draw(){
  
}
