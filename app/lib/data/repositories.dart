import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/models.dart';

class ProductRepository {
  final _dio = ApiClient.instance.dio;

  Future<List<Category>> categories() async {
    final res = await _dio.get('/categories');
    return (res.data['categories'] as List).map((e) => Category.fromJson(e)).toList();
  }

  Future<({List<Product> products, int total})> search({
    String? search,
    String? categoryId,
    int? minPrice,
    int? maxPrice,
    String? condition,
    String? sellerId,
    double? lat,
    double? lng,
    double? radiusKm,
    String sort = 'newest',
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get('/products', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null) 'category': categoryId,
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
      if (condition != null) 'condition': condition,
      if (sellerId != null) 'seller_id': sellerId,
      if (lat != null && lng != null && radiusKm != null) ...{
        'lat': lat, 'lng': lng, 'radius_km': radiusKm,
      },
      'sort': sort, 'page': page, 'limit': limit,
    });
    return (
      products: (res.data['products'] as List).map((e) => Product.fromJson(e)).toList(),
      total: (res.data['total'] ?? 0) as int,
    );
  }

  Future<({Product product, double? rating, int ratingCount, bool isFavorite})> detail(String id) async {
    final res = await _dio.get('/products/$id');
    return (
      product: Product.fromJson(res.data['product']),
      rating: (res.data['rating']?['average'] as num?)?.toDouble(),
      ratingCount: (res.data['rating']?['count'] ?? 0) as int,
      isFavorite: res.data['isFavorite'] == true,
    );
  }

  Future<List<Map<String, dynamic>>> reviews(String productId) async {
    final res = await _dio.get('/products/$productId/reviews');
    return List<Map<String, dynamic>>.from(res.data['reviews']);
  }

  Future<Product> create({
    required String name,
    String? description,
    required int price,
    required int stock,
    String condition = 'used',
    String? categoryId,
    String? location,
    double? latitude,
    double? longitude,
    List<String> images = const [],
    String status = 'active',
  }) async {
    final res = await _dio.post('/products', data: {
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'condition': condition,
      if (categoryId != null) 'categoryId': categoryId,
      if (location != null) 'location': location,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (images.isNotEmpty) 'images': images,
      'status': status,
    });
    return Product.fromJson(res.data['product']);
  }

  Future<Product> update(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('/products/$id', data: data);
    return Product.fromJson(res.data['product']);
  }

  Future<void> delete(String id) async => _dio.delete('/products/$id');

  Future<List<Product>> favorites() async {
    final res = await _dio.get('/favorites');
    return (res.data['favorites'] as List)
        .map((e) => Product.fromJson(e['product']))
        .toList();
  }

  Future<void> addFavorite(String productId) async =>
      _dio.post('/favorites', data: {'productId': productId});

  Future<void> removeFavorite(String productId) async =>
      _dio.delete('/favorites/$productId');
}

class CartRepository {
  final _dio = ApiClient.instance.dio;

  Future<({List<CartItem> items, int total})> get() async {
    final res = await _dio.get('/cart');
    return (
      items: (res.data['items'] as List).map((e) => CartItem.fromJson(e)).toList(),
      total: (res.data['total'] ?? 0) as int,
    );
  }

  Future<void> add(String productId, {int quantity = 1}) async =>
      _dio.post('/cart/items', data: {'productId': productId, 'quantity': quantity});

  Future<void> updateQty(String itemId, int quantity) async =>
      _dio.put('/cart/items/$itemId', data: {'quantity': quantity});

  Future<void> remove(String itemId) async => _dio.delete('/cart/items/$itemId');
}

class OrderRepository {
  final _dio = ApiClient.instance.dio;

  Future<List<Order>> list({bool asSeller = false}) async {
    final res = await _dio.get('/orders', queryParameters: asSeller ? {'as': 'seller'} : null);
    return (res.data['orders'] as List).map((e) => Order.fromJson(e)).toList();
  }

  Future<Order> detail(String id) async =>
      Order.fromJson((await _dio.get('/orders/$id')).data['order']);

  Future<List<Order>> checkout({
    required List<String> cartItemIds,
    String deliveryMethod = 'cod',
    String? deliveryAddress,
    double? latitude,
    double? longitude,
  }) async {
    final res = await _dio.post('/orders', data: {
      'cartItemIds': cartItemIds,
      'deliveryMethod': deliveryMethod,
      if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
    return (res.data['orders'] as List).map((e) => Order.fromJson(e)).toList();
  }

  Future<void> updateStatus(String orderId, String status) async =>
      _dio.put('/orders/$orderId/status', data: {'status': status});

  Future<void> review({required String orderId, required int rating, String? comment}) async =>
      _dio.post('/reviews', data: {
        'orderId': orderId, 'rating': rating,
        if (comment != null) 'comment': comment,
      });
}

class ChatRepository {
  final _dio = ApiClient.instance.dio;

  Future<List<Conversation>> conversations(String myId) async {
    final res = await _dio.get('/conversations');
    return (res.data['conversations'] as List)
        .map((e) => Conversation.fromJson(e, myId))
        .toList();
  }

  Future<Conversation> open({required String sellerId, String? productId, required String myId}) async {
    final res = await _dio.post('/conversations', data: {
      'sellerId': sellerId,
      if (productId != null) 'productId': productId,
    });
    return Conversation.fromJson(res.data['conversation'], myId);
  }

  Future<List<ChatMessage>> messages(String conversationId) async {
    final res = await _dio.get('/conversations/$conversationId/messages');
    return (res.data['messages'] as List).map((e) => ChatMessage.fromJson(e)).toList();
  }

  Future<ChatMessage> send(String conversationId, String text) async {
    final res = await _dio.post('/conversations/$conversationId/messages', data: {'message': text});
    return ChatMessage.fromJson(res.data['message']);
  }
}

class NotificationRepository {
  final _dio = ApiClient.instance.dio;

  Future<({List<AppNotification> items, int unread})> list() async {
    final res = await _dio.get('/notifications');
    return (
      items: (res.data['notifications'] as List).map((e) => AppNotification.fromJson(e)).toList(),
      unread: (res.data['unread'] ?? 0) as int,
    );
  }

  Future<void> markRead(String id) async => _dio.put('/notifications/$id/read');
  Future<void> markAllRead() async => _dio.put('/notifications/read-all');
}

class VerificationRepository {
  final _dio = ApiClient.instance.dio;

  Future<List<Map<String, dynamic>>> campuses() async {
    final res = await _dio.get('/verification/campuses');
    return List<Map<String, dynamic>>.from(res.data['campuses']);
  }

  Future<Map<String, dynamic>> status() async =>
      (await _dio.get('/verification/status')).data;

  Future<void> submit({String? campusId, required String studentIdentifier, String? document}) async {
    await _dio.post('/verification', data: {
      if (campusId != null) 'campusId': campusId,
      'studentIdentifier': studentIdentifier,
      if (document != null) 'document': document,
    });
  }
}

class SellerRepository {
  final _dio = ApiClient.instance.dio;

  Future<Map<String, dynamic>> dashboard() async => (await _dio.get('/seller/dashboard')).data;
  Future<List<Product>> products() async =>
      (await _dio.get('/seller/products')).data['products'] is List
          ? ((await _dio.get('/seller/products')).data['products'] as List)
              .map((e) => Product.fromJson(e))
              .toList()
          : [];
  Future<Map<String, dynamic>> statistics() async => (await _dio.get('/seller/statistics')).data;
}

class UploadRepository {
  final _dio = ApiClient.instance.dio;

  /// Upload file gambar (path lokal), return URL absolut.
  Future<String> uploadImage(String filePath, {String fileName = 'upload.jpg'}) async {
    final form = FormData.fromMap({
      'image': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final res = await _dio.post('/upload/image', data: form);
    return res.data['url'] as String;
  }

  /// Upload dari bytes (untuk Flutter Web).
  Future<String> uploadImageBytes(List<int> bytes, String fileName) async {
    final form = FormData.fromMap({
      'image': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final res = await _dio.post('/upload/image', data: form);
    return res.data['url'] as String;
  }
}
