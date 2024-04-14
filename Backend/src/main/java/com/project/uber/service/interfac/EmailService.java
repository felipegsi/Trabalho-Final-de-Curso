package com.project.uber.service.interfac;

import com.project.uber.dtos.EmailDto;
import com.project.uber.model.Order;

public interface EmailService {

    void sendSimpleMessage(EmailDto emailDto);

    void sendOrderStatusUpdateEmail(Order order);
}
