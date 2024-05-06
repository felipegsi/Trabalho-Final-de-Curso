import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:teste_2/views/screens/request_order/route_map_screen.dart';

class CheckMeasures extends StatefulWidget {
  final LatLng origin;
  final LatLng destination;

  const CheckMeasures({Key? key, required this.origin, required this.destination}) : super(key: key);

  @override
  _CheckMeasuresState createState() => _CheckMeasuresState();
}

class _CheckMeasuresState extends State<CheckMeasures> {
  final _formKey = GlobalKey<FormState>();
  String _categoryType = 'Small';
  Map<String, TextEditingController> _attributes = {};

  Map<String, Map<String, double>> categoryLimits = {
    'Small': {'width': 60, 'height': 60, 'length': 60, 'weight': 10},
    'Medium': {'width': 120, 'height': 120, 'length': 120, 'weight': 50},
    'Large': {'width': 200, 'height': 200, 'length': 200, 'weight': 100},
    'Motorized': {},
  };

  @override
  void initState() {
    super.initState();
    _initializeAttributes();
  }

  void _initializeAttributes() {
    const fields = ['Plate', 'Model', 'Brand', 'Weight', 'Length', 'Height', 'Width', 'Description'];
    fields.forEach((field) => _attributes[field] = TextEditingController());
  }

  @override
  void dispose() {
    _attributes.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Check Measures', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDropdown(),
              SizedBox(height: 20),
              ..._buildDynamicFields(),
              SizedBox(height: 40),
              _submitButton(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDynamicFields() {
    var configs = _categoryType == 'Motorized'
        ? {'Plate': Icons.directions_car, 'Model': Icons.build_circle, 'Brand': Icons.business}
        : {'Weight': Icons.monitor_weight, 'Length': Icons.straighten, 'Height': Icons.height, 'Width': Icons.aspect_ratio};

    List<Widget> fields = [];
    configs.forEach((key, icon) {
      fields.add(_buildTextField(key, '${key} (${key == 'Weight' ? 'kg' : 'cm'})', icon));
      fields.add(SizedBox(height: 20));
    });

    fields.add(_buildTextField('Description', 'Description', Icons.description_outlined));
    return fields;
  }

  Widget _buildTextField(String key, String label, IconData icon) {
    return TextFormField(
      controller: _attributes[key],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.deepPurpleAccent, width: 2.0),
        ),
      ),
      keyboardType: categoryLimits[_categoryType]!.containsKey(key) ? TextInputType.number : TextInputType.text,
      validator: (value) => _validateField(value, key),
    );
  }

  String? _validateField(String? value, String key) {
    if (value == null || value.isEmpty) return 'Please enter $key';
    if (!categoryLimits[_categoryType]!.containsKey(key)) return null;
    final numValue = double.tryParse(value);
    if (numValue == null) return 'Please enter a valid number for $key';
    if (numValue > categoryLimits[_categoryType]![key]!) return 'Max $key for $_categoryType is ${categoryLimits[_categoryType]![key]}';
    return null;
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _categoryType,
      decoration: InputDecoration(
        labelText: 'Category Type',
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.deepPurpleAccent, width: 2.0),
        ),
      ),
      onChanged: (newValue) => setState(() => _categoryType = newValue!),
      items: ['Small', 'Medium', 'Large', 'Motorized']
          .map((value) => DropdownMenuItem<String>(value: value, child: Text(value)))
          .toList(),
      validator: (value) => value == null ? 'Please select a category' : null,
    );
  }

  Widget _submitButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            // Cria um mapa de atributos que contém apenas os valores dos campos de texto
            Map<String, dynamic> attributeValues = {};
            _attributes.forEach((key, controller) {
              attributeValues[key] = controller.text; // Use o texto do controlador, não o controlador
            });

            // Navega para RouteMapScreen passando os valores dos atributos
            Navigator.push(context, MaterialPageRoute(builder: (context) => RouteMapScreen(
              origin: widget.origin,
              destination: widget.destination,
              categoryType: _categoryType,
              attributes: attributeValues, // Passa os valores, não os controladores
            )));
          }
        },
        child: Text('Submit'),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.deepPurple,
          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
        ),
      ),
    );
  }

}
