#include <WiFi.h>

void setup() {
  // 告诉板子，我们要用 115200 的速度通过 USB 管道给电脑打印文字
  Serial.begin(115200);
  delay(2000); // 稍微等 2 秒钟，让电脑反应一下
  
  WiFi.mode(WIFI_STA); // 必须开启无线硬件，才能读取到 MAC
  
  Serial.println("");
  Serial.println("=========================================");
  Serial.print("💡 这块 ESP32-C3 的 MAC 地址为: ");
  Serial.println(WiFi.macAddress()); // 这一行会打印出硬件唯一的身份证
  Serial.println("=========================================");
}

void loop() {
  // 板载小灯（GPIO8）规律闪烁，代表运行成功
  pinMode(8, OUTPUT);
  digitalWrite(8, LOW); // 低电平点亮 SuperMini 的灯
  delay(500);
  digitalWrite(8, HIGH); // 高电平熄灭
  delay(500);
}
