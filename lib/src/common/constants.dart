class AppConstants {
  static const String appName = 'RestoReserve';
  static const int maxReservationDays = 90;
  static const List<String> tableLocations = ['indoor', 'outdoor'];
  static const List<String> reservationStatuses = [
    'pending',
    'approved',
    'rejected',
    'canceled_by_user',
    'canceled_by_admin'
  ];
}