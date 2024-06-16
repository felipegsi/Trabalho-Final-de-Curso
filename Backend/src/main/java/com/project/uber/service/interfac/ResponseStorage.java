package com.project.uber.service.interfac;

import java.util.Map;
import java.util.concurrent.*;

public interface ResponseStorage {

    void saveResponse(Long driverId, Long orderId, Boolean response);

    Boolean waitForResponse(Long driverId, Long orderId, Long timeoutInSeconds) throws InterruptedException, ExecutionException, TimeoutException;

}