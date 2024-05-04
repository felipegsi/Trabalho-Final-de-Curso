package com.project.uber.service.implementation;

import com.project.uber.dtos.ClientDto;
import com.project.uber.infra.exceptions.BusinessException;
import com.project.uber.model.Client;
import com.project.uber.repository.ClientRepository;
import com.project.uber.service.interfac.ClientService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

// This is a service class for the Client entity. It implements the ClientService interface.
@Service
public class ClientServiceImpl implements ClientService {

    // The ClientRepository is autowired, which means Spring will automatically inject an instance of ClientRepository here.
    @Autowired
    private ClientRepository clientRepository;

    // The PasswordEncoder is autowired, which means Spring will automatically inject an instance of PasswordEncoder here.
    @Autowired
    private PasswordEncoder passwordEncoder;

    // This method is used to save a new client. It first checks if a client with the same email already exists.
    // If the client already exists, it throws a BusinessException. Otherwise, it saves the new client in the database.
    @Override
    public ClientDto saveClient(ClientDto clientDto) {

        Client clientAlredyExists = clientRepository.findByEmail(clientDto.email());

        if (clientAlredyExists != null) {
            throw new BusinessException("Client already exists!");
        }

        var passwordHash = passwordEncoder.encode(clientDto.password());

        Client newClient = clientRepository.save(new Client(clientDto.name(), clientDto.email(), passwordHash,
                clientDto.phoneNumber(), clientDto.taxPayerNumber(), clientDto.street(),
                clientDto.city(), clientDto.postalCode()));

        return new ClientDto(newClient.getName(), newClient.getEmail(), newClient.getPassword(),//nao tirei a senha porque se a retira-se o cliente nao iaconseguir se registar pois um parametro de entrada é a senha
                newClient.getPhoneNumber(), newClient.getTaxPayerNumber(), newClient.getStreet(),
                newClient.getCity(), newClient.getPostalCode());
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
        return new ClientDto(client.getName(), client.getEmail(), client.getPassword(),
                client.getPhoneNumber(), client.getTaxPayerNumber(), client.getStreet(),
                client.getCity(), client.getPostalCode());
    }

    // This method is used to edit a client's profile. It gets the client by their ID, then updates the client's information and saves the client in the database.
    @Override
    public ClientDto editProfile(Long clientId, ClientDto clientDto) {
        Client client = getClientById(clientId);
        client.setName(clientDto.name());
        //tratar os erros

        client.setEmail(clientDto.email());
        client.setPhoneNumber(clientDto.phoneNumber());
        client.setTaxPayerNumber(clientDto.taxPayerNumber());
        client.setStreet(clientDto.street());
        client.setCity(clientDto.city());
        client.setPostalCode(clientDto.postalCode());
        clientRepository.save(client);

        return new ClientDto(client.getName(), client.getEmail(), client.getPassword(),
                client.getPhoneNumber(), client.getTaxPayerNumber(), client.getStreet(),
                client.getCity(), client.getPostalCode());
    }
}