import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Adicione a dependência 'intl' ao seu pubspec.yaml
import 'package:provider/provider.dart';
import '../../../api/auth_api.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _taxPayerNumberController = TextEditingController();
  final TextEditingController _vehicleYearController = TextEditingController();
  final TextEditingController _vehiclePlateController = TextEditingController();
  final TextEditingController _vehicleBrandController = TextEditingController();
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();

  String? _selectedVehicleType = 'LIGHT';

  final List<String> _vehicleTypes = ['LIGHT', 'HEAVY', 'MOTORCYCLE', 'OTHER', 'TOW'];
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _birthdateController.dispose();
    _taxPayerNumberController.dispose();
    _vehicleYearController.dispose();
    _vehiclePlateController.dispose();
    _vehicleBrandController.dispose();
    _vehicleModelController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Widget _buildDateField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onTap: () => _selectDate(context, controller),
        child: AbsorbPointer(
          child: _buildTextField(
            controller: controller,
            label: label,
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      final String formattedDate = DateFormat('dd/MM/yyyy').format(pickedDate);
      controller.text = formattedDate;
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4.0),
          ),
          labelStyle: TextStyle(
            color: Colors.grey[800],
            fontSize: 16.0,
          ),
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.black, fontSize: 18.0),
      ),
    );
  }

  Widget _buildDropdownButton() {
    return DropdownButtonFormField<String>(
      value: _selectedVehicleType,
      onChanged: (String? newValue) {
        setState(() {
          _selectedVehicleType = newValue!;
        });
      },
      items: _vehicleTypes.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      decoration: InputDecoration(
        labelText: 'Tipo de Veículo',
        labelStyle: TextStyle(color: Colors.grey[800]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _attemptRegister(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    final Map<String, dynamic> registrationData = {
      'name': _nameController.text,
      'email': _emailController.text,
      'birthdate': _birthdateController.text,
      'password': _passwordController.text,
      'phoneNumber': _phoneNumberController.text,
      'taxPayerNumber': int.parse(_taxPayerNumberController.text),
      'street': _addressController.text,
      'city': _cityController.text,
      'postalCode': int.parse(_postalCodeController.text),
      'vehicleDto': {
        'year': int.parse(_vehicleYearController.text),
        'plate': _vehiclePlateController.text,
        'brand': _vehicleBrandController.text,
        'model': _vehicleModelController.text,
        'type': _selectedVehicleType,
        'capacity': double.tryParse(_capacityController.text) ?? 0,
      },
    };

    final authProvider = Provider.of<AuthApi>(context, listen: false);
    bool registrationSuccess = await authProvider.registerDriver(registrationData);

    setState(() {
      _isLoading = false;
    });

    if (registrationSuccess) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
            (Route<dynamic> route) => false,
      );
    } else {
      _showErrorDialog();
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: const Text('Failed to register. Please try again.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Registar Motorista', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Nome Completo',
              ),
              _buildDateField(
                context: context,
                controller: _birthdateController,
                label: 'Data de Nascimento',
              ),
              _buildTextField(
                controller: _emailController,
                label: 'E-mail',
                keyboardType: TextInputType.emailAddress,
              ),
              _buildTextField(
                controller: _passwordController,
                label: 'Senha',
                obscureText: true,
              ),
              _buildTextField(
                controller: _taxPayerNumberController,
                label: 'Número de Identificação Fiscal',
                keyboardType: TextInputType.number,
              ),
              _buildDropdownButton(),
              _buildTextField(
                controller: _phoneNumberController,
                label: 'Número de Telefone',
                keyboardType: TextInputType.phone,
              ),
              _buildTextField(
                controller: _addressController,
                label: 'Morada',
              ),
              _buildTextField(
                controller: _cityController,
                label: 'Cidade',
              ),
              _buildTextField(
                controller: _postalCodeController,
                label: 'Código Postal',
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                controller: _vehicleYearController,
                label: 'Ano do Veículo',
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                controller: _vehiclePlateController,
                label: 'Placa do Veículo',
              ),
              _buildTextField(
                controller: _vehicleBrandController,
                label: 'Marca do Veículo',
              ),
              _buildTextField(
                controller: _vehicleModelController,
                label: 'Modelo do Veículo',
              ),
              _buildTextField(
                controller: _capacityController,
                label: 'Capacidade do Veículo',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : () => _attemptRegister(context),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
                    : const Text('Finalizar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
