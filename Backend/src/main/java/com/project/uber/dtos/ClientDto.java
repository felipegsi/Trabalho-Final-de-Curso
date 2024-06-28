package com.project.uber.dtos;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Getter
@Setter
public class ClientDto {
    private Long id;
    private String name;
    private String email;
    private String birthdate;
    private String phoneNumber;
    private int taxPayerNumber;
    private String street;
    private String city;
    private String postalCode;



    // contrutuor com dados de saida(nao deve incluir a senha)
    public ClientDto(Long id, String name, String email, String birthdate, String phoneNumber,
                     int taxPayerNumber, String street, String city, String postalCode) {
        this.id = id;
        this.name = name;
        this.email = email;
        this.birthdate = birthdate;
        this.phoneNumber = phoneNumber;
        this.taxPayerNumber = taxPayerNumber;
        this.street = street;
        this.city = city;
        this.postalCode = postalCode;
    }


}
