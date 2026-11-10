/**
 * =============================================================================
 * KINETIX — Firmware da caixa inteligente (ESP32 · simulação Wokwi)
 * =============================================================================
 *
 * Sensores:
 *   MPU6050  (I2C 0x69) → orientação (roll/pitch/yaw) e impactos (G)
 *   DHT22    (pino 15)  → temperatura e umidade
 *   LDR      (pino 34)  → luz dentro da caixa (abertura / lacre)
 *   DS1307   (I2C 0x68) → relógio (RTC), sincronizado por NTP quando há Wi-Fi
 *   SSD1306  (I2C 0x3C) → display local com o status ("OK" / "ALERTA")
 *   LEDs     (26 verde, 27 vermelho) → sinalização rápida para o entregador
 *   Botão    (pino 4)   → simula perda de sinal (demonstra o buffer offline)
 *
 * O Wokwi não tem módulo GPS: a posição é simulada ao longo da Via Dutra
 * (São José dos Campos → Taubaté), igual ao simulador do app.
 *
 * Contrato MQTT v1 (ver packages/kinetix_core/lib/src/telemetry.dart):
 *   publica  kinetix/v1/<DEVICE_ID>/telemetry   JSON a cada 1 s
 *   publica  kinetix/v1/<DEVICE_ID>/status      "online"/"offline" (retido + LWT)
 *   assina   kinetix/v1/<DEVICE_ID>/score       score oficial vindo do serviço ponte
 */

#include <WiFi.h>
#include <PubSubClient.h>
#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <DHT.h>
#include <RTClib.h>
#include <time.h>
#include <math.h>

// -----------------------------------------------------------------------------
// 1. CONFIGURAÇÃO
// -----------------------------------------------------------------------------
#define DEVICE_ID        "kx-01"
#define FIRMWARE_VERSION "esp32-wokwi 2.0"

// No Wokwi a rede é sempre "Wokwi-GUEST", sem senha.
#define WIFI_SSID        "Wokwi-GUEST"
#define WIFI_PASSWORD    ""

// Broker MQTT público (troque por um HiveMQ Cloud privado se quiser).
#define MQTT_BROKER      "broker.hivemq.com"
#define MQTT_PORT        1883

#define TOPIC_PREFIX     "kinetix/v1/" DEVICE_ID
#define TOPIC_TELEMETRY  TOPIC_PREFIX "/telemetry"
#define TOPIC_STATUS     TOPIC_PREFIX "/status"
#define TOPIC_SCORE      TOPIC_PREFIX "/score"

// Limites locais (só para LEDs/display; o score oficial vem do servidor)
#define LIMIT_IMPACT_G   2.0f
#define LIMIT_TILT_DEG   30.0f
#define LIMIT_LIGHT_PCT  20.0f
#define LIMIT_TEMP_MIN   15.0f
#define LIMIT_TEMP_MAX   30.0f

// Pinos
#define PIN_DHT          15
#define PIN_LDR          34
#define PIN_LED_OK       26
#define PIN_LED_ALERT    27
#define PIN_BTN_SIGNAL   4

#define MPU_ADDR         0x69   // AD0 ligado no 3V3 (o DS1307 usa 0x68)
#define OLED_ADDR        0x3C

// Tempos
#define SAMPLE_MS        20     // leitura do MPU6050 (50 Hz)
#define PUBLISH_MS       1000   // envio da telemetria
#define DHT_MS           2000
#define BUFFER_SIZE      180    // leituras guardadas sem sinal (3 min)

// -----------------------------------------------------------------------------
// 2. OBJETOS
// -----------------------------------------------------------------------------
WiFiClient wifiClient;
PubSubClient mqtt(wifiClient);
Adafruit_MPU6050 mpu;
Adafruit_SSD1306 oled(128, 64, &Wire, -1);
DHT dht(PIN_DHT, DHT22);
RTC_DS1307 rtc;

bool hasMpu = false, hasRtc = false, hasOled = false;

// -----------------------------------------------------------------------------
// 3. ESTADO
// -----------------------------------------------------------------------------
float roll = 0, pitch = 0, yaw = 0;
float accelG = 1, peakG = 1;
float temperature = NAN, humidity = NAN, lightPct = 0;
float lat = -23.1896, lng = -45.8841;
uint32_t seq = 0;
float officialScore = 100;
char officialStatus[16] = "Carga OK";
bool simulatedSignalLoss = false;
bool ntpSynced = false;

unsigned long lastSample = 0, lastPublish = 0, lastDht = 0, lastMqttTry = 0, lastBtn = 0, bootMs = 0;

// Buffer offline (fila circular de JSONs prontos)
String offlineBuffer[BUFFER_SIZE];
int bufHead = 0, bufCount = 0;

// Rota simulada (Wokwi não tem GPS)
const float ROUTE[][2] = {
  {-23.1896, -45.8841}, {-23.1712, -45.8392}, {-23.1418, -45.7896}, {-23.1004, -45.7072},
  {-23.0689, -45.6425}, {-23.0461, -45.5921}, {-23.0264, -45.5553}};
const int ROUTE_LEN = sizeof(ROUTE) / sizeof(ROUTE[0]);
const float TRIP_SECONDS = 900;

// -----------------------------------------------------------------------------
// 4. SENSORES
// -----------------------------------------------------------------------------
void readMotion(float dt) {
  if (!hasMpu) return;
  sensors_event_t a, g, t;
  mpu.getEvent(&a, &g, &t);
  const float ax = a.acceleration.x / 9.80665f, ay = a.acceleration.y / 9.80665f, az = a.acceleration.z / 9.80665f;

  accelG = sqrtf(ax * ax + ay * ay + az * az);
  if (accelG > peakG) peakG = accelG;

  // Orientação pela gravidade + giroscópio (filtro complementar)
  const float accRoll = atan2f(ay, az) * 180.0f / PI;
  const float accPitch = atan2f(-ax, sqrtf(ay * ay + az * az)) * 180.0f / PI;
  const float gx = g.gyro.x * 180.0f / PI, gy = g.gyro.y * 180.0f / PI, gz = g.gyro.z * 180.0f / PI;
  const float k = 0.96f;
  // durante um solavanco a gravidade "some" na leitura: confia só no giroscópio
  const bool steady = fabsf(accelG - 1.0f) < 0.35f;
  roll = steady ? k * (roll + gx * dt) + (1 - k) * accRoll : roll + gx * dt;
  pitch = steady ? k * (pitch + gy * dt) + (1 - k) * accPitch : pitch + gy * dt;
  yaw += gz * dt;
  if (yaw > 180) yaw -= 360;
  if (yaw < -180) yaw += 360;
}

void readClimate() {
  const float t = dht.readTemperature(), h = dht.readHumidity();
  if (!isnan(t)) temperature = t;
  if (!isnan(h)) humidity = h;
}

// Converte a leitura do LDR em "quanto de luz" de 0 a 100 (escala logarítmica).
// Caixa fechada ≈ 0–10. Luz ambiente (500 lux) ≈ 67.
void readLight() {
  const int raw = analogRead(PIN_LDR);
  const float v = max(0.01f, raw / 4095.0f * 3.3f);
  const float resistance = 2000.0f * v / max(0.01f, 1.0f - v / 3.3f);
  const float GAMMA = 0.7f, RL10 = 50.0f;
  const float lux = powf(RL10 * 1e3f * powf(10, GAMMA) / resistance, 1.0f / GAMMA);
  lightPct = constrain(log10f(max(1.0f, lux)) / 4.0f * 100.0f, 0.0f, 100.0f);
}

void updateGps() {
  const float elapsed = (millis() - bootMs) / 1000.0f;
  const float lap = fmodf(elapsed, TRIP_SECONDS * 2) / TRIP_SECONDS;
  const float f = lap <= 1 ? lap : 2 - lap;
  const float seg = f * (ROUTE_LEN - 1);
  const int i = min((int)seg, ROUTE_LEN - 2);
  const float u = seg - i;
  lat = ROUTE[i][0] + (ROUTE[i + 1][0] - ROUTE[i][0]) * u;
  lng = ROUTE[i][1] + (ROUTE[i + 1][1] - ROUTE[i][1]) * u;
}

float tiltDeg() {
  const float c = cosf(roll * PI / 180) * cosf(pitch * PI / 180);
  return acosf(constrain(c, -1.0f, 1.0f)) * 180.0f / PI;
}

// -----------------------------------------------------------------------------
// 5. RELÓGIO (RTC + NTP)
// -----------------------------------------------------------------------------
void syncClock() {
  if (ntpSynced || WiFi.status() != WL_CONNECTED) return;
  configTime(0, 0, "pool.ntp.org", "time.google.com");
  struct tm tmNow;
  if (getLocalTime(&tmNow, 3000)) {
    ntpSynced = true;
    if (hasRtc) rtc.adjust(DateTime(tmNow.tm_year + 1900, tmNow.tm_mon + 1, tmNow.tm_mday, tmNow.tm_hour, tmNow.tm_min, tmNow.tm_sec));
    Serial.println(F("[RTC] Relogio sincronizado por NTP (UTC)"));
  }
}

void isoNow(char* out, size_t len) {
  if (hasRtc) {
    const DateTime n = rtc.now();
    snprintf(out, len, "%04d-%02d-%02dT%02d:%02d:%02dZ", n.year(), n.month(), n.day(), n.hour(), n.minute(), n.second());
    return;
  }
  const time_t now = time(nullptr);
  struct tm tmNow;
  gmtime_r(&now, &tmNow);
  strftime(out, len, "%Y-%m-%dT%H:%M:%SZ", &tmNow);
}

// -----------------------------------------------------------------------------
// 6. REDE E MQTT
// -----------------------------------------------------------------------------
void onMqttMessage(char* topic, byte* payload, unsigned int length) {
  // {"score": 87.0, "status": "Atenção"}  — leitura simples sem biblioteca JSON
  String msg;
  for (unsigned int i = 0; i < length; i++) msg += (char)payload[i];
  const int s = msg.indexOf("\"score\":");
  if (s >= 0) officialScore = msg.substring(s + 8).toFloat();
  const int st = msg.indexOf("\"status\":\"");
  if (st >= 0) {
    const int end = msg.indexOf('"', st + 10);
    msg.substring(st + 10, end).toCharArray(officialStatus, sizeof(officialStatus));
  }
}

bool online() { return !simulatedSignalLoss && WiFi.status() == WL_CONNECTED && mqtt.connected(); }

void networkLoop() {
  if (WiFi.status() != WL_CONNECTED) return;
  syncClock();
  if (simulatedSignalLoss) {
    if (mqtt.connected()) mqtt.disconnect();
    return;
  }
  if (!mqtt.connected() && millis() - lastMqttTry > 3000) {
    lastMqttTry = millis();
    const String clientId = String("kinetix-") + DEVICE_ID + "-" + String((uint32_t)esp_random(), HEX);
    Serial.print(F("[MQTT] Conectando... "));
    if (mqtt.connect(clientId.c_str(), nullptr, nullptr, TOPIC_STATUS, 1, true, "offline")) {
      Serial.println(F("ok"));
      mqtt.publish(TOPIC_STATUS, "online", true);
      mqtt.subscribe(TOPIC_SCORE);
    } else {
      Serial.printf("falhou (%d)\n", mqtt.state());
    }
  }
  mqtt.loop();
}

String buildTelemetry(bool buffered) {
  char ts[24];
  isoNow(ts, sizeof(ts));
  char tempStr[12], humStr[12];
  if (isnan(temperature)) strcpy(tempStr, "null"); else snprintf(tempStr, sizeof(tempStr), "%.1f", temperature);
  if (isnan(humidity)) strcpy(humStr, "null"); else snprintf(humStr, sizeof(humStr), "%.1f", humidity);
  char json[420];
  snprintf(json, sizeof(json),
           "{\"v\":1,\"device_id\":\"%s\",\"seq\":%lu,\"ts\":\"%s\","
           "\"roll\":%.1f,\"pitch\":%.1f,\"yaw\":%.1f,\"accel_g\":%.2f,\"peak_g\":%.2f,"
           "\"temp\":%s,\"hum\":%s,\"light\":%.0f,\"lat\":%.5f,\"lng\":%.5f,"
           "\"battery\":%d,\"rssi\":%d,\"buffered\":%s}",
           DEVICE_ID, (unsigned long)seq, ts, roll, pitch, yaw, accelG, peakG, tempStr, humStr, lightPct, lat, lng,
           100, (int)WiFi.RSSI(), buffered ? "true" : "false");
  return String(json);
}

void bufferPush(const String& json) {
  const int idx = (bufHead + bufCount) % BUFFER_SIZE;
  offlineBuffer[idx] = json;
  if (bufCount < BUFFER_SIZE) bufCount++;
  else bufHead = (bufHead + 1) % BUFFER_SIZE;  // cheio: descarta a mais antiga
}

void flushBuffer() {
  // envia até 10 leituras guardadas por volta do loop, sem travar a placa
  for (int i = 0; i < 10 && bufCount > 0 && online(); i++) {
    if (!mqtt.publish(TOPIC_TELEMETRY, offlineBuffer[bufHead].c_str())) break;
    offlineBuffer[bufHead] = String();
    bufHead = (bufHead + 1) % BUFFER_SIZE;
    bufCount--;
  }
}

void publishTelemetry() {
  seq++;
  if (online()) {
    const String json = buildTelemetry(false);
    mqtt.publish(TOPIC_TELEMETRY, json.c_str());
    Serial.println(json);
  } else {
    bufferPush(buildTelemetry(true));
    Serial.printf("[BUFFER] Sem sinal: %d leituras guardadas\n", bufCount);
  }
  peakG = accelG;  // começa a medir o próximo pico
}

// -----------------------------------------------------------------------------
// 7. SINALIZAÇÃO LOCAL (LEDs + DISPLAY)
// -----------------------------------------------------------------------------
bool localAlert() {
  return peakG >= LIMIT_IMPACT_G || tiltDeg() >= LIMIT_TILT_DEG || lightPct >= LIMIT_LIGHT_PCT ||
         (!isnan(temperature) && (temperature < LIMIT_TEMP_MIN || temperature > LIMIT_TEMP_MAX));
}

void updateIndicators() {
  const bool alert = localAlert() || officialScore < 70;
  digitalWrite(PIN_LED_OK, alert ? LOW : HIGH);
  digitalWrite(PIN_LED_ALERT, alert ? HIGH : LOW);
  if (!hasOled) return;

  oled.clearDisplay();
  oled.setTextColor(SSD1306_WHITE);
  oled.setTextSize(1);
  oled.setCursor(0, 0);
  oled.print(F("KINETIX "));
  oled.print(DEVICE_ID);
  oled.setCursor(92, 0);
  oled.print(online() ? F("ON") : (bufCount ? F("BUF") : F("OFF")));

  oled.setTextSize(2);
  oled.setCursor(0, 14);
  oled.print(alert ? F("ALERTA") : F("OK"));
  oled.setCursor(84, 14);
  oled.print((int)officialScore);

  oled.setTextSize(1);
  oled.setCursor(0, 36);
  oled.printf("T:%.1fC  U:%.0f%%", isnan(temperature) ? 0.0f : temperature, isnan(humidity) ? 0.0f : humidity);
  oled.setCursor(0, 46);
  oled.printf("G:%.1f  Inc:%.0f", peakG, tiltDeg());
  oled.setCursor(0, 56);
  oled.printf("Luz:%.0f  Buf:%d", lightPct, bufCount);
  oled.display();
}

// -----------------------------------------------------------------------------
// 8. SETUP / LOOP
// -----------------------------------------------------------------------------
void setup() {
  Serial.begin(115200);
  bootMs = millis();
  Serial.println(F("\n=== KINETIX ESP32 ==="));

  pinMode(PIN_LED_OK, OUTPUT);
  pinMode(PIN_LED_ALERT, OUTPUT);
  pinMode(PIN_BTN_SIGNAL, INPUT_PULLUP);
  analogReadResolution(12);

  Wire.begin(21, 22);
  hasOled = oled.begin(SSD1306_SWITCHCAPVCC, OLED_ADDR);
  if (hasOled) {
    oled.clearDisplay();
    oled.setTextColor(SSD1306_WHITE);
    oled.setTextSize(2);
    oled.setCursor(10, 20);
    oled.print(F("KINETIX"));
    oled.display();
  }
  hasMpu = mpu.begin(MPU_ADDR);
  if (hasMpu) {
    mpu.setAccelerometerRange(MPU6050_RANGE_16_G);
    mpu.setGyroRange(MPU6050_RANGE_500_DEG);
    mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
  }
  hasRtc = rtc.begin();
  if (hasRtc && !rtc.isrunning()) rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
  dht.begin();
  Serial.printf("[INIT] MPU6050:%s RTC:%s OLED:%s\n", hasMpu ? "ok" : "falhou", hasRtc ? "ok" : "falhou", hasOled ? "ok" : "falhou");

  mqtt.setServer(MQTT_BROKER, MQTT_PORT);
  mqtt.setBufferSize(1024);
  mqtt.setCallback(onMqttMessage);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD, 6);
}

void loop() {
  const unsigned long now = millis();

  if (now - lastSample >= SAMPLE_MS) {
    const float dt = (now - lastSample) / 1000.0f;
    lastSample = now;
    readMotion(dt);
    readLight();
  }
  if (now - lastDht >= DHT_MS) {
    lastDht = now;
    readClimate();
  }

  // botão: liga/desliga a simulação de "sem sinal"
  if (digitalRead(PIN_BTN_SIGNAL) == LOW && now - lastBtn > 400) {
    lastBtn = now;
    simulatedSignalLoss = !simulatedSignalLoss;
    Serial.println(simulatedSignalLoss ? F("[REDE] Simulando perda de sinal") : F("[REDE] Sinal restabelecido"));
  }

  networkLoop();
  flushBuffer();

  if (now - lastPublish >= PUBLISH_MS) {
    lastPublish = now;
    updateGps();
    publishTelemetry();
    updateIndicators();
  }
}
