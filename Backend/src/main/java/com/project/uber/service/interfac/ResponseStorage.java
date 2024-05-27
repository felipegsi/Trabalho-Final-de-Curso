package com.project.uber.service.interfac;

import java.util.Map;
import java.util.concurrent.*;

public interface ResponseStorage {

    void saveResponse(Long driverId, Boolean response);

    Boolean waitForResponse(Long driverId);

}