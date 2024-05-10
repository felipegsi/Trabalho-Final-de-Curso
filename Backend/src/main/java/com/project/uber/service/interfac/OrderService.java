package com.project.uber.service.interfac;

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

    List<BigDecimal> estimateAllCategoryOrderCost(String origin, String destination);

    // funçao que devolve uma lista de motoristas proximos a uma determinada localizaçao
    List<Driver> findAvailableDrivers(String location);

    public Order saveOrder(OrderDto orderDto, Long clientId);

    public List<Order> getClientOrderHistory(Long clientId);

    Boolean acceptOrder(Long orderId, Long driverId) throws BusinessException;

    @Transactional
    void confirmPickUp(Long orderId, Long driverId) throws Exception;

    @Transactional
    void updateOrderStatus(Long orderId, OrderStatus newStatus, Long driverId) throws Exception;

    List<OrderDto> getDriverOrderHistory(Long driverId);


    BigDecimal estimateOrderCost(String origin, String destination, Category category,
                                 int width, int height, int length, float weight) throws BusinessException;

    Driver assignOrderToDriver(Long orderId);
}
