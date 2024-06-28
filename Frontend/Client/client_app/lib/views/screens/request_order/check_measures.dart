import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'order_cost_screen.dart';

class CheckMeasures extends StatefulWidget {
  final LatLng origin;
  final LatLng destination;

  const CheckMeasures({super.key, required this.origin, required this.destination});

  @override
  _CheckMeasuresState createState() => _CheckMeasuresState();
}

class _CheckMeasuresState extends State<CheckMeasures> {
  final _formKey = GlobalKey<FormState>();
  String _categoryType = 'Small';
  final Map<String, TextEditingController> _attributes = {};

  Map<String, Map<String, double>> categoryLimits = {
    'Small': {'width': 40, 'height': 40, 'length': 40, 'weight': 10},
    'Medium': {'width': 100, 'height': 100, 'length': 100, 'weight': 30},
    'Large': {'width': 150, 'height': 150, 'length': 150, 'weight': 70},
    'Motorized': {},
  };

  @override
  void initState() {
    super.initState();
    _initializeAttributes();
  }

  void _initializeAttributes() {
    const fields = ['Weight', 'Length', 'Height', 'Width', 'Description'];
    for (var field in fields) {
      _attributes[field] = TextEditingController();
    }
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
        title: const Text('Check Measures', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDropdown(),
              const SizedBox(height: 20),
              ..._buildDynamicFields(),
              const SizedBox(height: 40),
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
      fields.add(_buildTextField(key, '$key (${key == 'Weight' ? 'kg' : 'cm'})', icon));
      fields.add(const SizedBox(height: 20));
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
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black87, width: 2.0),
        ),
      ),
      keyboardType: categoryLimits[_categoryType]!.containsKey(key.toLowerCase()) ? TextInputType.number : TextInputType.text,
      validator: (value) => _validateField(value, key.toLowerCase()),
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
      decoration: const InputDecoration(
        labelText: 'Category Type',
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black87, width: 2.0),
        ),
      ),
      onChanged: (newValue) {
        setState(() {
          _categoryType = newValue!;
          // Clear values when the category changes
          _attributes.forEach((key, controller) {
            controller.clear();
          });
        });
      },
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

            // Navega para OrderCostScreen passando os valores dos atributos
            Navigator.push(context, MaterialPageRoute(builder: (context) => OrderCostScreen(
              origin: LatLng(widget.origin.latitude, widget.origin.longitude),
              destination: LatLng(widget.destination.latitude, widget.destination.longitude),
              categoryType: _categoryType,
              attributes: attributeValues, // Passa os valores, não os controladores
            )));
          }
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
        ),
        child: const Text('Submit'),
      ),
    );
  }
}
