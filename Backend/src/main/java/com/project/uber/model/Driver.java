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
    public Driver(String name, String email, String passwordHash, String s, int i, String street, String city, int i1) {
        super(name, email, passwordHash, s, i, street,
                city, i1);
    }

    public Driver(String name, String email, LocalDate birthdate, String passwordHash, String s, int i, String street, String city, int i1) {
        super(name, email, passwordHash, s, i, street,
                city, i1);
        this.birthdate = birthdate;
    }
}
