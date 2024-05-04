package com.project.uber.controller;

import com.project.uber.dtos.*;
import com.project.uber.enums.Category;
import com.project.uber.infra.exceptions.BusinessException;
import com.project.uber.model.Order;
import com.project.uber.service.implementation.EmailServiceImpl;
import com.project.uber.service.interfac.AuthenticationService;
import com.project.uber.service.interfac.ClientService;

import com.project.uber.service.interfac.OrderService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;

//notes: logout on the front-end, and on the back-end, the token is invalidated.
//implement password change
//implement password recovery

// This Java code is part of a Spring Boot project located in the package com.project.uber.controller.
// It includes several imports from the project's own structure as well as Spring framework components.

// This class, ClientController, is annotated with @RestController, indicating it's a Spring MVC controller with REST API responses.
// The @RequestMapping("/client") annotation defines a base URI for all request mappings inside this controller.
@RestController
@RequestMapping("/client")
public class ClientController {

    // Spring's @Autowired annotation is used to auto-wire beans into the class.
    // Below are the fields for services and components used in this controller.
    @Autowired
    private AuthenticationManager authenticationManager;
    @Autowired
    private AuthenticationService authenticationService;
    @Autowired
    private ClientService clientService;
    @Autowired
    private EmailServiceImpl emailService;
    @Autowired
    private OrderService orderService;

    // This method handles POST requests to "/register" and registers a new client.
    @PostMapping("/register") // This annotation marks the method to accept POST requests on the path "/register".
    private ClientDto save(@RequestBody ClientDto clientDto) { // @RequestBody annotation indicates a method parameter should be bound to the body of the web request.
        try {
            // Attempts to save the client and return the saved client data.
            return clientService.saveClient(clientDto);
        } catch (BusinessException e) {
            // If there's a business logic exception, it rethrows it with a custom message.
            throw new BusinessException("Client already exists!");
        }
    }

    // This method handles user authentication with a POST request to "/login".
    @PostMapping("/login")
    public ResponseEntity<?> auth(@RequestBody AuthDto authDto) { // ResponseEntity is used to represent the whole HTTP response: status code, headers, and body.
        if (authDto == null || authDto.email() == null || authDto.password() == null) {
            throw new BusinessException("Email and password are mandatory.");
        }
        try {
            // Authentication logic, including the creation and verification of authentication tokens.
            var usuarioAutenticationToken = new UsernamePasswordAuthenticationToken(authDto.email(), authDto.password());
            authenticationManager.authenticate(usuarioAutenticationToken);
            String token = authenticationService.getClientTokenJwt(authDto);
            return ResponseEntity.ok(token);
        } catch (AuthenticationException e) {
            // Handles authentication failures.
            throw new BusinessException("Invalid credentials.");
        }
    }

    // This method returns the client profile based on the provided JWT token.
    @GetMapping("/viewProfile") // Handles GET requests for "/viewProfile".
    public ResponseEntity<?> viewProfile(
            @RequestHeader("Authorization") String token) { // @RequestHeader extracts the 'Authorization' header from the request.
        // Validates the token and retrieves the client ID from it.
        Long clientId = validateTokenAndGetClientId(token);

        ClientDto clientDto = clientService.viewProfile(clientId);
        return new ResponseEntity<>(clientDto, HttpStatus.OK);
    }
// verify if the token is valid
    @GetMapping("/isValidToken")
    public ResponseEntity<Boolean> isValidToken(@RequestHeader("Authorization") String token) {
        try {
            validateTokenAndGetClientId(token);
            return new ResponseEntity<>(true, HttpStatus.OK);
        } catch (BusinessException e) {
            return new ResponseEntity<>(false, HttpStatus.OK);
        }
    }

    // This method allows clients to edit their profiles.
    @PostMapping("/editProfile") // Handles POST requests to "/editProfile".
    public ResponseEntity<?> editProfile(
            @RequestBody ClientDto clientDto, // ClientDto contains new profile details.
            @RequestHeader("Authorization") String token) {
        // Same token validation as in the previous methods.
        Long clientId = validateTokenAndGetClientId(token);

        ClientDto newClient = clientService.editProfile(clientId, clientDto);
        return new ResponseEntity<>(newClient, HttpStatus.OK);
    }

    // This method estimates the cost of an order based on its details.
    @PostMapping("/estimateAllCategoryOrderCost") // Handles POST requests to "/estimateOrderCost".
    public ResponseEntity<List<BigDecimal>> estimateAllCategoryOrderCost( @RequestBody LocationDto locationDto,
                                                        @RequestHeader("Authorization") String token) {
        try {
            if (locationDto.getOrigin() == null || locationDto.getDestination() == null) {
                throw new BusinessException("Origin and destination are mandatory.");
            }

            if(validateTokenAndGetClientId(token) <= 0){
                throw new BusinessException("Client not found.");
            }

            // Calculates the estimated cost of an order.
            List<BigDecimal> estimatedCost = orderService.estimateAllCategoryOrderCost(locationDto.getOrigin(), locationDto.getDestination());

            return new ResponseEntity<>(estimatedCost, HttpStatus.OK);
        } catch (BusinessException e) {
            // Handles exceptions related to cost estimation.
            throw new BusinessException("Error estimating order cost: " + e.getMessage());
        }
    }


    @PostMapping("/estimateOrderCost") // Handles POST requests to "/estimateOrderCost".
    public ResponseEntity<BigDecimal> estimateOrderCost(@RequestBody OrderDto orderDto ,
                                                              @RequestHeader("Authorization") String token) {
        try {
            if (orderDto == null || orderDto.getOrigin() == null || orderDto.getDestination() == null) {
                throw new BusinessException("Origin and destination are mandatory.");
            }

            if(validateTokenAndGetClientId(token) <= 0){
                throw new BusinessException("Client not found.");
            }
           validateTokenAndGetClientId(token);

            // Calculates the estimated cost of an order.

            BigDecimal estimatedCost = orderService.estimateOrderCost(orderDto.getOrigin(), orderDto.getDestination(),
                    orderDto.getCategory(), orderDto.getWidth(), orderDto.getHeight(), orderDto.getLength(), orderDto.getWeight());

            return new ResponseEntity<>(estimatedCost, HttpStatus.OK);
        } catch (BusinessException e) {
            // Handles exceptions related to cost estimation.
            throw new BusinessException("Error estimating order cost: " + e.getMessage());
        }
    }
    // This method creates a new order for a client.
    @PostMapping("/createOrder") // Handles POST requests to "/createOrder".
    public ResponseEntity<?> createOrder(@RequestBody OrderDto orderDto,
                                         @RequestHeader("Authorization") String token) {
        try {
            // Validates token and gets client ID.
            Long clientId = validateTokenAndGetClientId(token);

            if (orderDto == null) {
                throw new BusinessException("Order not found.");
            }

            // Creates the order and returns the new order details.
            Order order = orderService.saveOrder(orderDto, clientId);
            return ResponseEntity.status(HttpStatus.CREATED).body(order);
        } catch (BusinessException e) {
            // Handles exceptions during order creation.
            throw new BusinessException("Error creating order: " + e.getMessage());
        }
    }

    // This method validates the JWT token and extracts the client ID from it.
    private Long validateTokenAndGetClientId(String token) {

        // Assumes the token is prefixed by "Bearer ", which is typical in HTTP authorization headers.
        String tokenSliced = token.substring("Bearer ".length());

        Long clientId = authenticationService.getClientIdFromToken(tokenSliced);
        if (clientId == null || clientId <= 0) {
            throw new BusinessException("Client not found.");
        }
        return clientId;
    }

    // This method retrieves the order history for a client based on their token.
    @GetMapping("/orderHistory") // Handles GET requests to "/orderHistory".
    public ResponseEntity<List<Order>> getOrderHistory(
            @RequestHeader("Authorization") String token) {
        try {
            // Validates token and retrieves client ID.
            Long clientId = validateTokenAndGetClientId(token);

            // Retrieves and returns the client's order history.
            List<Order> orderHistory = orderService.getClientOrderHistory(clientId);
            return new ResponseEntity<>(orderHistory, HttpStatus.OK);
        } catch (BusinessException e) {
            // Handles exceptions during retrieval of order history.
            throw new BusinessException(e.getMessage());
        }
    }

    // This method deletes a client's account.
    @GetMapping("/deleteClient") // Handles GET requests to "/deleteClient".
    public ResponseEntity<?> deleteClient(@RequestHeader("Authorization") String token) {
        try {
            // Validates token and retrieves client ID. Ensures all orders are deleted before proceeding with client deletion.
            Long clientId = validateTokenAndGetClientId(token);

            clientService.deleteClient(clientId);
            return new ResponseEntity<>(HttpStatus.OK);
        } catch (BusinessException e) {
            // Handles exceptions during client deletion.
            throw new BusinessException("Error deleting client " + e.getMessage());
        }
    }

    // This method handles password changes for a client.
    @PostMapping("/changePassword")
    public ResponseEntity<?> changePassword(
            @RequestBody ChangePasswordDto changePasswordDto, // Contains old and new passwords.
            @RequestHeader("Authorization") String token) {
        // Validates token and retrieves client ID.
        Long clientId = validateTokenAndGetClientId(token);

        // Changes the client's password.
        clientService.changePassword(clientId, changePasswordDto.oldPassword(), changePasswordDto.newPassword());
        return new ResponseEntity<>(HttpStatus.OK);
    }

    // This method sends a simple email message.
    @PostMapping("/sendSimpleMessage")
    public ResponseEntity<Void> sendSimpleMessage(@RequestBody EmailDto emailDto) {
        // Sends an email message using the EmailServiceImpl.
        emailService.sendSimpleMessage(emailDto);
        return ResponseEntity.ok().build();
    }





}
