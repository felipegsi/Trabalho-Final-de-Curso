package com.project.uber.controller;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;

@Controller
public class NotificationController {

    @Autowired
    private SimpMessagingTemplate template;

    // Simula o envio de uma notificação para o motorista mais próximo
    public void notifyNearestDriver(String driverId, String message) {
        // Simula encontrar o ID do canal/socket do motorista mais próximo
        String destination = "/topic/" + driverId;
        this.template.convertAndSend(destination, "New order notification: " + message);
    }

    @MessageMapping("/notify")
    @SendTo("/topic/notifications")
    public String sendNotification(String message) {
        // Lógica para processar a mensagem recebida
        return "New notification: " + message;
    }
}