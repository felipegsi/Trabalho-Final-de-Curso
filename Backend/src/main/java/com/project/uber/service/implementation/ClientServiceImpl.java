package com.project.uber.service.implementation;

import com.project.uber.dtos.ClientDto;
import com.project.uber.dtos.DriverDto;
import com.project.uber.dtos.OrderDto;
import com.project.uber.dtos.VehicleDto;
import com.project.uber.enums.Category;
import com.project.uber.infra.exceptions.BusinessException;
import com.project.uber.model.Client;
import com.project.uber.model.Driver;
import com.project.uber.model.Order;
import com.project.uber.model.Vehicle;
import com.project.uber.repository.ClientRepository;
import com.project.uber.repository.OrderRepository;
import com.project.uber.service.interfac.ClientService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

// This is a service class for the Client entity. It implements the ClientService interface.
@Service
public class ClientServiceImpl implements ClientService {

    // The ClientRepository is autowired, which means Spring will automatically inject an instance of ClientRepository here.
    @Autowired
    private ClientRepository clientRepository;

    // The PasswordEncoder is autowired, which means Spring will automatically inject an instance of PasswordEncoder here.
    @Autowired
    private PasswordEncoder passwordEncoder;
    @Autowired
    private OrderRepository orderRepository;

    // This method is used to save a new client. It first checks if a client with the same email already exists.
    // If the client already exists, it throws a BusinessException. Otherwise, it saves the new client in the database.
    @Override
    public ClientDto saveClient(Client newClient) {
        verifyUniqueAttributes(newClient.getEmail(), newClient.getPhoneNumber(), newClient.getTaxPayerNumber());

        var passwordHash = passwordEncoder.encode(newClient.getPassword());

        Client savedClient = new Client(newClient.getName(), newClient.getEmail(), passwordHash,
                newClient.getBirthdate(), newClient.getPhoneNumber(), newClient.getTaxPayerNumber(),
                newClient.getStreet(), newClient.getCity(), newClient.getPostalCode());
        clientRepository.save(savedClient);

        return convertToClientDto(savedClient);
    }

    private void verifyUniqueAttributes(String email, String phoneNumber, int taxPayerNumber) {
        Client clientWithSameEmail = clientRepository.findByEmail(email);
        Client clientWithSamePhoneNumber = clientRepository.findByPhoneNumber(phoneNumber);
        Client clientWithSameTaxPayerNumber = clientRepository.findByTaxPayerNumber(taxPayerNumber);

        // tudo num so if
        if (clientWithSameEmail != null || clientWithSamePhoneNumber != null || clientWithSameTaxPayerNumber != null) {
            throw new BusinessException("Client already exists!");
        }
    }

    @Override
    public List<OrderDto> getClientOrderHistory(Long driverId) {
        List<Order> orders = orderRepository.findByClientId(driverId);
        return orders.stream()
                .map(this::convertToFullOrderDto)
                .collect(Collectors.toList());
    }

    public OrderDto convertToFullOrderDto(Order order) {
        ClientDto clientDto = convertToClientDto(order.getClient());
        // para evitar null pointer exception no caso de não ter motorista
        DriverDto driverDto = (order.getDriver() != null) ? convertToDriverDto(order.getDriver()) : null;

        return new OrderDto(
                order.getId(),
                order.getOrigin(),
                order.getDestination(),
                order.getValue(),
                order.getStatus(),
                order.getDescription(),
                order.getFeedback(),
                order.getCategory(),
                (order.getCategory() != Category.MOTORIZED) ? order.getWidth() : null,
                (order.getCategory() != Category.MOTORIZED) ? order.getHeight() : null,
                (order.getCategory() != Category.MOTORIZED) ? order.getLength() : null,
                (order.getCategory() != Category.MOTORIZED) ? order.getWeight() : null,
                (order.getCategory() == Category.MOTORIZED) ? order.getLicensePlate() : null,
                (order.getCategory() == Category.MOTORIZED) ? order.getModel() : null,
                (order.getCategory() == Category.MOTORIZED) ? order.getBrand() : null,
                clientDto,
                driverDto
        );
    }

    public DriverDto convertToDriverDto(Driver driver) {
        VehicleDto vehicleDto = null;
        if (driver.getVehicle() != null) {
            vehicleDto = convertToVehicleDto(driver.getVehicle());
        }

        return new DriverDto(
                driver.getId(),
                driver.getName(),
                driver.getEmail(),
                driver.getBirthdate(),
                driver.getPhoneNumber(),
                driver.getTaxPayerNumber(),
                driver.getStreet(),
                driver.getCity(),
                driver.getPostalCode(),
                driver.getLocation(),
                vehicleDto
        );
    }


    // Converts a Vehicle object to a VehicleDto.
    public VehicleDto convertToVehicleDto(Vehicle vehicle) {
        return new VehicleDto(vehicle.getCategory(), vehicle.getYear(),
                vehicle.getPlate(), vehicle.getBrand(), vehicle.getModel());
    }


    // This method is used to delete a client by their ID.
    @Override
    public void deleteClient(Long clientId) {
        clientRepository.deleteById(clientId);
    }

    // This method is used to get a client by their ID. If the client is not found, it throws a BusinessException.
    @Override
    public Client getClientById(Long clientId) {
        return clientRepository.findById(clientId).orElseThrow(() -> new BusinessException("Client not found"));
    }


    // This method is used to get a client by their email. If the client is not found, it throws a BusinessException.
    @Override
    public Client getClientByEmail(String email) {
        Client client = clientRepository.findByEmail(email);
        if (client == null) {
            throw new BusinessException("Client not found");
        }
        return client;
    }

    // This method is used to change a client's password. It first gets the client by their ID, then checks if the old password is correct.
    // If the old password is not correct, it throws a BusinessException. Otherwise, it changes the password and saves the client in the database.
    @Override
    public void changePassword(Long clientId, String oldPassword, String newPassword) {

        Client client = getClientById(clientId);
        if (!passwordEncoder.matches(oldPassword, client.getPassword())) {
            throw new BusinessException("Invalid password");
        }

        client.setPassword(passwordEncoder.encode(newPassword));
        clientRepository.save(client);
    }

    // This method is used to view a client's profile. It gets the client by their ID and returns a ClientDto.
    @Override
    public ClientDto viewProfile(Long clientId) {
        Client client = getClientById(clientId);
        return convertToClientDto(client);
    }

    // This method is used to edit a client's profile. It gets the client by their ID, then updates the client's information and saves the client in the database.
    @Override
    public ClientDto editProfile(Long clientId, ClientDto clientDto) {
        Client client = getClientById(clientId);
        // verify if the new attributes are unique
        verifyUniqueAttributes(clientDto.getEmail(), clientDto.getPhoneNumber(), clientDto.getTaxPayerNumber());

        // update client details
        client.setName(clientDto.getName());
        client.setEmail(clientDto.getEmail());
        client.setBirthdate(clientDto.getBirthdate());
        client.setPhoneNumber(clientDto.getPhoneNumber());
        client.setTaxPayerNumber(clientDto.getTaxPayerNumber());
        client.setStreet(clientDto.getStreet());
        client.setCity(clientDto.getCity());
        client.setPostalCode(clientDto.getPostalCode());


        clientRepository.save(client);

        return convertToClientDto(client);
    }

    public ClientDto convertToClientDto(Client client) {
        return new ClientDto(
                client.getId(),
                client.getName(),
                client.getEmail(),
                client.getBirthdate(),
                client.getPhoneNumber(),
                client.getTaxPayerNumber(),
                client.getStreet(),
                client.getCity(),
                client.getPostalCode()
        );
    }
}