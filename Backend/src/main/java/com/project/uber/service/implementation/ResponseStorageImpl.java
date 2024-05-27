package com.project.uber.service.implementation;

import com.project.uber.service.interfac.ResponseStorage;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.concurrent.*;

@Service
public class ResponseStorageImpl implements ResponseStorage {
    private final Map<Long, CompletableFuture<Boolean>> responses = new ConcurrentHashMap<>();

    public void saveResponse(Long driverId, Boolean response) {
        CompletableFuture<Boolean> future = responses.getOrDefault(driverId, new CompletableFuture<>());
        future.complete(response);
        responses.put(driverId, future);
    }

    public Boolean waitForResponse(Long driverId) {
        CompletableFuture<Boolean> future = responses.computeIfAbsent(driverId, k -> new CompletableFuture<>());
        try {
            return future.get(30, TimeUnit.SECONDS); // Espera por até 30 segundos pela resposta
        } catch (InterruptedException | ExecutionException | TimeoutException e) {
            return null; // Trata exceções conforme necessário
        } finally {
            responses.remove(driverId); // Limpa a resposta após o uso
        }
    }
}