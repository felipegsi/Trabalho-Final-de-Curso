package com.project.uber.service.interfac;

import com.project.uber.dtos.ClientDto;
import com.project.uber.dtos.DriverDto;
import com.project.uber.dtos.OrderDto;
import com.project.uber.dtos.TravelInformationDto;
import com.project.uber.infra.exceptions.BusinessException;
import com.project.uber.model.Client;
import com.project.uber.model.Driver;
import com.project.uber.model.Order;

import java.util.List;

public interface DriverService {
    DriverDto saveDriver(Driver driver);

    void deleteDriver(Long driverId);

    String getDriverLocation(Long driverId);

    TravelInformationDto getTravelInformation(Long driverId, Long orderId);

    double getDriverSalary(Long driverId);

    void setDriverOnlineStatus(Long driverId, boolean isOnline) throws Exception;

    Boolean checkDriverStatus(Long driverId);

    Driver getDriverById(Long driverId);

    Driver getDriverByEmail(String email);

    DriverDto viewProfile(Long driverId);

    List<OrderDto> getDriverOrderHistory(Long driverId);

    DriverDto editProfile(Long driverId, DriverDto driverDto);

    void changePassword(Long clientId, String oldPassword, String newPassword);

    void updateDriverLocationAndStatus(Long driverId, String location, boolean isOnline);
}
