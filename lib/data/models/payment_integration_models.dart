
import 'package:json_annotation/json_annotation.dart';

// No PART file to avoid build_runner dependency issues in this environment
// Implementing manual fromJson/toJson for immediate stability

/// Response for Get User Subscription (Payway + Local)
class SubscriptionPaywayDetails {
  final PaywaySchedule? paywaySchedule;
  final LocalSubscription? localSubscription;

  SubscriptionPaywayDetails({
    this.paywaySchedule,
    this.localSubscription,
  });

  factory SubscriptionPaywayDetails.fromJson(Map<String, dynamic> json) {
    return SubscriptionPaywayDetails(
      paywaySchedule: json['paywaySchedule'] is Map<String, dynamic>
          ? PaywaySchedule.fromJson(json['paywaySchedule'] as Map<String, dynamic>)
          : null,
      localSubscription: json['localSubscription'] is Map<String, dynamic>
          ? LocalSubscription.fromJson(json['localSubscription'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PaywaySchedule {
  final String? frequency;
  final String? nextPaymentDate;
  final int? numberOfPaymentsRemaining;
  final num? nextPaymentAmount;
  final num? regularPaymentAmount;
  final num? finalPaymentAmount;

  PaywaySchedule({
    this.frequency,
    this.nextPaymentDate,
    this.numberOfPaymentsRemaining,
    this.nextPaymentAmount,
    this.regularPaymentAmount,
    this.finalPaymentAmount,
  });

  factory PaywaySchedule.fromJson(Map<String, dynamic> json) {
    num? parseNum(dynamic val) {
      if (val is num) return val;
      if (val is String) return num.tryParse(val);
      return null;
    }
    int? parseInt(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val);
      return null;
    }
    return PaywaySchedule(
      frequency: json['frequency']?.toString(),
      nextPaymentDate: json['nextPaymentDate']?.toString(),
      numberOfPaymentsRemaining: parseInt(json['numberOfPaymentsRemaining']),
      nextPaymentAmount: parseNum(json['nextPaymentAmount']),
      regularPaymentAmount: parseNum(json['regularPaymentAmount']),
      finalPaymentAmount: parseNum(json['finalPaymentAmount']),
    );
  }
}

class LocalSubscription {
  final String? id;
  final String? status;
  final String? startDate;
  final String? endDate;

  LocalSubscription({
    this.id,
    this.status,
    this.startDate,
    this.endDate,
  });

  factory LocalSubscription.fromJson(Map<String, dynamic> json) {
    return LocalSubscription(
      id: json['id']?.toString(),
      status: json['status']?.toString(),
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
    );
  }
}

/// Response for Get Saved Cards (Payment Customer)
class PaymentCustomerDetails {
  final String? customerNumber;
  final PaymentSetup? paymentSetup;
  final CreditCardDetails? creditCard; // Can be null if in paymentSetup

  PaymentCustomerDetails({
    this.customerNumber,
    this.paymentSetup,
    this.creditCard,
  });

  factory PaymentCustomerDetails.fromJson(Map<String, dynamic> json) {
    return PaymentCustomerDetails(
      customerNumber: json['customerNumber']?.toString(),
      paymentSetup: json['paymentSetup'] is Map<String, dynamic>
          ? PaymentSetup.fromJson(json['paymentSetup'] as Map<String, dynamic>)
          : null,
      creditCard: json['creditCard'] is Map<String, dynamic>
          ? CreditCardDetails.fromJson(json['creditCard'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PaymentSetup {
  final String? paymentMethod;
  final bool? stopped;
  final CreditCardDetails? creditCard;
  final MerchantDetails? merchant;

  PaymentSetup({
    this.paymentMethod,
    this.stopped,
    this.creditCard,
    this.merchant,
  });

  factory PaymentSetup.fromJson(Map<String, dynamic> json) {
    return PaymentSetup(
      paymentMethod: json['paymentMethod']?.toString(),
      stopped: json['stopped'] is bool 
          ? json['stopped'] as bool 
          : (json['stopped'] != null ? json['stopped'].toString().toLowerCase() == 'true' : null),
      creditCard: json['creditCard'] is Map<String, dynamic>
          ? CreditCardDetails.fromJson(json['creditCard'] as Map<String, dynamic>)
          : null,
      merchant: json['merchant'] is Map<String, dynamic>
          ? MerchantDetails.fromJson(json['merchant'] as Map<String, dynamic>)
          : null,
    );
  }
}

class CreditCardDetails {
  final String? cardNumber; // Often masked
  final String? expiryDateMonth;
  final String? expiryDateYear;
  final String? cardScheme;
  final String? cardType;
  final String? cardholderName;
  final String? panType;

  // Sometimes returned as 'maskedNumber' in save-card response
  final String? maskedNumber;

  CreditCardDetails({
    this.cardNumber,
    this.expiryDateMonth,
    this.expiryDateYear,
    this.cardScheme,
    this.cardType,
    this.cardholderName,
    this.panType,
    this.maskedNumber,
  });

  factory CreditCardDetails.fromJson(Map<String, dynamic> json) {
    return CreditCardDetails(
      cardNumber: json['cardNumber']?.toString(),
      expiryDateMonth: json['expiryDateMonth']?.toString(),
      expiryDateYear: json['expiryDateYear']?.toString(),
      cardScheme: json['cardScheme']?.toString(),
      cardType: json['cardType']?.toString(),
      cardholderName: json['cardholderName']?.toString(),
      panType: json['panType']?.toString(),
      maskedNumber: json['maskedNumber']?.toString(),
    );
  }
}

class MerchantDetails {
  final String? merchantId;
  final String? merchantName;

  MerchantDetails({
    this.merchantId,
    this.merchantName,
  });

  factory MerchantDetails.fromJson(Map<String, dynamic> json) {
    return MerchantDetails(
      merchantId: json['merchantId']?.toString(),
      merchantName: json['merchantName']?.toString(),
    );
  }
}

/// Response for Tokenize Card
class SingleUseTokenResponse {
  final String singleUseTokenId;

  SingleUseTokenResponse({required this.singleUseTokenId});

  factory SingleUseTokenResponse.fromJson(Map<String, dynamic> json) {
    return SingleUseTokenResponse(
      singleUseTokenId: json['singleUseTokenId']?.toString() ?? '',
    );
  }
}

/// Response for Save Card
class SaveCardResponse {
  final CreditCardDetails? creditCard;
  final String? message;

  SaveCardResponse({
    this.creditCard,
    this.message,
  });

  factory SaveCardResponse.fromJson(Map<String, dynamic> json) {
    return SaveCardResponse(
      creditCard: json['creditCard'] is Map<String, dynamic>
          ? CreditCardDetails.fromJson(json['creditCard'] as Map<String, dynamic>)
          : null,
      message: json['message']?.toString(),
    );
  }
}
