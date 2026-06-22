// No PART file to avoid build_runner dependency issues in this environment
// Implementing manual fromJson/toJson for immediate stability

class BillingResponseData {
  final CurrentSubscriptionModel? currentSubscription;
  final List<PaymentMethodModel>? paymentMethods;
  final List<BillingHistoryModel>? billingHistory;

  BillingResponseData({
    this.currentSubscription,
    this.paymentMethods,
    this.billingHistory,
  });

  factory BillingResponseData.fromJson(Map<String, dynamic> json) {
    return BillingResponseData(
      currentSubscription: json['currentSubscription'] is Map<String, dynamic>
          ? CurrentSubscriptionModel.fromJson(json['currentSubscription'] as Map<String, dynamic>)
          : null,
      paymentMethods: json['paymentMethods'] is List
          ? (json['paymentMethods'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => PaymentMethodModel.fromJson(e))
              .toList()
          : null,
      billingHistory: json['billingHistory'] is List
          ? (json['billingHistory'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => BillingHistoryModel.fromJson(e))
              .toList()
          : null,
    );
  }
}

class CurrentSubscriptionModel {
  final String? programName;
  final num? price;
  final String? frequency;
  final String? status;
  final String? renewalDate;
  final String? startDate;

  CurrentSubscriptionModel({
    this.programName,
    this.price,
    this.frequency,
    this.status,
    this.renewalDate,
    this.startDate,
  });

  factory CurrentSubscriptionModel.fromJson(Map<String, dynamic> json) {
    num? parseNum(dynamic val) {
      if (val is num) return val;
      if (val is String) return num.tryParse(val);
      return null;
    }
    return CurrentSubscriptionModel(
      programName: json['programName']?.toString(),
      price: parseNum(json['price']),
      frequency: json['frequency']?.toString(),
      status: json['status']?.toString(),
      renewalDate: json['renewalDate']?.toString(),
      startDate: json['startDate']?.toString(),
    );
  }
}

class PaymentMethodModel {
  final String? brand;
  final String? lastFour;
  final String? expiry;
  final bool? isPrimary;

  PaymentMethodModel({this.brand, this.lastFour, this.expiry, this.isPrimary});

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      brand: json['brand']?.toString(),
      lastFour: json['lastFour']?.toString(),
      expiry: json['expiry']?.toString(),
      isPrimary: json['isPrimary'] is bool 
          ? json['isPrimary'] as bool 
          : (json['isPrimary'] != null ? json['isPrimary'].toString().toLowerCase() == 'true' : null),
    );
  }
}

class BillingHistoryModel {
  final String? id;
  final String? description;
  final String? date;
  final num? amount;
  final String? currency;
  final String? status;
  final String? receiptNumber;

  BillingHistoryModel({
    this.id,
    this.description,
    this.date,
    this.amount,
    this.currency,
    this.status,
    this.receiptNumber,
  });

  factory BillingHistoryModel.fromJson(Map<String, dynamic> json) {
    num? parseNum(dynamic val) {
      if (val is num) return val;
      if (val is String) return num.tryParse(val);
      return null;
    }
    return BillingHistoryModel(
      id: json['id']?.toString(),
      description: json['description']?.toString(),
      date: json['date']?.toString(),
      amount: parseNum(json['amount']),
      currency: json['currency']?.toString(),
      status: json['status']?.toString(),
      receiptNumber: json['receiptNumber']?.toString(),
    );
  }
}
