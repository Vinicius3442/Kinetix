# Firmware Kinetix — ESP32 no Wokwi

É o mesmo circuito do ERS (ESP32 + MPU6050 + DHT22 + LDR + RTC + display), agora enviando para o contrato MQTT do Kinetix em vez da Wegnology.

| Peça | Pino | Para que serve |
|---|---|---|
| MPU6050 (I2C **0x69**, AD0 no 3V3) | SDA 21 · SCL 22 | Giro da caixa (roll/pitch/yaw) e impactos |
| DS1307 RTC (I2C 0x68) | SDA 21 · SCL 22 | Hora exata de cada leitura (acertada por NTP quando há Wi-Fi) |
| SSD1306 OLED (I2C 0x3C) | SDA 21 · SCL 22 | Status local: OK/ALERTA, nota e sensores |
| DHT22 | 15 | Temperatura e umidade |
| LDR (módulo) | 34 (AO) | Luz dentro da caixa → abertura |
| LED verde / vermelho | 26 / 27 | "OK" ou "Violado" para o entregador |
| Botão amarelo | 4 | Liga/desliga a simulação de **sem sinal** (testa o buffer offline) |

## Como rodar no Wokwi

1. Em [wokwi.com](https://wokwi.com), crie um projeto **ESP32** novo.
2. Substitua o `sketch.ino` pelo [`sketch.ino`](sketch.ino) daqui.
3. Abra a aba `diagram.json` e cole o [`diagram.json`](diagram.json).
4. Em **Library Manager**, adicione as bibliotecas de [`libraries.txt`](libraries.txt) (ou crie um arquivo `libraries.txt` com o mesmo conteúdo).
5. Clique em ▶. O Serial Monitor mostra o JSON enviado a cada segundo.

O MPU6050 é endereçado em **0x69** porque o RTC usa 0x68. Por isso o pino AD0 do MPU vai no 3V3.

## Como provocar cada ocorrência

Clique no sensor durante a simulação para abrir os controles:

| No Wokwi | O que o app mostra |
|---|---|
| **MPU6050** → acelerômetro acima de 2 g por um instante | Impacto (a caixa 3D treme) |
| **MPU6050** → mudar a direção da gravidade (ex.: x = 0,7 g, z = 0,7 g) | Caixa inclinada ou tombada |
| **MPU6050** → giroscópio no eixo Z | A caixa gira (yaw) |
| **LDR** → lux acima de ~10 | Caixa aberta (luz dentro) |
| **DHT22** → temperatura fora de 15–30 °C | Temperatura fora da faixa |
| **Botão SEM SINAL** | A caixa guarda as leituras e envia quando você apertar de novo |

Comece com o LDR em **1 lux** (caixa fechada). O `diagram.json` já vem assim.

## Configuração

No topo do `sketch.ino`:

- `DEVICE_ID`: precisa ser igual ao código da caixa no app (padrão `kx-01`).
- `MQTT_BROKER` / `MQTT_PORT`: broker público `broker.hivemq.com:1883`. Para um broker privado, troque aqui, no `bridge/.env` e no `MQTT_WS_URL` do app.
- `LIMIT_*`: limites usados **só** pelos LEDs e pelo display. A nota oficial é calculada pelo serviço ponte e volta para a caixa pelo tópico `.../score`.

## Diferenças para o firmware do Arduino R4

O repositório `kinetix-arduino` (UNO R4 + sensores liga/desliga) continua válido para o hardware físico. Este firmware usa sensores que dão números (ângulo em graus, impacto em G, luz em %), o que permite o **giro livre do gêmeo digital**, além de RTC, buffer offline e o contrato MQTT novo.
