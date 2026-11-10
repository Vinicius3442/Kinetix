# Kinetix — A inteligência que enxerga no escuro da carga

**Talpa Systems** · Projeto semestral SENAI · Luiz Felipe, Vinícius Montuani, Pietro Rennó e Samuel Mioni

O Kinetix é uma "caixa-preta" para cargas. Sensores dentro da caixa percebem impactos, inclinação, abertura e temperatura. O app mostra tudo ao vivo num **gêmeo digital 3D**, dá uma **nota de integridade (0 a 100)** e, na entrega, o destinatário lê o **QR Code** da etiqueta, confere a viagem e assina no celular.

```
 Caixa (ESP32 no Wokwi)  ──MQTT──►  Broker (HiveMQ)  ──►  Serviço ponte (Dart)  ──►  Supabase (Postgres)
   MPU6050 · DHT22 · LDR                 │                 calcula o score              login · tempo real
   RTC DS1307 · OLED · LEDs              │                                                     │
                                         └────────── MQTT ao vivo (WebSocket) ──►  App Flutter (web + Android)
```

> A Wegnology saiu do projeto: o **serviço ponte** faz o papel dela (recebe o MQTT, calcula o score e grava no banco).

---

## Começar em 1 minuto: modo demonstração

Sem banco, sem placa e sem internet. As caixas são simuladas dentro do app, com o mesmo motor de score do sistema real.

```bash
flutter pub get
```

```bash
flutter run -d chrome
```

Na tela de login, toque em **Gestor logístico**, **Administrador** ou **Motorista**. Abra uma carga e use **Simular ocorrência** (impacto, inclinar, abrir caixa, esquentar, perder sinal) para ver o gêmeo 3D, os alertas e a nota reagirem.

---

## Montar o sistema real (Wokwi + Supabase)

### 1. Banco de dados (Supabase)

1. Crie um projeto grátis em [supabase.com](https://supabase.com).
2. Vá em **SQL Editor**, cole todo o arquivo [`supabase/migrations/20261110000000_kinetix_schema.sql`](supabase/migrations/20261110000000_kinetix_schema.sql) e clique em **Run**.
3. Faça o mesmo com [`supabase/seed.sql`](supabase/seed.sql). Ele cria as caixas `kx-01`, `kx-02` e `kx-03` e cargas de exemplo.
4. Para testar sem confirmar e-mail: **Authentication → Sign In / Providers → Email**, desligue **Confirm email**.
5. Em **Project Settings → API**, copie:
   - **Project URL** e **anon/publishable key**, que vão para o app;
   - **service_role key**, que vai para o serviço ponte. Ela é **secreta**: nunca coloque no app nem no Git.

> **O primeiro usuário que se cadastrar vira Administrador.** Os próximos entram como Motorista e o admin muda o perfil deles em **Gestão → Usuários**.

### 2. A caixa (firmware no Wokwi)

Siga o guia [`firmware/kinetix-esp32/README.md`](firmware/kinetix-esp32/README.md). Em resumo: crie um projeto ESP32 no [wokwi.com](https://wokwi.com) e cole `sketch.ino`, `diagram.json` e `libraries.txt`.

### 3. Serviço ponte (MQTT → score → banco)

```bash
cd bridge && cp .env.example .env
```

Na primeira vez, baixe as dependências da ponte. Sem isso, o Dart usa as do app Flutter da pasta de cima e dá o erro `Couldn't resolve the package 'kinetix_bridge'`:

```bash
dart pub get
```

Preencha o `.env` com `SUPABASE_URL` e `SUPABASE_SERVICE_KEY` e rode:

```bash
dart run bin/bridge.dart
```

Deixe esse terminal aberto durante a apresentação. Sem a placa, dá para usar o simulador, que publica no MQTT como se fosse a caixa:

```bash
dart run bin/simulate.dart kx-01 kx-02
```

Com o simulador rodando, as teclas `i`, `t`, `a`, `c` e `s` provocam impacto, inclinação, abertura, calor e perda de sinal.

### 4. O app

```bash
cp config.example.json config.json
```

Preencha `SUPABASE_URL` e `SUPABASE_ANON_KEY` e rode:

```bash
flutter run -d chrome --dart-define-from-file=config.json
```

Depois: cadastre-se (o primeiro vira admin) → **Gestão → Nova carga** → escolha a caixa `kx-01` → abra a carga → **Iniciar viagem**. Mexa nos sensores do Wokwi e veja o gêmeo e os alertas reagirem.

### 5. Publicar a versão web

```bash
flutter build web --release --no-web-resources-cdn --dart-define-from-file=config.json
```

A pasta `build/web` pode ir para Netlify, Vercel, Firebase Hosting ou GitHub Pages. O `--no-web-resources-cdn` embute o motor gráfico, então o app abre mesmo em redes que bloqueiam CDNs. Coloque o endereço publicado em `APP_URL` para que o QR Code aponte para ele.

Para Android: `flutter build apk --release --dart-define-from-file=config.json`.

---

## Roteiro sugerido para a apresentação

1. **Login** como gestor → lista de cargas com nota e status ao vivo.
2. Abrir a carga ligada ao Wokwi → **gêmeo 3D** girando com o MPU6050 (arraste para girar a câmera).
3. No Wokwi: aumentar a aceleração (impacto), girar o MPU (inclinação), aumentar a luz do LDR (abertura) e esquentar o DHT22. Mostrar o **alerta na hora**, a nota caindo e as setas "este lado para cima".
4. Apertar o botão **SEM SINAL** do Wokwi por alguns segundos e soltar: o histórico mostra *"Sinal restabelecido — N leituras enviadas da memória"* (buffer offline).
5. **Histórico**: mapa do trajeto, gráfico de temperatura e "replay" 3D de cada ocorrência.
6. **QR Code** da carga → abrir em outro celular → resumo da viagem → **assinar e aprovar** → comprovante.

---

## Estrutura do repositório

| Pasta | O que tem |
|---|---|
| `lib/` | App Flutter (web + Android) |
| `lib/core/` | Tema (tokens do design system), rotas (GoRouter), componentes, formatação |
| `lib/data/` | Modelos, repositórios (Supabase e demonstração), MQTT ao vivo, providers (Riverpod) |
| `lib/features/` | Telas: login, cargas, detalhe + gêmeo 3D, histórico, alertas, recebimento, perfil, gestão |
| `packages/kinetix_core/` | Núcleo em Dart puro: contrato MQTT, **motor do score**, simulador. Usado pelo app e pela ponte |
| `bridge/` | Serviço ponte MQTT → Supabase e simulador de caixas |
| `firmware/kinetix-esp32/` | Firmware ESP32 + circuito do Wokwi |
| `supabase/` | Schema do banco (tabelas, permissões, funções) e dados de exemplo |
| `docs/telas/` | Telas do protótipo antigo (Figma) para referência |

## Contrato MQTT v1

| Tópico | Quem publica | Conteúdo |
|---|---|---|
| `kinetix/v1/{caixa}/telemetry` | caixa, 1×/s | JSON da leitura (abaixo) |
| `kinetix/v1/{caixa}/status` | caixa (retido + LWT) | `online` / `offline` |
| `kinetix/v1/{caixa}/score` | serviço ponte (retido) | `{"score": 87, "status": "Atenção"}`, que aparece no display da caixa |

```json
{ "v": 1, "device_id": "kx-01", "seq": 42, "ts": "2026-11-10T14:32:05Z",
  "roll": 1.2, "pitch": -0.4, "yaw": 87.0, "accel_g": 1.01, "peak_g": 2.4,
  "temp": 24.6, "hum": 55.0, "light": 3, "lat": -23.1896, "lng": -45.8841,
  "battery": 100, "rssi": -61, "buffered": false }
```

`peak_g` é o maior solavanco desde a leitura anterior, para não perder impactos entre os envios. `buffered: true` marca leituras guardadas sem sinal e enviadas depois.

## Como a nota (Score de Integridade) é calculada

Começa em 100. Cada **ocorrência** tira pontos **uma vez**. Uma caixa aberta por 2 minutos conta como uma ocorrência só, e não como 120 leituras. Isso corrige o protótipo, que zerava a nota.

| Ocorrência | Desconto |
|---|---|
| Impacto leve (≥ 2 G) / forte (≥ 3 G) / severo (≥ 4,5 G) | −5 / −10 / −20 |
| Caixa inclinada (≥ 30°) · tombada (≥ 60°) | −8 · mais −7 |
| Caixa aberta (entrou luz) | −25 |
| Temperatura fora da faixa · crítica (mais de 5 °C fora) | −5 · mais −5 |
| Umidade acima do máximo | −3 |

**90–100** Carga OK · **70–89** Atenção · **abaixo de 70** Problema. Os limites mudam por tipo de carga (ex.: farmacêutico 2–8 °C) e podem ser ajustados no cadastro.

## Testes

```bash
cd packages/kinetix_core && dart test
```

```bash
cd bridge && dart test
```

```bash
flutter test
```

## Limitações conhecidas

- **GPS simulado**: o Wokwi não tem módulo GPS, então a posição percorre a Via Dutra (SJC → Taubaté).
- **Broker público** (`broker.hivemq.com`): qualquer pessoa que souber o tópico pode ler os dados. Para algo privado, crie um cluster grátis no HiveMQ Cloud e ajuste `MQTT_*` no firmware, na ponte e no app.
- **Alertas** aparecem dentro do app (banner e aba Alertas). Notificação push com o app fechado ainda não foi feita.
- O serviço ponte precisa ficar rodando num computador (ou num serviço como Render/Railway) para gravar no banco.
