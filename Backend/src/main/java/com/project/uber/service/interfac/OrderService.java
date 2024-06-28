package com.project.uber.service.interfac;

import com.project.uber.dtos.DriverDto;
import com.project.uber.dtos.OrderDto;
import com.project.uber.enums.Category;
import com.project.uber.enums.OrderStatus;
import com.project.uber.infra.exceptions.BusinessException;
import com.project.uber.model.Driver;
import com.project.uber.model.Order;
import jakarta.transaction.Transactional;

import java.math.BigDecimal;
import java.util.List;

public interface OrderService {

    public OrderDto saveOrder(OrderDto orderDto, Long clientId);

    OrderDto getOrderDtoById(Long orderId) throws BusinessException;

    @Transactional
    void confirmPickUp(Long orderId, Long driverId) throws Exception;


    BigDecimal estimateOrderCost(String origin, String destination, Category category,
                                 Integer width, Integer height, Integer length, Float weight) throws BusinessException ;

    DriverDto assignOrderToDriver(Long orderId);

    // Updates the status of an order to a new specified status, ensuring valid state transitions.
    @Transactional
    void pickupOrderStatus(Long orderId) throws Exception;

    @Transactional
    void deliverOrderStatus(Long orderId, Long driverId) throws Exception;

    @Transactional
    void cancelledOrderStatus(Long orderId, Long driverId) throws Exception;
}