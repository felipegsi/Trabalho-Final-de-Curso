package com.project.uber.service.implementation;

import com.project.uber.dtos.DriverDto;
import com.project.uber.dtos.VehicleDto;
import com.project.uber.infra.exceptions.BusinessException;
import com.project.uber.model.Driver;
import com.project.uber.model.GeoPoint;
import com.project.uber.model.Order;
import com.project.uber.repository.DriverRepository;
import com.project.uber.repository.VehicleRepository;
import com.project.uber.service.interfac.DriverService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import com.project.uber.model.Vehicle;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.stream.Collectors;

@Service // Marks the class as a Spring service.
public class DriverServiceImpl implements DriverService {

    // Autowired's annotations to inject repository and encoder dependencies.
    @Autowired
    private DriverRepository driverRepository;
    @Autowired
    private PasswordEncoder passwordEncoder;
    @Autowired
    private VehicleRepository vehicleRepository;

    // Saves a new driver to the repository after performing checks and password encryption.
    @Override
    public DriverDto saveDriver(DriverDto driverDto) {
        // Checks if a driver with the same email already exists.
        Driver existingDriver = driverRepository.findByEmail(driverDto.email());
        if (existingDriver != null) {
            throw new BusinessException("Driver already exists!");
        }

        // Encrypts the password.
        String encryptedPassword = passwordEncoder.encode(driverDto.password());
        // Parses the birthdate from String to LocalDate.
        LocalDate birthdate = LocalDate.parse(driverDto.birthdate(), DateTimeFormatter.ofPattern("dd/MM/yyyy"));

        // Creates a new Driver object and saves it in the database.
        Driver newDriver = new Driver(driverDto.name(), driverDto.email(), birthdate, encryptedPassword,
                driverDto.phoneNumber(), driverDto.taxPayerNumber(), driverDto.street(),
                driverDto.city(), driverDto.postalCode(), false);
        newDriver = driverRepository.save(newDriver);

        // If vehicle information is present, associates and saves the vehicle for the driver.
        Vehicle vehicleInfo = driverDto.vehicleDto();
        if (vehicleInfo != null) {
            Vehicle vehicle = new Vehicle();
            vehicle.setDriver(newDriver);
            vehicle.setYear(vehicleInfo.getYear());
            vehicle.setPlate(vehicleInfo.getPlate());
            vehicle.setBrand(vehicleInfo.getBrand());
            vehicle.setModel(vehicleInfo.getModel());
            vehicle.setVehicleType(vehicleInfo.getVehicleType());
            vehicle.setCapacity(vehicleInfo.getCapacity());
            vehicleRepository.save(vehicle);
        }

        // Formats the birthdate for return.
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy");
        String formattedBirthdate = newDriver.getBirthdate().format(formatter);

        // Returns the newly created DriverDto.
        return new DriverDto(newDriver.getName(), newDriver.getEmail(), formattedBirthdate, newDriver.getPhoneNumber(),
                newDriver.getTaxPayerNumber(), newDriver.getStreet(), newDriver.getCity(),
                newDriver.getPostalCode(), vehicleInfo);
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
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy");
        String formattedBirthdate = driver.getBirthdate().format(formatter);
        return new DriverDto(driver.getName(), driver.getEmail(), formattedBirthdate, driver.getPhoneNumber(),
                driver.getTaxPayerNumber(), driver.getStreet(), driver.getCity(), driver.getPostalCode(),
                driver.getVehicle());
    }

    // Updates the profile of a driver.
    @Override
    public DriverDto editProfile(Long driverId, DriverDto driverDto) {
        Driver driver = getDriverById(driverId);

        // Updates driver details.
        driver.setName(driverDto.name());
        driver.setEmail(driverDto.email());
        driver.setPhoneNumber(driverDto.phoneNumber());
        driver.setTaxPayerNumber(driverDto.taxPayerNumber());
        driver.setStreet(driverDto.street());
        driver.setCity(driverDto.city());
        driver.setPostalCode(driverDto.postalCode());

        driverRepository.save(driver);

        // Returns the updated driver profile.
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy");
        String formattedBirthdate = driver.getBirthdate().format(formatter);
        return new DriverDto(driver.getName(), driver.getEmail(), formattedBirthdate, driver.getPhoneNumber(),
                driver.getTaxPayerNumber(), driver.getStreet(), driver.getCity(), driver.getPostalCode(),
                driver.getVehicle());
    }

    // Accepts an order for a driver.
    @Override
    public void acceptOrder(Long orderId, Long driverId, String driverEmail) throws BusinessException {
        Driver driver = driverRepository.findById(driverId).orElseThrow(() -> new BusinessException("Driver not found"));
        driver.setId(orderId);
        driverRepository.save(driver);
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

    // Finds available drivers, converting each to a DriverDto.
    @Override
    public List<DriverDto> findAvailableDrivers() {
        List<Driver> drivers = driverRepository.findAvailableDrivers();
        return drivers.stream().map(this::convertToDriverDto).collect(Collectors.toList());
    }

    // Selects a driver for an order based on certain criteria (e.g., proximity).
    @Override
    public Driver selectDriverForOrder(Order order, List<Driver> availableDrivers) {
        return availableDrivers.stream().findFirst().orElse(null);
    }

    // Converts a Driver object to a DriverDto.
    public DriverDto convertToDriverDto(Driver driver) {
        VehicleDto vehicleDto = null;
        if (driver.getVehicle() != null) {
            Vehicle vehicle = driver.getVehicle();
            vehicleDto = new VehicleDto(vehicle.getYear(), vehicle.getBrand(), vehicle.getPlate(),
                    vehicle.getModel(), vehicle.getCapacity());
        }

        assert vehicleDto != null;

        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy");
        String formattedBirthdate = driver.getBirthdate().format(formatter);
        return new DriverDto(driver.getName(), driver.getEmail(), formattedBirthdate, driver.getPhoneNumber(),
                driver.getTaxPayerNumber(), driver.getStreet(), driver.getCity(), driver.getPostalCode(),
                vehicleDto);
    }

    // Updates a driver's location and online status.
    @Override
    public void updateDriverLocationAndStatus(Long driverId, String location, boolean isOnline) {
        Driver driver = driverRepository.findById(driverId)
                .orElseThrow(() -> new BusinessException("Driver not found."));

        driver.setLocation(location); // Assumes a GeoPoint or similar model adjustment in the Driver class.
        driver.setIsOnline(isOnline);
        driverRepository.save(driver);
    }
}
