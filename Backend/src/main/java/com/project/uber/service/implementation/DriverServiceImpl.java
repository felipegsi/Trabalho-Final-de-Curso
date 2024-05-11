package com.project.uber.service.implementation;

import com.project.uber.dtos.DriverDto;
import com.project.uber.dtos.RegistrationDto;
import com.project.uber.dtos.VehicleDto;
import com.project.uber.infra.exceptions.BusinessException;
import com.project.uber.model.Driver;
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

    // Método modificado para incluir a senha como um parâmetro
    public DriverDto saveDriver(RegistrationDto registrationDto) {
        // Checks if a driver with the same email already exists.
        Driver existingDriver = driverRepository.findByEmail(registrationDto.email());
        if (existingDriver != null) {
            throw new BusinessException("Driver already exists!");
        }

        LocalDate birthdate = LocalDate.parse(registrationDto.birthdate(), DateTimeFormatter.ofPattern("dd/MM/yyyy"));


        // Criptografa a senha
        String encryptedPassword = passwordEncoder.encode(registrationDto.password());

        // Cria uma nova entidade Driver
        Driver driver = new Driver();
        driver.setName(registrationDto.name());
        driver.setEmail(registrationDto.email());
        driver.setBirthdate(birthdate);
        driver.setPassword(encryptedPassword);
        driver.setPhoneNumber(registrationDto.phoneNumber());
        driver.setTaxPayerNumber(registrationDto.taxPayerNumber());
        driver.setStreet(registrationDto.street());
        driver.setCity(registrationDto.city());
        driver.setPostalCode(registrationDto.postalCode());

        // Converte VehicleDto para Vehicle
        Vehicle vehicle = convertToVehicle(registrationDto.vehicleDto());
        driver.setVehicle(vehicle);
        vehicle.setDriver(driver); // Configura a relação bidirecional

        // Salva o driver no banco de dados
        driverRepository.save(driver);

        // Retorna um novo DriverDto
        return convertToDriverDto(driver);
    }

    private Vehicle convertToVehicle(VehicleDto vehicleDto) {
        // Lógica de conversão de VehicleDto para Vehicle
        Vehicle vehicle = new Vehicle();
        vehicle.setYear(vehicleDto.getYear());
        vehicle.setPlate(vehicleDto.getPlate());
        vehicle.setBrand(vehicleDto.getBrand());
        vehicle.setModel(vehicleDto.getModel());
        vehicle.setVehicleType(vehicleDto.getVehicleType());
        vehicle.setCapacity(vehicleDto.getCapacity());
        return vehicle;
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
            vehicleDto = new VehicleDto(String.valueOf(vehicle.getVehicleType()),vehicle.getYear(), vehicle.getBrand(), vehicle.getPlate(),
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
