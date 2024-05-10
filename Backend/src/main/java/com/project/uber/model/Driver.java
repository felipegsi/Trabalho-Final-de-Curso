package com.project.uber.model;

import com.fasterxml.jackson.annotation.JsonBackReference;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDate;

@Entity
@Table(name = "drivers")
@Data
public class Driver extends User {
    //@Lob
    // @Column(name = "criminalRecord")//estava dando erro aqui por causa do tipo de dado
    // private byte[] criminalRecord; // Confirmado como byte[] para armazenar uma imagem
    @Column(name = "salary")
    private double salary; // Alterado para BigDecimal

    @Column(name = "is_online")
    @JsonProperty(value = "is_online", access = JsonProperty.Access.WRITE_ONLY, defaultValue = "false")
    private Boolean isOnline = false; // Offline por padrão

    @Column(name = "is_busy")
    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY, defaultValue = "false")
    private Boolean isBusy = false; // Indica se o motorista está ocupado com um pedido

    @OneToOne(mappedBy = "driver", cascade = CascadeType.ALL)//cascade para quando deletar um driver, deletar o veículo também
    @JsonBackReference
    private Vehicle vehicle;

    @Column(name = "location")
    private String location;

    @Column(name = "birthdate")
    private LocalDate birthdate;

    public Driver(String name, String email, String password,
                  String phoneNumber, int taxPayerNumber, String street,
                  String city, int postalCode,
                  //byte[] criminalRecord
                  Vehicle vehicle
    ) {
        super(name, email, password, phoneNumber, taxPayerNumber, street,
                city, postalCode);
        //this.criminalRecord = criminalRecord;
        this.vehicle = vehicle;
    }

    public Driver() {
    }


    public Driver(String name, String email, LocalDate birthdate, String passwordHash, String phoneNumber,
                  int taxPayerNumber, String street, String city, int postalCode, boolean isBusy) {
        super(name, email, passwordHash, phoneNumber, taxPayerNumber, street, city, postalCode);
        this.birthdate = birthdate;
        this.isBusy = isBusy;
    }
}
