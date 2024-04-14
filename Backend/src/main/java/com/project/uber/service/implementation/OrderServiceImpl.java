package com.project.uber.service.implementation;

import com.project.uber.constants.OrderConstants;
import com.project.uber.dtos.OrderDto;
import com.project.uber.enums.Category;
import com.project.uber.enums.OrderStatus;
import com.project.uber.infra.exceptions.BusinessException;
import com.project.uber.infra.exceptions.InvalidOrderStateException;
import com.project.uber.infra.exceptions.OrderNotFoundException;
import com.project.uber.infra.exceptions.UnauthorizedDriverException;
import com.project.uber.model.Client;
import com.project.uber.model.Driver;
import com.project.uber.model.Order;
import com.project.uber.repository.DriverRepository;
import com.project.uber.repository.OrderRepository;
import com.project.uber.service.interfac.ClientService;
import com.project.uber.service.interfac.OrderService;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;


import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import org.json.JSONObject;

@Service
public class OrderServiceImpl implements OrderService {
    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private ClientService clientService;

    @Autowired
    private DriverRepository driverRepository;

    // Method to estimate the cost of an order using an external API for routing.
    @Override
    public BigDecimal estimateOrderCost(OrderDto orderDto) {
        OkHttpClient client = new OkHttpClient();

        // Splits the origin and destination into latitude and longitude.
        String[] originCoordinates = orderDto.getOrigin().split(",");
        String[] destinationCoordinates = orderDto.getDestination().split(",");

        // Builds the HTTP request for the routing API.
        Request request = new Request.Builder()
                .url("https://api.openrouteservice.org/v2/directions/driving-car?api_key=<API_KEY>&start="
                        + originCoordinates[1] + "," + originCoordinates[0] + "&end=" + destinationCoordinates[1] + ","
                        + destinationCoordinates[0])
                .build();

        try (Response response = client.newCall(request).execute()) {
            String jsonData = response.body().string();
            JSONObject jsonObject = new JSONObject(jsonData);
            // Extracts the distance from the JSON response.
            int distanceInMeters = jsonObject.getJSONArray("features")
                    .getJSONObject(0)
                    .getJSONObject("properties")
                    .getJSONArray("segments")
                    .getJSONObject(0)
                    .getInt("distance");

            BigDecimal distanceInKm = new BigDecimal(distanceInMeters).divide(new BigDecimal(1000));

            // Calls the method to calculate the final order cost based on distance and other dimensions.
            return calculateOrderCostBasedOnDimensionsAndCategory(orderDto, distanceInKm);
        } catch (BusinessException e) {
            throw e; // Repropagates the BusinessException
        } catch (Exception e) {
            throw new BusinessException("Failed to estimate order cost");
        }
    }

    // Calculates the cost of an order based on its dimensions and category.
    public BigDecimal calculateOrderCostBasedOnDimensionsAndCategory(OrderDto orderDto, BigDecimal distanceInKm) {
        BigDecimal baseValue = BigDecimal.valueOf(1.00);
        BigDecimal additionalValue = verifyMeasures(orderDto);

        return baseValue.add(additionalValue).multiply(distanceInKm);
    }

    // Verifies that the order dimensions match the specified category and returns a category-specific surcharge.
    public BigDecimal verifyMeasures(OrderDto orderDto) {
        BigDecimal additionalValue = BigDecimal.ZERO;

        switch (orderDto.getCategory()) {
            case SMALL:
                if (orderDto.getWidth() <= OrderConstants.SMALL_WIDTH && orderDto.getHeight() <= OrderConstants.SMALL_HEIGHT
                        && orderDto.getLength() <= OrderConstants.SMALL_LENGTH && orderDto.getWeight() <= OrderConstants.SMALL_WEIGHT) {
                    additionalValue = BigDecimal.valueOf(1.00);
                } else {
                    throw new BusinessException("Order dimensions do not match the SMALL category. Please check the dimensions and weight.");
                }
                break;
            case MEDIUM:
                if (orderDto.getWidth() <= OrderConstants.MEDIUM_WIDTH && orderDto.getHeight() <= OrderConstants.MEDIUM_HEIGHT
                        && orderDto.getLength() <= OrderConstants.MEDIUM_LENGTH && orderDto.getWeight() <= OrderConstants.MEDIUM_WEIGHT) {
                    additionalValue = BigDecimal.valueOf(2.00);
                } else {
                    throw new BusinessException("Order dimensions do not match the MEDIUM category. Please check the dimensions and weight.");
                }
                break;
            case LARGE:
                if (orderDto.getWidth() <= OrderConstants.LARGE_WIDTH && orderDto.getHeight() <= OrderConstants.LARGE_HEIGHT
                        && orderDto.getLength() <= OrderConstants.LARGE_LENGTH && orderDto.getWeight() <= OrderConstants.LARGE_WEIGHT) {
                    additionalValue = BigDecimal.valueOf(3.00);
                } else {
                    throw new BusinessException("Order dimensions do not match the LARGE category. Please check the dimensions and weight.");
                }
                break;
            case MOTORIZED:
                additionalValue = BigDecimal.valueOf(20.00);
                break;
            default:
                throw new BusinessException("Invalid category. Please check the category of the order.");
        }

        return additionalValue;
    }

    // Creates and assigns an order to a driver, starting with verifying client existence.
    @Override
    @Transactional // Ensures that the operation is performed atomically.
    public OrderDto createAndAssignOrder(OrderDto orderDto, Long clientId) throws BusinessException {
        // Verifies the existence of the client.
        Client client = clientService.getClientById(clientId);
        if (client == null) {
            throw new BusinessException("Client not found.");
        }

        // Estimates the cost of the order.
        BigDecimal estimatedCost = estimateOrderCost(orderDto);

        // Creates a new Order instance with provided details and the estimated cost.
        Order newOrder = new Order();
        newOrder.setOrigin(orderDto.getOrigin());
        newOrder.setDestination(orderDto.getDestination());
        newOrder.setDescription(orderDto.getDescription());
        newOrder.setFeedback(orderDto.getFeedback());
        newOrder.setCategory(orderDto.getCategory());
        newOrder.setClient(client);
        newOrder.setValue(estimatedCost);
        newOrder.setStatus(OrderStatus.PENDING); // Starts with the status PENDING.

        // Saves the order to ensure it has an ID before assigning a driver.
        newOrder = orderRepository.save(newOrder);

        // Attempts to assign a driver to the order.
        try {
            assignDriverToOrder(newOrder.getId());
            newOrder.setStatus(OrderStatus.IN_PROGRESS); // Changes the status to IN_PROGRESS once a driver has been assigned.
            orderRepository.save(newOrder); // Updates the order with the new status.
        } catch (BusinessException e) {
            throw new BusinessException("Failed to assign driver: " + e.getMessage());
        }

        // Converts the new order into OrderDto and returns it.
        return convertToOrderDto(newOrder);
    }

    // Assigns a driver to an order based on the order's pickup location and available drivers.
    @Override
    public void assignDriverToOrder(Long orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new BusinessException("Order not found."));

        if (!order.getStatus().equals(OrderStatus.PENDING)) {
            throw new BusinessException("Order is not in the correct state to be assigned.");
        }

        List<Driver> availableDrivers = driverRepository.findAvailableDrivers();
        if (availableDrivers.isEmpty()) {
            throw new BusinessException("No drivers available at the moment.");
        }

        // Assumes a method exists to calculate the distance to the pickup location.
        String pickupLocationStr = String.valueOf(order.getPickupLocation());
        if (pickupLocationStr == null || pickupLocationStr.isEmpty()) {
            throw new BusinessException("Pickup location is not set for the order.");
        }

        // Selects the closest available driver.
        Driver closestDriver = availableDrivers.stream()
                .min(Comparator.comparing(driver -> calculateDistance(pickupLocationStr, driver.getLocation())))
                .orElseThrow(() -> new BusinessException("No suitable driver found for the order."));

        // Assigns the selected driver to the order and updates its status to ASSIGNED.
        order.setDriver(closestDriver);
        order.setStatus(OrderStatus.ASSIGNED);

        orderRepository.save(order);
    }

    // Calculates the distance between two geographical locations.
    public static double calculateDistance(String pickupLocationStr1, String pickupLocationStr2) {
        if (pickupLocationStr1 == null || pickupLocationStr2 == null) {
            throw new IllegalArgumentException("The provided locations cannot be null.");
        }

        final int R = 6371; // Earth's radius in kilometers.
        String[] loc1 = pickupLocationStr1.split(",");
        String[] loc2 = pickupLocationStr2.split(",");
        double lat1 = Double.parseDouble(loc1[0]);
        double lon1 = Double.parseDouble(loc1[1]);
        double lat2 = Double.parseDouble(loc2[0]);
        double lon2 = Double.parseDouble(loc2[1]);

        double latDistance = Math.toRadians(lat2 - lat1);
        double lonDistance = Math.toRadians(lon2 - lon1);
        double a = Math.sin(latDistance / 2) * Math.sin(latDistance / 2) +
                Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) *
                        Math.sin(lonDistance / 2) * Math.sin(lonDistance / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        return R * c; // Distance in kilometers.
    }
    // Saves an order based on the provided OrderDto and associated client ID.
    @Override
    public Order saveOrder(OrderDto orderDto, Long clientId) {
        // Estimates the order cost and stores the result in the OrderDto variable.
        BigDecimal value = estimateOrderCost(orderDto);
        OrderStatus status = OrderStatus.PENDING; // Initial status for new orders.
        Client client = clientService.getClientById(clientId); // Retrieves the client based on the provided client ID.

        // Creates a new order with the calculated details and saves it to the repository.
        Order order = new Order(orderDto.getOrigin(), orderDto.getDestination(), value, status, LocalDate.now(), LocalTime.now(),
                orderDto.getDescription(), orderDto.getFeedback(), client, orderDto.getCategory());

        return orderRepository.save(order); // Persists the order and returns the saved instance.
    }

    // Retrieves the order history of a specific client using the client ID.
    @Override
    public List<Order> getClientOrderHistory(Long clientId) {
        // Finds all orders associated with the given client ID.
        return orderRepository.findByClientId(clientId);
    }

    // Accepts an order by setting its status to ACCEPTED if conditions are met.
    @Override
    public void acceptOrder(Long orderId, Long driverId) throws BusinessException {
        // Retrieves the order by ID or throws if not found.
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new BusinessException("Order not found."));

        // Validates the order's current status.
        if (!order.getStatus().equals(OrderStatus.PENDING)) {
            throw new BusinessException("Order is not in the correct state to be accepted.");
        }

        // Retrieves the driver by ID or throws if not found.
        Driver driver = driverRepository.findById(driverId)
                .orElseThrow(() -> new BusinessException("Driver not found."));

        // Checks if the driver is online and available to accept orders.
        if (!driver.getIsOnline()) {
            throw new BusinessException("Driver is not available to accept orders.");
        }

        // Sets the order's status to ACCEPTED and assigns the driver.
        order.setStatus(OrderStatus.ACCEPTED);
        order.setDriver(driver);

        // Attempts to save the updated order, handling any exceptions that occur.
        try {
            orderRepository.save(order);
        } catch (Exception e) {
            throw new BusinessException("Error updating the order: " + e.getMessage());
        }
    }

    // Confirms the pickup of an order by the assigned driver.
    @Override
    @Transactional
    public void confirmPickUp(Long orderId, Long driverId) throws Exception {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new OrderNotFoundException("Order not found."));

        // Validates that the correct driver is attempting to confirm the pickup.
        if (!order.getDriver().getId().equals(driverId)) {
            throw new UnauthorizedDriverException("Driver is not authorized to pick up this order.");
        }

        // Checks if the order is in the ACCEPTED state, which allows for pickup confirmation.
        if (order.getStatus() != OrderStatus.ACCEPTED) {
            throw new InvalidOrderStateException("Order is not in a state that allows pick-up confirmation.");
        }

        // Updates the order status to PICKED_UP.
        order.setStatus(OrderStatus.PICKED_UP);
        orderRepository.save(order);
    }

    // Updates the status of an order to a new specified status, ensuring valid state transitions.
    @Override
    @Transactional
    public void updateOrderStatus(Long orderId, OrderStatus newStatus, Long driverId) throws Exception {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new OrderNotFoundException("Order not found."));

        // Ensures the correct driver is updating the order.
        if (!order.getDriver().getId().equals(driverId)) {
            throw new UnauthorizedDriverException("Driver is not assigned to this order.");
        }

        // Checks for valid state transitions based on the new status.
        boolean isValidTransition = false;

        switch (newStatus) {
            case PICKED_UP:
                isValidTransition = order.getStatus() == OrderStatus.PENDING;
                break;
            case IN_PROGRESS:
                isValidTransition = order.getStatus() == OrderStatus.PICKED_UP;
                break;
            case DELIVERED:
                isValidTransition = order.getStatus() == OrderStatus.IN_PROGRESS;
                break;
            default:
                throw new InvalidOrderStateException("Unsupported status transition.");
        }

        if (!isValidTransition) {
            throw new InvalidOrderStateException("Invalid status transition from " +
                    order.getStatus() + " to " + newStatus + ".");
        }

        // Updates the order status and saves the changes.
        order.setStatus(newStatus);
        orderRepository.save(order);
    }

    // Retrieves the order history for a specific driver using the driver ID.
    @Override
    public List<OrderDto> getDriverOrderHistory(Long driverId) {
        // Finds all orders associated with the given driver ID.
        List<Order> orders = orderRepository.findByDriverId(driverId);

        // Converts each Order entity into an OrderDto and collects them into a list.
        return orders.stream()
                .map(this::convertToOrderDto)
                .collect(Collectors.toList());
    }

    // Converts an Order entity into an OrderDto, assuming necessary fields are properly set in the Order object.
    private OrderDto convertToOrderDto(Order order) {
        // Implements the conversion logic here.
        return new OrderDto(
                order.getOrigin(),
                order.getDestination(),
                order.getDescription(),
                order.getFeedback(),
                order.getCategory()
        );
    }




}
