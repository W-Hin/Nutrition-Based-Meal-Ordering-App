enum AddressLabel { home, work, others }

class AddressModel {
  String name;
  String phone;
  String address;
  AddressLabel? label;
  String customLabelName;

  AddressModel({
    this.name = 'Ali',
    this.phone = '012-345 6789',
    this.address = 'A-B-C, Jalan Roti Bakar 6, Taman 7, 11200 Bayan Fah...',
    this.label,
    this.customLabelName = '',
  });
}