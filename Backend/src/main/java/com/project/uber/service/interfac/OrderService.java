package com.project.uber.service.interfac;

import com.project.uber.dtos.OrderDto;
import com.project.uber.enums.OrderStatus;
import com.project.uber.infra.exceptions.BusinessException;
import com.project.uber.model.Order;
import jakarta.transaction.Transactional;

import java.math.BigDecimal;
import java.util.List;

public interface OrderService {

    BigDecimal estimateOrderCost(OrderDto orderDto);

    public Order saveOrder(OrderDto orderDto, Long clientId);

    public List<Order> getClientOrderHistory(Long clientId);

    void acceptOrder(Long orderId, Long driverId) throws BusinessException;

    @Transactional
    void confirmPickUp(Long orderId, Long driverId) throws Exception;

    @Transactional
    void updateOrderStatus(Long orderId, OrderStatus newStatus, Long driverId) throws Exception;

    List<OrderDto> getDriverOrderHistory(Long driverId);

    @Transactional// Garante que a operação seja realizada atomicamente
    OrderDto createAndAssignOrder(OrderDto orderDto, Long clientId) throws BusinessException;

    void assignDriverToOrder(Long orderId);
}
