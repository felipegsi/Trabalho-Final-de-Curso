package com.project.uber.service.implementation;

import com.project.uber.service.interfac.ResponseStorage;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.concurrent.*;

@Service
public class ResponseStorageImpl implements ResponseStorage {

    private final Map<Long, Map<Long, CompletableFuture<Boolean>>> responses = new ConcurrentHashMap<>();


    @Override
    public void saveResponse(Long driverId, Long orderId, Boolean response) {
        Map<Long, CompletableFuture<Boolean>> driverResponses = responses.computeIfAbsent(driverId, k -> new ConcurrentHashMap<>());
        CompletableFuture<Boolean> future = driverResponses.computeIfAbsent(orderId, k -> new CompletableFuture<>());
        future.complete(response);
    }

    @Override
    public Boolean waitForResponse(Long driverId, Long orderId, Long timeoutInSeconds) throws InterruptedException, ExecutionException, TimeoutException {
        Map<Long, CompletableFuture<Boolean>> driverResponses = responses.computeIfAbsent(driverId, k -> new ConcurrentHashMap<>());
        CompletableFuture<Boolean> future = driverResponses.computeIfAbsent(orderId, k -> new CompletableFuture<>());
        try {
            return future.get(timeoutInSeconds, TimeUnit.SECONDS);
        } catch (InterruptedException | ExecutionException | TimeoutException e) {
            return false;
        } finally {
            driverResponses.remove(orderId);
            if (driverResponses.isEmpty()) {
                responses.remove(driverId);
            }
        }
    }
}
