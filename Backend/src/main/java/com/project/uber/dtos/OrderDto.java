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
    private BigDecimal estimatedCost;
    private OrderStatus status;
    private String destination;
    private String description;
    private String feedback;
    private Category category;
    private int width;
    private int height;
    private int length;
    private float weight;//peso


    public OrderDto() {
    }

    public OrderDto(String origin, String destination, String description, String feedback, Category category) {
        this.origin = origin;
        this.destination = destination;
        this.description = description;
        this.feedback = feedback;
        this.category = category;
    }
}
