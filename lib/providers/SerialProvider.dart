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
    SerialPortConfig config = _serialPort!.config;
    config.baudRate = 9600;
    _serialPort!.config = config;

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

  // 4. 데이터 전송 (WriteFile 역할)
  void sendData(String text) {
    if (!_isOpen || _serialPort == null) return;
    
    final bytes = Uint8List.fromList(text.codeUnits);
    _serialPort!.write(bytes); // 비동기로 전송됨
  }

  // 5. 포트 닫기 (메모리 해제 필수)
  void disconnect() {
    _subscription?.cancel();
    _reader?.close();
    _serialPort?.close();
    _serialPort?.dispose();
    
    _isOpen = false;
    notifyListeners();
  }
}