import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class CheckMeasures extends StatefulWidget {
  final LatLng origin;
  final LatLng destination;

  const CheckMeasures({Key? key, required this.origin, required this.destination}) : super(key: key);

  @override
  _CheckMeasuresState createState() => _CheckMeasuresState();
}

class _CheckMeasuresState extends State<CheckMeasures> {
  TextEditingController _plateController = TextEditingController();
  TextEditingController _modelController = TextEditingController();
  TextEditingController _brandController = TextEditingController();
  TextEditingController _weightController = TextEditingController();
  TextEditingController _lengthController = TextEditingController();
  TextEditingController _heightController = TextEditingController();
  TextEditingController _widthController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();

  String _categoryType = 'Small';

  final _formKey = GlobalKey<FormState>(); // Key for form validation

  Map<String, Map<String, double>> categoryLimits = {
    'Small': {'width': 60, 'height': 60, 'length': 60, 'weight': 10},
    'Medium': {'width': 120, 'height': 120, 'length': 120, 'weight': 50},
    'Large': {'width': 200, 'height': 200, 'length': 200, 'weight': 100},
    'Motorized': {}, // Assuming no numeric limits for Motorized category
  };

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
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildDropdown(),
              SizedBox(height: 20),
              ..._buildDynamicFields(),
              SizedBox(height: 20),
              _buildTextField(_descriptionController, 'Description', Icons.description_outlined, null),
              SizedBox(height: 40),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Submission Successful'),
                          content: Text('Your data has been submitted.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  child: Text('Submit'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.deepPurple,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical :20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDynamicFields() {
    List<Widget> fields = [];
    List<Map<String, dynamic>> fieldConfigs = [
      {'controller': _weightController, 'label': 'Weight (kg)', 'icon': Icons.monitor_weight, 'measure': 'weight'},
      {'controller': _lengthController, 'label': 'Length (cm)', 'icon': Icons.straighten, 'measure': 'length'},
      {'controller': _heightController, 'label': 'Height (cm)', 'icon': Icons.height, 'measure': 'height'},
      {'controller': _widthController, 'label': 'Width (cm)', 'icon': Icons.aspect_ratio, 'measure': 'width'}
    ];

    if (_categoryType == 'Motorized') {
      fieldConfigs = [
        {'controller': _plateController, 'label': 'Plate', 'icon': Icons.directions_car},
        {'controller': _modelController, 'label': 'Model', 'icon': Icons.build_circle},
        {'controller': _brandController, 'label': 'Brand', 'icon': Icons.business}
      ];
    }

    for (var config in fieldConfigs) {
      fields.add(_buildTextField(
          config['controller'],
          config['label'],
          config['icon'],
          config['measure']
      ));
      fields.add(SizedBox(height: 20));
    }

    return fields;
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, String? measure) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.deepPurpleAccent, width: 2.0),
        ),
      ),
      keyboardType: measure != null ? TextInputType.number : TextInputType.text,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        if (measure != null && categoryLimits[_categoryType]!.containsKey(measure)) {
          final numValue = double.tryParse(value);
          if (numValue == null) {
            return 'Please enter a valid number for $label';
          }
          if (numValue > categoryLimits[_categoryType]![measure]!) {
            return 'Max $measure for $_categoryType is ${categoryLimits[_categoryType]![measure]}';
          }
        }
        return null;
      },
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField(
      value: _categoryType,
      decoration: const InputDecoration(
        labelText: 'Category Type',
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.deepPurpleAccent, width: 2.0),
        ),
      ),
      onChanged: (String? newValue) {
        setState(() {
          _categoryType = newValue!;
        });
      },
      items: <String>['Small', 'Medium', 'Large', 'Motorized']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      validator: (value) {
        if (value == null) {
          return 'Please select a category';
        }
        return null;
      },
    );
  }
}

