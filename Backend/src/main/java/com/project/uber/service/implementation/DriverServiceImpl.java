package com.project.uber.service.implementation;

import com.project.uber.dtos.*;
import com.project.uber.enums.Category;
import com.project.uber.infra.exceptions.BusinessException;
import com.project.uber.model.Client;
import com.project.uber.model.Driver;
import com.project.uber.model.Order;
import com.project.uber.repository.DriverRepository;
import com.project.uber.repository.OrderRepository;
import com.project.uber.repository.VehicleRepository;
import com.project.uber.service.interfac.DriverService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import com.project.uber.model.Vehicle;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Service // Marks the class as a Spring service.
public class DriverServiceImpl implements DriverService {

    // Autowired's annotations to inject repository and encoder dependencies.
    @Autowired
    private DriverRepository driverRepository;
    @Autowired
    private PasswordEncoder passwordEncoder;
    @Autowired
    private VehicleRepository vehicleRepository;
    @Autowired
    private OrderRepository orderRepository;

    @Transactional //para garantir que as duas operações sejam executadas ou nenhuma
    public DriverDto saveDriver(Driver driver) {
        // Checks if a driver with the same email already exists.
        verifyDriverUniqueAttributes(driver.getEmail(), driver.getPhoneNumber(), driver.getTaxPayerNumber());
        // Checks if a vehicle with the same plate already exists.
        verifyVehicleUniqueAttributes(driver.getVehicle().getPlate());
        // Criptografa a senha
        String encryptedPassword = passwordEncoder.encode(driver.getPassword());
        // inicializa salary
        double salary = 0;

        // Cria uma nova entidade Driver
        Driver newDriver = new Driver(driver.getName(), driver.getEmail(), encryptedPassword,
                driver.getBirthdate(), driver.getPhoneNumber(), driver.getTaxPayerNumber(),
                driver.getStreet(), driver.getCity(), driver.getPostalCode(),
                salary, driver.getVehicle(), driver.getLocation());

        // Salva o driver no banco de dados
        driverRepository.save(newDriver);

        // Retorna um novo DriverDto
        return convertToDriverDto(newDriver);
    }

    private void verifyDriverUniqueAttributes(String email, String phoneNumber, int taxPayerNumber) {
        Driver driverWithSameEmail = driverRepository.findByEmail(email);
        Driver driverWithSamePhoneNumber = driverRepository.findByPhoneNumber(phoneNumber);
        Driver driverWithSameTaxPayerNumber = driverRepository.findByTaxPayerNumber(taxPayerNumber);
        if (driverWithSameEmail != null || driverWithSamePhoneNumber != null ||
                driverWithSameTaxPayerNumber != null ) {
            throw new BusinessException("Driver already exists!");
        }
    }

    private void verifyVehicleUniqueAttributes(String plate ) {
        Vehicle vehicle = vehicleRepository.findByPlate(plate);
        if (vehicle != null) {
            throw new BusinessException("Vehicle already exists!");
        }
    }

    @Override
    public String getDriverLocation(Long driverId) {
        Driver driver = driverRepository.findById(driverId).orElseThrow(() -> new BusinessException("Driver not found."));
        return driver.getLocation();
    }

    @Override
    public TravelInformationDto getTravelInformation(Long driverId, Long orderId) {
        Driver driver = driverRepository.findById(driverId).orElseThrow(() -> new BusinessException("Driver not found."));
        Order order = orderRepository.findById(orderId).orElseThrow(() -> new BusinessException("Order not found."));

        return new TravelInformationDto(driver.getLocation(), order.getStatus().toString());

    }

    @Override
    public double getDriverSalary(Long driverId) {
        Driver driver = driverRepository.findById(driverId).orElseThrow(() -> new BusinessException("Driver not found."));
        return driver.getSalary();
    }

        // Changes the online status of a driver.
    @Override
    public void setDriverOnlineStatus(Long driverId, boolean isOnline) throws Exception {
        Driver driver = driverRepository.findById(driverId).orElseThrow(() -> new Exception("Driver not found."));
        driver.setIsOnline(isOnline);
        driverRepository.save(driver);
    }

    // Deletes a driver from the repository.
    @Override
    public void deleteDriver(Long driverId) {
        driverRepository.deleteById(driverId);
    }

    @Override
    public Boolean checkDriverStatus(Long driverId) {
        Driver driver = driverRepository.findById(driverId).orElseThrow(() -> new BusinessException("Driver not found."));
        return driver.getIsOnline();
    }
    // Retrieves a driver by ID, throwing an exception if not found.
    @Override
    public Driver getDriverById(Long driverId) {
        return driverRepository.findById(driverId).orElseThrow(() -> new BusinessException("Driver not found"));
    }

    // Retrieves a driver by email, throwing an exception if not found.
    @Override
    public Driver getDriverByEmail(String email) {
        Driver driver = driverRepository.findByEmail(email);
        if (driver == null) {
            throw new BusinessException("Driver not found");
        }
        return driver;
    }

    // Views the profile of a driver using their ID.
    @Override
    public DriverDto viewProfile(Long driverId) {
        Driver driver = getDriverById(driverId);
        return convertToDriverDto(driver);
    }

    @Override
    public List<OrderDto> getDriverOrderHistory(Long driverId) {
        // converter a lista de Order para OrderDto
        List<Order> orders = orderRepository.findByDriverId(driverId);
        List<OrderDto> orderDtos = new ArrayList<>();
        for (Order order : orders) {
            orderDtos.add(convertToFullOrderDto(order));
        }
        return orderDtos;
    }


    public OrderDto convertToFullOrderDto(Order order) {
        if (order.getCategory() == Category.MOTORIZED) {
            return new OrderDto(order.getId(), order.getOrigin(), order.getDestination(), order.getValue(),
                    order.getStatus(), order.getDescription(), order.getFeedback(), order.getCategory(),
                    null, null, null, null, order.getLicensePlate(), order.getModel(), order.getBrand(),
                    convertToClientDto(order.getClient()), convertToDriverDto(order.getDriver()));
        } else {
            return new OrderDto(order.getId(), order.getOrigin(), order.getDestination(), order.getValue(),
                    order.getStatus(), order.getDescription(), order.getFeedback(), order.getCategory(),
                    order.getWidth(), order.getHeight(), order.getLength(), order.getWeight(),
                    null, null, null, convertToClientDto(order.getClient()), convertToDriverDto(order.getDriver()));
        }
    }

    public ClientDto convertToClientDto(Client client) {
        return new ClientDto(client.getId(), client.getName(), client.getEmail(), client.getBirthdate(),
                client.getPhoneNumber(), client.getTaxPayerNumber(), client.getStreet(),
                client.getCity(), client.getPostalCode());
    }

    // Updates the profile of a driver.
    @Override
    public DriverDto editProfile(Long driverId, DriverDto driverDto) {
        Driver driver = getDriverById(driverId);
        verifyDriverUniqueAttributes(driverDto.getEmail(), driverDto.getPhoneNumber(), driverDto.getTaxPayerNumber());

        // Updates driver details.
        driver.setName(driverDto.getName());
        driver.setEmail(driverDto.getEmail());
        driver.setBirthdate(driverDto.getBirthdate());
        driver.setPhoneNumber(driverDto.getPhoneNumber());
        driver.setTaxPayerNumber(driverDto.getTaxPayerNumber());
        driver.setStreet(driverDto.getStreet());
        driver.setCity(driverDto.getCity());
        driver.setPostalCode(driverDto.getPostalCode());

        driverRepository.save(driver);

        return convertToDriverDto(driver);
    }



    // Changes the password of a driver after verifying the old password.
    @Override
    public void changePassword(Long driverId, String oldPassword, String newPassword) {
        Driver driver = getDriverById(driverId);
        if (!passwordEncoder.matches(oldPassword, driver.getPassword())) {
            throw new BusinessException("Invalid password");
        }

        driver.setPassword(passwordEncoder.encode(newPassword));
        driverRepository.save(driver);
    }


    // Converts a Driver object to a DriverDto.
    public DriverDto convertToDriverDto(Driver driver) {
        VehicleDto vehicleDto = null;
        if (driver.getVehicle() != null) {
            vehicleDto = convertToVehicleDto(driver.getVehicle());
        }

        if (vehicleDto == null) {
            throw new BusinessException("VehicleDto cannot be null");
        }

        return new DriverDto(driver.getId(), driver.getName(), driver.getEmail(), driver.getBirthdate(),
                driver.getPhoneNumber(), driver.getTaxPayerNumber(), driver.getStreet(),
                driver.getCity(), driver.getPostalCode(), driver.getLocation(), vehicleDto);
    }

    // Converts a Vehicle object to a VehicleDto.
    public VehicleDto convertToVehicleDto(Vehicle vehicle) {
        return new VehicleDto(vehicle.getCategory(), vehicle.getYear(),
                vehicle.getPlate(), vehicle.getBrand(), vehicle.getModel());
    }

    // Updates a driver's location and online status.
    @Override
    public void updateDriverLocationAndStatus(Long driverId, String location, boolean isOnline) {
        Driver driver = driverRepository.findById(driverId)
                .orElseThrow(() -> new BusinessException("Driver not found."));

        driver.setLocation(location); // Assumes a GeoPoint or similar model adjustment in the Driver class.
        driver.setIsOnline(isOnline);
        //TODO: remover isso do codigo depois
        if (driver.getIsBusy()){
            driver.setIsBusy(false);
        }
        driverRepository.save(driver);
    }




}
