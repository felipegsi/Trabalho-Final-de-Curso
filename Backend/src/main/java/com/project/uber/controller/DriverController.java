package com.project.uber.controller;

import com.project.uber.dtos.*;
import com.project.uber.enums.OrderStatus;
import com.project.uber.infra.exceptions.BusinessException;
import com.project.uber.model.Driver;
import com.project.uber.model.GeoPoint;
import com.project.uber.service.implementation.EmailServiceImpl;
import com.project.uber.service.interfac.AuthenticationService;
import com.project.uber.service.interfac.DriverService;
import com.project.uber.service.interfac.OrderService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.bind.annotation.*;

import java.util.List;

// This Java code is part of a Spring Boot project located in the package and is responsible for managing driver-related functionalities.
// It includes several imports from the project's own structure as well as Spring framework components.

// This class, DriverController, is annotated with @RestController, indicating it's a Spring MVC controller with REST API responses.
// The @RequestMapping("/driver") annotation sets the base URI for all request mappings inside this controller.

@RestController
@RequestMapping("/driver")
public class DriverController {

    // Spring's @Autowired annotation is used to auto-wire beans into the class.
    // Below are the fields for services and components used in this controller.
    @Autowired
    private AuthenticationManager authenticationManager;
    @Autowired
    private AuthenticationService authenticationService;
    @Autowired
    private DriverService driverService;
    @Autowired
    private OrderService orderService;
    @Autowired
    private EmailServiceImpl emailService;

    // This method handles POST requests to "/register" and registers a new driver.
    @PostMapping("/register") // This annotation marks the method to accept POST requests on the path "/register".
    private DriverDto save(@RequestBody DriverDto driverDto) { // @RequestBody annotation indicates a method parameter should be bound to the body of the web request.
        try {
            // Attempts to save the driver and return the saved driver data.
            return driverService.saveDriver(driverDto);
        } catch (BusinessException e) {
            // If there's a business logic exception, it rethrows it with a custom message.
            throw new BusinessException("Error registering driver: " + e.getMessage());
        }
    }

    // This method handles driver authentication with a POST request to "/login".
    @PostMapping("/login")
    public ResponseEntity<?> auth(@RequestBody AuthDto authDto) { // ResponseEntity is used to represent the whole HTTP response: status code, headers, and body.
        if (authDto == null || authDto.email() == null || authDto.password() == null) {
            throw new BusinessException("Email and password are mandatory.");
        }
        try {
            // Authentication logic, including the creation and verification of authentication tokens.
            var usuarioAutenticationToken = new UsernamePasswordAuthenticationToken(authDto.email(), authDto.password());
            authenticationManager.authenticate(usuarioAutenticationToken);
            String token = authenticationService.getDriverTokenJwt(authDto);
            return ResponseEntity.ok(token);
        } catch (AuthenticationException e) {
            // Handles authentication failures.
            throw new BusinessException("Error authenticating driver: " + e.getMessage());
        }
    }

    // This method deletes a driver's account.
    @GetMapping("/deleteDriver") // Handles GET requests to "/deleteDriver".
    public ResponseEntity<?> deleteDriver(@RequestHeader("Authorization") String token) {
        try {
            // Validates token and retrieves driver ID. Ensures all orders are deleted before proceeding with driver deletion.
            Long driverId = validateTokenAndGetDriverId(token);

            driverService.deleteDriver(driverId);
            return new ResponseEntity<>(HttpStatus.OK);
        } catch (BusinessException e) {
            // Handles exceptions during driver deletion.
            throw new BusinessException("Error deleting client " + e.getMessage());
        }
    }

    // This method returns a list of available drivers.
    @GetMapping("/available") // Handles GET requests to "/available".
    public ResponseEntity<List<DriverDto>> getAvailableDrivers() {
        try {
            // Retrieves a list of available drivers from the service and returns it.
            List<DriverDto> availableDrivers = driverService.findAvailableDrivers();
            return new ResponseEntity<>(availableDrivers, HttpStatus.OK);
        } catch (BusinessException e) {
            // Handles exceptions when fetching available drivers.
            return ResponseEntity.badRequest().body(null); // Could implement a different error handling.
        }
    }

    // This method handles accepting an order by a driver.
    @PostMapping("/accept-order") // Handles POST requests to "/accept-order".
    public ResponseEntity<?> acceptOrder(@RequestBody OrderDto acceptOrderRequest,
                                         @RequestHeader("Authorization") String token) {
        try {
            Long driverId = validateTokenAndGetDriverId(token);
            // Processes the order acceptance.
            orderService.acceptOrder(acceptOrderRequest.getId(), driverId);

            return ResponseEntity.ok().body("Order with ID: " + acceptOrderRequest.getId() +
                    " accepted successfully by driver ID: " + driverId);
        } catch (BusinessException e) {
            // Handles exceptions during order acceptance.
            return ResponseEntity.badRequest().body("Error accepting order: " + e.getMessage());
        }
    }

    // This method sets a driver's status to online.
    @PutMapping("/online") // Handles PUT requests to "/online".
    public ResponseEntity<?> setDriverOnline(@RequestHeader("Authorization") String token, @RequestBody Driver request) {
        Long driverId = validateTokenAndGetDriverId(token);
        try {
            // Validates location information and updates the driver's status.
            String location = request.getLocation();
            if (location == null || location.isEmpty()) {
                throw new BusinessException("Location must be provided to go online.");
            }
            driverService.updateDriverLocationAndStatus(driverId, location, true);
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            // Handles exceptions when setting driver status.
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    // This method sets a driver's status to offline.
    @PutMapping("/offline") // Handles PUT requests to "/offline".
    public ResponseEntity<?> setDriverOffline(@RequestHeader("Authorization") String token) {
        Long driverId = validateTokenAndGetDriverId(token);
        try {
            // Updates the driver's status to offline.
            driverService.setDriverOnlineStatus(driverId, false);
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            // Handles exceptions when setting driver status.
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    // This PUT mapping method is designed to handle the confirmation of a pickup by a driver.
    @PutMapping("/pick-up")
    public ResponseEntity<?> confirmPickUp(
            @RequestBody OrderDto statusChangeDto, // The order details needed for the pickup confirmation.
            @RequestHeader("Authorization") String token) { // The token is required to authenticate the driver.
        try {
            Long driverId = validateTokenAndGetDriverId(token); // Validates the token and retrieves the driver ID.
            orderService.confirmPickUp(statusChangeDto.getId(), driverId); // Calls the order service to confirm the pickup.
            return ResponseEntity.ok().build(); // Returns an OK response if successful.
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage()); // Returns a bad request response if an exception occurs.
        }
    }

    // This PUT mapping method is used to mark an order as in progress.
    @PutMapping("/in-progress")
    public ResponseEntity<?> markAsInProgress(
            @RequestBody OrderDto statusChangeDto, // The order details that will be updated.
            @RequestHeader("Authorization") String token) { // The token for driver authentication.
        try {
            Long driverId = validateTokenAndGetDriverId(token); // Validates the token and gets the driver ID.
            orderService.updateOrderStatus(statusChangeDto.getId(), OrderStatus.IN_PROGRESS, driverId); // Updates the order status to IN_PROGRESS.
            return ResponseEntity.ok().build(); // Returns an OK response if the operation is successful.
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage()); // Returns a bad request response if there's an issue.
        }
    }

    // This PUT mapping method updates the status of an order to deliver.
    @PutMapping("/delivered")
    public ResponseEntity<?> markAsDelivered(
            @RequestBody OrderDto statusChangeDto, // Contains the details of the order to be marked as delivered.
            @RequestHeader("Authorization") String token) { // Uses the token to authenticate the driver.
        try {
            Long driverId = validateTokenAndGetDriverId(token); // Validates the token and retrieves the driver ID.
            orderService.updateOrderStatus(statusChangeDto.getId(), OrderStatus.DELIVERED, driverId); // Marks the order as delivered in the order service.
            return ResponseEntity.ok().build(); // Successfully returns an OK status.
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage()); // Returns a bad request response on failure.
        }
    }

    // This POST method is for sending simple messages via email.
    @PostMapping("/sendSimpleMessage")
    public ResponseEntity<Void> sendSimpleMessage(@RequestBody EmailDto emailDto) { // Takes an email DTO which includes the details needed for the email.
        emailService.sendSimpleMessage(emailDto); // Uses the email service to send a message.
        return ResponseEntity.ok().build(); // Returns an OK response after sending the message.
    }

    // This GET method retrieves the driver profile based on the provided token.
    @GetMapping("/viewProfile")
    public ResponseEntity<?> viewProfile(
            @RequestHeader("Authorization") String token) { // The token is used to authenticate and identify the driver.
        Long driverId = validateTokenAndGetDriverId(token); // Validates the token and retrieves the driver ID.
        DriverDto driverDto = driverService.viewProfile(driverId); // Retrieves the driver profile using the driver service.
        return new ResponseEntity<>(driverDto, HttpStatus.OK); // Returns the driver profile with an OK status.
    }

    // This POST method allows the driver to edit their profile.
    @PostMapping("/editProfile")
    public ResponseEntity<?> editProfile(
            @RequestBody DriverDto driverDto, // The driver DTO with the updated profile information.
            @RequestHeader("Authorization") String token) { // The token for driver authentication.
        Long driverId = validateTokenAndGetDriverId(token); // Validates the token and retrieves the driver ID.
        DriverDto newDriver = driverService.editProfile(driverId, driverDto); // Updates the driver profile.
        return new ResponseEntity<>(newDriver, HttpStatus.OK); // Returns the updated profile with an OK status.
    }

    // This GET method retrieves the order history for a driver.
    @GetMapping("/orderHistory")
    public ResponseEntity<List<OrderDto>> getDriverOrderHistory(
            @RequestHeader("Authorization") String token) { // The token is used to authenticate the driver.
        try {
            Long driverId = validateTokenAndGetDriverId(token); // Validates the token and retrieves the driver ID.
            List<OrderDto> orderHistory = orderService.getDriverOrderHistory(driverId); // Fetches the order history from the order service.
            return new ResponseEntity<>(orderHistory, HttpStatus.OK); // Returns the order history with an OK status.
        } catch (BusinessException e) {
            return new ResponseEntity<>(HttpStatus.UNAUTHORIZED); // Returns an unauthorized status if there's an issue with token validation.
        }
    }

    // This POST method handles password changes for the driver.
    @PostMapping("/changePassword")
    public ResponseEntity<?> changePassword(
            @RequestBody ChangePasswordDto changePasswordDto, // Contains the old and new password.
            @RequestHeader("Authorization") String token) { // The token for driver authentication.
        Long driverId = validateTokenAndGetDriverId(token); // Validates the token and retrieves the driver ID.
        driverService.changePassword(driverId, changePasswordDto.oldPassword(), changePasswordDto.newPassword()); // Changes the password using the driver service.
        return new ResponseEntity<>(HttpStatus.OK); // Returns an OK status upon successful password change.
    }

    //    public Driver assignOrderToDriver(Long orderId) criar um endpoint para atribuir uma ordem a um motorista
    @PostMapping("/assignOrderToDriver")
    public ResponseEntity<?> assignOrderToDriver(@RequestBody OrderDto orderDto) {
        try {
            Driver driver = orderService.assignOrderToDriver(orderDto.getId());
            return new ResponseEntity<>(driver, HttpStatus.OK);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }


    // This private method validates the JWT token and extracts the driver ID from it.
    private Long validateTokenAndGetDriverId(String token) {
        // Assumes the token is prefixed by "Bearer ", which is typical in HTTP authorization headers.
        String tokenSliced = token.substring("Bearer ".length());

        Long driverId = authenticationService.getDriverIdFromToken(tokenSliced);
        if (driverId == null || driverId <= 0) {
            throw new BusinessException("Driver not found.");
        }
        return driverId;
    }
}
