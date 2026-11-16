//week11-11
void setup() {
  // put your setup code here, to run once:

}

void loop() {
  // put your main code here, to run repeatedly:
  int x = analogRead(A0);
  int y = analogRead(A1);
  tone(8, x);
}
