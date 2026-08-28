/**
 * Kinetix - Digital Twin & IIoT Mobile Application Logic (Talpa Systems)
 * Pure Vanilla JavaScript - Zero External Libraries for Figma Import Compatibility
 */

document.addEventListener('DOMContentLoaded', () => {
  // State Initialization
  const state = {
    score: 100,
    impactG: 0.12,
    lux: 0,
    temp: 22.4,
    humidity: 54,
    roll: 1.2,
    pitch: 0.5,
    yaw: 0.0,
    isLdrViolated: false,
    isImpactAlert: false,
    isTempAlert: false,
    bufferCount: 0,
    sparklineData: [21.8, 22.0, 22.1, 22.4, 22.3, 22.4, 22.5, 22.4],
    timeline: [
      { time: '14:30:12', type: 'INFO', msg: 'Telemetria Inicializada & Sincronizada', location: 'Origem Transportadora', alert: false },
      { time: '14:15:00', type: 'GPS', msg: 'Posicionamento GPS Atualizado', location: 'São José dos Campos-SP (-23.1896, -45.8841)', alert: false },
      { time: '13:50:00', type: 'CHECK', msg: 'Lacre Óptico Validado - 0 LUX', location: 'Centro Logístico SJC', alert: false }
    ]
  };

  // DOM Elements
  const statusClock = document.getElementById('statusClock');
  const twinCanvas = document.getElementById('twinCanvas');
  const orientCoords = document.getElementById('orientCoords');
  const twinStatusBadge = document.getElementById('twinStatusBadge');
  const scorePath = document.getElementById('scorePath');
  const scoreText = document.getElementById('scoreText');
  const scoreStatusTitle = document.getElementById('scoreStatusTitle');
  const scoreStatusDesc = document.getElementById('scoreStatusDesc');
  
  const valImpact = document.getElementById('valImpact');
  const mpuBadge = document.getElementById('mpuBadge');
  const cardMPU = document.getElementById('cardMPU');

  const valLux = document.getElementById('valLux');
  const ldrBadge = document.getElementById('ldrBadge');
  const cardLDR = document.getElementById('cardLDR');

  const valTemp = document.getElementById('valTemp');
  const valHum = document.getElementById('valHum');
  const dhtBadge = document.getElementById('dhtBadge');
  const cardDHT = document.getElementById('cardDHT');

  const timelineList = document.getElementById('timelineList');
  const bufferCountEl = document.getElementById('bufferCount');
  
  // Navigation Tabs (GoRouter simulation)
  const navItems = document.querySelectorAll('.nav-item');
  const tabContents = document.querySelectorAll('.tab-content');

  navItems.forEach(item => {
    item.addEventListener('click', () => {
      const targetTab = item.getAttribute('data-tab');
      navItems.forEach(n => n.classList.remove('active'));
      tabContents.forEach(t => t.classList.remove('active'));
      
      item.classList.add('active');
      document.getElementById(targetTab).classList.add('active');
    });
  });

  // Clock Update
  function updateClock() {
    const now = new Date();
    const hrs = String(now.getHours()).padStart(2, '0');
    const mins = String(now.getMinutes()).padStart(2, '0');
    if (statusClock) statusClock.textContent = `${hrs}:${mins}`;
  }
  setInterval(updateClock, 1000);
  updateClock();

  // ----------------------------------------------------
  // GÊMEO DIGITAL 3D ENGINE (Canvas 2D Native Projection)
  // ----------------------------------------------------
  const ctx = twinCanvas.getContext('2d');
  let animationFrameId;

  function resizeCanvas() {
    if (!twinCanvas) return;
    twinCanvas.width = twinCanvas.parentElement.clientWidth;
    twinCanvas.height = twinCanvas.parentElement.clientHeight;
  }
  window.addEventListener('resize', resizeCanvas);
  resizeCanvas();

  // 3D Cube Vertices
  const cubeVertices = [
    [-1, -1, -1], [1, -1, -1], [1, 1, -1], [-1, 1, -1],
    [-1, -1,  1], [1, -1,  1], [1, 1,  1], [-1, 1,  1]
  ];

  const cubeEdges = [
    [0,1], [1,2], [2,3], [3,0],
    [4,5], [5,6], [6,7], [7,4],
    [0,4], [1,5], [2,6], [3,7]
  ];

  let rotX = 0.3;
  let rotY = 0.5;

  function renderTwin3D() {
    if (!twinCanvas || !ctx) return;
    
    ctx.clearRect(0, 0, twinCanvas.width, twinCanvas.height);

    const width = twinCanvas.width;
    const height = twinCanvas.height;
    const cx = width / 2;
    const cy = height / 2;
    const scale = 55;

    // Apply continuous tilt + simulation roll/pitch
    rotY += 0.008;
    const currentRotX = rotX + (state.pitch * Math.PI / 180);
    const currentRotY = rotY + (state.roll * Math.PI / 180);

    const radX = currentRotX;
    const radY = currentRotY;

    // Projected Points
    const projected = cubeVertices.map(v => {
      // Rotate Y
      let x = v[0] * Math.cos(radY) + v[2] * Math.sin(radY);
      let y = v[1];
      let z = -v[0] * Math.sin(radY) + v[2] * Math.cos(radY);

      // Rotate X
      let y2 = y * Math.cos(radX) - z * Math.sin(radX);
      let z2 = y * Math.sin(radX) + z * Math.cos(radX);

      // Perspective Projection
      const fov = 3.5;
      const distance = 4;
      const pz = 1 / (distance - z2);
      const px = x * pz * scale * fov + cx;
      const py = y2 * pz * scale * fov + cy;

      return [px, py];
    });

    // Wireframe Color based on Alert status
    const isAlert = state.isImpactAlert || state.isLdrViolated;
    const strokeColor = isAlert ? '#FF5500' : '#00E5FF';
    const fillColor = isAlert ? 'rgba(255, 85, 0, 0.12)' : 'rgba(0, 229, 255, 0.08)';

    // Fill Top Face (Talpa Vector Emblem)
    ctx.beginPath();
    ctx.moveTo(projected[0][0], projected[0][1]);
    ctx.lineTo(projected[1][0], projected[1][1]);
    ctx.lineTo(projected[2][0], projected[2][1]);
    ctx.lineTo(projected[3][0], projected[3][1]);
    ctx.closePath();
    ctx.fillStyle = fillColor;
    ctx.fill();

    // Draw Edges
    ctx.strokeStyle = strokeColor;
    ctx.lineWidth = 1.8;
    ctx.lineJoin = 'round';

    cubeEdges.forEach(edge => {
      const p1 = projected[edge[0]];
      const p2 = projected[edge[1]];
      ctx.beginPath();
      ctx.moveTo(p1[0], p1[1]);
      ctx.lineTo(p2[0], p2[1]);
      ctx.stroke();
    });

    // Draw Corner Dots (Sensors Nodes)
    projected.forEach((p, idx) => {
      ctx.beginPath();
      ctx.arc(p[0], p[1], 3, 0, Math.PI * 2);
      ctx.fillStyle = idx % 2 === 0 ? strokeColor : '#00E676';
      ctx.fill();
    });

    // Update orientation text readout
    if (orientCoords) {
      orientCoords.textContent = `R: ${state.roll.toFixed(1)}° | P: ${state.pitch.toFixed(1)}° | Y: ${state.yaw.toFixed(1)}°`;
    }

    animationFrameId = requestAnimationFrame(renderTwin3D);
  }

  renderTwin3D();

  // ----------------------------------------------------
  // SPARKLINE CHART ENGINE (DHT22 Temperature Curve)
  // ----------------------------------------------------
  const sparkCanvas = document.getElementById('tempSparkline');
  const sparkCtx = sparkCanvas ? sparkCanvas.getContext('2d') : null;

  function renderSparkline() {
    if (!sparkCanvas || !sparkCtx) return;
    sparkCanvas.width = sparkCanvas.parentElement.clientWidth - 32;
    sparkCanvas.height = 40;

    const w = sparkCanvas.width;
    const h = sparkCanvas.height;
    const data = state.sparklineData;

    sparkCtx.clearRect(0, 0, w, h);

    const min = Math.min(...data) - 1;
    const max = Math.max(...data) + 1;
    const step = w / (data.length - 1);

    // Line Path
    sparkCtx.beginPath();
    data.forEach((val, i) => {
      const x = i * step;
      const y = h - ((val - min) / (max - min)) * h;
      if (i === 0) sparkCtx.moveTo(x, y);
      else sparkCtx.lineTo(x, y);
    });

    const lineColor = state.isTempAlert ? '#FFB300' : '#00E5FF';
    sparkCtx.strokeStyle = lineColor;
    sparkCtx.lineWidth = 2;
    sparkCtx.stroke();

    // Fill Gradient
    const grad = sparkCtx.createLinearGradient(0, 0, 0, h);
    grad.addColorStop(0, state.isTempAlert ? 'rgba(255, 179, 0, 0.25)' : 'rgba(0, 229, 255, 0.2)');
    grad.addColorStop(1, 'transparent');
    sparkCtx.lineTo(w, h);
    sparkCtx.lineTo(0, h);
    sparkCtx.closePath();
    sparkCtx.fillStyle = grad;
    sparkCtx.fill();
  }

  renderSparkline();

  // ----------------------------------------------------
  // UI & STATE UPDATE FUNCTIONS
  // ----------------------------------------------------
  function updateUI() {
    // Score Updates
    if (scoreText) scoreText.textContent = Math.round(state.score);
    
    // Circular SVG Progress
    if (scorePath) {
      const maxOffset = 220;
      const offset = maxOffset - (state.score / 100) * maxOffset;
      scorePath.style.strokeDashoffset = offset;
      
      if (state.score >= 90) {
        scorePath.style.stroke = 'var(--electric-lime)';
      } else if (state.score >= 70) {
        scorePath.style.stroke = 'var(--telemetry-amber)';
      } else {
        scorePath.style.stroke = 'var(--talpa-lava)';
      }
    }

    if (scoreStatusTitle && scoreStatusDesc) {
      if (state.score === 100) {
        scoreStatusTitle.textContent = 'Carga Intacta';
        scoreStatusTitle.style.color = 'var(--text-display)';
        scoreStatusDesc.textContent = 'Algoritmo Wegnology: Nenhum desvio de aceleração, temperatura ou luz detectado.';
      } else if (state.score >= 70) {
        scoreStatusTitle.textContent = 'Atenção Necessária';
        scoreStatusTitle.style.color = 'var(--telemetry-amber)';
        scoreStatusDesc.textContent = 'Desvios operacionais leves registrados. Monitoramento contínuo mantido.';
      } else {
        scoreStatusTitle.textContent = 'Carga Comprometida';
        scoreStatusTitle.style.color = 'var(--talpa-lava)';
        scoreStatusDesc.textContent = 'AVISO CRÍTICO: Violação de lacre ou impacto forte excedeu os limites de tolerância.';
      }
    }

    // MPU Card
    if (valImpact) valImpact.textContent = `${state.impactG.toFixed(2)} G`;
    if (cardMPU) {
      if (state.isImpactAlert) {
        cardMPU.classList.add('glow-alert');
        mpuBadge.className = 'card-badge badge-lava';
        mpuBadge.textContent = 'ALERTA IMPACTO';
      } else {
        cardMPU.classList.remove('glow-alert');
        mpuBadge.className = 'card-badge badge-cyan';
        mpuBadge.textContent = 'Estável';
      }
    }

    // LDR Card
    if (valLux) valLux.textContent = `${state.lux} LUX`;
    if (cardLDR) {
      if (state.isLdrViolated) {
        cardLDR.classList.add('glow-alert');
        ldrBadge.className = 'card-badge badge-lava';
        ldrBadge.textContent = 'VIOLADO';
      } else {
        cardLDR.classList.remove('glow-alert');
        ldrBadge.className = 'card-badge badge-lime';
        ldrBadge.textContent = 'Selado';
      }
    }

    // DHT Card
    if (valTemp) valTemp.textContent = `${state.temp.toFixed(1)} °C`;
    if (valHum) valHum.textContent = `${state.humidity}% UR`;
    if (cardDHT) {
      if (state.isTempAlert) {
        cardDHT.classList.add('glow-alert');
        dhtBadge.className = 'card-badge badge-amber';
        dhtBadge.textContent = 'Desvio Térmico';
      } else {
        cardDHT.classList.remove('glow-alert');
        dhtBadge.className = 'card-badge badge-cyan';
        dhtBadge.textContent = 'Faixa Normal';
      }
    }

    if (twinStatusBadge) {
      if (state.isImpactAlert || state.isLdrViolated) {
        twinStatusBadge.className = 'card-badge badge-lava';
        twinStatusBadge.textContent = 'Anomalia Detectada';
      } else {
        twinStatusBadge.className = 'card-badge badge-lime';
        twinStatusBadge.textContent = 'Gêmeo Sincronizado';
      }
    }

    // Buffer count
    if (bufferCountEl) {
      bufferCountEl.textContent = `${state.bufferCount} pacotes retidos na memória local \u2022 ${state.bufferCount > 0 ? 'Bufferizando' : 'Sincronizado'}`;
    }

    renderSparkline();
    renderTimeline();
  }

  function renderTimeline() {
    if (!timelineList) return;
    timelineList.innerHTML = '';
    
    state.timeline.forEach(item => {
      const el = document.createElement('div');
      el.className = `timeline-item ${item.alert ? 'alert' : ''}`;
      el.innerHTML = `
        <div class="timeline-header">
          <span class="timeline-time">${item.time}</span>
          <span class="timeline-gps">${item.location}</span>
        </div>
        <div class="timeline-msg">${item.msg}</div>
      `;
      timelineList.appendChild(el);
    });
  }

  function getRTCTime() {
    const d = new Date();
    return d.toTimeString().split(' ')[0];
  }

  // ----------------------------------------------------
  // INTERACTIVE SIMULATION BUTTON HANDLERS
  // ----------------------------------------------------
  document.getElementById('btnSimImpact')?.addEventListener('click', () => {
    state.impactG = 2.45;
    state.roll = 24.5;
    state.pitch = 18.2;
    state.isImpactAlert = true;
    state.score = Math.max(0, state.score - 25);
    state.bufferCount += 1;

    state.timeline.unshift({
      time: getRTCTime(),
      type: 'ALERT',
      msg: 'ALERTA: Impacto Severo Detectado (2.45G) - Sensor MPU6050',
      location: 'Caçapava-SP (-23.1004, -45.7072)',
      alert: true
    });

    updateUI();
  });

  document.getElementById('btnSimLight')?.addEventListener('click', () => {
    state.lux = 485;
    state.isLdrViolated = true;
    state.score = Math.max(0, state.score - 35);
    state.bufferCount += 1;

    state.timeline.unshift({
      time: getRTCTime(),
      type: 'ALERT',
      msg: 'VIOLAÇÃO CRÍTICA: Incidência Repentina de Luz (485 Lux) - LDR',
      location: 'São José dos Campos-SP (-23.1896, -45.8841)',
      alert: true
    });

    updateUI();
  });

  document.getElementById('btnSimTemp')?.addEventListener('click', () => {
    state.temp = 36.8;
    state.isTempAlert = true;
    state.sparklineData.push(36.8);
    state.sparklineData.shift();
    state.score = Math.max(0, state.score - 15);
    state.bufferCount += 1;

    state.timeline.unshift({
      time: getRTCTime(),
      type: 'WARN',
      msg: 'AVISO: Variação Térmica Acima do Limite (36.8°C) - DHT22',
      location: 'Rodovia Presidente Dutra km 142',
      alert: true
    });

    updateUI();
  });

  document.getElementById('btnResetSim')?.addEventListener('click', () => {
    state.score = 100;
    state.impactG = 0.12;
    state.lux = 0;
    state.temp = 22.4;
    state.humidity = 54;
    state.roll = 1.2;
    state.pitch = 0.5;
    state.yaw = 0.0;
    state.isLdrViolated = false;
    state.isImpactAlert = false;
    state.isTempAlert = false;
    state.bufferCount = 0;
    state.sparklineData = [21.8, 22.0, 22.1, 22.4, 22.3, 22.4, 22.5, 22.4];

    state.timeline.unshift({
      time: getRTCTime(),
      type: 'RESET',
      msg: 'Reset do Sistema & Sincronização Wegnology OK',
      location: 'Central TransCargo Express',
      alert: false
    });

    updateUI();
  });

  // ----------------------------------------------------
  // QR SCANNER & DIGITAL SIGNATURE CANVAS
  // ----------------------------------------------------
  const sigCanvas = document.getElementById('sigCanvas');
  const sigCtx = sigCanvas ? sigCanvas.getContext('2d') : null;
  let isSigning = false;

  if (sigCanvas && sigCtx) {
    function resizeSigCanvas() {
      sigCanvas.width = sigCanvas.parentElement.clientWidth;
      sigCanvas.height = sigCanvas.parentElement.clientHeight;
    }
    resizeSigCanvas();
    window.addEventListener('resize', resizeSigCanvas);

    function startDraw(e) {
      isSigning = true;
      document.getElementById('sigPlaceholder')?.style.setProperty('display', 'none');
      sigCtx.beginPath();
      const rect = sigCanvas.getBoundingClientRect();
      const clientX = e.touches ? e.touches[0].clientX : e.clientX;
      const clientY = e.touches ? e.touches[0].clientY : e.clientY;
      sigCtx.moveTo(clientX - rect.left, clientY - rect.top);
    }

    function draw(e) {
      if (!isSigning) return;
      const rect = sigCanvas.getBoundingClientRect();
      const clientX = e.touches ? e.touches[0].clientX : e.clientX;
      const clientY = e.touches ? e.touches[0].clientY : e.clientY;
      
      sigCtx.lineWidth = 2;
      sigCtx.lineCap = 'round';
      sigCtx.strokeStyle = '#00E5FF';
      sigCtx.lineTo(clientX - rect.left, clientY - rect.top);
      sigCtx.stroke();
    }

    function stopDraw() {
      isSigning = false;
    }

    sigCanvas.addEventListener('mousedown', startDraw);
    sigCanvas.addEventListener('mousemove', draw);
    sigCanvas.addEventListener('mouseup', stopDraw);

    sigCanvas.addEventListener('touchstart', startDraw);
    sigCanvas.addEventListener('touchmove', draw);
    sigCanvas.addEventListener('touchend', stopDraw);
  }

  document.getElementById('btnScanQR')?.addEventListener('click', () => {
    alert('QR Code Etiqueta Vinílica #TK89-2026 Lido com Sucesso!\n\nHistórico Rastreável Carregado no Certificado Digital.');
  });

  document.getElementById('btnConfirmDelivery')?.addEventListener('click', () => {
    const certBadge = document.getElementById('certBadge');
    if (certBadge) {
      certBadge.textContent = 'Entrega Confirmada & Assinada';
      certBadge.className = 'card-badge badge-lime';
    }
    alert('Recebimento Confirmado!\nAssinatura Digital emitida e transmitida via Webhook para a API TransCargo Express.');
  });

  // Initial render call
  updateUI();
});
