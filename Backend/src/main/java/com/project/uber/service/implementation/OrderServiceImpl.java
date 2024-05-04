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
import java.math.MathContext;
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

    // Saves an order based on the provided OrderDto and associated client ID.
    @Override
    public List<BigDecimal> estimateAllCategoryOrderCost(String origin, String destination) throws BusinessException {
        BigDecimal distanceInKm = fetchDistanceFromApi(origin, destination);

        //devolve uma lista com o valor de cada categoria
        return List.of(
                distanceInKm.multiply(BigDecimal.valueOf(1.00)), // Small
                distanceInKm.multiply(BigDecimal.valueOf(2.00)), // Medium
                distanceInKm.multiply(BigDecimal.valueOf(3.00)), // Large
                distanceInKm.multiply(BigDecimal.valueOf(5.00))); // Motorized
    }


    @Override
    public BigDecimal estimateOrderCost(String origin, String destination, Category category,
                                        int width, int height, int length, float weight) throws BusinessException {

        verifyDimensionsAndWeight(category, width, height, length, weight); // Verifies if the dimensions and weight comply with the selected category.

        BigDecimal distanceInKm = fetchDistanceFromApi(origin, destination);
        return calculateOrderCostBasedOnCategory(category, width, height, length, weight, distanceInKm);
    }

    private void verifyDimensionsAndWeight(Category category,
                                           int width, int height, int length, float weight) throws BusinessException {
        boolean isValid = switch (category) {
            case SMALL -> width <= OrderConstants.SMALL_WIDTH && height <= OrderConstants.SMALL_HEIGHT && length <= OrderConstants.SMALL_LENGTH && weight <= OrderConstants.SMALL_WEIGHT;
            case MEDIUM -> width <= OrderConstants.MEDIUM_WIDTH && height <= OrderConstants.MEDIUM_HEIGHT && length <= OrderConstants.MEDIUM_LENGTH && weight <= OrderConstants.MEDIUM_WEIGHT;
            case LARGE -> width <= OrderConstants.LARGE_WIDTH && height <= OrderConstants.LARGE_HEIGHT && length <= OrderConstants.LARGE_LENGTH && weight <= OrderConstants.LARGE_WEIGHT;
            case MOTORIZED -> true; // Assuming no specific size limits for motorized or it's a special category without explicit limits.
            default -> false;
        };

        if (!isValid) {
            throw new BusinessException("Dimensions and weight do not comply with the selected category.");
        }
    }

    /**
     * Fetches the distance between two locations using an external API.
     * @param origin The origin location.
     * @param destination The destination location.
     * @return The distance in kilometers as BigDecimal.
     */
    private BigDecimal fetchDistanceFromApi(String origin,String destination) throws BusinessException {
        OkHttpClient client = new OkHttpClient();
        String[] originParts = origin.split(",");
        String[] destinationParts = destination.split(",");

        String url = String.format(
                "https://api.openrouteservice.org/v2/directions/driving-car?api_key=%s&start=%s,%s&end=%s,%s",
                "5b3ce3597851110001cf6248b8fc3d76941643ee9de00a23820316b7", originParts[1], originParts[0], destinationParts[1], destinationParts[0]
        );

        Request request = new Request.Builder().url(url).build();
        try (Response response = client.newCall(request).execute()) {
            JSONObject jsonResponse = new JSONObject(response.body().string());
            int distanceInMeters = jsonResponse.getJSONArray("features")
                    .getJSONObject(0)
                    .getJSONObject("properties")
                    .getJSONArray("segments")
                    .getJSONObject(0)
                    .getInt("distance");
            return new BigDecimal(distanceInMeters).divide(BigDecimal.valueOf(1000));
        } catch (Exception e) {
            throw new BusinessException("Failed to fetch distance from API");
        }
    }

    /**
     * Calculates the cost of an order based on its category, dimensions, weight, and distance.
     * @param category The category of the order.
     * @param width The width of the order.
     * @param height The height of the order.
     * @param length The length of the order.
     * @param weight The weight of the order.
     * @param distanceInKm The distance between the origin and destination of the order.
     * @return The calculated cost as BigDecimal.
     */
    private BigDecimal calculateOrderCostBasedOnCategory(Category category,
                                                         int width, int height, int length, float weight, BigDecimal distanceInKm) {
        BigDecimal baseRate = BigDecimal.ONE;
        BigDecimal surcharge = getCategorySpecificSurcharge(category);
        BigDecimal adjustmentFactor = calculateAdjustmentFactor(category, width, height, length, weight);
        // Minor impact on the cost
        return baseRate.add(surcharge).multiply(adjustmentFactor).multiply(distanceInKm);
    }

    /**
     * Determines the additional cost based on the category of the order.
     * @param category The category of the order.
     * @return The surcharge for the specific category.
     */
    private BigDecimal getCategorySpecificSurcharge(Category category) {
        switch (category) {
            case SMALL: return BigDecimal.valueOf(1.00);
            case MEDIUM: return BigDecimal.valueOf(2.00);
            case LARGE: return BigDecimal.valueOf(3.00);
            case MOTORIZED: return BigDecimal.valueOf(20.00);
            default: throw new IllegalArgumentException("Invalid order category");
        }
    }

    private BigDecimal calculateAdjustmentFactor(Category category, int width, int height, int length, float weight) {


        BigDecimal sizeFactor = BigDecimal.ONE;
        BigDecimal weightFactor = BigDecimal.ONE;

        switch (category) {
            case SMALL:
                sizeFactor = calculateSizeFactor(width, height, length,
                        OrderConstants.SMALL_WIDTH, OrderConstants.SMALL_HEIGHT, OrderConstants.SMALL_LENGTH);
                weightFactor = calculateWeightFactor(weight, OrderConstants.SMALL_WEIGHT);
                break;
            case MEDIUM:
                sizeFactor = calculateSizeFactor(width, height, length,
                        OrderConstants.MEDIUM_WIDTH, OrderConstants.MEDIUM_HEIGHT, OrderConstants.MEDIUM_LENGTH);
                weightFactor = calculateWeightFactor(weight, OrderConstants.MEDIUM_WEIGHT);
                break;
            case LARGE:
                sizeFactor = calculateSizeFactor(width, height, length,
                        OrderConstants.LARGE_WIDTH, OrderConstants.LARGE_HEIGHT, OrderConstants.LARGE_LENGTH);
                weightFactor = calculateWeightFactor(weight, OrderConstants.LARGE_WEIGHT);
                break;
            case MOTORIZED:
                sizeFactor = BigDecimal.ONE; // Assuming no adjustment for motorized category
                weightFactor = BigDecimal.ONE; //mudar dps
                break;
        }

        BigDecimal combinedFactor = sizeFactor.multiply(weightFactor);
        double rootValue = Math.pow(combinedFactor.doubleValue(), 0.15); // Apply the 10th root
        return new BigDecimal(rootValue, MathContext.DECIMAL64); // Convert back to BigDecimal
    }

    private BigDecimal calculateSizeFactor(int width, int height, int length, int maxWidth, int maxHeight, int maxLength) {
        double volume = width * height * length;
        double maxVolume = maxWidth * maxHeight * maxLength;
        double ratio = volume / maxVolume;
        return BigDecimal.valueOf(Math.pow(ratio, 0.1)); // Mild adjustment using the 10th root
    }

    private BigDecimal calculateWeightFactor(float weight, float maxWeight) {
        double ratio = weight / maxWeight;
        return BigDecimal.valueOf(Math.pow(ratio, 0.15)); // Mild adjustment using the 10th root
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


        BigDecimal estimatedCost = estimateOrderCost(orderDto.getOrigin(),orderDto.getDestination(),
                orderDto.getCategory(), orderDto.getWidth(), orderDto.getHeight(), orderDto.getLength(),
                orderDto.getWeight());

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

        BigDecimal value = estimateOrderCost(orderDto.getOrigin(),orderDto.getDestination(),
                orderDto.getCategory(), orderDto.getWidth(), orderDto.getHeight(), orderDto.getLength(),
                orderDto.getWeight());
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
