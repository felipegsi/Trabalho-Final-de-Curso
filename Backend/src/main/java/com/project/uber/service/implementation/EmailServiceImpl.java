package com.project.uber.service.implementation;

import com.project.uber.dtos.EmailDto;
import com.project.uber.model.Order;
import com.project.uber.service.interfac.EmailService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

// This class is a service implementation for the Email entity. It implements the EmailService interface.
@Service
public class EmailServiceImpl implements EmailService {

    // The JavaMailSender is autowired, which means Spring will automatically inject an instance of JavaMailSender here.
    @Autowired
    private JavaMailSender emailSender;

    // This method is used to send a simple email message. It creates a new SimpleMailMessage, sets the sender, recipient, subject, and text,
    // and then sends the email using the JavaMailSender.
    @Override
    public void sendSimpleMessage(EmailDto emailDto) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom("uberdemercadorias@gmail.com");
        message.setTo(emailDto.to());
        message.setSubject(emailDto.subject());
        message.setText(emailDto.text());
        emailSender.send(message);
    }

    // This method is used to send an email about an order status update. It creates a new EmailDto with the client's email, a subject, and a text that includes the order's status,
    // and then calls the sendSimpleMessage method to send the email.
    @Override
    public void sendOrderStatusUpdateEmail(Order order) {
        EmailDto emailDto = new EmailDto(
                order.getClient().getEmail(),
                "Order status update",
                "Your order status has been updated to: " +
                        order.getStatus());
        sendSimpleMessage(emailDto);
    }
}
