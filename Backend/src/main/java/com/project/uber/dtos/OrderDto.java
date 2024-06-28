package com.project.uber.dtos;

import com.project.uber.enums.Category;
import com.project.uber.enums.OrderStatus;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
public class OrderDto {
    private Long id;
    private String origin;
    private String destination;
    private BigDecimal value;
    private OrderStatus status;
    private String description;
    private String feedback;
    private Category category;

    // Campos específicos para objetos
    private Integer width;
    private Integer height;
    private Integer length;
    private Float weight;

    // Campos específicos para carros
    private String licensePlate;
    private String model;
    private String brand;

    private ClientDto clientDto;
    private DriverDto driverDto;

    // Construtor vazio
    public OrderDto() {
    }

    // Construtor completo para ambos os tipos de pedidos
    public OrderDto(Long id, String origin, String destination, BigDecimal value, OrderStatus status,
                    String description, String feedback, Category category,
                    Integer width, Integer height, Integer length, Float weight,
                    String licensePlate, String model, String brand,
                    ClientDto clientDto, DriverDto driverDto) {
        this.id = id;
        this.origin = origin;
        this.destination = destination;
        this.value = value;
        this.status = status;
        this.description = description;
        this.feedback = feedback;
        this.category = category;
        this.width = width;
        this.height = height;
        this.length = length;
        this.weight = weight;
        this.licensePlate = licensePlate;
        this.model = model;
        this.brand = brand;
        this.clientDto = clientDto;
        this.driverDto = driverDto;
    }

    // Construtor para pedidos de objetos
    public OrderDto(String origin, String destination, BigDecimal value, OrderStatus status,
                    String description, Category category,
                    Integer width, Integer height, Integer length, Float weight,
                    ClientDto clientDto) {
        this(null, origin, destination, value, status, description, null, category,
                width, height, length, weight, null, null, null, clientDto, null);
    }

    // Construtor para pedidos de carros
    public OrderDto(String origin, String destination, BigDecimal value, OrderStatus status,
                    String description, Category category,
                    String licensePlate, String model, String brand,
                    ClientDto clientDto) {
        this(null, origin, destination, value, status, description, null, category,
                null, null, null, null, licensePlate, model, brand, clientDto, null);
    }
}
