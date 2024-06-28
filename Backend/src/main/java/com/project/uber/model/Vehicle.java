package com.project.uber.model;

import com.fasterxml.jackson.annotation.JsonBackReference;
import com.project.uber.enums.Category;
import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "vehicles")
@Data
public class Vehicle {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(mappedBy = "vehicle")
    @JsonBackReference
    private Driver driver;

    @Column(name = "year")
    private int year;

    @Column(name = "plate", length = 10, unique = true)
    private String plate;

    @Column(name = "brand", length = 50)
    private String brand;

    @Column(name = "model", length = 50)
    private String model;

    //@Lob
    //@Column(name = "document_photo")
  //  private byte[] documentPhoto;

//    @Column(nullable = false)
//    private Double capacity;

    @Enumerated(EnumType.STRING)
    private Category category;
    public Vehicle(Category category, int year, String plate, String brand, String model) {
        this.category = category;
        this.year = year;
        this.plate = plate;
        this.brand = brand;
        this.model = model;
      //  this.capacity = capacity;
    }

    public Vehicle() {

    }
}
