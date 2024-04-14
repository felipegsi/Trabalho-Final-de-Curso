package com.project.uber.dtos;

import com.project.uber.model.Vehicle;

import java.time.LocalDate;

public record DriverDto(String name,
                        String email,
                        String birthdate,
                        String password,
                        String phoneNumber,
                        int taxPayerNumber,
                        String street,
                        String city,
                        int postalCode,

                        // byte[] criminalRecord evitar essa complexidade agora
                        Vehicle vehicleDto

) {
    public DriverDto(String name, String email, String birthdate,  String phoneNumber, int taxPayerNumber, String street, String city, int postalCode, VehicleDto vehicleDto) {
        this(name, email, birthdate, phoneNumber, taxPayerNumber, street, city, postalCode, new Vehicle(vehicleDto.getYear(), vehicleDto.getPlate(), vehicleDto.getBrand(), vehicleDto.getModel(), vehicleDto.getCapacity()));
    }

    public DriverDto(String name, String email, String birthdate, String phoneNumber, int taxPayerNumber, String street, String city, int postalCode, Vehicle vehicle) {
        this(name, email, birthdate, null, phoneNumber, taxPayerNumber, street, city, postalCode, vehicle);
    }

}
