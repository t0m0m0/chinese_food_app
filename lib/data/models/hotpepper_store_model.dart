import 'dart:convert';

class HotpepperStoreModel {
  final String id;
  final String name;
  final String address;
  final double? lat;
  final double? lng;
  final String? genre;
  final String? budget;
  final String? access;
  final String? urlPc;
  final String? urlMobile;
  final String? photo;
  final String? open;
  final String? close;
  final String? catch_;

  const HotpepperStoreModel({
    required this.id,
    required this.name,
    required this.address,
    this.lat,
    this.lng,
    this.genre,
    this.budget,
    this.access,
    this.urlPc,
    this.urlMobile,
    this.photo,
    this.open,
    this.close,
    this.catch_,
  });

  factory HotpepperStoreModel.fromJson(Map<String, dynamic> json) {
    return HotpepperStoreModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      lng: json['lng'] != null ? double.tryParse(json['lng'].toString()) : null,
      genre: json['genre']?['name'] as String?,
      budget: json['budget']?['name'] as String?,
      access: json['access'] as String?,
      urlPc: json['urls']?['pc'] as String?,
      urlMobile: json['urls']?['mobile'] as String?,
      photo: json['photo']?['mobile']?['l'] as String?,
      open: json['open'] as String?,
      close: json['close'] as String?,
      catch_: json['catch'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
      'genre': genre,
      'budget': budget,
      'access': access,
      'urlPc': urlPc,
      'urlMobile': urlMobile,
      'photo': photo,
      'open': open,
      'close': close,
      'catch': catch_,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HotpepperStoreModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'HotpepperStoreModel(id: $id, name: $name, address: $address)';
  }
}

class HotpepperSearchResponse {
  final List<HotpepperStoreModel> shops;
  final int resultsAvailable;
  final int resultsReturned;
  final int resultsStart;

  const HotpepperSearchResponse({
    required this.shops,
    required this.resultsAvailable,
    required this.resultsReturned,
    required this.resultsStart,
  });

  factory HotpepperSearchResponse.fromJson(Map<String, dynamic> json) {
    final results = json['results'] as Map<String, dynamic>;
    final shopList = results['shop'] as List<dynamic>? ?? [];

    return HotpepperSearchResponse(
      shops: shopList
          .map((shop) =>
              HotpepperStoreModel.fromJson(shop as Map<String, dynamic>))
          .toList(),
      resultsAvailable: results['results_available'] as int? ?? 0,
      resultsReturned: results['results_returned'] as int? ?? 0,
      resultsStart: results['results_start'] as int? ?? 1,
    );
  }

  static HotpepperSearchResponse fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return HotpepperSearchResponse.fromJson(json);
  }

  bool get hasResults => shops.isNotEmpty;
  bool get hasMoreResults =>
      resultsAvailable > resultsStart + resultsReturned - 1;

  @override
  String toString() {
    return 'HotpepperSearchResponse(shops: ${shops.length}, available: $resultsAvailable)';
  }
}
