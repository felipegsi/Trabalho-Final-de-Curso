package com.project.uber.model;

import com.fasterxml.jackson.annotation.JsonManagedReference;
import com.project.uber.enums.Category;
import com.project.uber.enums.OrderStatus;
import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;

@Entity
@Data
@Table(name = "orders")
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 150)
    private String origin;

    @Column(nullable = false, length = 150)
    private String destination;

    @Column(nullable = false)
    private BigDecimal value;

    @Enumerated(EnumType.STRING)
    private OrderStatus status;

    @Column(nullable = false, updatable = false)
    @CreationTimestamp
    private LocalDate date;

    @Column(nullable = false, updatable = false)
    @CreationTimestamp
    private LocalTime time;

    @Column(nullable = true, length = 500)
    private String description;

    @Column(nullable = true, length = 1000)
    private String feedback;

    @JsonManagedReference
    @ManyToOne
    @JoinColumn(name = "client_id")
    private Client client;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Category category;

    @ManyToOne
    @JoinColumn(name = "driver_id")
    private Driver driver;

    // Campos específicos para objetos
    @Column(nullable = true)
    private Integer width;

    @Column(nullable = true)
    private Integer height;

    @Column(nullable = true)
    private Integer length;

    @Column(nullable = true)
    private Float weight;

    // Campos específicos para carros
    @Column(nullable = true, length = 10)
    private String licensePlate;

    @Column(nullable = true, length = 50)
    private String model;

    @Column(nullable = true, length = 50)
    private String brand;

    // Construtor principal
    public Order(String origin, String destination, BigDecimal value, OrderStatus status,
                 String description, String feedback, Category category, Client client,
                 LocalDate date, LocalTime time, Driver driver,
                 Integer width, Integer height, Integer length, Float weight,
                 String licensePlate, String model, String brand) {
        this.origin = origin;
        this.destination = destination;
        this.value = value;
        this.status = status;
        this.description = description;
        this.feedback = feedback;
        this.category = category;
        this.client = client;
        this.date = date;
        this.time = time;
        this.driver = driver;
        this.width = width;
        this.height = height;
        this.length = length;
        this.weight = weight;
        this.licensePlate = licensePlate;
        this.model = model;
        this.brand = brand;
    }

    // Construtor vazio para JPA
    public Order() {
    }

    // Construtor para pedidos de objetos
    public Order(String origin, String destination, BigDecimal value, OrderStatus status,
                 String description, Category category, Client client,
                 LocalDate date, LocalTime time, Integer width, Integer height,
                 Integer length, Float weight) {
        this(origin, destination, value, status, description, null, category, client, date, time, null,
                width, height, length, weight, null, null, null);
    }

    // Construtor para pedidos de carros
    public Order(String origin, String destination, BigDecimal value, OrderStatus status,
                 String description, Category category, Client client,
                 LocalDate date, LocalTime time, String licensePlate, String model, String brand) {
        this(origin, destination, value, status, description, null, category, client, date, time, null,
                null, null, null, null, licensePlate, model, brand);
    }
}
