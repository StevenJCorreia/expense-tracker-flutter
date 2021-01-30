class Category {
  int id;
  String name;

  Category() {
    this.id = 0;
    this.name = '';
  }

  String toString() {
    return 'id: $id, name; "$name"';
  }

  factory Category.fromJSON(Map<String, dynamic> json) => Category.builder(
    id: json['id'],
    name: json['name'],
  );

  Category.builder({this.id, this.name});
}