package com.project.uber.model;

import com.fasterxml.jackson.annotation.JsonBackReference;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDate;

@EqualsAndHashCode(callSuper = true)
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


    public Driver() {
    }

    public Driver(String name, String email, LocalDate birthdate, String password, String phoneNumber, Integer taxPayerNumber,
                  String street, String city, Integer postalCode) {
        super(name, email, password, phoneNumber, taxPayerNumber, street, city, postalCode);
        this.birthdate = birthdate;
    }

    @Override
    public String toString() {
        return "Driver{" +
                "user=" + super.toString() +
                ", salary=" + salary +
                ", isOnline=" + isOnline +
                ", isBusy=" + isBusy +
                ", vehicleId=" + vehicle.getId() +
                ", location='" + location + '\'' +
                ", birthdate=" + birthdate +
                '}';
    }
}
