import 'package:cp949_codec/cp949_codec.dart'; // CP949 인코더 추가
import 'package:flutter/material.dart';
import '../models/kiosk_models.dart';

class KioskProvider extends ChangeNotifier {
  // 1. 마스터 데이터 세팅 (실무에서는 DB나 API에서 가져옴)
  final List<Product> _masterProducts = [
    Product(id: 1, name: '아메리카노', price: 3000, category: '커피'),
    Product(id: 2, name: '카페라떼', price: 3500, category: '커피'),
    Product(id: 3, name: '바닐라라떼', price: 4000, category: '커피'),
    Product(id: 4, name: '아이스티', price: 3500, category: '음료'),
    Product(id: 5, name: '자몽에이드', price: 4500, category: '음료'),
    Product(id: 6, name: '치즈케이크', price: 5000, category: '디저트'),
    Product(id: 7, name: '초코쿠키', price: 2000, category: '디저트'),
  ];

  // 2. 관리할 내부 상태 변수 (은닉화)
  final List<CartItem> _cartItems = [];
  String _selectedCategory = '커피';

  // 3. 외부 View에서 안전하게 읽어갈 Getter
  // 선택된 카테고리의 상품만 필터링하여 반환
  List<Product> get products =>
      _masterProducts.where((p) => p.category == _selectedCategory).toList();
  List<CartItem> get cartItems => _cartItems;
  String get selectedCategory => _selectedCategory;

  // 장바구니에 담긴 전체 금액 실시간 합산 연산
  int get totalPrice =>
      _cartItems.fold(0, (sum, item) => sum + item.totalItemPrice);

  // 4. 비즈니스 로직 함수 (Commands)
  void changeCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void addToCart(Product product) {
    final existingIndex = _cartItems.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      _cartItems[existingIndex].quantity++;
    } else {
      _cartItems.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void removeFromCart(int index) {
    _cartItems.removeAt(index);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  Future<List<int>?> processPayment() async {
    if (_cartItems.isEmpty) return null; // 결제할 내용이 없으면 null 반환

    try {
      // 1. 가상의 네트워크 승인 및 DB 저장 지연 (1초)
      await Future.delayed(const Duration(seconds: 1));

      // 2. 영수증 데이터(바이트 배열) 생성
      final receiptBytes = await _generateReceiptBytes();

      // 3. 비즈니스 규칙에 따라 장바구니 비우기 및 화면 갱신 방송
      _cartItems.clear();
      notifyListeners();

      // 4. View가 활용할 수 있도록 컴파일된 영수증 데이터를 리턴합니다.
      return receiptBytes;
    } catch (e) {
      debugPrint('결제 처리 중 에러 발생: $e');
      return null; // 실패 시 null 반환
    }
  }

  // 💡 영수증 레이아웃을 ESC/POS 바이트(Hex) 배열로 변환해 주는 내부 헬퍼 함수
  Future<List<int>> _generateReceiptBytes() async {
    // List<int> bytes = [];

    // // 1. 프린터 초기화 (ESC @)
    // bytes += [0x1B, 0x40];

    // // 💡 [핵심] 한글 모드(FS &) 진입 커맨드 제거!
    // // 💡 [핵심] CP949 변환 없이 Dart 기본 UTF-8 바이트로 직행!
    // bytes += cp949.encode('--- UTF-8 Test ---\n');
    // bytes += cp949.encode('1. 아메리카노: 3000원\n');
    // bytes += cp949.encode('2. 카페라떼: 3500원\n');
    // bytes += cp949.encode('------------------------\n\n');

    // // 종이 자르기
    // bytes += [0x0A, 0x0A, 0x0A];
    // bytes += [0x1D, 0x56, 0x41, 0x10];

    // return bytes;
    List<int> bytes = [];

    // 1. 프린터 하드웨어 초기화 및 한글 모드 진입
    bytes += [0x1B, 0x40]; // ESC @
    bytes += [0x1C, 0x26]; // FS & (한글 모드 ON)

    // 💡 [핵심] 한글 CP949 인코딩 + 줄바꿈(\r\n) 처리를 전담하는 내부 헬퍼 함수
    List<int> printLine(String text) {
      return cp949.encode('$text\r\n');
    }

    // 2. 영수증 헤더
    // (보통 80mm 영수증은 영문/숫자 기준 42~48자, 58mm는 32자가 들어갑니다)
    bytes += printLine('================================');
    bytes += printLine('       커피 키오스크 주문서');
    bytes += printLine('================================');
    bytes += printLine(''); // 빈 줄 띄우기

    // 3. 장바구니 상품 목록 출력 (동적 로직 복구)
    for (var item in _cartItems) {
      // 💡 실무 팁: 한글은 2바이트, 숫자는 1바이트라 스페이스바 정렬이 매우 까다롭습니다.
      // 가장 깔끔하고 안전한 레이아웃은 [1줄: 상품명], [2줄: 수량 및 금액]으로 나누는 것입니다.
      bytes += printLine('${item.product.name}');

      // 금액이 우측에 오도록 스페이스바로 적절히 여백을 줍니다.
      bytes += printLine(
        '    ${item.quantity}개                 ${item.totalItemPrice}원',
      );
    }

    // 4. 총 결제 금액
    bytes += printLine('--------------------------------');
    bytes += printLine('총 결제 금액:             $totalPrice원');
    bytes += printLine('================================');

    // 커팅기 칼날 위치까지 종이를 밀어내기 위한 공백 라인 4줄 (필수)
    bytes += printLine('');
    bytes += printLine('');
    bytes += printLine('');
    bytes += printLine('');

    // 5. 종이 자르기 커맨드 (오토 커터)
    bytes += [0x1D, 0x56, 0x41, 0x10];

    return bytes;
  }
}
