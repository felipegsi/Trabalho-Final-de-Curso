package com.project.uber.service.interfac;

import com.project.uber.dtos.ClientDto;
import com.project.uber.dtos.DriverDto;
import com.project.uber.dtos.OrderDto;
import com.project.uber.infra.exceptions.BusinessException;
import com.project.uber.model.Client;
import com.project.uber.model.Driver;
import com.project.uber.model.Order;

import java.util.List;

public interface DriverService {

    DriverDto saveDriver(DriverDto driverDto);

    void acceptOrder(Long orderId, Long driverId, String driverEmail) throws BusinessException;

    void deleteDriver(Long driverId);
    void setDriverOnlineStatus(Long driverId, boolean isOnline) throws Exception;

    Driver getDriverById(Long driverId);

    Driver getDriverByEmail(String email);

    DriverDto viewProfile(Long driverId);

    DriverDto editProfile(Long driverId, DriverDto driverDto);

    void changePassword(Long clientId, String oldPassword, String newPassword);

    List<DriverDto> findAvailableDrivers();

    Driver selectDriverForOrder(Order order, List<Driver> availableDrivers);

    void updateDriverLocationAndStatus(Long driverId, String location, boolean isOnline);
}
