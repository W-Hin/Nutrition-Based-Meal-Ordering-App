enum PaymentStatus { idle, loading, success, failed }

class PaymentModel {
  final String billName;
  final String billDescription;
  final double amount;
  final String userName;
  final String userPhone;
  final String userEmail;

  PaymentModel({
    required this.billName,
    required this.billDescription,
    required this.amount,
    required this.userName,
    required this.userPhone,
    required this.userEmail,
  });
}