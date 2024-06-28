package com.project.uber.dtos;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class TravelInformationDto {
    private String driverLocation;
    private String orderStatus;

    public TravelInformationDto() {
    }

    public TravelInformationDto(String driverLocation, String orderStatus) {
        this.driverLocation = driverLocation;
        this.orderStatus = orderStatus;
    }

    //TODO. O QUE O CLIENTE VAI PEDIR É ESSA CLASSE MAS O QUE ELE VAI ENVIAR VAI SER O ID DO PEDIDO E O ID DO MOTORISTA
}
