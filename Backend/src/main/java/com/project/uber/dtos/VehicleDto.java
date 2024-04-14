package com.project.uber.dtos;

import lombok.Getter;
import lombok.Setter;

public class VehicleDto {
    // Getters and setters
    @Setter
    @Getter
    private int year;
    @Setter
    @Getter
    private String plate;
    @Getter
    private String brand;
    @Getter
    @Setter
    private String model;
    private byte[] documentPhoto;
    @Getter
    @Setter
    private Double capacity;

    // Default constructor
    public VehicleDto() {}

    // Constructor with all fields
    public VehicleDto(int year, String plate, String brand, String model, byte[] documentPhoto) {
        this.year = year;
        this.plate = plate;
        this.brand = brand;
        this.model = model;
        this.documentPhoto = documentPhoto;
    }

    public VehicleDto(int year, String brand, String plate, String model, Double capacity) {
        this.year = year;
        this.plate = plate;
        this.brand = brand;
        this.model = model;
        this.capacity = capacity;
    }

}
