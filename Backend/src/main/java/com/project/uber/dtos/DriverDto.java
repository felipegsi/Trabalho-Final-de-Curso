package com.project.uber.dtos;

import com.project.uber.model.Vehicle;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Getter
@Setter
public class DriverDto {
    private Long id;
    private String name;
    private String email;
    private String birthdate;
    private String phoneNumber;
    private int taxPayerNumber;
    private String street;
    private String city;
    private String postalCode;
    private String location; // latitude e longitude
    private VehicleDto vehicleDto;

    public DriverDto(Long id, String name, String email, String birthdate,
                     String phoneNumber, Integer taxPayerNumber,
                     String street, String city, String postalCode, String location,
                     VehicleDto vehicleDto) {
        this.id = id;
        this.name = name;
        this.email = email;
        this.birthdate = birthdate;
        this.phoneNumber = phoneNumber;
        this.taxPayerNumber = taxPayerNumber;
        this.street = street;
        this.city = city;
        this.postalCode = postalCode;
        this.location = location;
        this.vehicleDto = vehicleDto;
    }

    // Método estático de fábrica que aceita um Vehicle e constrói um VehicleDto

}
