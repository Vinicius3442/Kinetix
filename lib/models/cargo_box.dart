class CargoBox {
  final String code;
  final String title;
  final String origin;
  final String dest;
  final String status; // 'Em Trânsito', 'Alerta', 'Atenção', 'Entregue', 'No Pátio'
  final String nodeId;
  final double score;
  final double impactG;
  final int lux;
  final double temp;
  final int humidity;
  final double roll;
  final double pitch;
  final int battery;
  final String driver;
  final String vehiclePlate;
  final String lastUpdate;
  final String category; // 'Biológico/Farma', 'Eletrônicos', 'Óptico', 'Industrial'

  const CargoBox({
    required this.code,
    required this.title,
    required this.origin,
    required this.dest,
    required this.status,
    required this.nodeId,
    required this.score,
    required this.impactG,
    required this.lux,
    required this.temp,
    required this.humidity,
    required this.roll,
    required this.pitch,
    required this.battery,
    required this.driver,
    required this.vehiclePlate,
    required this.lastUpdate,
    required this.category,
  });

  bool get isAlert => impactG > 1.0 || lux > 1 || temp > 28.0 || score < 85;
  bool get isCritical => impactG > 1.3 || lux > 5 || score < 80;

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'title': title,
      'origin': origin,
      'dest': dest,
      'status': status,
      'nodeId': nodeId,
      'score': score,
      'impactG': impactG,
      'lux': lux,
      'temp': temp,
      'humidity': humidity,
      'roll': roll,
      'pitch': pitch,
      'battery': battery,
      'driver': driver,
      'vehiclePlate': vehiclePlate,
      'lastUpdate': lastUpdate,
      'category': category,
    };
  }
}

// Lista oficial da frota de Caixas Inteligentes Kinetix TransCargo Express
class CargoFleetRepository {
  static final List<CargoBox> fleet = [
    const CargoBox(
      code: 'TC-8902-SJC',
      title: 'Vacinas Termossensíveis',
      origin: 'SJC Logística',
      dest: 'Caçapava-SP',
      status: 'Em Trânsito',
      nodeId: 'Kinetix Node #01',
      score: 100.0,
      impactG: 0.12,
      lux: 0,
      temp: 22.4,
      humidity: 54,
      roll: 1.2,
      pitch: 0.5,
      battery: 98,
      driver: 'Roberto Lima',
      vehiclePlate: 'BRA-4E29',
      lastUpdate: 'Há 2 min (MQTT SJC)',
      category: 'Biológico/Farma',
    ),
    const CargoBox(
      code: 'TC-4410-SP',
      title: 'Componentes Eletrônicos',
      origin: 'Terminal Guarulhos',
      dest: 'São José dos Campos-SP',
      status: 'Em Trânsito',
      nodeId: 'Kinetix Node #02',
      score: 94.0,
      impactG: 0.38,
      lux: 0,
      temp: 19.8,
      humidity: 46,
      roll: -0.5,
      pitch: 0.8,
      battery: 92,
      driver: 'Marcos Vinicius',
      vehiclePlate: 'KNT-8821',
      lastUpdate: 'Há 5 min (MQTT Dutra)',
      category: 'Eletrônicos',
    ),
    const CargoBox(
      code: 'TC-1092-RJ',
      title: 'Equipamentos Ópticos',
      origin: 'Porto de Santos',
      dest: 'Resende-RJ',
      status: 'Atenção',
      nodeId: 'Kinetix Node #03',
      score: 88.0,
      impactG: 0.72,
      lux: 2,
      temp: 24.5,
      humidity: 58,
      roll: 2.1,
      pitch: -1.4,
      battery: 85,
      driver: 'Eduardo Ramos',
      vehiclePlate: 'LOG-7734',
      lastUpdate: 'Há 1 min (Lacre Alert)',
      category: 'Óptico',
    ),
    const CargoBox(
      code: 'TC-5520-BH',
      title: 'Medicamentos Especiais',
      origin: 'Campinas-SP',
      dest: 'Belo Horizonte-MG',
      status: 'Em Trânsito',
      nodeId: 'Kinetix Node #04',
      score: 98.0,
      impactG: 0.18,
      lux: 0,
      temp: 21.0,
      humidity: 50,
      roll: 0.4,
      pitch: 0.2,
      battery: 95,
      driver: 'André Carvalho',
      vehiclePlate: 'TRC-1090',
      lastUpdate: 'Há 4 min (MQTT Fernão Dias)',
      category: 'Biológico/Farma',
    ),
    const CargoBox(
      code: 'TC-3312-PR',
      title: 'Semicondutores Automotivos',
      origin: 'Curitiba-PR',
      dest: 'Taubaté-SP',
      status: 'Alerta',
      nodeId: 'Kinetix Node #05',
      score: 78.0,
      impactG: 1.45,
      lux: 0,
      temp: 23.1,
      humidity: 48,
      roll: -3.2,
      pitch: 4.1,
      battery: 88,
      driver: 'Jorge Nogueira',
      vehiclePlate: 'AUT-5211',
      lastUpdate: 'Há 3 min (Impact Alert)',
      category: 'Industrial',
    ),
    const CargoBox(
      code: 'TC-7741-GO',
      title: 'Amostras Biológicas Vivas',
      origin: 'Goiânia-GO',
      dest: 'São Paulo-SP',
      status: 'Em Trânsito',
      nodeId: 'Kinetix Node #06',
      score: 99.0,
      impactG: 0.08,
      lux: 0,
      temp: 4.2,
      humidity: 62,
      roll: 0.2,
      pitch: -0.1,
      battery: 94,
      driver: 'Claudio Medeiros',
      vehiclePlate: 'MED-9032',
      lastUpdate: 'Há 6 min (ColdChain OK)',
      category: 'Biológico/Farma',
    ),
    const CargoBox(
      code: 'TC-6204-MG',
      title: 'Sensores de Alta Precisão',
      origin: 'Betim-MG',
      dest: 'Santos-SP',
      status: 'No Pátio',
      nodeId: 'Kinetix Node #07',
      score: 100.0,
      impactG: 0.05,
      lux: 0,
      temp: 20.5,
      humidity: 52,
      roll: 0.0,
      pitch: 0.0,
      battery: 100,
      driver: 'Pátio Central SJC',
      vehiclePlate: 'DEP-0024',
      lastUpdate: 'Há 12 min (Check-in Pátio)',
      category: 'Industrial',
    ),
    const CargoBox(
      code: 'TC-9183-SC',
      title: 'Dispositivos Médicos Hospitalares',
      origin: 'Joinville-SC',
      dest: 'SJC Logística',
      status: 'Entregue',
      nodeId: 'Kinetix Node #08',
      score: 97.0,
      impactG: 0.22,
      lux: 0,
      temp: 21.8,
      humidity: 53,
      roll: 0.0,
      pitch: 0.0,
      battery: 91,
      driver: 'Fábio Guedes',
      vehiclePlate: 'HLT-6412',
      lastUpdate: 'Entregue c/ Assinatura QR',
      category: 'Biológico/Farma',
    ),
  ];
}

