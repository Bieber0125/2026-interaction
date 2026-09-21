//week03-3 arduino flow LED
//LED 流動的感覺
void setup() {
  for(int i=2; i<=13; i++)pinMode(i, OUTPUT);
}//

void loop() {
  for(int i=2; i<=13; i++){
    for(int k=2; k<=13; k++) digitalWrite(k, LOW);
    digitalWrite(i, HIGH);
    delay(100);
  }
}
