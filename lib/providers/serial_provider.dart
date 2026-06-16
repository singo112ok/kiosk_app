import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

class SerialProvider extends ChangeNotifier {
  SerialPort? _serialPort;
  SerialPortReader? _reader;
  StreamSubscription<Uint8List>? _subscription;

  // 상태 변수
  List<String> _availablePorts = [];
  bool _isOpen = false;
  String _receivedData = "";

  // UI 노출용 Getter
  List<String> get availablePorts => _availablePorts;
  bool get isOpen => _isOpen;
  String get receivedData => _receivedData;

  // 1. PC에 꽂힌 COM 포트 목록 검색
  void scanPorts() {
    _availablePorts = SerialPort.availablePorts;
    notifyListeners();
  }

  // 2. COM 포트 연결 (Win32의 CreateFile 역할)
  bool connect(String portName) {
    if (_isOpen) disconnect();

    _serialPort = SerialPort(portName);

    // 읽기/쓰기 모드로 포트 오픈 (보드레이트 등 설정 가능)
    if (!_serialPort!.openReadWrite()) {
      print('포트 열기 실패: ${SerialPort.lastError}');
      return false;
    }

    // 통신 속도(BaudRate) 등 포트 환경 설정 (DCB 구조체 세팅과 동일)
    final config = SerialPortConfig();

    config.baudRate = 9600;
    config.bits = 8;
    config.stopBits = 1;
    config.parity = 0; // None

    // 💡 [수정] 모든 하드웨어 및 소프트웨어 흐름 제어 라인을 완전히 비활성화 (0 설정)
    // 3핀 케이블 환경에서 가장 안전하게 데이터를 밀어 넣는 방식입니다.
    config.rts = 0;
    config.dtr = 0;
    config.cts = 0;
    config.dsr = 0;
    config.xonXoff = 0;

    _serialPort!.config = config;
    config.dispose();

    _isOpen = true;

    // 3. 수신 인터럽트(이벤트) 설정
    _reader = SerialPortReader(_serialPort!);

    // Stream.listen()이 바로 Delphi의 OnRxChar 이벤트 핸들러 역할입니다.
    _subscription = _reader!.stream.listen((Uint8List data) {
      // 바이트 배열을 문자열로 변환하여 버퍼에 누적 (ASCII 기준)
      _receivedData += String.fromCharCodes(data);

      // 데이터가 들어왔으니 화면 갱신 지시
      notifyListeners();
    });

    notifyListeners();
    return true;
  }

  void sendBytes(List<int> bytes) {
    if (!_isOpen || _serialPort == null) return;

    final data = Uint8List.fromList(bytes);
    int totalWritten = 0;

    // 1. [핵심] 남은 바이트가 없을 때까지 끝까지 밀어넣는 보장 루프
    while (totalWritten < data.length) {
      // 이미 쓴 만큼 잘라내고 남은 데이터만 전송
      final chunk = data.sublist(totalWritten);

      // timeout 옵션을 주어 무한 대기를 방지할 수 있습니다.
      final written = _serialPort!.write(chunk, timeout: 1000);

      if (written <= 0) {
        print('경고: 시리얼 버퍼 전송 중단');
        break;
      }
      totalWritten += written;
    }
  }

  // 5. 포트 닫기 (메모리 해제 필수)
  void disconnect() {
    try {
      _subscription?.cancel();
      _reader?.close();
      _serialPort?.close();
      //_serialPort?.dispose();
    } catch (e) {
      print('포트 해제 중 예외발생 : $e');
    } finally {
      _isOpen = false;
      notifyListeners();
    }
  }
}
