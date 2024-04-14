package com.project.uber.model;

import com.fasterxml.jackson.annotation.JsonBackReference;
import com.project.uber.enums.VehicleType;
import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "vehicles")
@Data
public class Vehicle {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne
    @JsonBackReference
    @JoinColumn(name = "driver_id")
    private Driver driver;

    @Column(name = "year")
    private int year;

    @Column(name = "plate", length = 10, unique = true)
    private String plate;

    @Column(name = "brand", length = 50)
    private String brand;

    @Column(name = "model", length = 50)
    private String model;

    @Lob
    @Column(name = "document_photo")
    private byte[] documentPhoto;

    @Column(nullable = false)
    private Double capacity;

    @Enumerated(EnumType.STRING)
    private VehicleType vehicleType;

    public Vehicle(int year, String plate, String brand, String model, Object capacity) {
        this.year = year;
        this.plate = plate;
        this.brand = brand;
        this.model = model;
        this.capacity = (Double) capacity;
    }

    public Vehicle() {

    }
}
