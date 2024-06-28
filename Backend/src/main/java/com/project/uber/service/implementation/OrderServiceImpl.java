package com.project.uber.service.implementation;

import com.project.uber.constants.OrderConstants;
import com.project.uber.dtos.ClientDto;
import com.project.uber.dtos.DriverDto;
import com.project.uber.dtos.OrderDto;
import com.project.uber.dtos.VehicleDto;
import com.project.uber.enums.Category;
import com.project.uber.enums.OrderStatus;
import com.project.uber.infra.exceptions.BusinessException;
import com.project.uber.infra.exceptions.InvalidOrderStateException;
import com.project.uber.infra.exceptions.OrderNotFoundException;
import com.project.uber.infra.exceptions.UnauthorizedDriverException;
import com.project.uber.model.Client;
import com.project.uber.model.Driver;
import com.project.uber.model.Order;
import com.project.uber.model.Vehicle;
import com.project.uber.repository.DriverRepository;
import com.project.uber.repository.OrderRepository;
import com.project.uber.service.interfac.ClientService;
import com.project.uber.service.interfac.OrderService;
import com.project.uber.service.interfac.ResponseStorage;
import jakarta.transaction.Transactional;
import org.json.JSONArray;
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
    public OrderDto saveOrder(OrderDto orderDto, Long clientId) {
        BigDecimal value = estimateOrderCost(orderDto.getOrigin(), orderDto.getDestination(),
                orderDto.getCategory(), orderDto.getWidth(), orderDto.getHeight(), orderDto.getLength(),
                orderDto.getWeight());

        OrderStatus status = OrderStatus.PENDING;
        Client client = clientService.getClientById(clientId);
        Category category = orderDto.getCategory();

        Order order;

        if (category == Category.MOTORIZED) {
            order = new Order(orderDto.getOrigin(), orderDto.getDestination(), value, status,
                    orderDto.getDescription(), category, client, LocalDate.now(), LocalTime.now(),
                    orderDto.getLicensePlate(), orderDto.getModel(), orderDto.getBrand());
        } else {
            order = new Order(orderDto.getOrigin(), orderDto.getDestination(), value, status,
                    orderDto.getDescription(), category, client, LocalDate.now(), LocalTime.now(),
                    orderDto.getWidth(), orderDto.getHeight(), orderDto.getLength(), orderDto.getWeight());
        }

        orderRepository.save(order);

        return convertToFullOrderDto(order);
    }

    public OrderDto convertToFullOrderDto(Order order) {
        if (order.getCategory() == Category.MOTORIZED) {
            return new OrderDto(order.getId(), order.getOrigin(), order.getDestination(), order.getValue(),
                    order.getStatus(), order.getDescription(), order.getFeedback(), order.getCategory(),
                    null, null, null, null, order.getLicensePlate(), order.getModel(), order.getBrand(),
                    convertToClientDto(order.getClient()), null);
        } else {
            return new OrderDto(order.getId(), order.getOrigin(), order.getDestination(), order.getValue(),
                    order.getStatus(), order.getDescription(), order.getFeedback(), order.getCategory(),
                    order.getWidth(), order.getHeight(), order.getLength(), order.getWeight(),
                    null, null, null, convertToClientDto(order.getClient()), null);
        }
    }

    public DriverDto convertToDriverDto(Driver driver) {
        return new DriverDto(driver.getId(), driver.getName(), driver.getEmail(), driver.getBirthdate(), driver.getPhoneNumber(),
                driver.getTaxPayerNumber(), driver.getStreet(), driver.getCity(), driver.getPostalCode(), driver.getLocation(), convertToVehicleDto(driver.getVehicle()));
    }

    public VehicleDto convertToVehicleDto(Vehicle vehicle) {
        return new VehicleDto(vehicle.getCategory(), vehicle.getYear(), vehicle.getPlate(),
                vehicle.getBrand(), vehicle.getModel());
    }

    public ClientDto convertToClientDto(Client client) {
        return new ClientDto(client.getId(), client.getName(), client.getEmail(), client.getBirthdate(),
                client.getPhoneNumber(), client.getTaxPayerNumber(), client.getStreet(),
                client.getCity(), client.getPostalCode());
    }



    @Override
    public BigDecimal estimateOrderCost(String origin, String destination, Category category,
                                        Integer width, Integer height, Integer length, Float weight) throws BusinessException {
        // Use valores padrão se forem nulos
        int safeWidth = width != null ? width : 0;
        int safeHeight = height != null ? height : 0;
        int safeLength = length != null ? length : 0;
        float safeWeight = weight != null ? weight : 0.0f;

        verifyDimensionsAndWeight(category, safeWidth, safeHeight, safeLength, safeWeight); // Verifica se as dimensões e peso estão de acordo com a categoria selecionada.

        BigDecimal distanceInKm = fetchDistanceFromApi(origin, destination);
        return calculateOrderCostBasedOnCategory(category, safeWidth, safeHeight, safeLength, safeWeight, distanceInKm);
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
                    true; // Assumindo que não há limites de tamanho específicos para a categoria motorizada ou é uma categoria especial sem limites explícitos.
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
    public BigDecimal fetchDistanceFromApi(String origin, String destination) throws BusinessException {
        OkHttpClient client = new OkHttpClient();
        String url = String.format(
                "https://maps.googleapis.com/maps/api/directions/json?origin=%s&destination=%s&key=%s",
                origin, destination, "AIzaSyDWkqwPVu8yCPdeR3ynYX-a8VHco5kS-Ik"
        );

        Request request = new Request.Builder().url(url).build();
        try (Response response = client.newCall(request).execute()) {
            assert response.body() != null;
            String responseBody = response.body().string();
            System.out.println("API Response: " + responseBody); // Log the API response

            if (response.isSuccessful()) {
                JSONObject jsonResponse = new JSONObject(responseBody);
                if (!jsonResponse.has("routes") || jsonResponse.getJSONArray("routes").isEmpty()) {
                    throw new BusinessException("Invalid JSON response structure");
                }

                // Google API response parsing
                JSONArray routes = jsonResponse.getJSONArray("routes");
                JSONObject route = routes.getJSONObject(0);
                JSONArray legs = route.getJSONArray("legs");
                JSONObject leg = legs.getJSONObject(0);
                JSONObject distance = leg.getJSONObject("distance");

                int distanceInMeters = distance.getInt("value");
                BigDecimal distanceInKm = new BigDecimal(distanceInMeters).divide(BigDecimal.valueOf(1000), MathContext.DECIMAL64);

                System.out.println("Fetched distance: " + distanceInKm + " km");
                return distanceInKm;
            } else {
                System.out.println("Unexpected response: " + response.code() + " " + response.message());
                throw new BusinessException("Unexpected response from API");
            }
        } catch (Exception e) {
            System.out.println("Failed to fetch distance: " + e.getMessage());
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

        // Impacto menor no custo
        return baseRate.add(surcharge).multiply(adjustmentFactor).multiply(distanceInKm);
    }

    /**
     * Determines the additional cost based on the category of the order.
     *
     * @param category The category of the order.
     * @return The surcharge for the specific category.
     */
    private BigDecimal getCategorySpecificSurcharge(Category category) {
        return switch (category) {
            case SMALL -> BigDecimal.valueOf(0.75); // Adicional de 0.75€ por kilómetro
            case MEDIUM -> BigDecimal.valueOf(0.90); // Adicional de 0.90€ por kilómetro
            case LARGE -> BigDecimal.valueOf(1.20); // Adicional de 1.20€ por kilómetro
            case MOTORIZED -> BigDecimal.valueOf(1.40); // Adicional de 1.40€ por kilómetro
            default -> throw new IllegalArgumentException("Invalid order category");
        };
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
                break;
        }

        BigDecimal combinedFactor = sizeFactor.multiply(weightFactor);
        double rootValue = Math.pow(combinedFactor.doubleValue(), 0.15); // Aplicar a raiz 10
        return new BigDecimal(rootValue, MathContext.DECIMAL64); // Converter de volta para BigDecimal
    }

    private BigDecimal calculateSizeFactor(int width, int height, int length, int maxWidth, int maxHeight, int maxLength) {
        double volume = width * height * length;
        double maxVolume = maxWidth * maxHeight * maxLength;
        double ratio = volume / maxVolume;
        return BigDecimal.valueOf(Math.pow(ratio, 0.1)); // Ajuste leve usando a raiz 10
    }

    private BigDecimal calculateWeightFactor(float weight, float maxWeight) {
        double ratio = weight / maxWeight;
        return BigDecimal.valueOf(Math.pow(ratio, 0.15)); // Ajuste leve usando a raiz 10
    }


    // Associo a ordem a um motorista disponível e envia uma solicitação para aceitar a ordem.
    @Override
    public DriverDto assignOrderToDriver(Long orderId) throws BusinessException {
        Order order = findOrderById(orderId); // Encontra a ordem ou lança uma exceção
        validateOrder(order); // Verifica se a ordem pode ser atribuída
        List<Driver> availableDrivers = findAvailableDrivers(order.getOrigin(), order.getCategory()); // Motoristas disponíveis
        return tryAssignOrderToDrivers(order, availableDrivers); // Tenta atribuir a ordem
    }
    // Tenta aceitar a ordem com cada motorista disponível.
    private DriverDto tryAssignOrderToDrivers(Order order, List<Driver> availableDrivers) throws BusinessException {
        for (Driver driver : availableDrivers) {
            System.out.println("Trying driver: " + driver.getName() + " - " + driver.getEmail() + " - " + driver.getId());
            if (Boolean.TRUE.equals(acceptOrder(order, driver))) {
                order.setDriver(driver);
                return convertToDriverDto(driver); // Retorna o motorista que aceitou a ordem.
            }
        }
        throw new BusinessException("No available drivers could accept the order at this time.");
    }

    // Encontra a ordem pelo ID ou lança uma exceção se não encontrada.
    private Order findOrderById(Long orderId) throws BusinessException {
        return orderRepository.findById(orderId)
                .orElseThrow(() -> new BusinessException("Order not found."));
    }

    @Override
    public OrderDto getOrderDtoById(Long orderId) throws BusinessException {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new BusinessException("Order not found."));
        return convertToFullOrderDto(order);
    }

    // Valida se a ordem está em um estado apropriado para aceitação.
    private void validateOrder(Order order) throws BusinessException {
        if (!order.getStatus().equals(OrderStatus.PENDING)) {
            throw new BusinessException("Order is not in the correct state to be assigned.");
        }
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

    private void sendOrderRequestToDriver(Driver driver, Order order) {
        try {
            String message = "New order worth " + String.format("%.2f", order.getValue()) + "€. Do you want to accept?? (Yes or No)"; // Mensagem para o motorista
            String destination = "/queue/driver/reply-" + driver.getId();

            // Cria os headers para incluir o orderId
            Map<String, Object> headers = new HashMap<>();
            headers.put("orderId", order.getId().toString());
            System.out.println("Enviando mensagem para: " + destination + " com orderId: " + order.getId() + " e headers: " + headers); // Log adicional
            simpMessagingTemplate.convertAndSend(destination, message, headers);
        } catch (BusinessException e) {
            throw new BusinessException("Error sending order request to driver");
        }
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


    // Returns a list of available drivers based on the provided location and vehicle type.
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
    public void pickupOrderStatus(Long orderId) throws Exception {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new OrderNotFoundException("Order not found."));
        OrderStatus newStatus = OrderStatus.PICKED_UP;
        // Updates the order status and saves the changes.
        order.setStatus(newStatus);
        orderRepository.save(order);
    }
    @Override
    @Transactional
    public void deliverOrderStatus(Long orderId, Long driverId) throws Exception {
        Driver driver = driverRepository.findById(driverId)
                .orElseThrow(() -> new BusinessException("Driver not found."));
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new OrderNotFoundException("Order not found."));
        double driverSalary = order.getValue().doubleValue() * 0.85; // 85% of the order value
        // Updates the driver's salary and status.
        driver.setSalary(driver.getSalary() + driverSalary);
        // Updates the driver's status to not busy.
        driver.setIsBusy(false);
        // Saves the changes to the driver.
        driverRepository.save(driver);
        // Updates the status of the order to DELIVERED.
        OrderStatus newStatus = OrderStatus.DELIVERED;
        // Updates the order status and saves the changes.
        order.setStatus(newStatus);
        orderRepository.save(order);
    }

    @Override
    @Transactional
    public void cancelledOrderStatus(Long orderId, Long driverId) throws Exception {
        Driver driver = driverRepository.findById(driverId)
                .orElseThrow(() -> new BusinessException("Driver not found."));
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new OrderNotFoundException("Order not found."));

        // Updates the driver's status to not busy.
        driver.setIsBusy(false);
        // Saves the changes to the driver.
        driverRepository.save(driver);
        // Updates the status of the order to DELIVERED.
        OrderStatus newStatus = OrderStatus.CANCELLED;
        // Updates the order status and saves the changes.
        order.setStatus(newStatus);
        orderRepository.save(order);
    }



    // Retrieves the order history for a specific driver using the driver ID.
 /*   @Override
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
    }*/


}