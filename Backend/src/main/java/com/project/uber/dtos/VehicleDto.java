package com.project.uber.dtos;

import com.project.uber.enums.Category;
import com.project.uber.enums.VehicleType;
import com.project.uber.model.Vehicle;
import lombok.Getter;
import lombok.Setter;
@Setter
@Getter
public class VehicleDto {
    // Getters and setters

    private int year;
    private String plate;
    private String brand;
    private String model;
    // private byte[] documentPhoto;
    // private Double capacity;
    private Category category;


    // Default constructor
    public VehicleDto() {}

    // Constructor with all fields
    public VehicleDto(Category category, int year, String plate, String brand, String model) {
        this.category = category;
        this.year = year;
        this.plate = plate;
        this.brand = brand;
        this.model = model;
    //  this.capacity = capacity;
    }




}
