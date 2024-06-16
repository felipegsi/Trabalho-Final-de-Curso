package com.project.uber.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.project.uber.model.DriverResponse;
import com.project.uber.service.implementation.ResponseStorageImpl;
import com.project.uber.service.interfac.ResponseStorage;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.handler.annotation.*;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.messaging.simp.annotation.SendToUser;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;

@Controller
public class NotificationController {

    @Autowired
    private SimpMessagingTemplate simpMessagingTemplate;

    @Autowired
    private ResponseStorage responseStorage;


    @MessageMapping("/driver/reply-{driverId}")
    public void handleDriverResponse(@DestinationVariable Long driverId, @Payload DriverResponse driverResponse) {
        System.out.println("Recebida a resposta do motorista: " + driverResponse.getResponse() + " para o pedido: " + driverResponse.getOrderId());
        boolean accepted = driverResponse.getResponse().equalsIgnoreCase("sim");
        responseStorage.saveResponse(driverId, driverResponse.getOrderId(), accepted);
    }

    @MessageMapping("/broadcast")
    @SendTo("/topic/reply")
    public String broadcastMessage ( @Payload String mensagem) { //payload é a mensagem enviada pelo cliente
        return  "Você recebeu uma mensagem: " + mensagem;
    }

    @MessageMapping("/user-message")
    @SendToUser("/queue/reply")
    public String sendBackToUser ( @Payload String message, @Header("simpSessionId") String sessionId) {
        return  "Só você recebeu esta mensagem: " + message;
    }

    @MessageMapping("/user-message-{userName}")
    public  void  sendToOtherUser (@Payload String mensagem, @DestinationVariable String userName, @Header("simpSessionId") String sessionId) {
        simpMessagingTemplate.convertAndSend( "/queue/driver/reply-" + userName, "Você recebeu uma mensagem de alguém: " + mensagem);
    }

    // Enviar mensagem a um usuário específico via WebSocket
    public void sendNotificationToUser(String userId, String message) {
        simpMessagingTemplate.convertAndSendToUser(userId, "/queue/notifications", message);
    }




    // Endpoint para enviar mensagens a um usuário específico
    @RestController
    public class NotificationRestController {

        @PostMapping("/api/notifications/user")
        public void sendNotificationToSpecificUser(@RequestParam String userId, @RequestBody String message) {
            simpMessagingTemplate.convertAndSendToUser(userId, "/queue/notifications", message);
        }
    }
}
