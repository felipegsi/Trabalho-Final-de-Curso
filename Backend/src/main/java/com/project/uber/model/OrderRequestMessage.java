package com.project.uber.model;

public class OrderRequestMessage {

    private Long orderId;
    private String message;

    public OrderRequestMessage(Long orderId, String message) {
        this.orderId = orderId;
        this.message = message;
    }

    // Getters e Setters
    public Long getOrderId() {
        return orderId;
    }

    public void setOrderId(Long orderId) {
        this.orderId = orderId;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }
}