class Product{
  final int id;
  final String name;
  final int price;
  final String category;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category
  });
}

class CartItem{
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1
  });

  int get totalItemPrice => product.price * quantity;
}