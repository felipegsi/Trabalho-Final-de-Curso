package com.project.uber.dtos;

import com.project.uber.enums.VehicleType;
import com.project.uber.model.Vehicle;
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
    @Getter
    @Setter
    private VehicleType vehicleType;


    // Default constructor
    public VehicleDto() {}

    // Constructor with all fields
    public VehicleDto(String vehicleType, int year, String plate, String brand, String model, Double capacity) {
        this.vehicleType = VehicleType.valueOf(vehicleType);
        this.year = year;
        this.plate = plate;
        this.brand = brand;
        this.model = model;
        this.capacity = capacity;
    }

    public static VehicleDto fromVehicle(Vehicle vehicle) {
        return new VehicleDto(
                String.valueOf(vehicle.getVehicleType()),
                vehicle.getYear(),
                vehicle.getPlate(),
                vehicle.getBrand(),
                vehicle.getModel(),
                vehicle.getCapacity()
        );
    }


}
