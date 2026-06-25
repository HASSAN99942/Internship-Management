import 'package:json_annotation/json_annotation.dart';

part 'offer.g.dart';

@JsonSerializable()
class CompanySummary {
  final int id;
  final String email;
  @JsonKey(name: 'company_name')
  final String companyName;

  const CompanySummary({
    required this.id,
    required this.email,
    required this.companyName,
  });

  factory CompanySummary.fromJson(Map<String, dynamic> json) =>
      _$CompanySummaryFromJson(json);
  Map<String, dynamic> toJson() => _$CompanySummaryToJson(this);
}

@JsonSerializable()
class Offer {
  final int id;
  final CompanySummary company;
  final String title;
  final String description;
  final String skills;
  final String location;
  @JsonKey(name: 'duration_weeks')
  final int durationWeeks;
  @JsonKey(name: 'start_date')
  final String startDate;
  final int positions;
  final String status; // draft | published | closed
  @JsonKey(name: 'is_open')
  final bool isOpen;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  const Offer({
    required this.id,
    required this.company,
    required this.title,
    required this.description,
    required this.skills,
    required this.location,
    required this.durationWeeks,
    required this.startDate,
    required this.positions,
    required this.status,
    required this.isOpen,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Offer.fromJson(Map<String, dynamic> json) => _$OfferFromJson(json);
  Map<String, dynamic> toJson() => _$OfferToJson(this);
}

@JsonSerializable()
class PaginatedOffers {
  final int count;
  final String? next;
  final String? previous;
  final List<Offer> results;

  const PaginatedOffers({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedOffers.fromJson(Map<String, dynamic> json) =>
      _$PaginatedOffersFromJson(json);
  Map<String, dynamic> toJson() => _$PaginatedOffersToJson(this);
}

class OfferFilters {
  final String? q;
  final String? location;
  final int? durationWeeks;
  final int? company;
  final int page;

  const OfferFilters({
    this.q,
    this.location,
    this.durationWeeks,
    this.company,
    this.page = 1,
  });

  OfferFilters copyWith({
    String? q,
    String? location,
    int? durationWeeks,
    int? company,
    int? page,
    bool clearQ = false,
    bool clearLocation = false,
    bool clearDuration = false,
  }) =>
      OfferFilters(
        q: clearQ ? null : (q ?? this.q),
        location: clearLocation ? null : (location ?? this.location),
        durationWeeks:
            clearDuration ? null : (durationWeeks ?? this.durationWeeks),
        company: company ?? this.company,
        page: page ?? this.page,
      );

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (q != null && q!.isNotEmpty) params['q'] = q;
    if (location != null && location!.isNotEmpty) params['location'] = location;
    if (durationWeeks != null) {
      params['duration_weeks'] = durationWeeks.toString();
    }
    if (company != null) params['company'] = company.toString();
    if (page > 1) params['page'] = page.toString();
    return params;
  }

  bool get hasActiveFilters =>
      (q != null && q!.isNotEmpty) ||
      (location != null && location!.isNotEmpty) ||
      durationWeeks != null;
}

class OfferInput {
  final String title;
  final String description;
  final String skills;
  final String location;
  final int durationWeeks;
  final String startDate; // ISO date yyyy-MM-dd
  final int positions;

  const OfferInput({
    required this.title,
    required this.description,
    required this.skills,
    required this.location,
    required this.durationWeeks,
    required this.startDate,
    required this.positions,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'skills': skills,
        'location': location,
        'duration_weeks': durationWeeks,
        'start_date': startDate,
        'positions': positions,
      };
}
