import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/kiosk_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => KioskProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: KioskMainPage(),
    );
  }
}

// =======================================================================
// [메인 레이아웃] 화면을 좌측(메뉴)과 우측(장바구니)으로 분할합니다.
// =======================================================================
class KioskMainPage extends StatelessWidget {
  const KioskMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('커피 키오스크 (MVVM)'), backgroundColor: Colors.brown),
      body: Row(
        children: [
          // 좌측 영역 (비율 2) : 카테고리 탭 + 상품 그리드
          Expanded(
            flex: 2,
            child: Column(
              children: const [
                CategorySelectionView(), // View 1
                Expanded(child: ProductGridView()), // View 2
              ],
            ),
          ),
          
          // 구분선
          const VerticalDivider(width: 1, thickness: 1),

          // 우측 영역 (비율 1) : 장바구니 리스트 + 결제 바
          Expanded(
            flex: 1,
            child: Column(
              children: const [
                Expanded(child: CartListView()), // View 3
                PaymentView(), // View 4
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =======================================================================
// [View 1] 카테고리 탭 영역
// =======================================================================
class CategorySelectionView extends StatelessWidget {
  const CategorySelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. 현재 선택된 카테고리 상태만 구독 (UI 갱신용)
    final selectedCategory = context.watch<KioskProvider>().selectedCategory;
    final categories = ['커피', '음료', '디저트'];

    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: categories.map((category) {
          final isSelected = selectedCategory == category;
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? Colors.brown : Colors.grey,
            ),
            // 2. 클릭 시 ViewModel의 함수 호출 (데이터 변경 요청)
            onPressed: () => context.read<KioskProvider>().changeCategory(category),
            child: Text(category, style: const TextStyle(color: Colors.white)),
          );
        }).toList(),
      ),
    );
  }
}

// =======================================================================
// [View 2] 상품 4x4 그리드 영역
// =======================================================================
class ProductGridView extends StatelessWidget {
  const ProductGridView({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. ViewModel에서 현재 카테고리에 맞는 상품 목록을 가져옴
    final products = context.watch<KioskProvider>().products;

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      // 4열(4x4) 그리드 설정
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return InkWell(
          // 2. 상품 클릭 시 장바구니 추가 함수 호출
          onTap: () => context.read<KioskProvider>().addToCart(product),
          child: Card(
            elevation: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_cafe, size: 40, color: Colors.brown[300]),
                const SizedBox(height: 10),
                Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${product.price}원', style: const TextStyle(color: Colors.blue)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =======================================================================
// [View 3] 장바구니 리스트 영역
// =======================================================================
class CartListView extends StatelessWidget {
  const CartListView({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. 장바구니 목록 상태 구독
    final cartItems = context.watch<KioskProvider>().cartItems;

    if (cartItems.isEmpty) {
      return const Center(child: Text('장바구니가 비어 있습니다.'));
    }

    return ListView.builder(
      itemCount: cartItems.length,
      itemBuilder: (context, index) {
        final item = cartItems[index];
        return ListTile(
          title: Text(item.product.name),
          subtitle: Text('${item.product.price}원 x ${item.quantity}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${item.totalItemPrice}원', style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () {
                  context.read<KioskProvider>().removeFromCart(index);
                },
                icon: const Icon(Icons.delete),
              ),
            ],
          ),
        );  // ListTile 닫는 괄호 + 세미콜론
      },
    );      
  }
}

// =======================================================================
// [View 4] 하단 결제 바 영역
// =======================================================================
class PaymentView extends StatelessWidget {
  const PaymentView({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. 총 결제 금액 상태 구독
    final totalPrice = context.watch<KioskProvider>().totalPrice;

    return Container(
      color: Colors.brown[50],
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('총 결제 금액:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text('$totalPrice원', style: const TextStyle(fontSize: 24, color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
              // 2. 결제 완료 (장바구니 초기화) 함수 호출
              //onPressed: () => context.read<KioskProvider>().clearCart(),
              onPressed: () async{
                final isSuccess = await context.read<KioskProvider>().processPayment();

                if(!context.mounted) return;

                if(isSuccess){
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('결제 성공'),
                      content: const Text('주문이 완료되었습니다.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('확인'),
                          ),
                      ],
                    ),
                  );
                }
              },
              child: const Text('결제하기', style: TextStyle(fontSize: 20, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}