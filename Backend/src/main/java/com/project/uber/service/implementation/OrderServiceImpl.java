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
import com.project.uber.service.interfac.ResponseStorage;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;

import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.MathContext;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
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

    @Autowired
    private SimpMessagingTemplate simpMessagingTemplate;


    @Autowired
    private ResponseStorage responseStorage;

    // Saves an order based on the provided OrderDto and associated client ID.
    @Override
    public Order saveOrder(OrderDto orderDto, Long clientId) {
        // Estimates the order cost and stores the result in the OrderDto variable.

        BigDecimal value = estimateOrderCost(orderDto.getOrigin(), orderDto.getDestination(),
                orderDto.getCategory(), orderDto.getWidth(), orderDto.getHeight(), orderDto.getLength(),
                orderDto.getWeight());
        OrderStatus status = OrderStatus.PENDING; // Initial status for new orders.
        Client client = clientService.getClientById(clientId); // Retrieves the client based on the provided client ID.
        Category category = orderDto.getCategory(); // Retrieves the category from the OrderDto.

        // Creates a new order with the calculated details and saves it to the repository.
        Order order = new Order(orderDto.getOrigin(), orderDto.getDestination(), value, status, LocalDate.now(), LocalTime.now(),
                orderDto.getDescription(), orderDto.getFeedback(), client, category);

        return orderRepository.save(order); // Persists the order and returns the saved instance.
    }

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
            case SMALL ->
                    width <= OrderConstants.SMALL_WIDTH && height <= OrderConstants.SMALL_HEIGHT && length <= OrderConstants.SMALL_LENGTH && weight <= OrderConstants.SMALL_WEIGHT;
            case MEDIUM ->
                    width <= OrderConstants.MEDIUM_WIDTH && height <= OrderConstants.MEDIUM_HEIGHT && length <= OrderConstants.MEDIUM_LENGTH && weight <= OrderConstants.MEDIUM_WEIGHT;
            case LARGE ->
                    width <= OrderConstants.LARGE_WIDTH && height <= OrderConstants.LARGE_HEIGHT && length <= OrderConstants.LARGE_LENGTH && weight <= OrderConstants.LARGE_WEIGHT;
            case MOTORIZED ->
                    true; // Assuming no specific size limits for motorized or it's a special category without explicit limits.
            default -> false;
        };

        if (!isValid) {
            throw new BusinessException("Dimensions and weight do not comply with the selected category.");
        }
    }

    /**
     * Fetches the distance between two locations using an external API.
     *
     * @param origin      The origin location.
     * @param destination The destination location.
     * @return The distance in kilometers as BigDecimal.
     */
    private BigDecimal fetchDistanceFromApi(String origin, String destination) throws BusinessException {
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
            BigDecimal distanceInKm = new BigDecimal(distanceInMeters).divide(BigDecimal.valueOf(1000), MathContext.DECIMAL64);

            System.out.println("Fetched distance: " + distanceInKm + " km"); // Log the fetched distance
            return distanceInKm;
        } catch (Exception e) {
            System.out.println("Failed to fetch distance: " + e.getMessage()); // Log failure
            throw new BusinessException("Failed to fetch distance from API");
        }
    }

    /**
     * Calculates the cost of an order based on its category, dimensions, weight, and distance.
     *
     * @param category     The category of the order.
     * @param width        The width of the order.
     * @param height       The height of the order.
     * @param length       The length of the order.
     * @param weight       The weight of the order.
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
     *
     * @param category The category of the order.
     * @return The surcharge for the specific category.
     */
    private BigDecimal getCategorySpecificSurcharge(Category category) {
        switch (category) {
            case SMALL:
                return BigDecimal.valueOf(1.00);
            case MEDIUM:
                return BigDecimal.valueOf(2.00);
            case LARGE:
                return BigDecimal.valueOf(3.00);
            case MOTORIZED:
                return BigDecimal.valueOf(20.00);
            default:
                throw new IllegalArgumentException("Invalid order category");
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

    // Assigns a driver to an order based on the order's pickup location and available drivers.
    // Assigns a driver to an order based on the order's pickup location and available drivers.
    @Override
    public Driver assignOrderToDriver(Long orderId) throws BusinessException {
        Order order = findOrderById(orderId); // Encontra a ordem ou lança uma exceção
        validateOrder(order); // Verifica se a ordem pode ser atribuída

        List<Driver> availableDrivers = findAvailableDrivers(order.getOrigin(), order.getCategory()); // Motoristas disponíveis

        return tryAssignOrderToDrivers(order, availableDrivers); // Tenta atribuir a ordem
    }

    // Encontra a ordem pelo ID ou lança uma exceção se não encontrada.
    private Order findOrderById(Long orderId) throws BusinessException {
        return orderRepository.findById(orderId)
                .orElseThrow(() -> new BusinessException("Order not found."));
    }

    // Valida se a ordem está em um estado apropriado para aceitação.
    private void validateOrder(Order order) throws BusinessException {
        if (!order.getStatus().equals(OrderStatus.PENDING)) {
            throw new BusinessException("Order is not in the correct state to be assigned.");
        }
    }

    // Tenta aceitar a ordem com cada motorista disponível.
    private Driver tryAssignOrderToDrivers(Order order, List<Driver> availableDrivers) throws BusinessException {
        for (Driver driver : availableDrivers) {
            System.out.println("Trying driver: " + driver.getName() + " - " + driver.getEmail() + " - " + driver.getId());
            if (Boolean.TRUE.equals(acceptOrder(order, driver))) {
                return driver; // Retorna o motorista que aceitou a ordem.
            }
        }
        throw new BusinessException("No available drivers could accept the order at this time.");
    }

    public Boolean acceptOrder(Order order, Driver driver) throws BusinessException {
        validateDriverForAcceptance(driver); // Verifica se o motorista pode aceitar a ordem
        sendOrderRequestToDriver(driver, order); // Envia a solicitação para o motorista
        return handleDriverResponse(driver, order); // Lida com a resposta do motorista
    }

    // Valida se o motorista está disponível para aceitar a ordem.
    private void validateDriverForAcceptance(Driver driver) throws BusinessException {
        if (!driver.getIsOnline()) {
            throw new BusinessException("Driver is not available to accept orders.");
        }
        if (driver.getIsBusy()) {
            throw new BusinessException("Driver is currently busy.");
        }
    }

    // Envia solicitação para o motorista via WebSocket.
    /*private void sendOrderRequestToDriver(Driver driver, Order order) {
        String message = "Você foi escolhido para carregar uma encomenda no valor de " + String.format("%.2f", order.getValue()) + "€. Aceitar? (Sim ou Não)";
        String destination = "/queue/driver/reply-" + driver.getId();

        // Cria os headers para incluir o orderId
        SimpMessageHeaderAccessor headerAccessor = SimpMessageHeaderAccessor.create();
        headerAccessor.setLeaveMutable(true); // Deixa os headers mutáveis para adicionar informações
        headerAccessor.setHeader("orderId", order.getId().toString());
        headerAccessor.setContentType(MimeTypeUtils.APPLICATION_JSON);

        System.out.println("Enviando mensagem para: " + destination + " com orderId: " + order.getId()); // Log adicional

        // Enviar a mensagem com headers incluídos
        simpMessagingTemplate.convertAndSend(destination, message, headerAccessor.getMessageHeaders());
    }*/

    private void sendOrderRequestToDriver(Driver driver, Order order) {
        String message = "Você foi escolhido para carregar uma encomenda no valor de " + String.format("%.2f", order.getValue()) + "€. Aceitar? (Sim ou Não)";
        String destination = "/queue/driver/reply-" + driver.getId();

        // Cria os headers para incluir o orderId
        Map<String, Object> headers = new HashMap<>();
        headers.put("orderId", order.getId().toString());

        System.out.println("Enviando mensagem para: " + destination + " com orderId: " + order.getId() + " e headers: " + headers); // Log adicional

        simpMessagingTemplate.convertAndSend(destination, message, headers);
    }

    // Lida com a resposta do motorista à solicitação.
    private Boolean handleDriverResponse(Driver driver, Order order) throws BusinessException {
        try {
            Boolean response = responseStorage.waitForResponse(driver.getId(), order.getId(), 20L); // 20 segundos de timeout
            System.out.println("Driver response received for: " + driver.getEmail() + " - " + driver.getEmail());
            if (Boolean.TRUE.equals(response)) {
                order.setStatus(OrderStatus.ACCEPTED);
                order.setDriver(driver);
                driver.setIsBusy(true);
                orderRepository.save(order);
                driverRepository.save(driver);
                System.out.println("Order accepted by driver: " + driver.getEmail());
                return true;
            } else {
                System.out.println("Driver declined or did not respond: " + driver.getEmail());
                return false;
            }
        } catch (Exception e) {
            System.out.println("Error waiting for driver response: " + e.getMessage());
            throw new BusinessException("Error handling driver response");
        }
    }

    // Função que devolve uma lista de motoristas próximos a uma determinada localização.
    public List<Driver> findAvailableDrivers(String location, Category category) throws BusinessException {
        List<Driver> drivers = driverRepository.findAvailableDriversByVehicleType(category); // Motoristas disponíveis

        if (drivers.isEmpty()) {
            throw new BusinessException("No drivers available at the moment.");
        }


        int maxDistance = 1000000; // Distância máxima em metros
        return drivers.stream()
                .filter(driver -> calculateDistance(location, driver.getLocation()) <= maxDistance)
                .sorted(Comparator.comparing(driver -> calculateDistance(location, driver.getLocation())))
                .collect(Collectors.toList()); // Lista de motoristas próximos
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


    // Retrieves the order history of a specific client using the client ID.
    @Override
    public List<Order> getClientOrderHistory(Long clientId) {
        // Finds all orders associated with the given client ID.
        return orderRepository.findByClientId(clientId);
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