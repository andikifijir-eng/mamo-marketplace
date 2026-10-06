class UserProfile {
  final String? fullName;
  final String? phone;
  final String? avatar;
  final String? bio;

  UserProfile({this.fullName, this.phone, this.avatar, this.bio});

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        fullName: j['fullName'],
        phone: j['phone'],
        avatar: j['avatar'],
        bio: j['bio'],
      );
}

class User {
  final String id;
  final String email;
  final String role;
  final String accountStatus;
  final UserProfile? profile;

  User({
    required this.id,
    required this.email,
    required this.role,
    required this.accountStatus,
    this.profile,
  });

  String get displayName => profile?.fullName ?? email.split('@').first;
  bool get isSeller => role == 'seller' || role == 'admin';
  bool get isAdmin => role == 'admin';

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'],
        email: j['email'] ?? '',
        role: j['role'] ?? 'buyer',
        accountStatus: j['accountStatus'] ?? 'active',
        profile: j['profile'] != null ? UserProfile.fromJson(j['profile']) : null,
      );
}

class Category {
  final String id;
  final String name;
  final String? icon;
  final String? parentId;

  Category({required this.id, required this.name, this.icon, this.parentId});

  factory Category.fromJson(Map<String, dynamic> j) =>
      Category(id: j['id'], name: j['name'], icon: j['icon'], parentId: j['parentId']);
}

class ProductImage {
  final String id;
  final String imageUrl;
  ProductImage({required this.id, required this.imageUrl});
  factory ProductImage.fromJson(Map<String, dynamic> j) =>
      ProductImage(id: j['id'] ?? '', imageUrl: j['imageUrl'] ?? '');
}

class Product {
  final String id;
  final String name;
  final String? description;
  final int price;
  final int stock;
  final String condition;
  final String status;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String sellerId;
  final String? categoryId;
  final String? campusId;
  final List<ProductImage> images;
  final String? sellerName;
  final String? sellerAvatar;
  final String? categoryName;
  final int favoriteCount;
  final int reviewCount;
  final DateTime? createdAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    required this.condition,
    required this.status,
    this.location,
    this.latitude,
    this.longitude,
    required this.sellerId,
    this.categoryId,
    this.campusId,
    this.images = const [],
    this.sellerName,
    this.sellerAvatar,
    this.categoryName,
    this.favoriteCount = 0,
    this.reviewCount = 0,
    this.createdAt,
  });

  String get imageUrl => images.isNotEmpty ? images.first.imageUrl : '';
  String get conditionLabel => condition == 'new' ? 'Baru' : 'Bekas';

  factory Product.fromJson(Map<String, dynamic> j) {
    final seller = j['seller'] as Map<String, dynamic>?;
    final prof = seller?['profile'] as Map<String, dynamic>?;
    final cat = j['category'] as Map<String, dynamic>?;
    final counts = j['_count'] as Map<String, dynamic>?;
    return Product(
      id: j['id'],
      name: j['name'] ?? '',
      description: j['description'],
      price: (j['price'] ?? 0).toInt(),
      stock: (j['stock'] ?? 0).toInt(),
      condition: j['condition'] ?? 'used',
      status: j['status'] ?? 'active',
      location: j['location'],
      latitude: (j['latitude'] as num?)?.toDouble(),
      longitude: (j['longitude'] as num?)?.toDouble(),
      sellerId: j['sellerId'] ?? seller?['id'] ?? '',
      categoryId: j['categoryId'],
      campusId: j['campusId'],
      images: (j['images'] as List?)?.map((e) => ProductImage.fromJson(e)).toList() ?? [],
      sellerName: prof?['fullName'],
      sellerAvatar: prof?['avatar'],
      categoryName: cat?['name'],
      favoriteCount: (counts?['favorites'] ?? 0).toInt(),
      reviewCount: (counts?['reviews'] ?? 0).toInt(),
      createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt']) : null,
    );
  }
}

class CartItem {
  final String id;
  final int quantity;
  final Product product;
  CartItem({required this.id, required this.quantity, required this.product});
  int get subtotal => product.price * quantity;
  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
        id: j['id'],
        quantity: (j['quantity'] ?? 1).toInt(),
        product: Product.fromJson(j['product']),
      );
}

class OrderItem {
  final String id;
  final String productId;
  final int quantity;
  final int price;
  final int subtotal;
  final String? productName;
  final String? productImage;

  OrderItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.subtotal,
    this.productName,
    this.productImage,
  });

  factory OrderItem.fromJson(Map<String, dynamic> j) {
    final p = j['product'] as Map<String, dynamic>?;
    final imgs = p?['images'] as List?;
    return OrderItem(
      id: j['id'],
      productId: j['productId'] ?? '',
      quantity: (j['quantity'] ?? 1).toInt(),
      price: (j['price'] ?? 0).toInt(),
      subtotal: (j['subtotal'] ?? 0).toInt(),
      productName: p?['name'],
      productImage: (imgs != null && imgs.isNotEmpty) ? imgs.first['imageUrl'] : null,
    );
  }
}

class Order {
  final String id;
  final String buyerId;
  final String sellerId;
  final int totalAmount;
  final String deliveryMethod;
  final String? deliveryAddress;
  final String status;
  final List<OrderItem> items;
  final String? buyerName;
  final String? sellerName;
  final bool hasReview;
  final DateTime? createdAt;

  Order({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.totalAmount,
    required this.deliveryMethod,
    this.deliveryAddress,
    required this.status,
    this.items = const [],
    this.buyerName,
    this.sellerName,
    this.hasReview = false,
    this.createdAt,
  });

  static const statusLabels = {
    'pending': 'Menunggu',
    'accepted': 'Diterima',
    'processed': 'Diproses',
    'ready': 'Siap',
    'completed': 'Selesai',
    'cancelled': 'Dibatalkan',
    'rejected': 'Ditolak',
  };

  String get statusLabel => statusLabels[status] ?? status;
  String get shortId => id.length > 8 ? id.substring(0, 8) : id;

  factory Order.fromJson(Map<String, dynamic> j) {
    final b = j['buyer'] as Map<String, dynamic>?;
    final s = j['seller'] as Map<String, dynamic>?;
    return Order(
      id: j['id'],
      buyerId: j['buyerId'] ?? '',
      sellerId: j['sellerId'] ?? '',
      totalAmount: (j['totalAmount'] ?? 0).toInt(),
      deliveryMethod: j['deliveryMethod'] ?? 'cod',
      deliveryAddress: j['deliveryAddress'],
      status: j['status'] ?? 'pending',
      items: (j['items'] as List?)?.map((e) => OrderItem.fromJson(e)).toList() ?? [],
      buyerName: (b?['profile'] as Map<String, dynamic>?)?['fullName'],
      sellerName: (s?['profile'] as Map<String, dynamic>?)?['fullName'],
      hasReview: j['review'] != null,
      createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt']) : null,
    );
  }
}

class Conversation {
  final String id;
  final String buyerId;
  final String sellerId;
  final String? productId;
  final String? productName;
  final String? otherName;
  final String? otherAvatar;
  final String? lastMessage;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    this.productId,
    this.productName,
    this.otherName,
    this.otherAvatar,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> j, String myId) {
    final isBuyer = j['buyerId'] == myId;
    final other = (isBuyer ? j['seller'] : j['buyer']) as Map<String, dynamic>?;
    final prof = other?['profile'] as Map<String, dynamic>?;
    final msgs = j['messages'] as List?;
    final counts = j['_count'] as Map<String, dynamic>?;
    return Conversation(
      id: j['id'],
      buyerId: j['buyerId'],
      sellerId: j['sellerId'],
      productId: j['productId'],
      productName: (j['product'] as Map<String, dynamic>?)?['name'],
      otherName: prof?['fullName'] ?? (other?['email'] as String?)?.split('@').first,
      otherAvatar: prof?['avatar'],
      lastMessage: (msgs != null && msgs.isNotEmpty) ? msgs.first['message'] : null,
      unreadCount: (counts?['messages'] ?? 0).toInt(),
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.message,
    this.isRead = false,
    this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'],
        senderId: j['senderId'] ?? '',
        message: j['message'] ?? '',
        isRead: j['isRead'] ?? false,
        createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt']) : null,
      );
}

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String? body;
  final bool isRead;
  final DateTime? createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.isRead = false,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'],
        type: j['type'] ?? 'system',
        title: j['title'] ?? '',
        body: j['body'],
        isRead: j['isRead'] ?? false,
        createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt']) : null,
      );
}
