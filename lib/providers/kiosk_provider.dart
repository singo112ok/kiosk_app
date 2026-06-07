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
  List<Product> get products => _masterProducts.where((p) => p.category == _selectedCategory).toList();
  List<CartItem> get cartItems => _cartItems;
  String get selectedCategory => _selectedCategory;

  // 장바구니에 담긴 전체 금액 실시간 합산 연산
  int get totalPrice => _cartItems.fold(0, (sum, item) => sum + item.totalItemPrice);

  // 4. 비즈니스 로직 함수 (Commands)
  void changeCategory(String category){
    _selectedCategory = category;
    notifyListeners();
  }

  void addToCart(Product product)
  {
    final existingIndex = _cartItems.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0){
      _cartItems[existingIndex].quantity++;
    } else {
      _cartItems.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void removeFromCart(int index)
  {
    _cartItems.removeAt(index);
    notifyListeners();
  }

  void clearCart(){
    _cartItems.clear();
    notifyListeners();
  }
  
  Future<bool> processPayment() async {
  if (_cartItems.isEmpty) return false;

    try {
      // 1. 가상의 네트워크/DB 지연 시간 (예: 1초)
      await Future.delayed(const Duration(seconds: 1)); 
      
      // 2. 결제 완료 처리
      _cartItems.clear();
      notifyListeners();
      
      // 3. 뷰에게 성공했다고 결과만 툭 던져줍니다.
      return true; 
    } catch (e) {
      return false; // 실패
    }
  }
}