#include <esp_now.h>
#include <WiFi.h>

// 🔒 核心绑定：在此处填入你的【接收端 B】的 6 位物理 MAC 地址
uint8_t broadcastAddress[] = {0xF0, 0x08, 0xD1, 0x2E, 0x7A, 0xEC};

uint8_t serialRxBuf[32];
int rxCount = 0;
int expectedLen = 14;

void setup() {
  Serial.begin(115200);
  WiFi.mode(WIFI_STA);
  WiFi.disconnect();

  if (esp_now_init() != ESP_OK) return;

  esp_now_peer_info_t peerInfo;
  memcpy(peerInfo.peer_addr, broadcastAddress, 6);
  peerInfo.channel = 0;
  peerInfo.encrypt = false;

  if (esp_now_add_peer(&peerInfo) != ESP_OK) return;
}

void loop() {
  while (Serial.available() > 0) {
    uint8_t c = Serial.read();

    // 严格对齐 CH9329 协议帧头 0x57 0xAB
    if (rxCount == 0 && c != 0x57) continue;
    if (rxCount == 1 && c != 0xAB) { rxCount = 0; continue; }

    // 动态变长分帧：第四字节（CMD）判定包边界
    if (rxCount == 3) {
      if (c == 0x05)      expectedLen = 11;  // 相对鼠标包
      else if (c == 0x04) expectedLen = 13;  // 绝对鼠标包
      else                expectedLen = 14;  // 键盘包
    }

    serialRxBuf[rxCount++] = c;

    if (rxCount == expectedLen) {
      esp_now_send(broadcastAddress, serialRxBuf, expectedLen);
      rxCount = 0;
    }
  }

  if (rxCount >= 32) rxCount = 0; // 异常溢出防护
}