package com.project.uber.dtos;

public record RegistrationDto(
        String name,
        String email,
        String birthdate,
        String phoneNumber,
        Integer taxPayerNumber,  // Mudado de int para Integer
        String street,
        String city,
        Integer postalCode,
        VehicleDto vehicleDto,
        String password
) {}
