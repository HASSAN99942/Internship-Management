import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'models/offer.dart';

class OffersRepository {
  const OffersRepository();

  Future<PaginatedOffers> listOffers(OfferFilters filters) async {
    final response = await apiClient.get(
      '/offers/',
      queryParameters: filters.toQueryParams(),
    );
    return PaginatedOffers.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PaginatedOffers> listMyOffers() async {
    final response = await apiClient.get('/offers/mine/');
    return PaginatedOffers.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Offer> getOffer(int id) async {
    final response = await apiClient.get('/offers/$id/');
    return Offer.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Offer> createOffer(OfferInput input) async {
    final response = await apiClient.post('/offers/', data: input.toJson());
    return Offer.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Offer> updateOffer(int id, OfferInput input) async {
    final response =
        await apiClient.patch('/offers/$id/', data: input.toJson());
    return Offer.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> publishOffer(int id) async {
    await apiClient.post('/offers/$id/publish/');
  }

  Future<void> closeOffer(int id) async {
    await apiClient.post('/offers/$id/close/');
  }

  Future<void> deleteOffer(int id) async {
    await apiClient.delete('/offers/$id/');
  }
}

final offersRepositoryProvider =
    Provider<OffersRepository>((_) => const OffersRepository());
