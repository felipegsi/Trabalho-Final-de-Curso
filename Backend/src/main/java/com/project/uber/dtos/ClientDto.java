package com.project.uber.dtos;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class ClientDto {
    /* String name,
     String email,
     String password,
     String phoneNumber,
     int taxPayerNumber,
     String street,
     String city,
     int postalCode*/
    private String name;
    private String email;
    private String phoneNumber;
    private int taxPayerNumber;
    private String street;
    private String city;
    private int postalCode;



    // contrutuor com dados de saida(nao deve incluir a senha)
    public ClientDto(String name, String email, String phoneNumber, int taxPayerNumber, String street, String city, int postalCode) {
        this.name = name;
        this.email = email;
        this.phoneNumber = phoneNumber;
        this.taxPayerNumber = taxPayerNumber;
        this.street = street;
        this.city = city;
        this.postalCode = postalCode;
    }


}
