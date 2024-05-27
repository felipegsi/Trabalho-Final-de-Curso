package com.project.uber.dtos;

import com.project.uber.model.Vehicle;

public record DriverDto(
        String name,
        String email,
        String birthdate,
        String phoneNumber,
        Integer taxPayerNumber,
        String street,
        String city,
        Integer postalCode,
        VehicleDto vehicleDto // Use a classe DTO para `Vehicle`
) {
    public DriverDto(String name, String email, String formattedBirthdate, String phoneNumber, Integer taxPayerNumber, String street, String city, Integer postalCode, Vehicle vehicle) {
        this(name, email, formattedBirthdate, phoneNumber, taxPayerNumber, street, city, postalCode, VehicleDto.fromVehicle(vehicle));
    }

    // Método estático de fábrica que aceita um Vehicle e constrói um VehicleDto

}
