class ViewingRequest {
  final String propertyTitle;
  final String propertyAddress;
  final String room;
  final String date;
  final String time;
  final String status;

  const ViewingRequest({
    required this.propertyTitle,
    required this.propertyAddress,
    required this.room,
    required this.date,
    required this.time,
    required this.status,
  });
}
