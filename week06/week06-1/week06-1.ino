//week06_1_
void setup(){
  pinMode(2, INPUT_PULLUP);
  pinMode(8, OUTPUT);
  tone(8, 523, 100);
}

void loop(){
  if(digitalRead(2) == LOW ){ 
    tone(8, 523, 100);
    delay(100);
    }
    
}
