enum RentalPropertyType {
  room('room', 'Quarto'),
  house('house', 'Casa'),
  apartment('apartment', 'Apartamento'),
  studio('studio', 'Studio/Kitnet'),
  loft('loft', 'Loft'),
  building('building', 'Prédio/Edifício'),
  commercialRoom('commercial_room', 'Sala comercial'),
  office('office', 'Escritório'),
  warehouse('warehouse', 'Galpão'),
  store('store', 'Loja'),
  chalet('chalet', 'Chalé'),
  farm('farm', 'Sítio/Chácara'),
  land('land', 'Terreno'),
  parkingSpace('parking_space', 'Vaga/Garagem'),
  hostelBed('hostel_bed', 'Leito (Hostel)'),
  hotelRoom('hotel_room', 'Quarto (Hotel)'),
  other('other', 'Outro');

  const RentalPropertyType(this.value, this.label);
  final String value;
  final String label;

  static RentalPropertyType fromValue(String value) {
    return RentalPropertyType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => RentalPropertyType.other,
    );
  }
}
